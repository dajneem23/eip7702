// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../contracts/MaliciousDrain.sol";
import "../contracts/TestERC20.sol";

contract MaliciousDrainTest is Test {
    MaliciousDrain drain;
    TestERC20 tokenA;
    TestERC20 tokenB;
    address payable constant DRAIN_ADDR = payable(address(0xBEEF));

    function setUp() public {
        drain = new MaliciousDrain(DRAIN_ADDR); // set test contract as owner

        tokenA = new TestERC20();
        tokenB = new TestERC20();

        // ensure drain-address starts with zero balance for deterministic asserts
        vm.deal(DRAIN_ADDR, 0);
    }

    function test_withdrawETH_forwards_balance() public {
        // send 5 ETH to the contract
        vm.deal(address(this), 5 ether);
        (bool s, ) = address(this).call{value: 0}("");
        // fund contract by sending from this test address
        payable(address(drain)).transfer(0); // noop (keeps compiler happy)

        // actually send ether to contract
        (bool ok, ) = address(drain).call{value: 3 ether}("");
        assertTrue(ok, "fund send failed");
        console.log("drain balance after funding:", address(drain).balance);
        console.log("DRAIN_ADDR balance after funding:", DRAIN_ADDR.balance);
        assertEq(DRAIN_ADDR.balance, 3 ether, "Drain address should auto-receive ETH");
        assertEq(address(drain).balance, 0, "MaliciousDrain should not retain ETH");

        // incase something weird happened, eth stuck in contract, top it up
        deal(address(drain), 3 ether);
        // Call withdrawETH
        drain.withdrawETH();

        assertEq(DRAIN_ADDR.balance, 6 ether, "Drain address balance changed after withdrawETH");
        assertEq(address(drain).balance, 0, "MaliciousDrain still empty");
    }

    function test_receive_forwards_eth() public {
        // send ETH via empty calldata to trigger receive()
        uint256 before = DRAIN_ADDR.balance;
        assertEq(before, 0);

        (bool ok, ) = address(drain).call{value: 1 ether}("");
        assertTrue(ok, "call transfer failed");

        uint256 afterBalance = DRAIN_ADDR.balance;
        assertEq(afterBalance, 1 ether);
    }

    function test_withdrawERC20_moves_tokens() public {
        // mint tokens to the drain contract
        tokenA.mint(address(drain), 1000 ether);

        // sanity
        assertEq(tokenA.balanceOf(address(drain)), 1000 ether);
        assertEq(tokenA.balanceOf(DRAIN_ADDR), 0);

        // call withdrawERC20
        drain.withdrawERC20(address(tokenA));

        assertEq(tokenA.balanceOf(address(drain)), 0);
        assertEq(tokenA.balanceOf(DRAIN_ADDR), 1000 ether);
    }

    function test_drainTokens_array_drains_multiple() public {
        // mint tokens to the contract
        tokenA.mint(address(drain), 500 ether);
        tokenB.mint(address(drain), 200 ether);

        address[] memory arr = new address[](2);
        arr[0] = address(tokenA);
        arr[1] = address(tokenB);

        assertEq(tokenA.balanceOf(address(drain)), 500 ether);
        assertEq(tokenB.balanceOf(address(drain)), 200 ether);

        // call drainTokens
        drain.drainTokens(arr);

        assertEq(tokenA.balanceOf(address(drain)), 0);
        assertEq(tokenB.balanceOf(address(drain)), 0);

        assertEq(tokenA.balanceOf(DRAIN_ADDR), 500 ether);
        assertEq(tokenB.balanceOf(DRAIN_ADDR), 200 ether);
    }

    // Helper to receive ETH in tests (Test contract must be payable)
    receive() external payable {}
}