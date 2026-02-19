//
//  TransactionPreconditions.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 29.04.22.
//  Copyright © 2022 Soneso. All rights reserved.
//

import Foundation

/**
 * Preconditions of a transaction per <a href="https://github.com/stellar/stellar-protocol/blob/master/core/cap-0021.md#specification">CAP-21<a/>
 */
final public class TransactionPreconditions: Sendable {

    /// Maximum number of extra signers allowed per transaction preconditions.
    final public let MAX_EXTRA_SIGNERS_COUNT = 2;
    /// Value indicating infinite timeout for transaction validity (no time-based expiration).
    final public let TIMEOUT_INFINITE = 0;

    /// Ledger number bounds for transaction validity (inclusive range).
    public let ledgerBounds:LedgerBounds?
    /// Time bounds for transaction validity (Unix timestamp range).
    public let timeBounds:TimeBounds?
    /// Minimum source account sequence number required for transaction validity.
    public let minSeqNumber: Int64?
    /// Minimum age in seconds since source account sequence number changed.
    public let minSeqAge: UInt64
    /// Minimum number of ledgers that must pass since source account sequence number changed.
    public let minSeqLedgerGap: UInt32
    /// Additional signers required to authorize this transaction.
    public let extraSigners:[SignerKeyXDR]

    /// Creates transaction preconditions with individual constraint parameters per CAP-21.
    public init(ledgerBounds:LedgerBounds? = nil, timeBounds:TimeBounds? = nil, minSeqNumber: Int64? = nil, minSeqAge: UInt64 = 0, minSeqLedgerGap: UInt32 = 0, extraSigners:[SignerKeyXDR] = []) {
        self.ledgerBounds = ledgerBounds
        self.timeBounds = timeBounds
        self.minSeqNumber = minSeqNumber
        self.minSeqAge = minSeqAge
        self.minSeqLedgerGap = minSeqLedgerGap
        self.extraSigners = extraSigners
    }

    /// Creates transaction preconditions from an XDR preconditions object.
    public convenience init(preconditions:PreconditionsXDR) {
        switch preconditions {
        case .none:
            self.init()
            return
        case .time(let timeBoundsXDR):
            self.init(timeBounds:TimeBounds(timebounds: timeBoundsXDR))
            return
        case .v2(let preconditionsV2XDR):
            var lb:LedgerBounds? = nil
            if let lbxdr = preconditionsV2XDR.ledgerBounds {
                lb = LedgerBounds(lederbounds: lbxdr)
            }
            var tb:TimeBounds? = nil
            if let tbxdr = preconditionsV2XDR.timeBounds {
                tb = TimeBounds(timebounds: tbxdr)
            }
            self.init(ledgerBounds:lb,
                      timeBounds: tb,
                      minSeqNumber: preconditionsV2XDR.sequenceNumber,
                      minSeqAge: preconditionsV2XDR.minSeqAge,
                      minSeqLedgerGap: preconditionsV2XDR.minSeqLedgerGap,
                      extraSigners: preconditionsV2XDR.extraSigners)
        }
    }

    /// Converts this TransactionPreconditions to its XDR representation.
    public func toXdr() -> PreconditionsXDR {
        if hasV2() {
            var tbXdr:TimeBoundsXDR? = nil
            if let tb = timeBounds {
                tbXdr = tb.toXdr()
            }
            var lbXdr:LedgerBoundsXDR? = nil
            if let lb = ledgerBounds {
                lbXdr = lb.toXdr()
            }
            let xdr = PreconditionsV2XDR(timeBounds: tbXdr, ledgerBounds: lbXdr, sequenceNumber: minSeqNumber, minSeqAge: minSeqAge, minSeqLedgerGap: minSeqLedgerGap, extraSigners: extraSigners)
            return PreconditionsXDR.v2(xdr)
        } else {
            if let tb = timeBounds {
                return PreconditionsXDR.time(tb.toXdr())
            } else {
                return PreconditionsXDR.none
            }
        }
    }

    /// Returns true if this precondition requires the V2 format (CAP-21).
    public func hasV2() -> Bool {
        if ledgerBounds != nil || minSeqNumber != nil {
            return true
        }
        if minSeqLedgerGap > 0 {
            return true
        }
        if minSeqAge > 0 {
            return true
        }
        if extraSigners.count > 0 {
            return true
        }
        return false
    }
}
