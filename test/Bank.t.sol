// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "src/Bank.sol";

contract BankTest is Test {
    uint256 constant USER_COUNT = 10;
    Bank public bank;

    function setUp() public {
        bank = new Bank();

        // get code size
        uint256 codeSize;
        address bankAddr = address(bank);
        assembly {
            codeSize := extcodesize(bankAddr)
        }
        console2.log("[before]: codeSize", codeSize);
    }

    // receive function to receive ETH
    receive() external payable { }

    function testTopDepositors() public {
        address user1 = makeAddr("user1");
        address user2 = makeAddr("user2");
        address user3 = makeAddr("user3");
        address user4 = makeAddr("user4");
        address user5 = makeAddr("user5");
        address user6 = makeAddr("user6");
        address user7 = makeAddr("user7");
        address user8 = makeAddr("user8");
        address user9 = makeAddr("user9");
        address user10 = makeAddr("user10");

        vm.deal(user1, 1 ether);
        vm.deal(user2, 2 ether);
        vm.deal(user3, 3 ether);
        vm.deal(user4, 4 ether);
        vm.deal(user5, 5 ether);
        vm.deal(user6, 6 ether);
        vm.deal(user7, 7 ether);
        vm.deal(user8, 8 ether);
        vm.deal(user9, 9 ether);
        vm.deal(user10, 10 ether);

        vm.prank(user1);
        bank.deposit{ value: 0.5 ether }();
        vm.prank(user2);
        bank.deposit{ value: 1 ether }();
        vm.prank(user3);
        bank.deposit{ value: 1.5 ether }();
        vm.prank(user4);
        bank.deposit{ value: 2 ether }();
        vm.prank(user5);
        bank.deposit{ value: 2.5 ether }();
        vm.prank(user6);
        bank.deposit{ value: 3 ether }();
        vm.prank(user7);
        bank.deposit{ value: 3.5 ether }();
        vm.prank(user8);
        bank.deposit{ value: 4 ether }();
        vm.prank(user9);
        bank.deposit{ value: 4.5 ether }();
        vm.prank(user10);
        bank.deposit{ value: 5 ether }();

        address[USER_COUNT] memory topDepositors = bank.getTopDepositors();
        assertEq(topDepositors[0], user10);
        assertEq(topDepositors[1], user9);
        assertEq(topDepositors[2], user8);
        assertEq(topDepositors[3], user7);
        assertEq(topDepositors[4], user6);
        assertEq(topDepositors[5], user5);
        assertEq(topDepositors[6], user4);
        assertEq(topDepositors[7], user3);
        assertEq(topDepositors[8], user2);
        assertEq(topDepositors[9], user1);
    }
}
