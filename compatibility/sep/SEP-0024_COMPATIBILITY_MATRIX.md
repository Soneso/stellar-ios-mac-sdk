# SEP-0024 (Hosted Deposit and Withdrawal) Compatibility Matrix

**Generated:** 2025-10-10

**SEP Version:** 3.8.0
**SEP Status:** Active
**SEP URL:** https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0024.md

## SEP Summary

This SEP defines the standard way for anchors and wallets to interact on behalf of users.

This improves user experience by allowing wallets and other clients to interact with anchors directly without the user needing to leave the wallet to go to the anchor's site.

It is based on [SEP-0006](sep-0006.md), but only supports the interactive flow, and cleans up or removes confusing artifacts.

If you are updating from SEP-0006 see the [changes from SEP-6](#changes-from-SEP-6) at the bottom of this document.

This proposal defines a standard protocol enabling the following features directly within a wallet or other Stellar client: - Deposit external assets with an anchor - Withdraw assets from an anchor - Communicate deposit & withdrawal fee structure for an anchor to the user - Handle anchor KYC .

## Overall Coverage

**Total Coverage:** 100.0% (94/94 fields)

- ✅ **Implemented:** 94/94
- ❌ **Not Implemented:** 0/94

**Required Fields:** 100.0% (24/24)

**Optional Fields:** 100.0% (70/70)

## Implementation Status

✅ **Implemented**

### Implementation Files

- `stellarsdk/stellarsdk/interactive/InteractiveService.swift`
- `stellarsdk/stellarsdk/interactive/requests/Sep24DepositRequest.swift`
- `stellarsdk/stellarsdk/interactive/requests/Sep24WithdrawRequest.swift`
- `stellarsdk/stellarsdk/interactive/requests/Sep24FeeRequest.swift`
- `stellarsdk/stellarsdk/interactive/requests/Sep24TransactionRequest.swift`
- `stellarsdk/stellarsdk/interactive/requests/Sep24TransactionsRequest.swift`
- `stellarsdk/stellarsdk/interactive/responses/Sep24InfoResponse.swift`
- `stellarsdk/stellarsdk/interactive/responses/Sep24InteractiveResponse.swift`
- `stellarsdk/stellarsdk/interactive/responses/Sep24TransactionResponse.swift`
- `stellarsdk/stellarsdk/interactive/responses/Sep24FeeResponse.swift`

### Key Classes

- **`InteractiveService`**: Main service class implementing all SEP-24 endpoints
- **`Sep24DepositRequest`**: Request model for POST /transactions/deposit/interactive
- **`Sep24WithdrawRequest`**: Request model for POST /transactions/withdraw/interactive
- **`Sep24FeeRequest`**: Request model for GET /fee endpoint
- **`Sep24TransactionRequest`**: Request model for GET /transaction endpoint
- **`Sep24TransactionsRequest`**: Request model for GET /transactions endpoint
- **`Sep24InfoResponse`**: Response model for GET /info with anchor capabilities
- **`Sep24InteractiveResponse`**: Response model with interactive URL and transaction ID
- **`Sep24TransactionResponse`**: Response model for single transaction details
- **`Sep24TransactionsResponse`**: Response model for transaction history
- **`Sep24FeeResponse`**: Response model with fee calculations
- **`Sep24Transaction`**: Transaction model with status, amounts, and timestamps
- **`Sep24DepositAsset`**: Deposit asset information with fees and limits
- **`Sep24WithdrawAsset`**: Withdrawal asset information with fees and limits
- **`Sep24FeatureFlags`**: Feature flags (account_creation, claimable_balances)
- **`Sep24FeeEndpointInfo`**: Fee endpoint availability and auth requirements

## Coverage by Section

| Section | Coverage | Required Coverage | Implemented | Total |
|---------|----------|-------------------|-------------|-------|
| Info Endpoint | 100.0% | 100.0% | 1 | 1 |
| Interactive Deposit Endpoint | 100.0% | 100.0% | 1 | 1 |
| Interactive Withdraw Endpoint | 100.0% | 100.0% | 1 | 1 |
| Transaction Endpoints | 100.0% | 100.0% | 2 | 2 |
| Fee Endpoint | 100.0% | 100.0% | 1 | 1 |
| Deposit Request Parameters | 100.0% | 100.0% | 12 | 12 |
| Withdraw Request Parameters | 100.0% | 100.0% | 11 | 11 |
| Interactive Response Fields | 100.0% | 100.0% | 3 | 3 |
| Transaction Status Values | 100.0% | 100.0% | 12 | 12 |
| Transaction Fields | 100.0% | 100.0% | 30 | 30 |
| Info Response Fields | 100.0% | 100.0% | 4 | 4 |
| Deposit Asset Fields | 100.0% | 100.0% | 6 | 6 |
| Withdraw Asset Fields | 100.0% | 100.0% | 6 | 6 |
| Feature Flags Fields | 100.0% | 100.0% | 2 | 2 |
| Fee Endpoint Info Fields | 100.0% | 100.0% | 2 | 2 |

## Detailed Field Comparison

### Info Endpoint

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `info_endpoint` | ✓ | ✅ | `info(language:)` | GET /info - Provides anchor capabilities and supported assets for interactive deposits/withdrawals |

### Interactive Deposit Endpoint

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `interactive_deposit` | ✓ | ✅ | `deposit(request:)` | POST /transactions/deposit/interactive - Initiates an interactive deposit transaction |

### Interactive Withdraw Endpoint

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `interactive_withdraw` | ✓ | ✅ | `withdraw(request:)` | POST /transactions/withdraw/interactive - Initiates an interactive withdrawal transaction |

### Transaction Endpoints

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `transactions` | ✓ | ✅ | `getTransactions(request:)` | GET /transactions - Retrieves transaction history for authenticated account |
| `transaction` | ✓ | ✅ | `getTransaction(request:)` | GET /transaction - Retrieves details for a single transaction |

### Fee Endpoint

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `fee_endpoint` |  | ✅ | `fee(request:)` | GET /fee - Calculates fees for a deposit or withdrawal operation (optional) |

### Deposit Request Parameters

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `asset_code` | ✓ | ✅ | `assetCode` | Code of the Stellar asset the user wants to receive |
| `asset_issuer` |  | ✅ | `assetIssuer` | Issuer of the Stellar asset (optional if anchor is issuer) |
| `source_asset` |  | ✅ | `sourceAsset` | Off-chain asset user wants to deposit (in SEP-38 format) |
| `amount` |  | ✅ | `amount` | Amount of asset to deposit |
| `quote_id` |  | ✅ | `quoteId` | ID from SEP-38 quote (for asset exchange) |
| `account` |  | ✅ | `account` | Stellar or muxed account for receiving deposit |
| `memo` |  | ✅ | `memo` | Memo value for transaction identification |
| `memo_type` |  | ✅ | `memoType` | Type of memo (text, id, or hash) |
| `wallet_name` |  | ✅ | `walletName` | Name of wallet for user communication |
| `wallet_url` |  | ✅ | `walletUrl` | URL to link in transaction notifications |
| `lang` |  | ✅ | `lang` | Language code for UI and messages (RFC 4646) |
| `claimable_balance_supported` |  | ✅ | `claimableBalanceSupported` | Whether client supports claimable balances |

### Withdraw Request Parameters

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `asset_code` | ✓ | ✅ | `assetCode` | Code of the Stellar asset user wants to send |
| `asset_issuer` |  | ✅ | `assetIssuer` | Issuer of the Stellar asset (optional if anchor is issuer) |
| `destination_asset` |  | ✅ | `destinationAsset` | Off-chain asset user wants to receive (in SEP-38 format) |
| `amount` |  | ✅ | `amount` | Amount of asset to withdraw |
| `quote_id` |  | ✅ | `quoteId` | ID from SEP-38 quote (for asset exchange) |
| `account` |  | ✅ | `account` | Stellar or muxed account that will send the withdrawal |
| `memo` |  | ✅ | `memo` | Memo for identifying the withdrawal transaction |
| `memo_type` |  | ✅ | `memoType` | Type of memo (text, id, or hash) |
| `wallet_name` |  | ✅ | `walletName` | Name of wallet for user communication |
| `wallet_url` |  | ✅ | `walletUrl` | URL to link in transaction notifications |
| `lang` |  | ✅ | `lang` | Language code for UI and messages (RFC 4646) |

### Interactive Response Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `type` | ✓ | ✅ | `type` | Always "interactive_customer_info_needed" for SEP-24 |
| `url` | ✓ | ✅ | `url` | URL for interactive flow popup/iframe |
| `id` | ✓ | ✅ | `id` | Unique transaction identifier |

### Transaction Status Values

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `incomplete` | ✓ | ✅ | `status: "incomplete"` | Customer information still being collected via interactive flow |
| `pending_user_transfer_start` | ✓ | ✅ | `status: "pending_user_transfer_start"` | Waiting for user to send funds (deposits) |
| `pending_user_transfer_complete` |  | ✅ | `status: "pending_user_transfer_complete"` | User transfer detected, awaiting confirmations |
| `pending_external` |  | ✅ | `status: "pending_external"` | Transaction being processed by external system |
| `pending_anchor` | ✓ | ✅ | `status: "pending_anchor"` | Anchor processing the transaction |
| `pending_stellar` |  | ✅ | `status: "pending_stellar"` | Transaction submitted to Stellar network |
| `pending_trust` |  | ✅ | `status: "pending_trust"` | User needs to establish trustline |
| `pending_user` |  | ✅ | `status: "pending_user"` | Waiting for user action (e.g., accepting claimable balance) |
| `completed` | ✓ | ✅ | `status: "completed"` | Transaction completed successfully |
| `refunded` |  | ✅ | `status: "refunded"` | Transaction refunded |
| `expired` |  | ✅ | `status: "expired"` | Transaction expired before completion |
| `error` |  | ✅ | `status: "error"` | Transaction encountered an error |

### Transaction Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `id` | ✓ | ✅ | `id` | Unique transaction identifier |
| `kind` | ✓ | ✅ | `kind` | Kind of transaction (deposit or withdrawal) |
| `status` | ✓ | ✅ | `status` | Current status of the transaction |
| `status_eta` |  | ✅ | `statusEta` | Estimated seconds until status changes |
| `kyc_verified` |  | ✅ | `kycVerified` | Whether KYC has been verified for this transaction |
| `more_info_url` | ✓ | ✅ | `moreInfoUrl` | URL with additional transaction information |
| `amount_in` |  | ✅ | `amountIn` | Amount received by anchor |
| `amount_in_asset` |  | ✅ | `amountInAsset` | Asset received by anchor (SEP-38 format) |
| `amount_out` |  | ✅ | `amountOut` | Amount sent by anchor to user |
| `amount_out_asset` |  | ✅ | `amountOutAsset` | Asset delivered to user (SEP-38 format) |
| `amount_fee` |  | ✅ | `amountFee` | Total fee charged for transaction |
| `amount_fee_asset` |  | ✅ | `amountFeeAsset` | Asset in which fees are calculated (SEP-38 format) |
| `quote_id` |  | ✅ | `quoteId` | ID of SEP-38 quote used for this transaction |
| `started_at` | ✓ | ✅ | `startedAt` | When transaction was created (ISO 8601) |
| `completed_at` |  | ✅ | `completedAt` | When transaction completed (ISO 8601) |
| `updated_at` |  | ✅ | `updatedAt` | When transaction status last changed (ISO 8601) |
| `user_action_required_by` |  | ✅ | `userActionRequiredBy` | Deadline for user action (ISO 8601) |
| `stellar_transaction_id` |  | ✅ | `stellarTransactionId` | Hash of the Stellar transaction |
| `external_transaction_id` |  | ✅ | `externalTransactionId` | Identifier from external system |
| `message` |  | ✅ | `message` | Human-readable message about transaction |
| `refunded` |  | ✅ | `refunded` | Whether transaction was refunded (deprecated) |
| `refunds` |  | ✅ | `refunds` | Refund information object |
| `from` |  | ✅ | `from` | Source address (Stellar for withdrawals, external for deposits) |
| `to` |  | ✅ | `to` | Destination address (Stellar for deposits, external for withdrawals) |
| `deposit_memo` |  | ✅ | `depositMemo` | Memo for deposit to Stellar address |
| `deposit_memo_type` |  | ✅ | `depositMemoType` | Type of deposit memo |
| `claimable_balance_id` |  | ✅ | `claimableBalanceId` | ID of claimable balance for deposit |
| `withdraw_anchor_account` |  | ✅ | `withdrawAnchorAccount` | Anchor's Stellar account for withdrawal payment |
| `withdraw_memo` |  | ✅ | `withdrawMemo` | Memo for withdrawal to anchor account |
| `withdraw_memo_type` |  | ✅ | `withdrawMemoType` | Type of withdraw memo |

### Info Response Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `deposit` | ✓ | ✅ | `depositAssets` | Map of asset codes to deposit asset information |
| `withdraw` | ✓ | ✅ | `withdrawAssets` | Map of asset codes to withdraw asset information |
| `fee` |  | ✅ | `feeEndpointInfo` | Fee endpoint information object |
| `features` |  | ✅ | `featureFlags` | Feature flags object |

### Deposit Asset Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `enabled` | ✓ | ✅ | `enabled` | Whether deposits are enabled for this asset |
| `min_amount` |  | ✅ | `minAmount` | Minimum deposit amount |
| `max_amount` |  | ✅ | `maxAmount` | Maximum deposit amount |
| `fee_fixed` |  | ✅ | `feeFixed` | Fixed deposit fee |
| `fee_percent` |  | ✅ | `feePercent` | Percentage deposit fee |
| `fee_minimum` |  | ✅ | `feeMinimum` | Minimum deposit fee |

### Withdraw Asset Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `enabled` | ✓ | ✅ | `enabled` | Whether withdrawals are enabled for this asset |
| `min_amount` |  | ✅ | `minAmount` | Minimum withdrawal amount |
| `max_amount` |  | ✅ | `maxAmount` | Maximum withdrawal amount |
| `fee_fixed` |  | ✅ | `feeFixed` | Fixed withdrawal fee |
| `fee_percent` |  | ✅ | `feePercent` | Percentage withdrawal fee |
| `fee_minimum` |  | ✅ | `feeMinimum` | Minimum withdrawal fee |

### Feature Flags Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `account_creation` |  | ✅ | `accountCreation` | Whether anchor supports creating accounts |
| `claimable_balances` |  | ✅ | `claimableBalances` | Whether anchor supports claimable balances |

### Fee Endpoint Info Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `enabled` | ✓ | ✅ | `enabled` | Whether fee endpoint is available |
| `authentication_required` |  | ✅ | `authenticationRequired` | Whether authentication is required for fee endpoint |

## Implementation Gaps

🎉 **No gaps found!** All fields are implemented.

## Recommendations

✅ The SDK has full compatibility with SEP-24!
- Always use SEP-10 authentication for deposit/withdraw endpoints
- Display the interactive URL in a popup or iframe for user KYC
- Poll transaction status endpoint to track deposit/withdrawal progress
- Handle all transaction status values appropriately in client applications
- Use /info endpoint to discover supported assets and capabilities
- Provide quote_id from SEP-38 when asset exchange is needed
- Include wallet_name and wallet_url for better user communication
- Support claimable balances for users without trustlines
- Implement proper memo handling for transaction identification
- Use lang parameter for localized user experience
- Monitor user_action_required_by timestamps for time-sensitive actions

## Legend

- ✅ **Implemented**: Field is implemented in SDK
- ❌ **Not Implemented**: Field is missing from SDK
- ✓ **Required**: Field is required by SEP specification
- (blank) **Optional**: Field is optional

---

**Report Generated:** 2025-10-10
**SDK Version:** 3.2.6
**Analysis Tool:** SEP Compatibility Matrix Generator v2.0