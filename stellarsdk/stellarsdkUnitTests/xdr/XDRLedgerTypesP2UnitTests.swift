//
//  XDRLedgerTypesP2UnitTests.swift
//  stellarsdkTests
//
//  Created by Soneso
//  Copyright (c) 2025 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

/// Round-trip XDR tests for the second half of Stellar-ledger.x:
/// transaction meta types, contract events, diagnostic events,
/// soroban transaction meta, ledger close meta types, and related types.
class XDRLedgerTypesP2UnitTests: XCTestCase {

    // MARK: - Helper: build common sub-objects

    /// Build a minimal ContractEventXDR for reuse in tests.
    private func makeContractEvent(
        contractID: WrappedData32? = nil,
        eventType: Int32 = ContractEventType.contract.rawValue
    ) -> ContractEventXDR {
        let bodyV0 = ContractEventBodyV0XDR(
            topics: [XDRTestHelpers.scVal()],
            data: .i32(99)
        )
        return ContractEventXDR(
            ext: .void,
            hash: contractID,
            type: eventType,
            body: .v0(bodyV0)
        )
    }

    /// Build a minimal DiagnosticEventXDR for reuse in tests.
    private func makeDiagnosticEvent(inSuccess: Bool = true) -> DiagnosticEventXDR {
        DiagnosticEventXDR(
            inSuccessfulContractCall: inSuccess,
            event: makeContractEvent()
        )
    }

    /// Build a minimal LedgerHeaderHistoryEntryXDR for reuse in LedgerCloseMeta tests.
    private func makeLedgerHeaderHistoryEntry() throws -> LedgerHeaderHistoryEntryXDR {
        let hash = XDRTestHelpers.wrappedData32()
        let scpValue = StellarValueXDR(
            txSetHash: hash,
            closeTime: 1700000000,
            upgrades: [],
            ext: .basic
        )
        let skipList = (0..<4).map { _ in XDRTestHelpers.wrappedData32() }
        let header = LedgerHeaderXDR(
            ledgerVersion: 21,
            previousLedgerHash: hash,
            scpValue: scpValue,
            txSetResultHash: hash,
            bucketListHash: hash,
            ledgerSeq: 100,
            totalCoins: 10000000000,
            feePool: 500,
            inflationSeq: 0,
            idPool: 42,
            baseFee: 100,
            baseReserve: 5000000,
            maxTxSetSize: 100,
            skipList: skipList,
            ext: .void
        )
        return LedgerHeaderHistoryEntryXDR(
            hash: WrappedData32(Data(repeating: 0xFF, count: 32)),
            header: header,
            ext: .void
        )
    }

    /// Build a minimal TransactionResultPairXDR for reuse.
    private func makeTransactionResultPair() -> TransactionResultPairXDR {
        TransactionResultPairXDR(
            transactionHash: XDRTestHelpers.wrappedData32(),
            result: TransactionResultXDR(feeCharged: 100, result: .tooEarly)
        )
    }

    // MARK: - Enums (Equatable)

    func testContractEventTypeAllCasesRoundTrip() throws {
        let cases: [ContractEventType] = [.system, .contract, .diagnostic]
        for original in cases {
            let encoded = try XDREncoder.encode(original)
            let decoded = try XDRDecoder.decode(ContractEventType.self, data: encoded)
            XCTAssertEqual(original, decoded)
        }
    }

    func testTransactionEventStageAllCasesRoundTrip() throws {
        let cases: [TransactionEventStage] = [.beforeAllTxs, .afterTx, .afterAllTx]
        for original in cases {
            let encoded = try XDREncoder.encode(original)
            let decoded = try XDRDecoder.decode(TransactionEventStage.self, data: encoded)
            XCTAssertEqual(original, decoded)
        }
    }

    // MARK: - ContractEventBodyV0XDR

    func testContractEventBodyV0RoundTrip() throws {
        let original = ContractEventBodyV0XDR(
            topics: [.u32(1), .i64(200)],
            data: .bool(true)
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ContractEventBodyV0XDR.self, data: encoded)

        XCTAssertEqual(decoded.topics.count, 2)
        if case .u32(let v) = decoded.topics[0] {
            XCTAssertEqual(v, 1)
        } else {
            XCTFail("Expected .u32 for topic[0]")
        }
        if case .i64(let v) = decoded.topics[1] {
            XCTAssertEqual(v, 200)
        } else {
            XCTFail("Expected .i64 for topic[1]")
        }
        if case .bool(let v) = decoded.data {
            XCTAssertTrue(v)
        } else {
            XCTFail("Expected .bool for data")
        }
    }

    func testContractEventBodyV0EmptyTopicsRoundTrip() throws {
        let original = ContractEventBodyV0XDR(
            topics: [],
            data: .u32(42)
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ContractEventBodyV0XDR.self, data: encoded)

        XCTAssertEqual(decoded.topics.count, 0)
        if case .u32(let v) = decoded.data {
            XCTAssertEqual(v, 42)
        } else {
            XCTFail("Expected .u32 for data")
        }
    }

    // MARK: - ContractEventBodyXDR

    func testContractEventBodyV0ArmRoundTrip() throws {
        let bodyV0 = ContractEventBodyV0XDR(
            topics: [.u32(7)],
            data: .i32(-55)
        )
        let original = ContractEventBodyXDR.v0(bodyV0)

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ContractEventBodyXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), 0)
        if case .v0(let v) = decoded {
            XCTAssertEqual(v.topics.count, 1)
            if case .i32(let d) = v.data {
                XCTAssertEqual(d, -55)
            } else {
                XCTFail("Expected .i32 for data")
            }
        } else {
            XCTFail("Expected .v0")
        }
    }

    // MARK: - ContractEventXDR

    func testContractEventNoContractIDRoundTrip() throws {
        let original = makeContractEvent(contractID: nil, eventType: ContractEventType.system.rawValue)

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ContractEventXDR.self, data: encoded)

        XCTAssertEqual(decoded.ext.type(), 0)
        XCTAssertNil(decoded.hash)
        XCTAssertEqual(decoded.type, ContractEventType.system.rawValue)
        if case .v0(let body) = decoded.body {
            XCTAssertEqual(body.topics.count, 1)
        } else {
            XCTFail("Expected .v0 body")
        }
    }

    func testContractEventWithContractIDRoundTrip() throws {
        let contractID = WrappedData32(Data(repeating: 0xAA, count: 32))
        let original = makeContractEvent(
            contractID: contractID,
            eventType: ContractEventType.contract.rawValue
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ContractEventXDR.self, data: encoded)

        XCTAssertNotNil(decoded.hash)
        XCTAssertEqual(decoded.hash!.wrapped, Data(repeating: 0xAA, count: 32))
        XCTAssertEqual(decoded.type, ContractEventType.contract.rawValue)
    }

    func testContractEventDiagnosticTypeRoundTrip() throws {
        let original = makeContractEvent(eventType: ContractEventType.diagnostic.rawValue)

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ContractEventXDR.self, data: encoded)

        XCTAssertEqual(decoded.type, ContractEventType.diagnostic.rawValue)
    }

    // MARK: - DiagnosticEventXDR

    func testDiagnosticEventInSuccessRoundTrip() throws {
        let event = makeContractEvent()
        let original = DiagnosticEventXDR(
            inSuccessfulContractCall: true,
            event: event
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(DiagnosticEventXDR.self, data: encoded)

        XCTAssertTrue(decoded.inSuccessfulContractCall)
        XCTAssertEqual(decoded.event.type, ContractEventType.contract.rawValue)
    }

    func testDiagnosticEventNotInSuccessRoundTrip() throws {
        let event = makeContractEvent(eventType: ContractEventType.diagnostic.rawValue)
        let original = DiagnosticEventXDR(
            inSuccessfulContractCall: false,
            event: event
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(DiagnosticEventXDR.self, data: encoded)

        XCTAssertFalse(decoded.inSuccessfulContractCall)
        XCTAssertEqual(decoded.event.type, ContractEventType.diagnostic.rawValue)
    }

    // MARK: - TransactionEventXDR

    func testTransactionEventBeforeAllTxsRoundTrip() throws {
        let event = makeContractEvent()
        let original = TransactionEventXDR(stage: .beforeAllTxs, event: event)

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TransactionEventXDR.self, data: encoded)

        XCTAssertEqual(decoded.stage, .beforeAllTxs)
        XCTAssertEqual(decoded.event.type, ContractEventType.contract.rawValue)
    }

    func testTransactionEventAfterTxRoundTrip() throws {
        let event = makeContractEvent(eventType: ContractEventType.system.rawValue)
        let original = TransactionEventXDR(stage: .afterTx, event: event)

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TransactionEventXDR.self, data: encoded)

        XCTAssertEqual(decoded.stage, .afterTx)
        XCTAssertEqual(decoded.event.type, ContractEventType.system.rawValue)
    }

    func testTransactionEventAfterAllTxsRoundTrip() throws {
        let event = makeContractEvent()
        let original = TransactionEventXDR(stage: .afterAllTx, event: event)

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TransactionEventXDR.self, data: encoded)

        XCTAssertEqual(decoded.stage, .afterAllTx)
    }

    // MARK: - OperationMetaXDR

    func testOperationMetaEmptyChangesRoundTrip() throws {
        let changes = LedgerEntryChangesXDR(LedgerEntryChanges: [])
        let original = OperationMetaXDR(changes: changes)

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(OperationMetaXDR.self, data: encoded)

        XCTAssertEqual(decoded.changes.ledgerEntryChanges.count, 0)
    }

    func testOperationMetaWithChangesRoundTrip() throws {
        let key = XDRTestHelpers.ledgerKey()
        let change = LedgerEntryChangeXDR.removed(key)
        let changes = LedgerEntryChangesXDR(LedgerEntryChanges: [change])
        let original = OperationMetaXDR(changes: changes)

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(OperationMetaXDR.self, data: encoded)

        XCTAssertEqual(decoded.changes.ledgerEntryChanges.count, 1)
        XCTAssertEqual(decoded.changes.ledgerEntryChanges[0].type(), LedgerEntryChangeType.ledgerEntryRemoved.rawValue)
    }

    // MARK: - OperationMetaV2XDR

    func testOperationMetaV2EmptyRoundTrip() throws {
        let original = OperationMetaV2XDR(
            ext: .void,
            changes: LedgerEntryChangesXDR(LedgerEntryChanges: []),
            events: []
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(OperationMetaV2XDR.self, data: encoded)

        XCTAssertEqual(decoded.ext.type(), 0)
        XCTAssertEqual(decoded.changes.ledgerEntryChanges.count, 0)
        XCTAssertEqual(decoded.events.count, 0)
    }

    func testOperationMetaV2WithEventsRoundTrip() throws {
        let event = makeContractEvent()
        let original = OperationMetaV2XDR(
            ext: .void,
            changes: LedgerEntryChangesXDR(LedgerEntryChanges: []),
            events: [event]
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(OperationMetaV2XDR.self, data: encoded)

        XCTAssertEqual(decoded.events.count, 1)
        XCTAssertEqual(decoded.events[0].type, ContractEventType.contract.rawValue)
    }

    // MARK: - SorobanTransactionMetaExtV1

    func testSorobanTransactionMetaExtV1RoundTrip() throws {
        let original = SorobanTransactionMetaExtV1(
            ext: .void,
            totalNonRefundableResourceFeeCharged: 50000,
            totalRefundableResourceFeeCharged: 25000,
            rentFeeCharged: 10000
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SorobanTransactionMetaExtV1.self, data: encoded)

        XCTAssertEqual(decoded.ext.type(), 0)
        XCTAssertEqual(decoded.totalNonRefundableResourceFeeCharged, 50000)
        XCTAssertEqual(decoded.totalRefundableResourceFeeCharged, 25000)
        XCTAssertEqual(decoded.rentFeeCharged, 10000)
    }

    // MARK: - SorobanTransactionMetaExt

    func testSorobanTransactionMetaExtVoidRoundTrip() throws {
        let original = SorobanTransactionMetaExt.void

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SorobanTransactionMetaExt.self, data: encoded)

        XCTAssertEqual(decoded.type(), 0)
    }

    func testSorobanTransactionMetaExtV1ArmRoundTrip() throws {
        let v1 = SorobanTransactionMetaExtV1(
            ext: .void,
            totalNonRefundableResourceFeeCharged: 100000,
            totalRefundableResourceFeeCharged: 75000,
            rentFeeCharged: 30000
        )
        let original = SorobanTransactionMetaExt.v1(v1)

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SorobanTransactionMetaExt.self, data: encoded)

        XCTAssertEqual(decoded.type(), 1)
        if case .v1(let dv1) = decoded {
            XCTAssertEqual(dv1.totalNonRefundableResourceFeeCharged, 100000)
            XCTAssertEqual(dv1.totalRefundableResourceFeeCharged, 75000)
            XCTAssertEqual(dv1.rentFeeCharged, 30000)
        } else {
            XCTFail("Expected .v1")
        }
    }

    // MARK: - SorobanTransactionMetaXDR

    func testSorobanTransactionMetaMinimalRoundTrip() throws {
        let original = SorobanTransactionMetaXDR(
            ext: .void,
            events: [],
            returnValue: .u32(42),
            diagnosticEvents: []
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SorobanTransactionMetaXDR.self, data: encoded)

        XCTAssertEqual(decoded.ext.type(), 0)
        XCTAssertEqual(decoded.events.count, 0)
        if case .u32(let v) = decoded.returnValue {
            XCTAssertEqual(v, 42)
        } else {
            XCTFail("Expected .u32 returnValue")
        }
        XCTAssertEqual(decoded.diagnosticEvents.count, 0)
    }

    func testSorobanTransactionMetaWithEventsAndDiagnosticsRoundTrip() throws {
        let event = makeContractEvent()
        let diagEvent = makeDiagnosticEvent(inSuccess: false)

        let v1 = SorobanTransactionMetaExtV1(
            ext: .void,
            totalNonRefundableResourceFeeCharged: 5000,
            totalRefundableResourceFeeCharged: 3000,
            rentFeeCharged: 1000
        )
        let original = SorobanTransactionMetaXDR(
            ext: .v1(v1),
            events: [event],
            returnValue: .bool(true),
            diagnosticEvents: [diagEvent]
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SorobanTransactionMetaXDR.self, data: encoded)

        XCTAssertEqual(decoded.ext.type(), 1)
        XCTAssertEqual(decoded.events.count, 1)
        XCTAssertEqual(decoded.events[0].type, ContractEventType.contract.rawValue)
        if case .bool(let v) = decoded.returnValue {
            XCTAssertTrue(v)
        } else {
            XCTFail("Expected .bool returnValue")
        }
        XCTAssertEqual(decoded.diagnosticEvents.count, 1)
        XCTAssertFalse(decoded.diagnosticEvents[0].inSuccessfulContractCall)
    }

    // MARK: - SorobanTransactionMetaV2XDR

    func testSorobanTransactionMetaV2NoReturnValueRoundTrip() throws {
        let original = SorobanTransactionMetaV2XDR(
            ext: .void,
            returnValue: nil
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SorobanTransactionMetaV2XDR.self, data: encoded)

        XCTAssertEqual(decoded.ext.type(), 0)
        XCTAssertNil(decoded.returnValue)
    }

    func testSorobanTransactionMetaV2WithReturnValueRoundTrip() throws {
        let original = SorobanTransactionMetaV2XDR(
            ext: .void,
            returnValue: .i128(Int128PartsXDR(hi: 0, lo: 12345))
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SorobanTransactionMetaV2XDR.self, data: encoded)

        XCTAssertEqual(decoded.ext.type(), 0)
        XCTAssertNotNil(decoded.returnValue)
        if case .i128(let parts) = decoded.returnValue {
            XCTAssertEqual(parts.hi, 0)
            XCTAssertEqual(parts.lo, 12345)
        } else {
            XCTFail("Expected .i128 returnValue")
        }
    }

    func testSorobanTransactionMetaV2WithExtV1RoundTrip() throws {
        let v1 = SorobanTransactionMetaExtV1(
            ext: .void,
            totalNonRefundableResourceFeeCharged: 8000,
            totalRefundableResourceFeeCharged: 4000,
            rentFeeCharged: 2000
        )
        let original = SorobanTransactionMetaV2XDR(
            ext: .v1(v1),
            returnValue: .u32(77)
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SorobanTransactionMetaV2XDR.self, data: encoded)

        XCTAssertEqual(decoded.ext.type(), 1)
        if case .v1(let dv1) = decoded.ext {
            XCTAssertEqual(dv1.totalNonRefundableResourceFeeCharged, 8000)
        } else {
            XCTFail("Expected ext .v1")
        }
        if case .u32(let v) = decoded.returnValue {
            XCTAssertEqual(v, 77)
        } else {
            XCTFail("Expected .u32 returnValue")
        }
    }

    // MARK: - TransactionMetaV1XDR

    func testTransactionMetaV1EmptyRoundTrip() throws {
        let original = TransactionMetaV1XDR(
            txChanges: LedgerEntryChangesXDR(LedgerEntryChanges: []),
            operations: []
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TransactionMetaV1XDR.self, data: encoded)

        XCTAssertEqual(decoded.txChanges.ledgerEntryChanges.count, 0)
        XCTAssertEqual(decoded.operations.count, 0)
    }

    func testTransactionMetaV1WithOperationsRoundTrip() throws {
        let opMeta = OperationMetaXDR(
            changes: LedgerEntryChangesXDR(LedgerEntryChanges: [])
        )
        let original = TransactionMetaV1XDR(
            txChanges: LedgerEntryChangesXDR(LedgerEntryChanges: []),
            operations: [opMeta]
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TransactionMetaV1XDR.self, data: encoded)

        XCTAssertEqual(decoded.operations.count, 1)
        XCTAssertEqual(decoded.operations[0].changes.ledgerEntryChanges.count, 0)
    }

    // MARK: - TransactionMetaV2XDR

    func testTransactionMetaV2EmptyRoundTrip() throws {
        let original = TransactionMetaV2XDR(
            txChangesBefore: LedgerEntryChangesXDR(LedgerEntryChanges: []),
            operations: [],
            txChangesAfter: LedgerEntryChangesXDR(LedgerEntryChanges: [])
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TransactionMetaV2XDR.self, data: encoded)

        XCTAssertEqual(decoded.txChangesBefore.ledgerEntryChanges.count, 0)
        XCTAssertEqual(decoded.operations.count, 0)
        XCTAssertEqual(decoded.txChangesAfter.ledgerEntryChanges.count, 0)
    }

    func testTransactionMetaV2WithOperationsRoundTrip() throws {
        let key = XDRTestHelpers.ledgerKey()
        let change = LedgerEntryChangeXDR.removed(key)
        let opMeta = OperationMetaXDR(
            changes: LedgerEntryChangesXDR(LedgerEntryChanges: [change])
        )
        let original = TransactionMetaV2XDR(
            txChangesBefore: LedgerEntryChangesXDR(LedgerEntryChanges: []),
            operations: [opMeta],
            txChangesAfter: LedgerEntryChangesXDR(LedgerEntryChanges: [])
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TransactionMetaV2XDR.self, data: encoded)

        XCTAssertEqual(decoded.operations.count, 1)
        XCTAssertEqual(decoded.operations[0].changes.ledgerEntryChanges.count, 1)
    }

    // MARK: - TransactionMetaV3XDR

    func testTransactionMetaV3NoSorobanMetaRoundTrip() throws {
        let original = TransactionMetaV3XDR(
            ext: .void,
            txChangesBefore: LedgerEntryChangesXDR(LedgerEntryChanges: []),
            operations: [],
            txChangesAfter: LedgerEntryChangesXDR(LedgerEntryChanges: []),
            sorobanMeta: nil
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TransactionMetaV3XDR.self, data: encoded)

        XCTAssertEqual(decoded.ext.type(), 0)
        XCTAssertEqual(decoded.txChangesBefore.ledgerEntryChanges.count, 0)
        XCTAssertEqual(decoded.operations.count, 0)
        XCTAssertEqual(decoded.txChangesAfter.ledgerEntryChanges.count, 0)
        XCTAssertNil(decoded.sorobanMeta)
    }

    func testTransactionMetaV3WithSorobanMetaRoundTrip() throws {
        let sorobanMeta = SorobanTransactionMetaXDR(
            ext: .void,
            events: [makeContractEvent()],
            returnValue: .u32(99),
            diagnosticEvents: []
        )
        let original = TransactionMetaV3XDR(
            ext: .void,
            txChangesBefore: LedgerEntryChangesXDR(LedgerEntryChanges: []),
            operations: [],
            txChangesAfter: LedgerEntryChangesXDR(LedgerEntryChanges: []),
            sorobanMeta: sorobanMeta
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TransactionMetaV3XDR.self, data: encoded)

        XCTAssertNotNil(decoded.sorobanMeta)
        XCTAssertEqual(decoded.sorobanMeta!.events.count, 1)
        if case .u32(let v) = decoded.sorobanMeta!.returnValue {
            XCTAssertEqual(v, 99)
        } else {
            XCTFail("Expected .u32 returnValue in sorobanMeta")
        }
    }

    // MARK: - TransactionMetaV4XDR

    func testTransactionMetaV4MinimalRoundTrip() throws {
        let original = TransactionMetaV4XDR(
            ext: .void,
            txChangesBefore: LedgerEntryChangesXDR(LedgerEntryChanges: []),
            operations: [],
            txChangesAfter: LedgerEntryChangesXDR(LedgerEntryChanges: []),
            sorobanMeta: nil,
            events: [],
            diagnosticEvents: []
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TransactionMetaV4XDR.self, data: encoded)

        XCTAssertEqual(decoded.ext.type(), 0)
        XCTAssertEqual(decoded.operations.count, 0)
        XCTAssertNil(decoded.sorobanMeta)
        XCTAssertEqual(decoded.events.count, 0)
        XCTAssertEqual(decoded.diagnosticEvents.count, 0)
    }

    func testTransactionMetaV4WithSorobanMetaAndEventsRoundTrip() throws {
        let sorobanV2 = SorobanTransactionMetaV2XDR(
            ext: .void,
            returnValue: .u32(88)
        )
        let txEvent = TransactionEventXDR(
            stage: .afterTx,
            event: makeContractEvent()
        )
        let diagEvent = makeDiagnosticEvent()
        let opMetaV2 = OperationMetaV2XDR(
            ext: .void,
            changes: LedgerEntryChangesXDR(LedgerEntryChanges: []),
            events: []
        )
        let original = TransactionMetaV4XDR(
            ext: .void,
            txChangesBefore: LedgerEntryChangesXDR(LedgerEntryChanges: []),
            operations: [opMetaV2],
            txChangesAfter: LedgerEntryChangesXDR(LedgerEntryChanges: []),
            sorobanMeta: sorobanV2,
            events: [txEvent],
            diagnosticEvents: [diagEvent]
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TransactionMetaV4XDR.self, data: encoded)

        XCTAssertEqual(decoded.operations.count, 1)
        XCTAssertNotNil(decoded.sorobanMeta)
        if case .u32(let v) = decoded.sorobanMeta?.returnValue {
            XCTAssertEqual(v, 88)
        } else {
            XCTFail("Expected .u32 returnValue in sorobanMeta")
        }
        XCTAssertEqual(decoded.events.count, 1)
        XCTAssertEqual(decoded.events[0].stage, .afterTx)
        XCTAssertEqual(decoded.diagnosticEvents.count, 1)
        XCTAssertTrue(decoded.diagnosticEvents[0].inSuccessfulContractCall)
    }

    // MARK: - TransactionMetaXDR (union)

    func testTransactionMetaV0OperationsRoundTrip() throws {
        let opMeta = OperationMetaXDR(
            changes: LedgerEntryChangesXDR(LedgerEntryChanges: [])
        )
        let original = TransactionMetaXDR.operations([opMeta])

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TransactionMetaXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), 0)
        if case .operations(let ops) = decoded {
            XCTAssertEqual(ops.count, 1)
        } else {
            XCTFail("Expected .operations")
        }
    }

    func testTransactionMetaV1ArmRoundTrip() throws {
        let v1 = TransactionMetaV1XDR(
            txChanges: LedgerEntryChangesXDR(LedgerEntryChanges: []),
            operations: []
        )
        let original = TransactionMetaXDR.transactionMetaV1(v1)

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TransactionMetaXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), 1)
        if case .transactionMetaV1(let dv1) = decoded {
            XCTAssertEqual(dv1.operations.count, 0)
        } else {
            XCTFail("Expected .transactionMetaV1")
        }
    }

    func testTransactionMetaV2ArmRoundTrip() throws {
        let v2 = TransactionMetaV2XDR(
            txChangesBefore: LedgerEntryChangesXDR(LedgerEntryChanges: []),
            operations: [],
            txChangesAfter: LedgerEntryChangesXDR(LedgerEntryChanges: [])
        )
        let original = TransactionMetaXDR.transactionMetaV2(v2)

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TransactionMetaXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), 2)
        if case .transactionMetaV2(let dv2) = decoded {
            XCTAssertEqual(dv2.operations.count, 0)
        } else {
            XCTFail("Expected .transactionMetaV2")
        }
    }

    func testTransactionMetaV3ArmRoundTrip() throws {
        let v3 = TransactionMetaV3XDR(
            ext: .void,
            txChangesBefore: LedgerEntryChangesXDR(LedgerEntryChanges: []),
            operations: [],
            txChangesAfter: LedgerEntryChangesXDR(LedgerEntryChanges: []),
            sorobanMeta: nil
        )
        let original = TransactionMetaXDR.transactionMetaV3(v3)

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TransactionMetaXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), 3)
        if case .transactionMetaV3(let dv3) = decoded {
            XCTAssertNil(dv3.sorobanMeta)
        } else {
            XCTFail("Expected .transactionMetaV3")
        }
    }

    func testTransactionMetaV4ArmRoundTrip() throws {
        let v4 = TransactionMetaV4XDR(
            ext: .void,
            txChangesBefore: LedgerEntryChangesXDR(LedgerEntryChanges: []),
            operations: [],
            txChangesAfter: LedgerEntryChangesXDR(LedgerEntryChanges: []),
            sorobanMeta: nil,
            events: [],
            diagnosticEvents: []
        )
        let original = TransactionMetaXDR.transactionMetaV4(v4)

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TransactionMetaXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), 4)
        if case .transactionMetaV4(let dv4) = decoded {
            XCTAssertEqual(dv4.events.count, 0)
        } else {
            XCTFail("Expected .transactionMetaV4")
        }
    }

    // MARK: - TransactionResultMetaXDR

    func testTransactionResultMetaRoundTrip() throws {
        let resultPair = makeTransactionResultPair()
        let txMeta = TransactionMetaXDR.operations([])
        let original = TransactionResultMetaXDR(
            result: resultPair,
            feeProcessing: LedgerEntryChangesXDR(LedgerEntryChanges: []),
            txApplyProcessing: txMeta
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TransactionResultMetaXDR.self, data: encoded)

        XCTAssertEqual(decoded.result.result.feeCharged, 100)
        XCTAssertEqual(decoded.feeProcessing.ledgerEntryChanges.count, 0)
        XCTAssertEqual(decoded.txApplyProcessing.type(), 0)
    }

    // MARK: - TransactionResultMetaV1XDR

    func testTransactionResultMetaV1RoundTrip() throws {
        let resultPair = makeTransactionResultPair()
        let txMeta = TransactionMetaXDR.operations([])
        let original = TransactionResultMetaV1XDR(
            ext: .void,
            result: resultPair,
            feeProcessing: LedgerEntryChangesXDR(LedgerEntryChanges: []),
            txApplyProcessing: txMeta,
            postTxApplyFeeProcessing: LedgerEntryChangesXDR(LedgerEntryChanges: [])
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TransactionResultMetaV1XDR.self, data: encoded)

        XCTAssertEqual(decoded.ext.type(), 0)
        XCTAssertEqual(decoded.result.result.feeCharged, 100)
        XCTAssertEqual(decoded.feeProcessing.ledgerEntryChanges.count, 0)
        XCTAssertEqual(decoded.txApplyProcessing.type(), 0)
        XCTAssertEqual(decoded.postTxApplyFeeProcessing.ledgerEntryChanges.count, 0)
    }

    // MARK: - InvokeHostFunctionSuccessPreImageXDR

    func testInvokeHostFunctionSuccessPreImageEmptyRoundTrip() throws {
        let original = InvokeHostFunctionSuccessPreImageXDR(
            returnValue: .void,
            events: []
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(InvokeHostFunctionSuccessPreImageXDR.self, data: encoded)

        if case .void = decoded.returnValue {
            // success
        } else {
            XCTFail("Expected .void returnValue")
        }
        XCTAssertEqual(decoded.events.count, 0)
    }

    func testInvokeHostFunctionSuccessPreImageWithEventsRoundTrip() throws {
        let event = makeContractEvent()
        let original = InvokeHostFunctionSuccessPreImageXDR(
            returnValue: .u32(55),
            events: [event]
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(InvokeHostFunctionSuccessPreImageXDR.self, data: encoded)

        if case .u32(let v) = decoded.returnValue {
            XCTAssertEqual(v, 55)
        } else {
            XCTFail("Expected .u32 returnValue")
        }
        XCTAssertEqual(decoded.events.count, 1)
    }

    // MARK: - LedgerCloseMetaExtV1XDR

    func testLedgerCloseMetaExtV1RoundTrip() throws {
        let original = LedgerCloseMetaExtV1XDR(
            ext: .void,
            sorobanFeeWrite1KB: 123456
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerCloseMetaExtV1XDR.self, data: encoded)

        XCTAssertEqual(decoded.ext.type(), 0)
        XCTAssertEqual(decoded.sorobanFeeWrite1KB, 123456)
    }

    // MARK: - LedgerCloseMetaExtXDR

    func testLedgerCloseMetaExtVoidRoundTrip() throws {
        let original = LedgerCloseMetaExtXDR.void

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerCloseMetaExtXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), 0)
    }

    func testLedgerCloseMetaExtV1ArmRoundTrip() throws {
        let v1 = LedgerCloseMetaExtV1XDR(ext: .void, sorobanFeeWrite1KB: 999)
        let original = LedgerCloseMetaExtXDR.v1(v1)

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerCloseMetaExtXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), 1)
        if case .v1(let dv1) = decoded {
            XCTAssertEqual(dv1.sorobanFeeWrite1KB, 999)
        } else {
            XCTFail("Expected .v1")
        }
    }

    // MARK: - LedgerCloseMetaV0XDR

    func testLedgerCloseMetaV0MinimalRoundTrip() throws {
        let ledgerHeader = try makeLedgerHeaderHistoryEntry()
        let txSet = TransactionSetXDR(
            previousLedgerHash: XDRTestHelpers.wrappedData32(),
            txs: []
        )
        let original = LedgerCloseMetaV0XDR(
            ledgerHeader: ledgerHeader,
            txSet: txSet,
            txProcessing: [],
            upgradesProcessing: [],
            scpInfo: []
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerCloseMetaV0XDR.self, data: encoded)

        XCTAssertEqual(decoded.ledgerHeader.header.ledgerVersion, 21)
        XCTAssertEqual(decoded.txSet.txs.count, 0)
        XCTAssertEqual(decoded.txProcessing.count, 0)
        XCTAssertEqual(decoded.upgradesProcessing.count, 0)
        XCTAssertEqual(decoded.scpInfo.count, 0)
    }

    // MARK: - LedgerCloseMetaV1XDR

    func testLedgerCloseMetaV1MinimalRoundTrip() throws {
        let ledgerHeader = try makeLedgerHeaderHistoryEntry()
        let v1TxSet = TransactionSetV1XDR(
            previousLedgerHash: XDRTestHelpers.wrappedData32(),
            phases: []
        )
        let genTxSet = GeneralizedTransactionSetXDR.v1TxSet(v1TxSet)
        let original = LedgerCloseMetaV1XDR(
            ext: .void,
            ledgerHeader: ledgerHeader,
            txSet: genTxSet,
            txProcessing: [],
            upgradesProcessing: [],
            scpInfo: [],
            totalByteSizeOfLiveSorobanState: 5000000,
            evictedKeys: [],
            unused: []
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerCloseMetaV1XDR.self, data: encoded)

        XCTAssertEqual(decoded.ext.type(), 0)
        XCTAssertEqual(decoded.ledgerHeader.header.ledgerVersion, 21)
        XCTAssertEqual(decoded.txProcessing.count, 0)
        XCTAssertEqual(decoded.upgradesProcessing.count, 0)
        XCTAssertEqual(decoded.scpInfo.count, 0)
        XCTAssertEqual(decoded.totalByteSizeOfLiveSorobanState, 5000000)
        XCTAssertEqual(decoded.evictedKeys.count, 0)
        XCTAssertEqual(decoded.unused.count, 0)
    }

    func testLedgerCloseMetaV1WithExtV1RoundTrip() throws {
        let ledgerHeader = try makeLedgerHeaderHistoryEntry()
        let v1TxSet = TransactionSetV1XDR(
            previousLedgerHash: XDRTestHelpers.wrappedData32(),
            phases: []
        )
        let genTxSet = GeneralizedTransactionSetXDR.v1TxSet(v1TxSet)
        let extV1 = LedgerCloseMetaExtV1XDR(ext: .void, sorobanFeeWrite1KB: 7777)
        let original = LedgerCloseMetaV1XDR(
            ext: .v1(extV1),
            ledgerHeader: ledgerHeader,
            txSet: genTxSet,
            txProcessing: [],
            upgradesProcessing: [],
            scpInfo: [],
            totalByteSizeOfLiveSorobanState: 3000000,
            evictedKeys: [],
            unused: []
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerCloseMetaV1XDR.self, data: encoded)

        XCTAssertEqual(decoded.ext.type(), 1)
        if case .v1(let dv1) = decoded.ext {
            XCTAssertEqual(dv1.sorobanFeeWrite1KB, 7777)
        } else {
            XCTFail("Expected ext .v1")
        }
        XCTAssertEqual(decoded.totalByteSizeOfLiveSorobanState, 3000000)
    }

    // MARK: - LedgerCloseMetaV2XDR

    func testLedgerCloseMetaV2MinimalRoundTrip() throws {
        let ledgerHeader = try makeLedgerHeaderHistoryEntry()
        let v1TxSet = TransactionSetV1XDR(
            previousLedgerHash: XDRTestHelpers.wrappedData32(),
            phases: []
        )
        let genTxSet = GeneralizedTransactionSetXDR.v1TxSet(v1TxSet)
        let original = LedgerCloseMetaV2XDR(
            ext: .void,
            ledgerHeader: ledgerHeader,
            txSet: genTxSet,
            txProcessing: [],
            upgradesProcessing: [],
            scpInfo: [],
            totalByteSizeOfLiveSorobanState: 8000000,
            evictedKeys: []
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerCloseMetaV2XDR.self, data: encoded)

        XCTAssertEqual(decoded.ext.type(), 0)
        XCTAssertEqual(decoded.ledgerHeader.header.ledgerVersion, 21)
        XCTAssertEqual(decoded.txProcessing.count, 0)
        XCTAssertEqual(decoded.upgradesProcessing.count, 0)
        XCTAssertEqual(decoded.scpInfo.count, 0)
        XCTAssertEqual(decoded.totalByteSizeOfLiveSorobanState, 8000000)
        XCTAssertEqual(decoded.evictedKeys.count, 0)
    }

    func testLedgerCloseMetaV2WithEvictedKeysRoundTrip() throws {
        let ledgerHeader = try makeLedgerHeaderHistoryEntry()
        let v1TxSet = TransactionSetV1XDR(
            previousLedgerHash: XDRTestHelpers.wrappedData32(),
            phases: []
        )
        let genTxSet = GeneralizedTransactionSetXDR.v1TxSet(v1TxSet)
        let evictedKey = XDRTestHelpers.ledgerKey()
        let original = LedgerCloseMetaV2XDR(
            ext: .void,
            ledgerHeader: ledgerHeader,
            txSet: genTxSet,
            txProcessing: [],
            upgradesProcessing: [],
            scpInfo: [],
            totalByteSizeOfLiveSorobanState: 1000000,
            evictedKeys: [evictedKey]
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerCloseMetaV2XDR.self, data: encoded)

        XCTAssertEqual(decoded.evictedKeys.count, 1)
        XCTAssertEqual(decoded.totalByteSizeOfLiveSorobanState, 1000000)
    }

    // MARK: - LedgerCloseMetaXDR (union)

    func testLedgerCloseMetaV0ArmRoundTrip() throws {
        let ledgerHeader = try makeLedgerHeaderHistoryEntry()
        let txSet = TransactionSetXDR(
            previousLedgerHash: XDRTestHelpers.wrappedData32(),
            txs: []
        )
        let v0 = LedgerCloseMetaV0XDR(
            ledgerHeader: ledgerHeader,
            txSet: txSet,
            txProcessing: [],
            upgradesProcessing: [],
            scpInfo: []
        )
        let original = LedgerCloseMetaXDR.v0(v0)

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerCloseMetaXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), 0)
        if case .v0(let dv0) = decoded {
            XCTAssertEqual(dv0.ledgerHeader.header.ledgerVersion, 21)
        } else {
            XCTFail("Expected .v0")
        }
    }

    func testLedgerCloseMetaV1ArmRoundTrip() throws {
        let ledgerHeader = try makeLedgerHeaderHistoryEntry()
        let v1TxSet = TransactionSetV1XDR(
            previousLedgerHash: XDRTestHelpers.wrappedData32(),
            phases: []
        )
        let genTxSet = GeneralizedTransactionSetXDR.v1TxSet(v1TxSet)
        let v1 = LedgerCloseMetaV1XDR(
            ext: .void,
            ledgerHeader: ledgerHeader,
            txSet: genTxSet,
            txProcessing: [],
            upgradesProcessing: [],
            scpInfo: [],
            totalByteSizeOfLiveSorobanState: 2000000,
            evictedKeys: [],
            unused: []
        )
        let original = LedgerCloseMetaXDR.v1(v1)

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerCloseMetaXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), 1)
        if case .v1(let dv1) = decoded {
            XCTAssertEqual(dv1.totalByteSizeOfLiveSorobanState, 2000000)
        } else {
            XCTFail("Expected .v1")
        }
    }

    func testLedgerCloseMetaV2ArmRoundTrip() throws {
        let ledgerHeader = try makeLedgerHeaderHistoryEntry()
        let v1TxSet = TransactionSetV1XDR(
            previousLedgerHash: XDRTestHelpers.wrappedData32(),
            phases: []
        )
        let genTxSet = GeneralizedTransactionSetXDR.v1TxSet(v1TxSet)
        let v2 = LedgerCloseMetaV2XDR(
            ext: .void,
            ledgerHeader: ledgerHeader,
            txSet: genTxSet,
            txProcessing: [],
            upgradesProcessing: [],
            scpInfo: [],
            totalByteSizeOfLiveSorobanState: 4000000,
            evictedKeys: []
        )
        let original = LedgerCloseMetaXDR.v2(v2)

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerCloseMetaXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), 2)
        if case .v2(let dv2) = decoded {
            XCTAssertEqual(dv2.totalByteSizeOfLiveSorobanState, 4000000)
        } else {
            XCTFail("Expected .v2")
        }
    }

    // MARK: - LedgerCloseMetaBatchXDR

    func testLedgerCloseMetaBatchEmptyRoundTrip() throws {
        let original = LedgerCloseMetaBatchXDR(
            startSequence: 100,
            endSequence: 200,
            ledgerCloseMetas: []
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerCloseMetaBatchXDR.self, data: encoded)

        XCTAssertEqual(decoded.startSequence, 100)
        XCTAssertEqual(decoded.endSequence, 200)
        XCTAssertEqual(decoded.ledgerCloseMetas.count, 0)
    }

    func testLedgerCloseMetaBatchWithMetaRoundTrip() throws {
        let ledgerHeader = try makeLedgerHeaderHistoryEntry()
        let txSet = TransactionSetXDR(
            previousLedgerHash: XDRTestHelpers.wrappedData32(),
            txs: []
        )
        let v0 = LedgerCloseMetaV0XDR(
            ledgerHeader: ledgerHeader,
            txSet: txSet,
            txProcessing: [],
            upgradesProcessing: [],
            scpInfo: []
        )
        let closeMeta = LedgerCloseMetaXDR.v0(v0)
        let original = LedgerCloseMetaBatchXDR(
            startSequence: 50,
            endSequence: 51,
            ledgerCloseMetas: [closeMeta]
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerCloseMetaBatchXDR.self, data: encoded)

        XCTAssertEqual(decoded.startSequence, 50)
        XCTAssertEqual(decoded.endSequence, 51)
        XCTAssertEqual(decoded.ledgerCloseMetas.count, 1)
        XCTAssertEqual(decoded.ledgerCloseMetas[0].type(), 0)
    }
}
