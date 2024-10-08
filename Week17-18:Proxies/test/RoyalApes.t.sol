// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {Test, console2} from "forge-std/Test.sol";
import {RoyalApes, RoyalApesV2} from "../src/RoyalApes.sol";
import {MerkleProof} from "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import {ERC1967Proxy} from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract RoyalApesTest is Test {
    RoyalApes royalApes;
    address admin;
    address user1;
    address user2;
    bytes32[] public merkleTree;

    function setUp() public {
        admin = address(this);
        user1 = address(0x1);
        user2 = address(0x2);

        /// @dev build the merkle tree/root
        /// tree with 2 leaves and 2 levels
        merkleTree = new bytes32[](3);
        uint256 index = 0;
        merkleTree[1] = keccak256(abi.encode(index++, user1));
        merkleTree[2] = keccak256(abi.encode(index++, user2));
        merkleTree[0] = keccak256(abi.encode(merkleTree[1], merkleTree[2]));

        //royalApes = new RoyalApes(admin, merkleTree[0]);
        //vm.deal(user1, 10 ether);

         // deploy logic contract
        RoyalApes royalApesImplementation = new RoyalApes(admin, merkleTree[0]);
        // deploy proxy contract and point it to implementation
        ERC1967Proxy proxy = new ERC1967Proxy(address(royalApesImplementation), "");
    
        // initialize implementation contract
        address(proxy).call(abi.encodeWithSignature("initialize()"));

        // wrap proxy in RoyalApes
        royalApes = RoyalApes(address(proxy));

        vm.deal(user1, 10 ether);
    }

    function testUpgrade() public {
        vm.prank(user1);
        royalApes.mint{value: 1 ether}();
        assertEq(royalApes.balanceOf(user1), 1);

        // deploy new logic contract
        RoyalApesV2 newRoyalApesImplementation = new RoyalApesV2(admin, merkleTree[0]);
        // upgrade proxy to new logic contract
        royalApes.upgradeToAndCall(address(newRoyalApesImplementation), "");
        // wrap proxy in new RoyalApesV2
        RoyalApesV2 royalApesV2 = RoyalApesV2(address(royalApes));

        vm.prank(user2);
        royalApesV2.godTransfer(user1, user2, 1);
        assertEq(royalApes.balanceOf(user1), 0);
        assertEq(royalApes.balanceOf(user2), 1);
    }

    function testMint() public {
        vm.prank(user1);
        royalApes.mint{value: 1 ether}();
        assertEq(royalApes.balanceOf(user1), 1);
    }

    function testMintNotEnoughETH() public {
        vm.prank(user1);
        vm.expectRevert("Not right amount of ETH");
        royalApes.mint{value: .99 ether}();
    }

    function testMintWithExcessSent() public {
        vm.prank(user1);
        vm.expectRevert("Not right amount of ETH");
        royalApes.mint{value: 1.5 ether}();
    }

    function testMintWithDiscount() public {
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = merkleTree[2];
        vm.prank(user1);
        royalApes.mintWithDiscount{value: .5 ether}(0, user1, proof);
        assertEq(royalApes.balanceOf(user1), 1);
    }

    function testMintWithDiscountAlreadyClaimed() public {
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = merkleTree[2];
        vm.prank(user1);
        royalApes.mintWithDiscount{value: .5 ether}(0, user1, proof);
        assertEq(royalApes.balanceOf(user1), 1);

        vm.prank(user1);
        /// @dev reverts due to AlreadyMintedAtDiscount();
        vm.expectRevert();
        royalApes.mintWithDiscount{value: .5 ether}(0, user1, proof);
    }

    function testMintWithDiscountCantMintDifferentIndex() public {
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = merkleTree[2];
        vm.prank(user1);
        /// @dev reverts due to InvalidProof();
        vm.expectRevert();
        royalApes.mintWithDiscount{value: .5 ether}(1, user1, proof);
    }

    function testMintWithDiscountWrongAmount() public {
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = merkleTree[2];
        vm.prank(user1);
        vm.expectRevert("Not right amount of ETH");
        royalApes.mintWithDiscount{value: .51 ether}(0, user1, proof);
    }

    function testMintWithDiscountWrongAmount2() public {
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = merkleTree[2];
        vm.prank(user1);
        vm.expectRevert("Not right amount of ETH");
        royalApes.mintWithDiscount{value: .49 ether}(0, user1, proof);
    }

    /// @dev test that my merkle tree theories in setup are correct
    function testMerkleTree() public {
        /// @dev make sure leaves are correct
        bytes32[] memory proof = new bytes32[](2);
        uint256 zero = 0;
        uint256 one = 1;
        proof[0] = keccak256(abi.encode(zero, user1));
        proof[1] = keccak256(abi.encode(one, user2));
        assertEq(proof[0], merkleTree[1]);
        assertEq(proof[1], merkleTree[2]);

        /// @dev make sure root is correct
        bytes32 root = keccak256(abi.encode(proof[0], proof[1]));
        assertEq(root, merkleTree[0]);

        /// @dev make sure the verfying and proofs work
        bytes32[] memory proof2 = new bytes32[](1);
        proof2[0] = merkleTree[2];
        assertTrue(MerkleProof.verify(proof2, merkleTree[0], merkleTree[1]));
    }
}