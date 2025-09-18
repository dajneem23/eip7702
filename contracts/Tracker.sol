// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

contract Tracker {
    mapping(address account => uint256 nonce) public nonces;

    function useNonce() external returns (uint256 nonce) {
        nonce = nonces[msg.sender]++;
    }
}