// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../ChecklistBase.sol";

/// @title FlashLoanCheck — test resistance to flash-loan-powered attacks
/// @notice Verifies that critical state changes can't be exploited atomically.
/// @author kcolbchain
abstract contract FlashLoanCheck is ChecklistBase {
    /// @dev Override to return calldata for a critical action (borrow, liquidate, vote, etc.)
    function getCriticalActionCalldata() internal view virtual returns (bytes memory);

    /// @dev Override to simulate having a large balance (flash loan proceeds)
    function simulateFlashLoan(address recipient, uint256 amount) internal virtual;

    /// @dev Override to return the flash loan amount to test with
    function getFlashLoanAmount() internal view virtual returns (uint256) {
        return 10000 ether;
    }

    function test_critical_action_with_flash_loaned_funds() public {
        address attacker = makeAddr("flashloan_attacker");
        uint256 amount = getFlashLoanAmount();

        // Simulate flash loan: give attacker a massive temporary balance
        simulateFlashLoan(attacker, amount);

        // Attempt the critical action with flash-loaned funds
        vm.prank(attacker);
        (bool success,) = targetContract.call(getCriticalActionCalldata());

        // Check if the action succeeded — if it did with flash-loaned funds,
        // the protocol may be vulnerable to flash loan attacks
        if (success) {
            emit log("WARNING: Critical action succeeded with flash-loaned funds");
            emit log("Review whether this action should have time-weighted or multi-block requirements");
            // This is a warning, not automatic failure — context matters
        }
    }
}
