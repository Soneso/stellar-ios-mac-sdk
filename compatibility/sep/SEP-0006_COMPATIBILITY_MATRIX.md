# SEP-0006 (Deposit and Withdrawal API) Compatibility Matrix

**Generated:** 2026-03-29

**SDK Version:** 3.4.6

**SEP Version:** 4.3.0

**SEP Status:** Active (Interactive components are deprecated in favor of SEP-24)

**SEP URL:** https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md

## SEP Summary

This SEP defines the standard way for anchors and wallets to interact on behalf of users.

This improves user experience by allowing wallets and other clients to interact with anchors directly without the user needing to leave the wallet to go to the anchor's site.

Please note that this SEP provides a normalized interface specification that allows wallets and other services to interact with anchors _programmatically_.

[SEP-24](sep-0024.md) was created to support use cases where the anchor may want to interact with users _interactively_ using a popup opened within the wallet application.

This proposal defines a standard protocol enabling the following features directly within a wallet or other Stellar client: - Deposit external assets with an anchor - Withdraw assets from an anchor - Execute.

## Overall Coverage

**Total Coverage:** 100.0% (95/95 fields)

- ✅ **Implemented:** 95/95
- ❌ **Not Implemented:** 0/95

**Required Fields:** 100.0% (22/22)

**Optional Fields:** 100.0% (73/73)

## Implementation Status

✅ **Implemented**

### Implementation Files

- `stellarsdk/stellarsdk/transfer_server_protocol/TransferServerService.swift`
- `stellarsdk/stellarsdk/transfer_server_protocol/requests/DepositRequest.swift`
- `stellarsdk/stellarsdk/transfer_server_protocol/responses/DepositResponse.swift`
- `stellarsdk/stellarsdk/transfer_server_protocol/requests/DepositExchangeRequest.swift`
- `stellarsdk/stellarsdk/transfer_server_protocol/requests/WithdrawRequest.swift`
- `stellarsdk/stellarsdk/transfer_server_protocol/responses/WithdrawResponse.swift`
- `stellarsdk/stellarsdk/transfer_server_protocol/requests/WithdrawExchangeRequest.swift`
- `stellarsdk/stellarsdk/transfer_server_protocol/responses/AnchorInfoResponse.swift`
- `stellarsdk/stellarsdk/transfer_server_protocol/responses/AnchorTransactionsResponse.swift`
- `stellarsdk/stellarsdk/transfer_server_protocol/requests/FeeRequest.swift`
- `stellarsdk/stellarsdk/transfer_server_protocol/responses/AnchorFeeResponse.swift`
- `stellarsdk/stellarsdk/transfer_server_protocol/errors/TransferServerError.swift`

### Key Classes

- **`TransferServerService`**: Main service class implementing all SEP-06 endpoints
- **`DepositRequest`**: Request model for GET /deposit endpoint
- **`DepositResponse`**: Response model with deposit instructions and transaction ID
- **`DepositExchangeRequest`**: Request model for GET /deposit-exchange with SEP-38 quotes
- **`WithdrawRequest`**: Request model for GET /withdraw endpoint
- **`WithdrawResponse`**: Response model with withdrawal account and transaction ID
- **`WithdrawExchangeRequest`**: Request model for GET /withdraw-exchange with SEP-38 quotes
- **`AnchorInfoResponse`**: Response model for GET /info with anchor capabilities
- **`AnchorTransaction`**: Transaction model with status and details
- **`AnchorTransactionStatus`**: Enum for all transaction status values
- **`AnchorTransactionsResponse`**: Response model for GET /transactions endpoint
- **`FeeRequest`**: Request model for GET /fee endpoint (deprecated)
- **`AnchorFeeResponse`**: Response model with fee calculations
- **`DepositAsset`**: Asset information for deposits from /info endpoint
- **`WithdrawAsset`**: Asset information for withdrawals from /info endpoint
- **`AnchorFeatureFlags`**: Feature flags (account_creation, claimable_balances)
- **`TransferServerError`**: Error enum for all SEP-06 error cases

## Coverage by Section

| Section | Coverage | Required Coverage | Implemented | Total |
|---------|----------|-------------------|-------------|-------|
| Deposit Endpoints | 100.0% | 100.0% | 2 | 2 |
| Deposit Request Parameters | 100.0% | 100.0% | 15 | 15 |
| Deposit Response Fields | 100.0% | 100.0% | 8 | 8 |
| Withdraw Endpoints | 100.0% | 100.0% | 2 | 2 |
| Withdraw Request Parameters | 100.0% | 100.0% | 17 | 17 |
| Withdraw Response Fields | 100.0% | 100.0% | 10 | 10 |
| Info Endpoint | 100.0% | 100.0% | 1 | 1 |
| Info Response Fields | 100.0% | 100.0% | 8 | 8 |
| Fee Endpoint | 100.0% | 100.0% | 1 | 1 |
| Transaction Endpoints | 100.0% | 100.0% | 3 | 3 |
| Transaction Fields | 100.0% | 100.0% | 16 | 16 |
| Transaction Status Values | 100.0% | 100.0% | 12 | 12 |

## Detailed Field Comparison

### Deposit Endpoints

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `deposit` | ✓ | ✅ | `deposit(request:)` | GET /deposit - Initiates a deposit transaction for on-chain assets |
| `deposit_exchange` |  | ✅ | `depositExchange(request:)` | GET /deposit-exchange - Initiates a deposit with asset exchange (SEP-38 integration) |

### Deposit Request Parameters

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `asset_code` | ✓ | ✅ | `assetCode` | Code of the on-chain asset the user wants to receive |
| `account` | ✓ | ✅ | `account` | Stellar account ID of the user |
| `memo_type` |  | ✅ | `memoType` | Type of memo to attach to transaction |
| `memo` |  | ✅ | `memo` | Value of memo to attach to transaction |
| `email_address` |  | ✅ | `emailAddress` | Email address of the user (for notifications) |
| `type` |  | ✅ | `type` | Type of deposit method (e.g., bank_account, cash, mobile_money) |
| `wallet_name` |  | ✅ | `walletName` | Name of the wallet the user is using |
| `wallet_url` |  | ✅ | `walletUrl` | URL of the wallet the user is using |
| `lang` |  | ✅ | `lang` | Language code for response messages (ISO 639-1) |
| `on_change_callback` |  | ✅ | `onChangeCallback` | URL for anchor to send callback when transaction status changes |
| `amount` |  | ✅ | `amount` | Amount of on-chain asset the user wants to receive |
| `country_code` |  | ✅ | `countryCode` | Country code of the user (ISO 3166-1 alpha-3) |
| `claimable_balance_supported` |  | ✅ | `claimableBalanceSupported` | Whether the client supports receiving claimable balances |
| `customer_id` |  | ✅ | `customerId` | ID of the customer from SEP-12 KYC process |
| `location_id` |  | ✅ | `locationId` | ID of the physical location for cash pickup |

### Deposit Response Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `how` | ✓ | ✅ | `how` | Instructions for how to deposit the asset |
| `id` |  | ✅ | `id` | Persistent transaction identifier |
| `eta` |  | ✅ | `eta` | Estimated seconds until deposit completes |
| `min_amount` |  | ✅ | `minAmount` | Minimum deposit amount |
| `max_amount` |  | ✅ | `maxAmount` | Maximum deposit amount |
| `fee_fixed` |  | ✅ | `feeFixed` | Fixed fee for deposit |
| `fee_percent` |  | ✅ | `feePercent` | Percentage fee for deposit |
| `extra_info` |  | ✅ | `extraInfo` | Additional information about the deposit |

### Withdraw Endpoints

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `withdraw` | ✓ | ✅ | `withdraw(request:)` | GET /withdraw - Initiates a withdrawal transaction for off-chain assets |
| `withdraw_exchange` |  | ✅ | `withdrawExchange(request:)` | GET /withdraw-exchange - Initiates a withdrawal with asset exchange (SEP-38 integration) |

### Withdraw Request Parameters

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `asset_code` | ✓ | ✅ | `assetCode` | Code of the on-chain asset the user wants to send |
| `type` | ✓ | ✅ | `type` | Type of withdrawal method (e.g., bank_account, cash, mobile_money) |
| `dest` |  | ✅ | `dest` | Destination for withdrawal (bank account number, etc.) |
| `dest_extra` |  | ✅ | `destExtra` | Extra information for destination (routing number, etc.) |
| `account` |  | ✅ | `account` | Stellar account ID of the user |
| `memo` |  | ✅ | `memo` | Memo to identify the user if account is shared |
| `memo_type` |  | ✅ | `memoType` | Type of memo (text, id, or hash) |
| `wallet_name` |  | ✅ | `walletName` | Name of the wallet the user is using |
| `wallet_url` |  | ✅ | `walletUrl` | URL of the wallet the user is using |
| `lang` |  | ✅ | `lang` | Language code for response messages (ISO 639-1) |
| `on_change_callback` |  | ✅ | `onChangeCallback` | URL for anchor to send callback when transaction status changes |
| `amount` |  | ✅ | `amount` | Amount of on-chain asset the user wants to send |
| `country_code` |  | ✅ | `countryCode` | Country code of the user (ISO 3166-1 alpha-3) |
| `refund_memo` |  | ✅ | `refundMemo` | Memo to use for refund transaction if withdrawal fails |
| `refund_memo_type` |  | ✅ | `refundMemoType` | Type of refund memo (text, id, or hash) |
| `customer_id` |  | ✅ | `customerId` | ID of the customer from SEP-12 KYC process |
| `location_id` |  | ✅ | `locationId` | ID of the physical location for cash pickup |

### Withdraw Response Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `account_id` | ✓ | ✅ | `accountId` | Stellar account to send withdrawn assets to |
| `memo_type` |  | ✅ | `memoType` | Type of memo to attach to transaction |
| `memo` |  | ✅ | `memo` | Value of memo to attach to transaction |
| `id` | ✓ | ✅ | `id` | Persistent transaction identifier |
| `eta` |  | ✅ | `eta` | Estimated seconds until withdrawal completes |
| `min_amount` |  | ✅ | `minAmount` | Minimum withdrawal amount |
| `max_amount` |  | ✅ | `maxAmount` | Maximum withdrawal amount |
| `fee_fixed` |  | ✅ | `feeFixed` | Fixed fee for withdrawal |
| `fee_percent` |  | ✅ | `feePercent` | Percentage fee for withdrawal |
| `extra_info` |  | ✅ | `extraInfo` | Additional information about the withdrawal |

### Info Endpoint

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `info_endpoint` | ✓ | ✅ | `info(language:jwtToken:)` | GET /info - Provides anchor capabilities and asset information |

### Info Response Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `deposit` | ✓ | ✅ | `deposit` | Map of asset codes to deposit asset information |
| `withdraw` | ✓ | ✅ | `withdraw` | Map of asset codes to withdraw asset information |
| `deposit-exchange` |  | ✅ | `depositExchange` | Map of asset codes to deposit-exchange asset information |
| `withdraw-exchange` |  | ✅ | `withdrawExchange` | Map of asset codes to withdraw-exchange asset information |
| `fee` |  | ✅ | `fee` | Fee endpoint information |
| `transactions` |  | ✅ | `transactions` | Transaction history endpoint information |
| `transaction` |  | ✅ | `transaction` | Single transaction endpoint information |
| `features` |  | ✅ | `features` | Feature flags supported by the anchor |

### Fee Endpoint

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `fee_endpoint` |  | ✅ | `fee(request:)` | GET /fee - Calculates fees for a deposit or withdrawal operation (deprecated) |

### Transaction Endpoints

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `transactions` | ✓ | ✅ | `getTransactions(request:)` | GET /transactions - Retrieves transaction history for an account |
| `transaction` | ✓ | ✅ | `getTransaction(request:)` | GET /transaction - Retrieves details for a single transaction |
| `patch_transaction` |  | ✅ | `patchTransaction(id:jwt:contentType:body:)` | PATCH /transaction - Updates transaction fields (for debugging/testing) |

### Transaction Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `id` | ✓ | ✅ | `id` | Unique transaction identifier |
| `kind` | ✓ | ✅ | `kind` | Kind of transaction (deposit, withdrawal, deposit-exchange, withdrawal-exchange) |
| `status` | ✓ | ✅ | `status` | Current status of the transaction |
| `started_at` | ✓ | ✅ | `startedAt` | When transaction was created (ISO 8601) |
| `status_eta` |  | ✅ | `statusEta` | Estimated seconds until status changes |
| `amount_in` |  | ✅ | `amountIn` | Amount received by anchor |
| `amount_out` |  | ✅ | `amountOut` | Amount sent by anchor to user |
| `amount_fee` |  | ✅ | `amountFee` | Total fee charged for transaction |
| `completed_at` |  | ✅ | `completedAt` | When transaction completed (ISO 8601) |
| `stellar_transaction_id` |  | ✅ | `stellarTransactionId` | Hash of the Stellar transaction |
| `external_transaction_id` |  | ✅ | `externalTransactionId` | Identifier from external system |
| `message` |  | ✅ | `message` | Human-readable message about transaction |
| `refunded` |  | ✅ | `refunded` | Whether transaction was refunded |
| `refunds` |  | ✅ | `refunds` | Refund information if applicable |
| `from` |  | ✅ | `from` | Stellar account that initiated the transaction |
| `to` |  | ✅ | `to` | Stellar account receiving the transaction |

### Transaction Status Values

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `completed` | ✓ | ✅ | `completed` | Transaction completed successfully |
| `pending_anchor` | ✓ | ✅ | `pendingAnchor` | Anchor is processing the transaction |
| `pending_stellar` |  | ✅ | `pendingStellar` | Stellar transaction has been submitted |
| `pending_user_transfer_start` | ✓ | ✅ | `pendingUserTransferStart` | Waiting for user to initiate off-chain transfer |
| `incomplete` | ✓ | ✅ | `incomplete` | Deposit/withdrawal has not yet been submitted |
| `pending_external` |  | ✅ | `pendingExternal` | Waiting for external action (banking system, etc.) |
| `pending_trust` |  | ✅ | `pendingTrust` | User needs to add trustline for asset |
| `pending_user` |  | ✅ | `pendingUser` | Waiting for user action (accepting claimable balance) |
| `pending_user_transfer_complete` |  | ✅ | `pendingUserTransferComplete` | Off-chain transfer has been initiated |
| `error` |  | ✅ | `error` | Transaction failed with error |
| `refunded` |  | ✅ | `refunded` | Transaction refunded |
| `expired` |  | ✅ | `expired` | Transaction expired without completion |

## Implementation Gaps

🎉 **No gaps found!** All fields are implemented.

## Legend

- ✅ **Implemented**: Field is implemented in SDK
- ❌ **Not Implemented**: Field is missing from SDK
- ⚙️ **Server**: Server-side only feature (not applicable to client SDKs)
- ✓ **Required**: Field is required by SEP specification
- (blank) **Optional**: Field is optional