# BORG Participation Agreement Registry

This directory houses smart contracts written in Solidity which serve three main purposes:

1. Allow a party to officially adopt the form BORG Participation Agreement for their applicable BORG.
2. Store the agreement details on-chain for ease-of-use and persistent credibly neutral storage.
3. Allow for future agreement versions and adoptions without affecting prior agreements.

# Technical Details

This repository is built using [Foundry](https://book.getfoundry.sh/). See the installation instructions [here](https://github.com/foundry-rs/foundry#installation). To test the contracts, use `forge test`.

Contracts in this system:

-   `BORGParticipationRegistry` - Where adopted agreement addresses are stored, new agreements are registered, and agreement factories are enabled / disabled.
-   `AgreementV1Factory` within RicardianTriplerBORGParticipation.sol - Where parties adopt new agreement contracts.
-   `RicardianTriplerBORGParticipation` - Agreement adopted by a party, containing the agreement details.
-   `SignatureValidator` - Used to determine whether a hash was validly signed by an address

## Setup

1. The `BORGParticipationRegistry` contract is deployed with the `admin` passed as a constructor argument.
2. The `AgreementV1Factory` contract is deployed with the `BORGParticipationRegistry` address passed as a constructor argument.
3. The `BORGParticipationRegistry` `admin` calls `enableFactory()` on `BORGParticipationRegistry` with the `AgreementV1Factory`'s address.

In the future MetaLeX may create new versions of the legal agreement, or adjust the agreement details struct. When this happens a new factory (e.g. `AgreementV2Factory`) may be deployed and enabled using the `enableFactory()` method. Optionally, the registry admin may disable old factories to prevent new adoptions using old agreement structures. 

## Adoption

1.  A party to a BORG Participation Agreement calls `adoptBORGParticipationAgreement()` on an `AgreementFactory` with their `AgreementDetails`. 
2.  The factory creates an `RicardianTriplerBORGParticipation` contract containing the provided `AgreementDetails`.
3.  The factory adds the `RicardianTriplerBORGParticipation` contract address to the `BORGParticipationRegistry`.

Calling `adoptBORGParticipationAgreement()` operates as a legally binding signature to the agreement for the calling party.

### Signed Accounts

For added security, parties may choose to sign their agreement for the scoped accounts. Both EOA and ERC-1271 signatures are supported and can be validated with the agreement's factory. 

#### Signing the Agreement Details

When preparing the final agreement details, prior to deploying onchain, the party may sign the agreement details for the account under scope and store the signature within the agreement details. A helper script to generate these account signatures for EOA accounts has been provided. To use it set the `SIGNER_PRIVATE_KEY` environment variable. Then, run the script using:

```
forge script GenerateAccountSignatureV1.s.sol --fork-url <YOUR_RPC_URL> -vvvv
```

#### Verification of Signed Accounts

Parties may use the agreement factory's `validateAccount()` method to verify that a given Account has consented to the agreement details.

## Querying Agreements

1. Query the `agreements` nested mapping in the `BORGParticipationRegistry` contract (via the getter) a party's address and their `nonce` index to get the party's `RicardianTriplerBORGParticipation` address. This information is also emitted in the `BORGParticipationRegistry_BORGParticipationAdoption` event when `recordAdoption()` is called. To check if a `RicardianTriplerBORGParticipation` was properly signed and recorded, a user may pass its address to the `signedAgreement` mapping in the `BORGParticipationRegistry`; if it returns `true`, it was signed and recorded.
2. Query the `RicardianTriplerBORGParticipation` contract with `getDetails()` to get the structured agreement details.

Different versions may have different `AgreementDetails` structs. All `RicardianTriplerBORGParticipation` and `AgreementFactory` contracts will include a `version()` method that can be used to infer the `AgreementDetails` structure.

# Deployment

The BORG Participation Agreement Registry will be deployed using the deterministic deployment proxy described here: https://github.com/Arachnid/deterministic-deployment-proxy, which is built into Foundry by default.

To deploy the registry to an EVM-compatible chain where it is not currently deployed:

1. Ensure the deterministic-deployment-proxy is deployed at 0x4e59b44847b379578588920cA78FbF26c0B4956C, and if it's not, deploy it using [the process mentioned above](https://github.com/Arachnid/deterministic-deployment-proxy).
2. Deploy the registry using the above proxy with salt `bytes32(0)` from the EOA that will become the registry admin. The file [`script/BORGParticipationRegistryDeploy.s.sol`](script/BORGParticipationRegistryDeploy.s.sol) is a convenience script for this task. To use it, set the `REGISTRY_DEPLOYER_PRIVATE_KEY` environment variable to a private key that can pay for the deployment transaction costs. Then, run the script using:

```
forge script BORGParticipationRegistryDeploy --rpc-url <CHAIN_RPC_URL> --verify --etherscan-api-key <ETHERSCAN_API_KEY> --broadcast -vvvv
```
