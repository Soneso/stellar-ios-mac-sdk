# Path Payments

In a path payment, the asset received differs from the asset sent. Rather than the operation transferring assets directly from one account to another, path payments cross through the SDEX and/or liquidity pools before arriving at the destination account. For the path payment to succeed, there has to be a DEX offer or liquidity pool exchange path in existence. It can sometimes take several hops of conversion to succeed.

For example:

Account A sells XLM → [buy XLM / sell ETH → buy ETH / sell BTC → buy BTC / sell USDC] → Account B receives USDC

It is possible for path payments to fail if there are no viable exchange paths.

Path payments use the Path Payment Strict Send or Path Payment Strict Receive operations. Path Payment Strict Send allows a user to specify the amount of the asset to send. The amount received will vary based on offers in the order books and/or liquidity pools. Path Payment allows a user to specify the amount of the asset received. The amount sent will vary based on the offers in the order books/liquidity pools.

Source code examples can be found in [the path payment test cases](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdkIntegrationTests/payment_paths/PaymentPathsTestCase.swift)

Next chapter is [Trading](trading.md)