# EIP-7702 Batch Transaction Executor

This project provides a powerful smart contract framework for executing multiple transactions (a "batch") atomically under the authority of an Externally Owned Account (EOA), leveraging the capabilities of [EIP-7702](https://eips.ethereum.org/EIPS/eip-7702).

Its primary and most critical use case is the **recovery of assets from compromised wallets** where a sweeper bot instantly drains any gas fees (like ETH) deposited for rescue operations.

---

## The Problem: Stranded Assets in Compromised Wallets

Imagine your wallet's private key is compromised. A malicious actor has deployed a "sweeper bot" that constantly monitors your address. The moment you send ETH to your wallet to pay for the gas needed to transfer your valuable assets (like NFTs or other tokens) to a safe address, the bot instantly sweeps the ETH away. Your assets are visible, yet effectively trapped.

How can you execute a transaction if you can't pay the gas fee from the compromised account?

## The Solution: Gas-Sponsored Batched Transactions

This project solves this problem by allowing a trusted third-party wallet (a "sponsor") to pay the gas fee for a series of operations executed by the compromised wallet.

With EIP-7702, a wallet can temporarily adopt the bytecode of a smart contract for a single transaction. This `BatchCall.sol` contract is designed to be that temporary code. The compromised wallet signs a message containing the batch of transactions (e.g., `claim` an airdrop, then `transfer` the tokens out), but **it does not broadcast the transaction itself**.

Instead, a separate, secure wallet (the "sponsor") wraps this signature and the desired operations into an EIP-7702 transaction and broadcasts it to the network, paying the gas fee. From the network's perspective, the compromised wallet is executing the operations, but the gas is paid by the sponsor.

## Key Features & Use Cases

- **Asset Recovery from Compromised Wallets**: The primary use case. Execute a multi-step rescue operation like `claim` + `transfer` (for airdrops), `unstake` + `transfer` (for staked assets), or a direct `transfer` in a single, atomic, externally-funded transaction that a sweeper bot cannot front-run.
- **Complex Atomic Operations**: Perform a series of actions that must all succeed or fail together. For example, participating in a multi-token NFT mint, or performing multiple token swaps in a specific order.
- **Sponsored Transactions**: Enable applications where a project or another user can pay for a user's transaction fees, improving user experience by abstracting away gas payments.

## How It Works: A Detailed Walkthrough

Let's illustrate the asset recovery scenario for a claimed airdrop:

- **Wallet A**: Your compromised wallet. It is eligible for an airdrop but holds no ETH. You still have the private key.
- **Wallet B**: A secure, funded wallet you control (the "sponsor").

1. **Craft the Payload**: You define the sequence of operations for Wallet A to execute. For example:
    - Call 1: `claim` the airdropped tokens from the airdrop contract.
    - Call 2: `transfer` the newly claimed tokens to Wallet B.
2. **Sign Offline**: Using Wallet A's private key, you sign a message containing this sequence of calls. This signature authorizes the `BatchCall.sol` contract to execute these calls on behalf of Wallet A. This step is done offline and requires no gas.
3. **Broadcast with Sponsor**: Wallet B broadcasts the EIP-7702 transaction. This transaction sets Wallet A's code to `BatchCall.sol` for this transaction only, calls the `execute` function with the signed payload, and **pays the entire gas fee**.
4. **Execution & Verification**:
    - The `BatchCall.sol` contract (now acting as Wallet A) first calls the `Tracker.sol` contract to get a unique nonce. This prevents the same signed message from being broadcast and executed multiple times (a replay attack).
    - It then verifies that the signature was indeed created by Wallet A. In the context of EIP-7702, `address(this)` resolves to Wallet A's address, confirming the authorization.
    - If verification passes, the contract executes the calls (`claim`, `transfer`) in order. The entire batch is atomic—if any call fails, the whole transaction reverts.

Your assets are now safely in Wallet B. The sweeper bot never had a chance to steal any ETH from Wallet A because none was ever sent there.

## Core Components

### `BatchCall.sol`: The Executor Contract

This is the heart of the system. It's the temporary code that an EOA adopts via EIP-7702. Its sole purpose is to verify a signature against a payload of calls and, if valid, execute them sequentially.

### `Tracker.sol`: The Nonce Manager (Anti-Replay Protection)

This is a simple but critical security component. It's a standalone contract that maintains a `nonce` (a number that is only used once) for every address that interacts with it.

When `BatchCall.sol` executes, it asks the `Tracker` for the *next* nonce for the calling EOA. This nonce is included in the data that gets hashed and verified against the signature. If an attacker tried to re-submit the same transaction, the `Tracker` would provide a *new* nonce. The old signature would be invalid because it was signed with the old nonce, and the transaction would fail. This ensures that a signed batch can only ever be executed once.

## Post-Pectra Upgrade Compatibility

This functionality is dependent on the inclusion of **EIP-7702** in a future Ethereum network upgrade, widely expected to be the **Pectra** upgrade. Once implemented, this tool will be usable on all EVM-compatible networks that adopt this upgrade.

## Setup and Usage

This project is developed using [Foundry](https://book.getfoundry.sh/).

### Dependencies

To install the dependencies, run the following command:

```shell
forge install
```

### Build

To compile the contracts:

```shell
forge build
```

### Test

To run the tests:

```shell
forge test
```

### Deployment

You can use the scripts in the `script` directory to deploy the contracts.

1. **Deploy the `Tracker` contract:** This is a one-time deployment.

    ```shell
    forge script script/DeployTracker.s.sol:DeployTrackerScript --rpc-url <your_rpc_url> --private-key <your_private_key> --broadcast
    ```

2. **Update `BatchCall.sol`:** Take the deployed `Tracker` address and update the `TRACKER_ADDRESS` constant in `BatchCall.sol`.
3. **Deploy the `BatchCall` contract:**

    ```shell
    forge script script/DeployBatch.s.sol:DeployBatchScript --rpc-url <your_rpc_url> --private-key <your_private_key> --broadcast
    ```

## Security Disclaimer

These contracts have not been professionally audited. They are provided for educational and experimental purposes. While they implement critical security patterns like signature verification and nonce-based replay protection, use them in a production environment at your own risk. The security of your assets depends on the correctness of this code and the underlying EIP-7702 implementation.
[Source](https://github.com/codeesura/eip7702-asset-rescuer)
