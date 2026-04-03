// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/checks/ReentrancyCheck.sol";
import "../src/checks/AccessControlCheck.sol";
import "../src/examples/VulnerableVault.sol";

/// @title ExampleAudit — demonstrates audit-checklist against VulnerableVault
/// @notice Run with: forge test -vvv
contract ExampleReentrancyAudit is ReentrancyCheck {
    VulnerableVault vault;

    function setUp() public {
        vault = new VulnerableVault();
        vault.initialize();
        targetContract = address(vault);
    }

    function getWithdrawCalldata() internal pure override returns (bytes memory) {
        return abi.encodeWithSignature("withdraw()");
    }

    function performDeposit(address depositor, uint256 amount) internal override {
        vm.prank(depositor);
        vault.deposit{value: amount}();
    }
}

contract ExampleAccessControlAudit is AccessControlCheck {
    VulnerableVault vault;

    function setUp() public {
        vault = new VulnerableVault();
        vault.initialize();
        targetContract = address(vault);
    }

    function getAdminFunctions() internal view override returns (bytes[] memory) {
        bytes[] memory calls = new bytes[](1);
        calls[0] = abi.encodeWithSignature("emergencyWithdraw(address)", address(0xbeef));
        return calls;
    }
}
