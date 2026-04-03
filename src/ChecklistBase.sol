// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

/// @title ChecklistBase — shared helpers for audit checks
/// @author kcolbchain (est. 2015)
abstract contract ChecklistBase is Test {
    /// @dev The contract under audit. Set this in setUp().
    address public targetContract;

    /// @dev Call a function on the target and expect it to revert
    function _expectRevert(bytes memory callData) internal {
        (bool success,) = targetContract.call(callData);
        assertFalse(success, "Expected revert but call succeeded");
    }

    /// @dev Call a function on the target and expect success
    function _expectSuccess(bytes memory callData) internal returns (bytes memory) {
        (bool success, bytes memory ret) = targetContract.call(callData);
        assertTrue(success, "Expected success but call reverted");
        return ret;
    }

    /// @dev Deploy a contract that will attempt reentrancy on callback
    function _deployReentrant(bytes memory attackCalldata) internal returns (address) {
        ReentrantAttacker attacker = new ReentrantAttacker(targetContract, attackCalldata);
        return address(attacker);
    }
}

/// @dev Helper contract that re-enters on receive()
contract ReentrantAttacker {
    address public target;
    bytes public payload;
    uint256 public attackCount;

    constructor(address _target, bytes memory _payload) {
        target = _target;
        payload = _payload;
    }

    receive() external payable {
        if (attackCount < 2) {
            attackCount++;
            (bool s,) = target.call(payload);
            // We don't care if it succeeds — we're testing if it's possible
            s;
        }
    }

    function attack() external payable {
        (bool s,) = target.call{value: msg.value}(payload);
        s;
    }
}
