## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Run Local Chain

To run a local Ethereum chain for testing:

```shell
$ anvil
```

This will start a local Ethereum node at http://localhost:8545 with 10 test accounts, each funded with 10000 ETH.

### Deploy to Local Chain

To deploy the Uniswap contracts to your local chain:

```shell
$ forge script script/DeployUniswap.s.sol --broadcast --rpc-url http://localhost:8545
```

This will deploy the contracts to your local chain and broadcast the transactions.

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
