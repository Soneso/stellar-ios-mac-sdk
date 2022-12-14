# Claimable Balances

Claimable balances are used to split a payment into two parts.

Part 1: sending account creates a payment, or ClaimableBalanceEntry, using the Create Claimable Balance operation
Part 2: destination account(s), or claimant(s), accepts the ClaimableBalanceEntry using the Claim Claimable Balance operation

Claimable balances allow an account to send a payment to another account that is not necessarily prepared to receive the payment. They can be used when you send a non-native asset to an account that has not yet established a trustline, which can be useful for anchors onboarding new users. A trustline must be established by the claimant to the asset before it can claim the claimable balance, otherwise, the claim will result in an op_no_trust error.

Claimable Balances are described in more detail in the [Claimable Balances](https://developers.stellar.org/docs/encyclopedia/claimable-balances) chapter of the Stellar developer site.

Source code examples of using Claimable Balances with the SDK can be found in the [Operations test cases](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdkTests/operations/OperationsRemoteTestCase.swift) and in the [Clawback test cases](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdkTests/payments/ClawbackTestCase.swift) of the SDK.

Next chapter is [Sponsoring Future reserves](sponsoring.md)