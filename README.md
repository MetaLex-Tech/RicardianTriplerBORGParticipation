<p align="center">
  <img src="https://pbs.twimg.com/media/GIZRzEIXcAADT9j.png"/>
</p>

# BORG Participation Agreement Ricardian Tripler

Smart contracts for the adoption of the BORG Participation Agreement Agreement as a ['ricardian triple'](https://financialcryptography.com/mt/archives/001556.html). 

## What's in this repo?

- [documents/agreement.pdf](documents/agreement.pdf) - MetaLeX BORG Participation Agreement v1 
- [registry-contracts/](registry-contracts/) - the smart contracts used to adopt the agreement 

## How does it work?

- MetaLeX sets up the Ricardian tripler factory with the legal agreement form and approved factories as set forth in [Setup](https://github.com/MetaLex-Tech/RicardianTriplerBORGParticipation/tree/main/registry-contracts#setup)
- Party(ies) to a BORG Participation Agreement navigate to an approved factory and become legally bound to a properly corresponding legal agreement by undertaking the steps set forth below

## Adoption/Signing

A few steps are required.

Firstly, the adopting party must review the proposed agreement's terms, including:
- Confirming suitability and acceptance of the MetaLeX BORG Participation Agreement v1 terms, as well as the BORG's bylaws referenced therein
- `BORGName`: string input of the name of the BORG whose bylaws are to be adopted 


Once the specifics are determined, a party calls `adoptBORGParticipationAgreement()` including the parameters in the passed `AgreementDetails`, in each case on an `AgreementFactory`.

The `AgreementFactory` creates a `RicardianTriplerBORGParticipation` agreement contract containing the provided proposed agreement details. In either case, the details include the BORG's name, `Party` details, and the legal agreement's URI.

The factory adds the `RicardianTriplerBORGParticipation` contract address to the `BORGParticipationRegistry`, updating both the `agreements`and `signedAgreement` mappings.

A user may check if a `RicardianTriplerBORGParticipation` agreement was mutually signed (and thus recorded in the registry) by passing its address to the `signedAgreement` mapping in the `BORGParticipationRegistry`; if it returns `true`, the agreement's details are then easily accessed by calling `getDetails()` directly in the `RicardianTriplerBORGParticipation` contract address.
  
The adopting party's onchain transaction to adopt the agreement details constitutes legally binding action, so the transacting address should represent the decision-making authority of the party to the BORG Participation Agreement.




