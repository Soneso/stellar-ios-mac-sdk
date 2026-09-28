# SEP-0029 (Account Memo Requirements) Compatibility Matrix

**Generated:** 2026-09-28

**SDK Version:** 3.12.0

**SEP Version:** 0.5.0

**SEP Status:** Active

**SEP URL:** https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0029.md

## SEP Summary

This SEP describes a standard way to define transaction memo requirements for incoming payments.

## Overall Coverage

**Total Coverage:** 100.0% (17/17 fields)

- ✅ **Implemented:** 17/17
- ❌ **Not Implemented:** 0/17

**Required Fields:** 100.0% (17/17)

**Optional Fields:** 100.0% (0/0)

## Implementation Status

✅ **Implemented**

### Implementation Files

- `stellarsdk/stellarsdk/service/TransactionsService.swift`
- `stellarsdk/stellarsdk/xdr_helpers/TransactionEnvelopeXDR+Helpers.swift`
- `stellarsdk/stellarsdk/sdk/ManageDataOperation.swift`

### Key Classes

- **`TransactionsService`**: Horizon transactions service whose submit and post methods run the SEP-29 memo required check unless skipMemoRequiredCheck is true
- **`TransactionPostResponseEnum`**: Submission result enum whose destinationRequiresMemo(destinationAccountId:) case names the account that requires a memo
- **`TransactionPostAsyncResponseEnum`**: Async submission result enum with the same destinationRequiresMemo(destinationAccountId:) case
- **`ManageDataOperation`**: Sets or removes the config.memo_required data entry on an account

## Coverage by Section

| Section | Coverage | Required Coverage | Implemented | Total |
|---------|----------|-------------------|-------------|-------|
| Memo Requirement Flag | 100.0% | 100.0% | 2 | 2 |
| Sender-side Check | 100.0% | 100.0% | 8 | 8 |
| Submission Integration | 100.0% | 100.0% | 7 | 7 |

## Detailed Field Comparison

### Memo Requirement Flag

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `memo_required_data_entry` | ✓ | ✅ | `checkMemoRequiredForDestinations (config.memo_required == "MQ==")` | Reads the destination account's config.memo_required data entry and compares it with the base64 encoding of 1 |
| `set_memo_required_flag` | ✓ | ✅ | `ManageDataOperation(sourceAccountId:name:data:)` | Sets or removes the data entry with a manage data operation |

### Sender-side Check

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `payment_destination` | ✓ | ✅ | `checkMemoRequired (PaymentOperation)` | Checks the destination of a payment operation |
| `path_payment_strict_send_destination` | ✓ | ✅ | `checkMemoRequired (PathPaymentStrictSendOperation)` | Checks the destination of a path payment strict send operation |
| `path_payment_strict_receive_destination` | ✓ | ✅ | `checkMemoRequired (PathPaymentStrictReceiveOperation)` | Checks the destination of a path payment strict receive operation |
| `account_merge_destination` | ✓ | ✅ | `checkMemoRequired (AccountMergeOperation)` | Checks the destination of an account merge operation |
| `muxed_destination_exempt` | ✓ | ✅ | `checkMemoRequired (M-address destinations skipped)` | Checks G-address destinations only and skips multiplexed M-address destinations |
| `memo_present_skips_lookup` | ✓ | ✅ | `checkMemoRequired (memo short-circuit)` | Performs no lookup when the transaction carries a memo |
| `fee_bump_inner_transaction` | ✓ | ✅ | `Transaction(envelopeXdr:) (fee bump inner transaction)` | Checks a fee bump envelope through the memo and operations of its inner transaction |
| `unknown_destination_skipped` | ✓ | ✅ | `checkMemoRequiredForDestinations (HTTP 404 skipped)` | Skips a destination Horizon does not know and lets the network report it |

### Submission Integration

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `submit_transaction_opt_out` | ✓ | ✅ | `submitTransaction(skipMemoRequiredCheck:)` | submitTransaction runs the check unless skipMemoRequiredCheck is true |
| `submit_async_transaction_opt_out` | ✓ | ✅ | `submitAsyncTransaction(skipMemoRequiredCheck:)` | submitAsyncTransaction runs the check unless skipMemoRequiredCheck is true |
| `submit_fee_bump_transaction_opt_out` | ✓ | ✅ | `submitFeeBumpTransaction(skipMemoRequiredCheck:)` | submitFeeBumpTransaction runs the check unless skipMemoRequiredCheck is true |
| `submit_fee_bump_async_transaction_opt_out` | ✓ | ✅ | `submitFeeBumpAsyncTransaction(skipMemoRequiredCheck:)` | submitFeeBumpAsyncTransaction runs the check unless skipMemoRequiredCheck is true |
| `post_transaction_opt_out` | ✓ | ✅ | `postTransaction(skipMemoRequiredCheck:)` | postTransaction runs the check unless skipMemoRequiredCheck is true |
| `post_transaction_async_opt_out` | ✓ | ✅ | `postTransactionAsync(skipMemoRequiredCheck:)` | postTransactionAsync runs the check unless skipMemoRequiredCheck is true |
| `destination_requires_memo_result` | ✓ | ✅ | `destinationRequiresMemo(destinationAccountId:)` | Submission result case carrying the id of the account that requires a memo |

## Implementation Gaps

🎉 **No gaps found!** All fields are implemented.

## Legend

- ✅ **Implemented**: Field is implemented in SDK
- ❌ **Not Implemented**: Field is missing from SDK
- ⚙️ **Server**: Server-side only feature (not applicable to client SDKs)
- ✓ **Required**: Field is required by SEP specification
- (blank) **Optional**: Field is optional