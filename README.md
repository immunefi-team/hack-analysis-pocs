# Immunefi Hack Analysis Proof of Concepts

This repository contains all the proof of concepts (POCs) related to the Hack Analysis articles published on the Immunefi Medium blog, [https://medium.com/immunefi](https://medium.com/immunefi).

## Table of Contents

| Name | POC | Article | Command
| ---- | ------- | ---- | ---- |
| Platypus Finance Attack | [Platypus Finance Hack PoC](./test/platypus-february-2023/Attacker.t.sol) | [Hack Analysis: Platypus Finance, February 2023](https://medium.com/immunefi/hack-analysis-platypus-finance-february-2023-d11fce37d861) | `forge test -vvv --match-path ./test/platypus-february-2023/Attacker.t.sol --via-ir` |
| Omni Protocol Attack | [Omni Hack PoC](test/omni-july-2022/Attacker.t.sol) | [Hack Analysis: Omni Protocol, July 2022](https://medium.com/immunefi/hack-analysis-omni-protocol-july-2022-2d35091a0109) | `forge test -vvv --match-path ./test/omni-july-2022/Attacker.t.sol --via-ir` |
| Nomad Bridge Attack | [Nomad Hack PoC](./test/nomad-august-2022/Attacker.t.sol) | [Hack Analysis: Nomad Bridge, August 2022](https://medium.com/immunefi/hack-analysis-nomad-bridge-august-2022-5aa63d53814a) | `forge test -vvv --match-path ./test/nomad-august-2022/Attacker.t.sol --via-ir` |
| BonqDAO Price Manipulation Attack | [BonqDAO Hack PoC](./test/bonq-february-2023/Attacker.t.sol) | [Hack Analysis: BonqDAO, February 2023](https://medium.com/immunefi/hack-analysis-bonqdao-february-2023-ef6aab0086d6) | `forge test -vvv --match-path ./test/bonq-february-2023/Attacker.t.sol --via-ir` |
| Binance Bridge Attack | [Binance Hack PoC](./test/binance-october-2022/Attacker.t.sol) | [Hack Analysis: Binance Bridge, October 2022](https://medium.com/immunefi/hack-analysis-binance-bridge-october-2022-2876d39247c1) | `forge test -vvv --match-path ./test/binance-october-2022/Attacker.t.sol --via-ir` |
| Beanstalk Governance Attack | [Beanstalk Hack PoC](test/beanstalk-april-2022/Attacker.t.sol) | [Hack Analysis: Beanstalk Governance Attack, April 2022](https://medium.com/immunefi/hack-analysis-beanstalk-governance-attack-april-2022-f42788fc821e) | `forge test -vvv --match-path ./test/beanstalk-april-2022/Attacker.t.sol --via-ir` |
| 0xbaDc0dE MEV Bot | [0xbaDc0dE Hack PoC](./test/0xbad-september-2022/Attacker.t.sol) | [Hack Analysis: 0xbaDc0dE MEV Bot, September 2022](https://medium.com/immunefi/0xbadc0de-mev-bot-hack-analysis-30b9031ff0ba) | `forge test -vvv --match-path ./test/0xbad-september-2022/Attacker.t.sol --via-ir`


## Getting Started

Foundry is required to use this repository. See: https://book.getfoundry.sh/getting-started/installation.
