// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./SafeHarborRegistry.sol";

/// @notice Contract that contains the AgreementDetails that will be deployed by the Agreement Factory
contract AgreementV1 {
    /// @notice The details of the agreement.
    AgreementDetailsV1 public details;

    /// @notice Constructor that sets the details of the agreement.
    /// @param _details The details of the agreement.
    constructor(AgreementDetailsV1 memory _details) {
        details = _details;
    }
}

/// @notice Factory contract that creates new AgreementV1 contracts and records their adoption in the SafeHarborRegistry
contract AgreementV1Factory {
    /// @notice The SafeHarborRegistry contract.
    SafeHarborRegistry public registry;

    /// @notice Constructor that sets the SafeHarborRegistry address.
    /// @param registryAddress The address of the SafeHarborRegistry contract.
    constructor(address registryAddress) {
        registry = SafeHarborRegistry(registryAddress);
    }

    /// @notice Function that creates a new AgreementV1 contract and records its adoption in the SafeHarborRegistry
    /// @param details The details of the agreement.
    function adoptSafeHarbor(AgreementDetailsV1 memory details) external {
        AgreementV1 agreementDetails = new AgreementV1(details);
        registry.recordAdoption(address(agreementDetails));
    }
}

/// @notice Struct that contains the details of the agreement
struct AgreementDetailsV1 {
    // The name of the protocol adopting the agreement.
    string protocolName;
    // The scope and recovery address by chain.
    Chain[] chains;
    // The contact details (required for pre-notifying).
    Contact[] contactDetails;
    // The terms of the agreement.
    BountyTerms bountyTerms;
    // Indication whether the agreement should be automatically upgraded to future versions approved by SEAL.
    bool automaticallyUpgrade;
    // IPFS hash of the actual agreement document, which confirms all terms.
    string agreementURI;
}

/// @notice Struct that contains the details of an agreement by chain
struct Chain {
    // The accounts in scope for the agreement.
    Account[] accounts;
    // The address to which recovered assets will be sent.
    address assetRecoveryAddress;
    // The chain ID.
    uint chainID;
}

/// @notice Struct that contains the details of an account in an agreement
struct Account {
    // The address of the account (EOA or smart contract).
    address accountAddress;
    // Whether smart contracts deployed by this account are in scope.
    bool includeChildContracts;
    // Whether smart contracts deployed by this account after the agreement is adopted are in scope.
    bool includeNewChildContracts;
}

/// @notice Struct that contains the contact details of the agreement
struct Contact {
    // The name of the contact.
    string name;
    // The role of the contact.
    string role;
    // The contact details (IE email, phone, telegram).
    string contact;
}

/// @notice Enum that defines the identity requirements for a Whitehat to be eligible under the agreement
enum IdentityRequirement {
    // The Whitehat can remain fully anonymous.
    Anonymous,
    // The Whitehat uses a moniker and there's no/limited KYC.
    Pseudonymous,
    // The Whitehat must be KYCed.
    Named
}

struct BountyTerms {
    // Percentage of the recovered funds a Whitehat receives as their bounty (0-100).
    uint bountyPercentage;
    // The maximum bounty in USD.
    uint bountyCapUSD;
    // Indicates if the Whitehat can retain their bounty.
    bool retainable;
    // Identity requirements for Whitehats eligible under the agreement.
    IdentityRequirement identityRequirement;
    // Description of what KYC, sanctions, diligence, or other verification will be performed on Whitehats to determine their eligibility to receive the bounty.
    string diligenceRequirements;
}