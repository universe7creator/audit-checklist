// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../ChecklistBase.sol";

/// @title OracleCheck — detect oracle manipulation vulnerabilities
/// @notice Checks if the contract uses spot prices that can be manipulated in a single block.
/// @author kcolbchain
abstract contract OracleCheck is ChecklistBase {
    /// @dev Override to return the function calldata that reads a price
    function getPriceReadCalldata() internal view virtual returns (bytes memory);

    /// @dev Override to manipulate the price source (e.g., swap in a pool)
    function manipulatePrice() internal virtual;

    /// @dev Override to restore the price source
    function restorePrice() internal virtual;

    function test_spot_price_manipulation() public {
        // Read price before manipulation
        bytes memory callData = getPriceReadCalldata();
        (, bytes memory beforeData) = targetContract.staticcall(callData);
        uint256 priceBefore = abi.decode(beforeData, (uint256));

        // Manipulate within same block
        manipulatePrice();

        (, bytes memory afterData) = targetContract.staticcall(callData);
        uint256 priceAfter = abi.decode(afterData, (uint256));

        restorePrice();

        // If price changed >10% in a single block, it's manipulable
        if (priceBefore > 0) {
            uint256 delta = priceBefore > priceAfter
                ? priceBefore - priceAfter
                : priceAfter - priceBefore;
            uint256 pctChange = (delta * 100) / priceBefore;

            if (pctChange > 10) {
                emit log("VULNERABILITY: Price oracle manipulable within single block");
                emit log_named_uint("Price before", priceBefore);
                emit log_named_uint("Price after", priceAfter);
                emit log_named_uint("Change %", pctChange);
                fail();
            }
        }
    }
}
