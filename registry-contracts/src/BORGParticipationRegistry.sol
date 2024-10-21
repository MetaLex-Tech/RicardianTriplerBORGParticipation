//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.18;

/// @author MetaLeX Labs, Inc.
/// @title BORG Participation Registry
/// @notice `admin`-controlled registry contract for valid agreement factories which records duly adopted BORG Participation Agreements
/// @dev `admin` sets valid factories with approved agreement forms
contract BORGParticipationRegistry {
    /// @notice admin address used to enable or disable factories.
    address public admin;
    /// @notice pending new admin address
    address public _pendingAdmin;

    /// @notice A mapping which records the approved agreement factories.
    mapping(address factory => bool) public agreementFactories;

    /// @notice maps an address to whether it is a confirmed and adopted agreement;
    /// if true, user may call `getDetails()` on such address to easily view the details
    /// @dev enables public getter function to check an agreement address more easily than via the nested `agreements` mapping
    mapping(address => bool) public signedAgreement;

    /// @notice maps an address to a counter in order to support multiple adopted agreements by one address
    mapping(address => uint256) private nonce;

    /// @notice maps an address to their index `nonce` of adopted agreements to the agreement details for the applicable nonce
    mapping(address adopter => mapping(uint256 nonce => address details)) public agreements;

    ///
    /// EVENTS
    ///

    event BORGParticipationRegistry_AdminUpdated(address newAdmin);

    /// @notice An event that records when an address either newly adopts the BORG Participation Agreement, or alters its previous terms.
    event BORGParticipationRegistry_BORGParticipationAdoption(
        address adoptingParty,
        uint256 adoptingPartyNonce,
        address agreementAddress
    );

    /// @notice An event that records when an address is newly enabled as a factory.
    event BORGParticipationRegistry_FactoryEnabled(address factory);

    /// @notice An event that records when an address is newly disabled as a factory.
    event BORGParticipationRegistry_FactoryDisabled(address factory);

    ///
    /// ERRORS
    ///

    error BORGParticipationRegistry_OnlyAdmin();
    error BORGParticipationFactory_OnlyPendingAdmin();
    error BORGParticipationRegistry_OnlyFactories();
    error BORGParticipationRegistry_ZeroAddress();

    /// @notice restrict access to admin-only functions.
    modifier onlyAdmin() {
        if (msg.sender != admin) revert BORGParticipationRegistry_OnlyAdmin();
        _;
    }

    /// @notice Sets the admin address to the provided address.
    constructor(address _admin) {
        admin = _admin;
    }

    /// @notice Officially adopt the agreement, or modify its terms if already adopted. Only callable by approved factories.
    /// @dev updates mappings for each party to the agreement and records the agreement address as a `signedAgreement`
    /// @param adoptingParty address that adopted the BORG Participation Agreement
    /// @param agreementDetailsAddress The contract address housing the agreement details.
    function recordAdoption(address adoptingParty, address agreementDetailsAddress) external {
        if (!agreementFactories[msg.sender]) revert BORGParticipationRegistry_OnlyFactories();
        uint256 _adoptingPartyNonce = ++nonce[adoptingParty];

        signedAgreement[agreementDetailsAddress] = true;
        agreements[adoptingParty][_adoptingPartyNonce] = agreementDetailsAddress;

        emit BORGParticipationRegistry_BORGParticipationAdoption(
            adoptingParty,
            _adoptingPartyNonce,
            agreementDetailsAddress
        );
    }

    /// @notice Enables an address as a factory.
    /// @param factory The address to enable.
    function enableFactory(address factory) external onlyAdmin {
        agreementFactories[factory] = true;
        emit BORGParticipationRegistry_FactoryEnabled(factory);
    }

    /// @notice Disables an address as an factory.
    /// @param factory The address to disable.
    function disableFactory(address factory) external onlyAdmin {
        delete agreementFactories[factory];
        emit BORGParticipationRegistry_FactoryDisabled(factory);
    }

    /// @notice allows the `admin` to propose a replacement to their address. First step in two-step address change, as `_newAdmin` will subsequently need to call `acceptAdminRole()`
    /// @dev use care in updating `admin` as it must have the ability to call `acceptAdminRole()`, or once it needs to be replaced, `updateAdmin()`
    /// @param _newAdmin new address for pending `admin`, who must accept the role by calling `acceptAdminRole`
    function updateAdmin(address _newAdmin) external onlyAdmin {
        if (_newAdmin == address(0)) revert BORGParticipationRegistry_ZeroAddress();

        _pendingAdmin = _newAdmin;
    }

    /// @notice allows the pending new admin to accept the role transfer, and receive fees
    /// @dev access restricted to the address stored as `_pendingAdmin` to accept the two-step change. Transfers `admin` role to the caller and deletes `_pendingAdmin` to reset.
    function acceptAdminRole() external {
        address _sender = msg.sender;
        if (_sender != _pendingAdmin) revert BORGParticipationFactory_OnlyPendingAdmin();
        delete _pendingAdmin;
        admin = _sender;
        emit BORGParticipationRegistry_AdminUpdated(admin);
    }
}
