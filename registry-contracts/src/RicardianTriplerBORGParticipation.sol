//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.18;

import "./SignatureValidator.sol";

/// @author MetaLeX Labs, Inc.

interface IBORGParticipationRegistry {
    function recordAdoption(address adoptingParty, address agreementDetailsAddress) external;
}

///
/// STRUCTS AND TYPES
///

/// @notice the details of an account in an agreement
struct Account {
    // The address of the account (EOA or smart contract)
    address accountAddress;
    // The signature of the account. Optionally used to verify that this account has signed hashed agreement details
    bytes signature;
}

/// @notice the details of the agreement, consisting of all necessary information to deploy a BORGParticipation contract and the legal agreement information
struct AgreementDetails {
    /// @notice The `Party` struct details of the party adopting the agreement
    Party adoptingParty;
    /// @notice string name of the applicable BORG
    string BORGName;
    /// @notice IPFS hash of the official MetaLeX BORG Participation Agreement version being agreed to which confirms all terms, and may contain a unique interface identifier
    string legalAgreementURI;
}

/// @notice details of a party: address, name, and contact information
struct Party {
    /// @notice The blockchain address of the party to be used in the BORG multisig(s)
    address partyBlockchainAddy;
    /// @notice The name of the party adopting the agreement
    string partyName;
    /// @notice The contact details of the party (required for legal notifications under the agreement)
    string contactDetails;
}

///
/// CONTRACTS
///

/// @notice Contract that contains the BORG Participation agreement details that will be deployed by the Agreement Factory.
contract RicardianTriplerBORGParticipation {
    uint256 internal constant AGREEMENT_VERSION = 1;

    /// @notice The details of the agreement; accessible via `getDetails`
    AgreementDetails internal details;

    /// @notice Constructor that sets the details of the agreement.
    /// @param _details the `AgreementDetails` struct containing the details of the agreement.
    constructor(AgreementDetails memory _details) {
        details.adoptingParty = _details.adoptingParty;
        details.BORGName = _details.BORGName;
        details.legalAgreementURI = _details.legalAgreementURI;
    }

    /// @notice Function that returns the version of the agreement.
    function version() external pure returns (uint256) {
        return AGREEMENT_VERSION;
    }

    /// @notice Function that returns the details of the agreement.
    /// @dev view function necessary to convert storage to memory automatically for the nested structs.
    /// @return `AgreementDetails` struct containing the details of the agreement.
    function getDetails() external view returns (AgreementDetails memory) {
        return details;
    }
}

/// @notice Factory contract that creates a new RicardianTriplerBORGParticipation contract if adopted properly, and records adoption in the BORGParticipationRegistry.
/// @dev various events emitted in the `registry` contract
contract AgreementV1Factory is SignatureValidator {
    uint256 internal constant FACTORY_VERSION = 1;

    /// @notice The BORGParticipationRegistry contract.
    address public registry;

    error RicardianTriplerBORGParticipation_NotParty();

    /// @notice event that fires if an address adopts a new RicardianTriplerBORGParticipation contract
    event RicardianTriplerBORGParticipation_Adopted(address adoptingParty, address agreementAddress);

    /// @notice Constructor that sets the BORGParticipationRegistry address.
    /// @dev no access control necessary as valid factories are set by the `admin` in the `registry` contract
    /// @param registryAddress The address of the BORGParticipationRegistry contract.
    constructor(address registryAddress) {
        registry = registryAddress;
    }

    /// @notice creates a new RicardianTriplerBORGParticipation contract and records its adoption in the BORGParticipationRegistry if called by the `details.adoptingParty.partyBlockchainAddy`
    /// @param details `AgreementDetails` struct of the agreement details which will be hashed to ensure same parameters as the proposed agreement
    function adoptBORGParticipationAgreement(AgreementDetails calldata details) external returns (address) {
        if (msg.sender != details.adoptingParty.partyBlockchainAddy)
            revert RicardianTriplerBORGParticipation_NotParty();

        RicardianTriplerBORGParticipation agreementDetails = new RicardianTriplerBORGParticipation(details);

        address _agreementAddress = address(agreementDetails);
        IBORGParticipationRegistry(registry).recordAdoption(msg.sender, _agreementAddress);

        emit RicardianTriplerBORGParticipation_Adopted(msg.sender, _agreementAddress);
        return (_agreementAddress);
    }

    /// @notice validate that an `account` has signed the hashed agreement details
    /// @param details `AgreementDetails` struct of the agreement details to which `account` is being validated as signed
    /// @param account `Account` struct of the account which is being validated as having signed `details`
    function validateAccount(AgreementDetails calldata details, Account memory account) external view returns (bool) {
        bytes32 hash = keccak256(abi.encode(details));

        // Verify that the account's accountAddress signed the hashed details.
        return isSignatureValid(account.accountAddress, hash, account.signature);
    }

    /// @notice Function that returns the version of the agreement factory.
    function version() external pure returns (uint256) {
        return FACTORY_VERSION;
    }
}
