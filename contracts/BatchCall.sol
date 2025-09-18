// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {ECDSA} from "solady/utils/ECDSA.sol";
import {Tracker} from "./Tracker.sol";

error InvalidSignature();
error CallReverted();

contract BatchCall {
    using ECDSA for bytes32;

    address private constant TRACKER_ADDRESS = 0x0000000000000000000000000000000000000000;

    struct Call {
        address to;
        uint256 value;
        bytes data;
    }

    function execute(Call[] calldata calls, bytes calldata signature) external payable {
        uint256 nonce = Tracker(TRACKER_ADDRESS).useNonce();

        bytes memory encodedCalls;
        for (uint256 i = 0; i < calls.length; i++) {
            encodedCalls = abi.encodePacked(encodedCalls, calls[i].to, calls[i].value, calls[i].data);
        }
        bytes32 digest = keccak256(abi.encodePacked(nonce, encodedCalls));

        bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(digest);

        address recovered = ECDSA.recover(ethSignedMessageHash, signature);
        if (recovered != address(this)) revert InvalidSignature();

        _executeBatch(calls);
    }

    function _executeBatch(Call[] calldata calls) internal {
        for (uint256 i = 0; i < calls.length; i++) {
            _executeCall(calls[i]);
        }
    }

    function _executeCall(Call calldata callItem) internal {
        (bool success,) = callItem.to.call{value: callItem.value}(callItem.data);
        if (!success) revert CallReverted();
    }

    fallback() external payable {}
    receive() external payable {}
}

