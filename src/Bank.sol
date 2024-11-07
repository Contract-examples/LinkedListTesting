// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract Bank is Ownable, ReentrancyGuard, Pausable {
    uint256 public constant USER_COUNT = 10;

    address public admin;
    mapping(address => uint256) public balances;
    // store the next depositor
    mapping(address => address) private _nextDepositors;
    uint256 public listSize;

    // use guard node to simplify boundary case handling
    address constant GUARD = address(1);

    error DepositTooLow();
    error OnlyAdminCanWithdraw();

    constructor() Ownable(msg.sender) {
        admin = msg.sender;
        // initialize guard node
        _nextDepositors[GUARD] = GUARD;
    }

    receive() external payable {
        deposit();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function deposit() public payable whenNotPaused nonReentrant {
        if (msg.value == 0) revert DepositTooLow();

        address depositor = msg.sender;
        uint256 newBalance = balances[depositor] + msg.value;

        if (_nextDepositors[depositor] == address(0)) {
            // new depositor, find the suitable insertion position
            address candidate = GUARD;
            while (_nextDepositors[candidate] != GUARD && balances[_nextDepositors[candidate]] >= newBalance) {
                candidate = _nextDepositors[candidate];
            }

            balances[depositor] = newBalance;
            _nextDepositors[depositor] = _nextDepositors[candidate];
            _nextDepositors[candidate] = depositor;
            listSize++;
        } else {
            // existing depositor, update balance and reorder
            address oldCandidate = _findPrevDepositor(depositor);
            _nextDepositors[oldCandidate] = _nextDepositors[depositor];

            // find the new insertion position
            address newCandidate = GUARD;
            while (_nextDepositors[newCandidate] != GUARD && balances[_nextDepositors[newCandidate]] >= newBalance) {
                newCandidate = _nextDepositors[newCandidate];
            }

            balances[depositor] = newBalance;
            _nextDepositors[depositor] = _nextDepositors[newCandidate];
            _nextDepositors[newCandidate] = depositor;
        }
    }

    function _findPrevDepositor(address depositor) private view returns (address) {
        address current = GUARD;
        while (_nextDepositors[current] != depositor) {
            current = _nextDepositors[current];
        }
        return current;
    }

    function withdraw(uint256 amount) external whenNotPaused nonReentrant {
        if (msg.sender != admin) revert OnlyAdminCanWithdraw();

        uint256 balance = address(this).balance;
        amount = amount > balance ? balance : amount;
        if (amount != 0) {
            Address.sendValue(payable(admin), amount);
        }
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getTopDepositors() public view returns (address[USER_COUNT] memory) {
        address[USER_COUNT] memory result;
        address current = _nextDepositors[GUARD];

        unchecked {
            for (uint256 i = 0; i < USER_COUNT && current != GUARD; ++i) {
                result[i] = current;
                current = _nextDepositors[current];
            }
        }

        return result;
    }

    function getDepositAmount(address depositor) public view returns (uint256) {
        return balances[depositor];
    }

    function destroy(address payable recipient) public onlyOwner {
        selfdestruct(recipient);
    }
}
