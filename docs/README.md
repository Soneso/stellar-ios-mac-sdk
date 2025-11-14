# Welcome


This Swift Stellar SDK helps iOS and macOS developers to interact with the Stellar Blockchain and its Ecosystem. 

The SDK has three main uses: 

- It helps you to query the blockchain by using the Horizon & RPC endpoints provided by Stellar.
- It helps you to build, sign and submit transactions to the Stellar Network.
- It helps you deploy and invoke smart contracts.
- It helps you to interact with the Stellar Ecosystem (e.g. Anchors), by providing implementations of different [Stellar Ecosystem Proposals](https://github.com/stellar/stellar-protocol/tree/master/ecosystem).

The goal of this documentation is to provide you knowledge of how to use the different functions of SDK in your app. 

Before you start, please familiarize yourself with the basic concepts of Stellar. Take a look at the [Stellar developer site](https://developers.stellar.org/docs/).

We also recommend that you use the [Stellar Laboratory](https://laboratory.stellar.org/) tools while learning to implement applications that access the Stellar Network. It provides a set of tools that enables you to try out and learn about the Stellar Network. With the laboratory you can manually build transactions, sign them, and submit them to the network via the browser. It can also make requests to any of the Horizon endpoints.

API documentation can be found [here](https://soneso.github.io/stellar-ios-mac-sdk/).

## Documentation content

We have structured the documentation in such a way that it starts with the basics and builds on this to cover the more advanced topics. Of course, it can also be used as a reference work. 

Many of the source code examples from the documentation can also be found as [test cases](https://github.com/Soneso/stellar-ios-mac-sdk/tree/master/stellarsdk/stellarsdkTests) in the source code of the SDK. If you don't find what you search for in this documentation, we recommend you to also look for it in the [test cases](https://github.com/Soneso/stellar-ios-mac-sdk/tree/master/stellarsdk/stellarsdkTests), because they cover the whole functionality of the SDK.

| Topics | Description |
| :--- | :--- |
| [Overview](overview.md)| Gives you an overview and insights about the functionality of the SDK. |
| [Working with accounts](accounts.md)| Shows you how to create new accounts, query their data, update them by using the SDK. |
| [Send and receive native Payments](payments.md)| Describes how to send native XLM payments from one account to another. Also describes how to query them.|
| [Assets & trustlines](assets.md)| Describes how to work with non native assets (issue, transfer, query, etc.). |
| [Querying data](querying.md)| Shows how to query data from the Stellar Network.|
| [Streaming](streaming.md)| Learn how to listen for events such as payments or trades as they occur on the stellar network.|
| [Path Payments](path-payments.md)| Learn how to use path payments with the sdk.|
| [Trading: SDEX and Liquidity Pools](trading.md)| Learn how to manage offers, query the orderbook and other things related to trading.|
| [Claimable Balances](claimable-balances.md)| Describes how to work with claimable balances by using the SDK.|
| [Sponsoring Future reserves](sponsoring.md)| Describes how to sponsor and revoke future reserves by using the SDK.|
| [Stellar Ecosystem Proposals](seps.md)| Learn how to work with the SEP's implementations of this SDK.|


Next chapter is [Overview](overview.md).