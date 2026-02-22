# Advanced Features

Less common but important patterns for the Stellar iOS/Mac SDK.

## Multi-Signature Accounts

```swift
import stellarsdk

func setupMultiSig(
    primaryKeyPair: KeyPair,
    secondaryKeyPair: KeyPair
) async throws {
    let sdk = StellarSDK.testNet()

    let accountEnum = await sdk.accounts.getAccountDetails(accountId: primaryKeyPair.accountId)
    guard case .success(let accountResponse) = accountEnum else {
        throw StellarSDKError.invalidArgument(message: "Account load failed")
    }

    // Add secondary signer with weight and set thresholds
    let signer = Signer.ed25519PublicKey(keyPair: secondaryKeyPair)
    let setOptionsOp = try SetOptionsOperation(
        sourceAccountId: nil,
        inflationDestination: nil,
        clearFlags: nil,
        setFlags: nil,
        masterKeyWeight: 1,
        lowThreshold: 1,
        mediumThreshold: 2,
        highThreshold: 2,
        homeDomain: nil,
        signer: signer,
        signerWeight: 1
    )

    let tx = try Transaction(
        sourceAccount: accountResponse,
        operations: [setOptionsOp],
        memo: nil
    )

    try tx.sign(keyPair: primaryKeyPair, network: Network.testnet)

    let submitEnum = await sdk.transactions.submitTransaction(transaction: tx)
    if case .success(let response) = submitEnum {
        print("Multi-sig setup TX: \(response.transactionHash)")
    }
}

// Sign with multiple signers
func signMultiSig(
    transaction: Transaction,
    signers: [KeyPair],
    network: Network
) throws {
    for signer in signers {
        try transaction.sign(keyPair: signer, network: network)
    }
}
```

## Sponsored Reserves

```swift
import stellarsdk

func sponsorAccountCreation(
    sponsorKeyPair: KeyPair,
    newAccountKeyPair: KeyPair
) async throws {
    let sdk = StellarSDK.testNet()

    let accountEnum = await sdk.accounts.getAccountDetails(accountId: sponsorKeyPair.accountId)
    guard case .success(let accountResponse) = accountEnum else {
        throw StellarSDKError.invalidArgument(message: "Sponsor account load failed")
    }

    let beginSponsorOp = BeginSponsoringFutureReservesOperation(
        sponsoredAccountId: newAccountKeyPair.accountId,
        sponsoringAccountId: nil  // uses transaction source (sponsor)
    )

    let createOp = CreateAccountOperation(
        sourceAccountId: sponsorKeyPair.accountId,
        destination: newAccountKeyPair,
        startBalance: 0
    )

    let endSponsorOp = EndSponsoringFutureReservesOperation(
        sponsoredAccountId: newAccountKeyPair.accountId
    )

    let tx = try Transaction(
        sourceAccount: accountResponse,
        operations: [beginSponsorOp, createOp, endSponsorOp],
        memo: nil
    )

    // Both parties must sign
    try tx.sign(keyPair: sponsorKeyPair, network: Network.testnet)
    try tx.sign(keyPair: newAccountKeyPair, network: Network.testnet)

    let submitEnum = await sdk.transactions.submitTransaction(transaction: tx)
    if case .success(let response) = submitEnum {
        print("Sponsored creation TX: \(response.transactionHash)")
    }
}
```

## Claimable Balances

```swift
import stellarsdk

func createClaimableBalance(
    senderKeyPair: KeyPair,
    claimantAccountId: String,
    amount: Decimal
) async throws {
    let sdk = StellarSDK.testNet()

    let accountEnum = await sdk.accounts.getAccountDetails(accountId: senderKeyPair.accountId)
    guard case .success(let accountResponse) = accountEnum else {
        throw StellarSDKError.invalidArgument(message: "Account load failed")
    }

    let claimant = Claimant(destination: claimantAccountId, predicate: Claimant.predicateUnconditional())
    let createOp = CreateClaimableBalanceOperation(
        asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
        amount: amount,
        claimants: [claimant]
    )

    let tx = try Transaction(
        sourceAccount: accountResponse,
        operations: [createOp],
        memo: nil
    )

    try tx.sign(keyPair: senderKeyPair, network: Network.testnet)
    let submitEnum = await sdk.transactions.submitTransaction(transaction: tx)
    if case .success(let response) = submitEnum {
        print("Claimable balance created: \(response.transactionHash)")
    }
}
```

## Liquidity Pools

```swift
import stellarsdk

func depositToLiquidityPool(
    keyPair: KeyPair,
    poolId: String,
    maxAmountA: Decimal,
    maxAmountB: Decimal
) async throws {
    let sdk = StellarSDK.testNet()

    let accountEnum = await sdk.accounts.getAccountDetails(accountId: keyPair.accountId)
    guard case .success(let accountResponse) = accountEnum else {
        throw StellarSDKError.invalidArgument(message: "Account load failed")
    }

    let depositOp = LiquidityPoolDepositOperation(
        sourceAccountId: nil,
        liquidityPoolId: poolId,
        maxAmountA: maxAmountA,
        maxAmountB: maxAmountB,
        minPrice: Price(numerator: 1, denominator: 2),
        maxPrice: Price(numerator: 2, denominator: 1)
    )

    let tx = try Transaction(
        sourceAccount: accountResponse,
        operations: [depositOp],
        memo: nil
    )

    try tx.sign(keyPair: keyPair, network: Network.testnet)
    let submitEnum = await sdk.transactions.submitTransaction(transaction: tx)
    if case .success(let response) = submitEnum {
        print("Pool deposit TX: \(response.transactionHash)")
    }
}
```

## Muxed Accounts

```swift
import stellarsdk

func useMuxedAccount(keyPair: KeyPair, muxedId: UInt64) throws {
    // Create muxed account (M-address) from base account
    let muxedAccount = MuxedAccount(keyPair: keyPair, sequenceNumber: 0, id: muxedId)
    print("Muxed account ID (M-address): \(muxedAccount.accountId)")
    print("Base account (G-address): \(muxedAccount.ed25519AccountId)")

    // Muxed accounts can be used as payment destinations
    let payment = try PaymentOperation(
        sourceAccountId: nil,
        destinationAccountId: muxedAccount.accountId,  // M-address
        asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
        amount: 10.0
    )
    print("Payment to muxed account created")
}
```

## Fee-Bump Transactions

```swift
import stellarsdk

func createFeeBumpTransaction(
    innerTransaction: Transaction,
    feeSourceKeyPair: KeyPair,
    newFee: UInt64
) async throws {
    let sdk = StellarSDK.testNet()

    let accountEnum = await sdk.accounts.getAccountDetails(accountId: feeSourceKeyPair.accountId)
    guard case .success(let accountResponse) = accountEnum else {
        throw StellarSDKError.invalidArgument(message: "Fee source account load failed")
    }

    let feeSourceAccount = MuxedAccount(
        keyPair: feeSourceKeyPair,
        sequenceNumber: accountResponse.sequenceNumber
    )

    // fee is the TOTAL max fee in stroops (not per-operation)
    // Must be >= (inner per-op fee * inner op count) + 100
    // Example: inner tx has 2 ops at 100 stroops each → fee must be >= 300
    let feeBumpTx = try FeeBumpTransaction(
        sourceAccount: feeSourceAccount,
        fee: newFee,
        innerTransaction: innerTransaction
    )

    try feeBumpTx.sign(keyPair: feeSourceKeyPair, network: Network.testnet)

    let submitEnum = await sdk.transactions.submitFeeBumpTransaction(transaction: feeBumpTx)
    switch submitEnum {
    case .success(let response):
        print("Fee-bump TX: \(response.transactionHash)")
    case .destinationRequiresMemo(let accountId):
        print("Destination \(accountId) requires memo")
    case .failure(let error):
        print("Fee-bump failed: \(error)")
    }
}
```

## Path Payments

```swift
import stellarsdk

func strictReceivePathPayment(
    senderKeyPair: KeyPair,
    destinationAccountId: String,
    sendAsset: Asset,
    sendMax: Decimal,
    destAsset: Asset,
    destAmount: Decimal,
    path: [Asset]
) async throws {
    let sdk = StellarSDK.testNet()

    let accountEnum = await sdk.accounts.getAccountDetails(accountId: senderKeyPair.accountId)
    guard case .success(let accountResponse) = accountEnum else {
        throw StellarSDKError.invalidArgument(message: "Account load failed")
    }

    let pathPaymentOp = try PathPaymentStrictReceiveOperation(
        sourceAccountId: nil,
        sendAsset: sendAsset,
        sendMax: sendMax,
        destinationAccountId: destinationAccountId,
        destAsset: destAsset,
        destAmount: destAmount,
        path: path
    )

    let tx = try Transaction(
        sourceAccount: accountResponse,
        operations: [pathPaymentOp],
        memo: nil
    )

    try tx.sign(keyPair: senderKeyPair, network: Network.testnet)
    let submitEnum = await sdk.transactions.submitTransaction(transaction: tx)
    if case .success(let response) = submitEnum {
        print("Path payment TX: \(response.transactionHash)")
    }
}
```
