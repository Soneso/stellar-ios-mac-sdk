//
//  Sep24TransactionStatusesMock.swift
//  stellarsdkTests
//
//  Created by Soneso on 05.02.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

class Sep24TransactionStatusesMock: ResponsesMock {
    var address: String

    init(address:String) {
        self.address = address

        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            guard let self = self else { return nil }

            // Check for status parameter to return different transaction statuses
            if let key = mock.variables["status"] {
                switch key {
                case "incomplete":
                    return self.transactionIncomplete
                case "pending_user_transfer_start":
                    return self.transactionPendingUserTransferStart
                case "pending_user_transfer_complete":
                    return self.transactionPendingUserTransferComplete
                case "pending_external":
                    return self.transactionPendingExternal
                case "pending_anchor":
                    return self.transactionPendingAnchor
                case "pending_stellar":
                    return self.transactionPendingStellar
                case "pending_trust":
                    return self.transactionPendingTrust
                case "pending_user":
                    return self.transactionPendingUser
                case "completed":
                    return self.transactionCompleted
                case "refunded":
                    return self.transactionRefunded
                case "expired":
                    return self.transactionExpired
                case "no_market":
                    return self.transactionNoMarket
                case "too_small":
                    return self.transactionTooSmall
                case "too_large":
                    return self.transactionTooLarge
                case "error":
                    return self.transactionError
                default:
                    return self.transactionCompleted
                }
            }
            return self.transactionCompleted
        }

        return RequestMock(host: address,
                           path: "/transaction",
                           httpMethod: "GET",
                           mockHandler: handler)
    }

    let transactionIncomplete = """
    {
      "transaction": {
        "id": "tx-incomplete",
        "kind": "deposit",
        "status": "incomplete",
        "started_at": "2025-01-14T14:22:06Z",
        "more_info_url": "https://anchor.com/tx/incomplete"
      }
    }
    """

    let transactionPendingUserTransferStart = """
    {
      "transaction": {
        "id": "tx-pending-user-transfer-start",
        "kind": "deposit",
        "status": "pending_user_transfer_start",
        "status_eta": 3600,
        "started_at": "2025-01-14T14:22:06Z",
        "more_info_url": "https://anchor.com/tx/pending"
      }
    }
    """

    let transactionPendingUserTransferComplete = """
    {
      "transaction": {
        "id": "tx-pending-user-transfer-complete",
        "kind": "deposit",
        "status": "pending_user_transfer_complete",
        "started_at": "2025-01-14T14:22:06Z"
      }
    }
    """

    let transactionPendingExternal = """
    {
      "transaction": {
        "id": "tx-pending-external",
        "kind": "deposit",
        "status": "pending_external",
        "status_eta": 7200,
        "started_at": "2025-01-14T14:22:06Z",
        "external_transaction_id": "ext-123"
      }
    }
    """

    let transactionPendingAnchor = """
    {
      "transaction": {
        "id": "tx-pending-anchor",
        "kind": "withdrawal",
        "status": "pending_anchor",
        "status_eta": 1800,
        "started_at": "2025-01-14T14:22:06Z"
      }
    }
    """

    let transactionPendingStellar = """
    {
      "transaction": {
        "id": "tx-pending-stellar",
        "kind": "deposit",
        "status": "pending_stellar",
        "started_at": "2025-01-14T14:22:06Z"
      }
    }
    """

    let transactionPendingTrust = """
    {
      "transaction": {
        "id": "tx-pending-trust",
        "kind": "deposit",
        "status": "pending_trust",
        "started_at": "2025-01-14T14:22:06Z",
        "message": "Please add a trustline for this asset"
      }
    }
    """

    let transactionPendingUser = """
    {
      "transaction": {
        "id": "tx-pending-user",
        "kind": "withdrawal",
        "status": "pending_user",
        "started_at": "2025-01-14T14:22:06Z",
        "user_action_required_by": "2025-01-15T14:22:06Z"
      }
    }
    """

    let transactionCompleted = """
    {
      "transaction": {
        "id": "tx-completed",
        "kind": "deposit",
        "status": "completed",
        "started_at": "2025-01-14T14:22:06Z",
        "completed_at": "2025-01-14T14:30:00Z",
        "amount_in": "100.00",
        "amount_out": "99.50",
        "amount_fee": "0.50",
        "stellar_transaction_id": "abc123def456"
      }
    }
    """

    let transactionRefunded = """
    {
      "transaction": {
        "id": "tx-refunded",
        "kind": "deposit",
        "status": "refunded",
        "started_at": "2025-01-14T14:22:06Z",
        "completed_at": "2025-01-14T16:00:00Z",
        "amount_in": "100.00",
        "amount_out": "0.00",
        "amount_fee": "0.00",
        "refunded": true,
        "refunds": {
          "amount_refunded": "100.00",
          "amount_fee": "0.00",
          "payments": [
            {
              "id": "refund-payment-1",
              "id_type": "stellar",
              "amount": "100.00",
              "fee": "0.00"
            }
          ]
        }
      }
    }
    """

    let transactionExpired = """
    {
      "transaction": {
        "id": "tx-expired",
        "kind": "deposit",
        "status": "expired",
        "started_at": "2025-01-14T14:22:06Z",
        "message": "Transaction expired due to user inactivity"
      }
    }
    """

    let transactionNoMarket = """
    {
      "transaction": {
        "id": "tx-no-market",
        "kind": "withdrawal",
        "status": "no_market",
        "started_at": "2025-01-14T14:22:06Z",
        "message": "No market available for this trading pair"
      }
    }
    """

    let transactionTooSmall = """
    {
      "transaction": {
        "id": "tx-too-small",
        "kind": "deposit",
        "status": "too_small",
        "started_at": "2025-01-14T14:22:06Z",
        "message": "Amount is below minimum"
      }
    }
    """

    let transactionTooLarge = """
    {
      "transaction": {
        "id": "tx-too-large",
        "kind": "deposit",
        "status": "too_large",
        "started_at": "2025-01-14T14:22:06Z",
        "message": "Amount exceeds maximum"
      }
    }
    """

    let transactionError = """
    {
      "transaction": {
        "id": "tx-error",
        "kind": "deposit",
        "status": "error",
        "started_at": "2025-01-14T14:22:06Z",
        "message": "An error occurred processing the transaction"
      }
    }
    """
}
