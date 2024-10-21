//SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Vm} from "forge-std/Vm.sol";
import "../src/BORGParticipationRegistry.sol";
import "../src/RicardianTriplerBORGParticipation.sol";

contract RicardianTriplerBORGParticipationTest is Test {
    BORGParticipationRegistry registry;
    AgreementV1Factory factory;

    uint256 internal constant FACTORY_VERSION = 1;
    uint256 internal constant AGREEMENT_VERSION = 1;

    uint256 mockKey = 100;
    uint256 adoptingPartyNonce;
    address adoptingParty = address(1);

    mapping(address => AgreementDetails) public details;

    function setUp() external {
        _setDetails();
        address fakeAdmin = address(0xaa);

        registry = new BORGParticipationRegistry(fakeAdmin);
        factory = new AgreementV1Factory(address(registry));

        vm.prank(fakeAdmin);
        registry.enableFactory(address(factory));
    }

    function testVersion() public {
        assertEq(FACTORY_VERSION, factory.version(), "factory version != 1");
        AgreementDetails storage mockDetails = details[address(this)];
        RicardianTriplerBORGParticipation newAgreement = new RicardianTriplerBORGParticipation(mockDetails);
        assertEq(AGREEMENT_VERSION, newAgreement.version(), "agreement version != 1");
    }

    function testAdoptBORGParticipationAgreement() public {
        ++adoptingPartyNonce;
        vm.prank(adoptingParty);
        AgreementDetails storage mockDetails = details[address(this)];
        address _newAgreement = factory.adoptBORGParticipationAgreement(mockDetails);

        vm.prank(adoptingParty);
        factory.adoptBORGParticipationAgreement(mockDetails);

        assertEq(
            registry.agreements(adoptingParty, adoptingPartyNonce),
            _newAgreement,
            "agreement address does not match"
        );
        assertTrue(registry.signedAgreement(_newAgreement), "signedAgreement should be true for new agreement address");
    }

    function testAdoptBORGParticipationAgreement_invalid(address _randomAddr) public {
        ++adoptingPartyNonce;
        AgreementDetails storage mockDetails = details[address(this)];

        vm.prank(_randomAddr);
        if (_randomAddr != adoptingParty) {
            vm.expectRevert();
            address _newAgreement = factory.adoptBORGParticipationAgreement(mockDetails);

            assertTrue(
                !registry.signedAgreement(_newAgreement),
                "signedAgreement should remain false for new agreement address"
            );
        }
    }

    function testValidateAccount() public {
        Account memory account = Account({accountAddress: vm.addr(mockKey), signature: new bytes(0)});
        AgreementDetails storage mockDetails = details[address(this)];
        bytes32 hash = keccak256(abi.encode(mockDetails));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(mockKey, hash);
        bytes memory signature = abi.encodePacked(r, s, v);

        account.signature = signature;

        bool isValid = factory.validateAccount(mockDetails, account);
        assertTrue(isValid);
    }

    function testValidateAccount_invalid() public {
        Account memory account = Account({accountAddress: vm.addr(mockKey), signature: new bytes(0)});
        uint256 fakeKey = 200;
        AgreementDetails storage mockDetails = details[address(this)];
        bytes32 hash = keccak256(abi.encode(mockDetails));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(fakeKey, hash);
        bytes memory signature = abi.encodePacked(r, s, v);

        account.signature = signature;

        bool isValid = factory.validateAccount(mockDetails, account);
        assertTrue(!isValid);
    }

    function _setDetails() public {
        AgreementDetails storage mockDetails = details[address(this)];

        mockDetails.adoptingParty = Party({
            partyBlockchainAddy: address(1),
            partyName: "Party A",
            contactDetails: "partyA@email.com"
        });
        mockDetails.BORGName = "BORG Name";
        mockDetails.legalAgreementURI = "ipfs://testHash";
    }
}
