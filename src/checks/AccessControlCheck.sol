// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../ChecklistBase.sol";

/// @title AccessControlCheck — verify admin functions are protected
/// @notice Override `getAdminFunctions()` to list calldata for admin-only functions.
///         Each will be called from a non-privileged address and must revert.
/// @author kcolbchain
abstract contract AccessControlCheck is ChecklistBase {
    /// @dev Override to return array of admin function calldata to test
    function getAdminFunctions() internal view virtual returns (bytes[] memory);

    /// @dev Address that should NOT have admin access
    function getNonAdminAddress() internal view virtual returns (address) {
        return address(0xdead);
    }

    function test_admin_functions_revert_for_non_admin() public {
        bytes[] memory adminCalls = getAdminFunctions();
        address nonAdmin = getNonAdminAddress();

        for (uint256 i = 0; i < adminCalls.length; i++) {
            vm.prank(nonAdmin);
            (bool success,) = targetContract.call(adminCalls[i]);
            if (success) {
                emit log("VULNERABILITY: Admin function callable by non-admin");
                emit log_bytes(adminCalls[i]);
                fail();
            }
        }
    }

    function test_zero_address_cannot_call_admin() public {
        bytes[] memory adminCalls = getAdminFunctions();

        for (uint256 i = 0; i < adminCalls.length; i++) {
            vm.prank(address(0));
            (bool success,) = targetContract.call(adminCalls[i]);
            if (success) {
                emit log("VULNERABILITY: Admin function callable by address(0)");
                fail();
            }
        }
    }
}
