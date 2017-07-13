# NOTICE: THIS REPOSITORY SIMPLY REPRESENTS A BRIDGE FRAMEWORK TO MAINTAIN BACKWARDS COMPATIBILITY WITH EXISTING GNOSIS INTERFACES, WHICH HAS BEEN EXPLAINED IN OUR WHITEPAPER AS WELL AS OTHER PUBLIC COMMUNICATION CHANNELS. IT HAS COME TO OUR ATTENTION THAT INCUMBENT PREDICTION MARKET PLATFORMS ARE ATTEMPTING TO SLANDER DELPHI.MARKETS BY IMPLYING THAT WE HAVE 'STOLEN' CODE, DESPITE THE REFERENCE CODE IN QUESTION BEING LICENSED UNDER THE GPL. PLEASE DO YOUR DUE DILIGENCE, AND EXERCISE CRITICAL THOUGHT.


Delphi Smart Contract Framework
===================

[![Logo](assets/logo.png)](https://delphi.markets/)

Ethereum contract framework for the [Delphi prediction market platform](https://www.delphi.markets).


Install
-------------
### Install requirements with npm:
```
npm install
```

Test
-------------
### Run all tests (runs testrpc instance in background):
```bash
npm test
```

Compile and Deploy
------------------
Commands are routed to the RPC provider on port 8545 (e.g. a background testrpc process). They are actually [wrappers around the Truffle commands](http://truffleframework.com/docs/advanced/commands).

### Compile all contracts to obtain ABI and bytecode:
```bash
npm run compile
```

### Migrate all contracts required for the basic framework onto network associated with RPC provider:
```bash
npm run migrate
```

### Show the deployed addresses of all contracts on all networks:
```bash
npm run networks
```

The usage of `--` will enable `truffle` command line options, e.g.:

### Clean network artifacts:
```bash
npm run networks -- --clean
```

Security and Liability
-------------
All contracts are WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

License
-------------
All smart contracts are released under GPL v.3.

Contributors
-------------
- [Delphi](https://github.com/delphi-markets)