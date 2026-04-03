// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title VulnerableVault — intentionally vulnerable for demonstration
/// @notice DO NOT USE IN PRODUCTION. This contract has deliberate vulnerabilities
///         to demonstrate the audit-checklist detection capabilities.
/// @author kcolbchain
contract VulnerableVault {
    mapping(address => uint256) public balances;
    address public owner;
    bool public initialized;

    // BUG 1: No constructor protection — anyone can call initialize()
    function initialize() external {
        // Missing: require(!initialized)
        owner = msg.sender;
        initialized = true;
    }

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    // BUG 2: Reentrancy — sends ETH before updating balance
    function withdraw() external {
        uint256 bal = balances[msg.sender];
        require(bal > 0, "No balance");

        // External call BEFORE state update — classic reentrancy
        (bool sent,) = msg.sender.call{value: bal}("");
        require(sent, "Transfer failed");

        balances[msg.sender] = 0; // Too late — attacker already re-entered
    }

    // BUG 3: Missing access control on admin function
    function emergencyWithdraw(address to) external {
        // Missing: require(msg.sender == owner)
        payable(to).transfer(address(this).balance);
    }

    // BUG 4: Spot price oracle — manipulable in single transaction
    function getPrice() external view returns (uint256) {
        // In a real contract this would read from a DEX spot price
        // which can be manipulated via flash loan
        return address(this).balance; // Proxy for manipulable price
    }
}
