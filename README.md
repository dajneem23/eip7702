# EIP-7702 Proof-of-Concept

## Disclaimer

This repository contains smart contracts for demonstration and educational purposes only. This is a proof-of-concept project for EIP-7702. It is not intended for production use. The contracts have not been audited for security. Use at your own risk. The authors and contributors are not responsible for any loss of funds, vulnerabilities, or damages resulting from the use, deployment, or modification of these contracts.

## Overview

This project demonstrates a potential security vulnerability related to [EIP-7702](https://eips.ethereum.org/EIPS/eip-7702). EIP-7702 introduces a new transaction type that allows an Externally Owned Account (EOA) to have contract code for the duration of a single transaction. This allows for features like batched transactions without the need for full account abstraction.

This repository contains a set of smart contracts to illustrate how this new capability could be exploited in a reentrancy-like attack.

## Contracts

The repository includes the following contracts:

* **`FundHolder.sol`**: A simple vault contract that can hold Ether and ERC20 tokens. The owner of the contract can withdraw these assets.
* **`MaliciousDrain.sol`**: A contract designed to demonstrate a potential attack vector. It contains a function that, when called, can drain funds from the `FundHolder` contract by exploiting the temporary contract code of an EOA.
* **`TestERC20.sol`**: A mock ERC20 token contract used for testing purposes.

## Testing

The project uses Foundry for testing. The tests in `test/MaliciousDrain.t.sol` demonstrate the vulnerability.

### Prerequisites

* [Foundry](https://book.getfoundry.sh/getting-started/installation)

### Running the Tests

To run the tests, execute the following command in your terminal:

```bash
forge test -vvvv
```

This command will compile the contracts and run the tests, providing a verbose output of the test execution, which will show the attack scenario.

## How the Exploit Works (as demonstrated in the tests)

1. A `FundHolder` contract is deployed, and an owner is set.
2. Two mock ERC20 tokens (`tokenA` and `tokenB`) are created and transferred to the `FundHolder` contract.
3. A `MaliciousDrain` contract is deployed.
4. The test simulates a transaction from an EOA that has temporarily set its code to be the `MaliciousDrain` contract's code (as per EIP-7702).
5. The EOA, now acting as the `MaliciousDrain` contract, calls the `sweepTokens` function on the `FundHolder` contract.
6. The `MaliciousDrain` contract is coded to repeatedly call `sweepTokens` within its `receive()` or fallback function, leading to a reentrancy-like attack that drains the `FundHolder` of its tokens.

This example highlights the importance of being aware of the implications of EIP-7702 and ensuring that contracts are not vulnerable to such reentrancy-like attacks from EOAs that can temporarily have code.
