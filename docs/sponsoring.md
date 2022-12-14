# Sponsored Reserves

Sponsored reserves allow an account (sponsoring account) to pay the base reserves for another account (sponsored account). While this relationship exists, base reserve requirements that would normally accumulate on the sponsored account now accumulate on the sponsoring account.

Both the Begin Sponsoring Future Reserves and the End Sponsoring Future Reserves operations must appear in the sponsorship transaction, guaranteeing that both accounts agree to the sponsorship.

Anything that increases the minimum balance can be sponsored (account creation, offers, trustlines, data entries, signers, claimable balances).

Sponsoring future reservers are described in detail in the [Sponsored Reserves](https://developers.stellar.org/docs/encyclopedia/sponsored-reserves) chapter of the Stellar developer site.

Source code examples of using Sponsoring reserves with the SDK can be found in the [Operations test cases](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/stellarsdk/stellarsdkTests/operations/OperationsRemoteTestCase.swift) of the SDK.

Next chapter is [Stellar Ecosystem Proposals](seps.md).