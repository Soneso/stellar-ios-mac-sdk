//
// GENERATED FILE - DO NOT EDIT
//
// This file was produced by tools/xdr-generator/test/emit_json_tests.rb. It exercises
// the SEP-0051 (XDR-JSON) conversions of every type declared in one .x source. To
// regenerate, run:
//
//     make xdr-generate-tests
//
// Any manual edits will be overwritten on the next run.
//

import XCTest
import Foundation
import stellarsdk

final class GeneratedXdrJsonStellarExporterUnitTests: XCTestCase {

    func test_LedgerCloseMetaBatchXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try LedgerCloseMetaBatchXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "LedgerCloseMetaBatchXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_LedgerCloseMetaBatchXDR_roundTrip() throws {
        let original: LedgerCloseMetaBatchXDR = LedgerCloseMetaBatchXDR(startSequence: UInt32(42), endSequence: UInt32(42), ledgerCloseMetas: [.v0(LedgerCloseMetaV0XDR(ledgerHeader: LedgerHeaderHistoryEntryXDR(hash: WrappedData32(Data(repeating: 0xAB, count: 32)), header: LedgerHeaderXDR(ledgerVersion: UInt32(42), previousLedgerHash: WrappedData32(Data(repeating: 0xAB, count: 32)), scpValue: StellarValueXDR(txSetHash: WrappedData32(Data(repeating: 0xAB, count: 32)), closeTime: UInt64(1234567), upgrades: [Data([0x01, 0x02, 0x03])], ext: .basic), txSetResultHash: WrappedData32(Data(repeating: 0xAB, count: 32)), bucketListHash: WrappedData32(Data(repeating: 0xAB, count: 32)), ledgerSeq: UInt32(42), totalCoins: Int64(1234567), feePool: Int64(1234567), inflationSeq: UInt32(42), idPool: UInt64(1234567), baseFee: UInt32(42), baseReserve: UInt32(42), maxTxSetSize: UInt32(42), skipList: [WrappedData32(Data(repeating: 0xAB, count: 32)), WrappedData32(Data(repeating: 0xAB, count: 32)), WrappedData32(Data(repeating: 0xAB, count: 32)), WrappedData32(Data(repeating: 0xAB, count: 32))], ext: .void), ext: .void), txSet: TransactionSetXDR(previousLedgerHash: WrappedData32(Data(repeating: 0xAB, count: 32)), txs: [.v0(TransactionV0EnvelopeXDR(tx: TransactionV0XDR(sourceAccount: try PublicKey([UInt8](repeating: 0xAB, count: 32)), seqNum: Int64(100), timeBounds: nil, memo: .none, operations: []), signatures: []))]), txProcessing: [], upgradesProcessing: [UpgradeEntryMetaXDR(upgrade: .newLedgerVersion(UInt32(42)), changes: LedgerEntryChangesXDR(LedgerEntryChanges: []))], scpInfo: []))])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerCloseMetaBatchXDR.fromXdrJson(json)
        let viaValue = try LedgerCloseMetaBatchXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerCloseMetaBatchXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerCloseMetaBatchXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerCloseMetaBatchXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerCloseMetaBatchXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerCloseMetaBatchXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerCloseMetaBatchXDR must reach the same bytes through JSON and XDR")
    }
}
