//
//  PreconditionsXDRUnitTests.swift
//  stellarsdkTests
//
//  Created by Soneso
//  Copyright (c) 2025 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class PreconditionsXDRUnitTests: XCTestCase {

    // MARK: - PreconditionsXDR Variant Tests

    func testPreconditionsXDRNone() throws {
        let preconditions = PreconditionsXDR.none

        XCTAssertEqual(preconditions.type(), PreconditionType.none.rawValue)

        let encoded = try XDREncoder.encode(preconditions)
        let decoded = try XDRDecoder.decode(PreconditionsXDR.self, data: encoded)

        switch decoded {
        case .none:
            XCTAssertEqual(decoded.type(), PreconditionType.none.rawValue)
        default:
            XCTFail("Expected .none precondition")
        }
    }

    func testPreconditionsXDRTime() throws {
        let timeBounds = TimeBoundsXDR(minTime: 1000, maxTime: 2000)
        let preconditions = PreconditionsXDR.time(timeBounds)

        XCTAssertEqual(preconditions.type(), PreconditionType.time.rawValue)

        let encoded = try XDREncoder.encode(preconditions)
        let decoded = try XDRDecoder.decode(PreconditionsXDR.self, data: encoded)

        switch decoded {
        case .time(let decodedTimeBounds):
            XCTAssertEqual(decodedTimeBounds.minTime, 1000)
            XCTAssertEqual(decodedTimeBounds.maxTime, 2000)
        default:
            XCTFail("Expected .time precondition")
        }
    }

    func testPreconditionsXDRV2Minimal() throws {
        let v2 = PreconditionsV2XDR(
            timeBounds: nil,
            ledgerBounds: nil,
            sequenceNumber: nil,
            minSeqAge: 0,
            minSeqLedgerGap: 0,
            extraSigners: []
        )
        let preconditions = PreconditionsXDR.v2(v2)

        XCTAssertEqual(preconditions.type(), PreconditionType.v2.rawValue)

        let encoded = try XDREncoder.encode(preconditions)
        let decoded = try XDRDecoder.decode(PreconditionsXDR.self, data: encoded)

        switch decoded {
        case .v2(let decodedV2):
            XCTAssertNil(decodedV2.timeBounds)
            XCTAssertNil(decodedV2.ledgerBounds)
            XCTAssertNil(decodedV2.sequenceNumber)
            XCTAssertEqual(decodedV2.minSeqAge, 0)
            XCTAssertEqual(decodedV2.minSeqLedgerGap, 0)
            XCTAssertEqual(decodedV2.extraSigners.count, 0)
        default:
            XCTFail("Expected .v2 precondition")
        }
    }

    func testPreconditionsXDRV2WithTimeBounds() throws {
        let timeBounds = TimeBoundsXDR(minTime: 1609459200, maxTime: 1609545600)
        let v2 = PreconditionsV2XDR(
            timeBounds: timeBounds,
            ledgerBounds: nil,
            sequenceNumber: nil,
            minSeqAge: 0,
            minSeqLedgerGap: 0,
            extraSigners: []
        )
        let preconditions = PreconditionsXDR.v2(v2)

        let encoded = try XDREncoder.encode(preconditions)
        let decoded = try XDRDecoder.decode(PreconditionsXDR.self, data: encoded)

        switch decoded {
        case .v2(let decodedV2):
            XCTAssertNotNil(decodedV2.timeBounds)
            XCTAssertEqual(decodedV2.timeBounds?.minTime, 1609459200)
            XCTAssertEqual(decodedV2.timeBounds?.maxTime, 1609545600)
            XCTAssertNil(decodedV2.ledgerBounds)
        default:
            XCTFail("Expected .v2 precondition")
        }
    }

    func testPreconditionsXDRV2WithLedgerBounds() throws {
        let ledgerBounds = LedgerBoundsXDR(minLedger: 100000, maxLedger: 200000)
        let v2 = PreconditionsV2XDR(
            timeBounds: nil,
            ledgerBounds: ledgerBounds,
            sequenceNumber: nil,
            minSeqAge: 0,
            minSeqLedgerGap: 0,
            extraSigners: []
        )
        let preconditions = PreconditionsXDR.v2(v2)

        let encoded = try XDREncoder.encode(preconditions)
        let decoded = try XDRDecoder.decode(PreconditionsXDR.self, data: encoded)

        switch decoded {
        case .v2(let decodedV2):
            XCTAssertNil(decodedV2.timeBounds)
            XCTAssertNotNil(decodedV2.ledgerBounds)
            XCTAssertEqual(decodedV2.ledgerBounds?.minLedger, 100000)
            XCTAssertEqual(decodedV2.ledgerBounds?.maxLedger, 200000)
        default:
            XCTFail("Expected .v2 precondition")
        }
    }

    func testPreconditionsXDRV2WithMinSeqNum() throws {
        let minSeqNum: Int64 = 123456789012345
        let v2 = PreconditionsV2XDR(
            timeBounds: nil,
            ledgerBounds: nil,
            sequenceNumber: minSeqNum,
            minSeqAge: 0,
            minSeqLedgerGap: 0,
            extraSigners: []
        )
        let preconditions = PreconditionsXDR.v2(v2)

        let encoded = try XDREncoder.encode(preconditions)
        let decoded = try XDRDecoder.decode(PreconditionsXDR.self, data: encoded)

        switch decoded {
        case .v2(let decodedV2):
            XCTAssertNotNil(decodedV2.sequenceNumber)
            XCTAssertEqual(decodedV2.sequenceNumber, minSeqNum)
        default:
            XCTFail("Expected .v2 precondition")
        }
    }

    func testPreconditionsXDRV2WithMinSeqAge() throws {
        let minSeqAge: UInt64 = 86400
        let v2 = PreconditionsV2XDR(
            timeBounds: nil,
            ledgerBounds: nil,
            sequenceNumber: nil,
            minSeqAge: minSeqAge,
            minSeqLedgerGap: 0,
            extraSigners: []
        )
        let preconditions = PreconditionsXDR.v2(v2)

        let encoded = try XDREncoder.encode(preconditions)
        let decoded = try XDRDecoder.decode(PreconditionsXDR.self, data: encoded)

        switch decoded {
        case .v2(let decodedV2):
            XCTAssertEqual(decodedV2.minSeqAge, minSeqAge)
        default:
            XCTFail("Expected .v2 precondition")
        }
    }

    func testPreconditionsXDRV2WithMinSeqLedgerGap() throws {
        let minSeqLedgerGap: UInt32 = 100
        let v2 = PreconditionsV2XDR(
            timeBounds: nil,
            ledgerBounds: nil,
            sequenceNumber: nil,
            minSeqAge: 0,
            minSeqLedgerGap: minSeqLedgerGap,
            extraSigners: []
        )
        let preconditions = PreconditionsXDR.v2(v2)

        let encoded = try XDREncoder.encode(preconditions)
        let decoded = try XDRDecoder.decode(PreconditionsXDR.self, data: encoded)

        switch decoded {
        case .v2(let decodedV2):
            XCTAssertEqual(decodedV2.minSeqLedgerGap, minSeqLedgerGap)
        default:
            XCTFail("Expected .v2 precondition")
        }
    }

    func testPreconditionsXDRV2WithExtraSigners() throws {
        let signerKey1 = SignerKeyXDR.ed25519(WrappedData32(Data(repeating: 0xAB, count: 32)))
        let signerKey2 = SignerKeyXDR.preAuthTx(WrappedData32(Data(repeating: 0xCD, count: 32)))

        let v2 = PreconditionsV2XDR(
            timeBounds: nil,
            ledgerBounds: nil,
            sequenceNumber: nil,
            minSeqAge: 0,
            minSeqLedgerGap: 0,
            extraSigners: [signerKey1, signerKey2]
        )
        let preconditions = PreconditionsXDR.v2(v2)

        let encoded = try XDREncoder.encode(preconditions)
        let decoded = try XDRDecoder.decode(PreconditionsXDR.self, data: encoded)

        switch decoded {
        case .v2(let decodedV2):
            XCTAssertEqual(decodedV2.extraSigners.count, 2)
        default:
            XCTFail("Expected .v2 precondition")
        }
    }

    // MARK: - Round-Trip Tests

    func testPreconditionsXDRRoundTrip() throws {
        let timeBounds = TimeBoundsXDR(minTime: 1609459200, maxTime: 1609545600)
        let ledgerBounds = LedgerBoundsXDR(minLedger: 50000, maxLedger: 100000)
        let signerKey = SignerKeyXDR.hashX(WrappedData32(Data(repeating: 0xEF, count: 32)))

        let v2 = PreconditionsV2XDR(
            timeBounds: timeBounds,
            ledgerBounds: ledgerBounds,
            sequenceNumber: 9876543210,
            minSeqAge: 3600,
            minSeqLedgerGap: 50,
            extraSigners: [signerKey]
        )
        let preconditions = PreconditionsXDR.v2(v2)

        let encoded = try XDREncoder.encode(preconditions)
        let base64 = Data(encoded).base64EncodedString()

        guard let decodedData = Data(base64Encoded: base64) else {
            XCTFail("Failed to decode base64")
            return
        }
        let decoded = try XDRDecoder.decode(PreconditionsXDR.self, data: [UInt8](decodedData))

        switch decoded {
        case .v2(let decodedV2):
            XCTAssertEqual(decodedV2.timeBounds?.minTime, 1609459200)
            XCTAssertEqual(decodedV2.timeBounds?.maxTime, 1609545600)
            XCTAssertEqual(decodedV2.ledgerBounds?.minLedger, 50000)
            XCTAssertEqual(decodedV2.ledgerBounds?.maxLedger, 100000)
            XCTAssertEqual(decodedV2.sequenceNumber, 9876543210)
            XCTAssertEqual(decodedV2.minSeqAge, 3600)
            XCTAssertEqual(decodedV2.minSeqLedgerGap, 50)
            XCTAssertEqual(decodedV2.extraSigners.count, 1)
        default:
            XCTFail("Expected .v2 precondition")
        }
    }

    func testPreconditionsXDREncodeDecode() throws {
        let testCases: [PreconditionsXDR] = [
            .none,
            .time(TimeBoundsXDR(minTime: 0, maxTime: UInt64.max)),
            .v2(PreconditionsV2XDR(
                timeBounds: nil,
                ledgerBounds: nil,
                sequenceNumber: nil,
                minSeqAge: 0,
                minSeqLedgerGap: 0,
                extraSigners: []
            ))
        ]

        for precondition in testCases {
            let encoded = try XDREncoder.encode(precondition)
            let decoded = try XDRDecoder.decode(PreconditionsXDR.self, data: encoded)
            XCTAssertEqual(decoded.type(), precondition.type())
        }
    }

    // MARK: - LedgerBoundsXDR Tests

    func testLedgerBoundsXDREncodeDecode() throws {
        let ledgerBounds = LedgerBoundsXDR(minLedger: 1000, maxLedger: 5000)

        let encoded = try XDREncoder.encode(ledgerBounds)
        let decoded = try XDRDecoder.decode(LedgerBoundsXDR.self, data: encoded)

        XCTAssertEqual(decoded.minLedger, 1000)
        XCTAssertEqual(decoded.maxLedger, 5000)
    }

    func testLedgerBoundsXDRBoundaryValues() throws {
        let ledgerBounds = LedgerBoundsXDR(minLedger: 0, maxLedger: UInt32.max)

        let encoded = try XDREncoder.encode(ledgerBounds)
        let decoded = try XDRDecoder.decode(LedgerBoundsXDR.self, data: encoded)

        XCTAssertEqual(decoded.minLedger, 0)
        XCTAssertEqual(decoded.maxLedger, UInt32.max)
    }

    // MARK: - PreconditionsXDR Extended Tests

    func testPreconditionsXDRV2AllFields() throws {
        let timeBounds = TimeBoundsXDR(minTime: 1609459200, maxTime: 1609545600)
        let ledgerBounds = LedgerBoundsXDR(minLedger: 50000, maxLedger: 100000)
        let sequenceNumber: Int64 = 9876543210
        let minSeqAge: UInt64 = 86400
        let minSeqLedgerGap: UInt32 = 100

        let signerKey1 = SignerKeyXDR.ed25519(WrappedData32(Data(repeating: 0xAB, count: 32)))
        let signerKey2 = SignerKeyXDR.preAuthTx(WrappedData32(Data(repeating: 0xCD, count: 32)))
        let signerKey3 = SignerKeyXDR.hashX(WrappedData32(Data(repeating: 0xEF, count: 32)))

        let v2 = PreconditionsV2XDR(
            timeBounds: timeBounds,
            ledgerBounds: ledgerBounds,
            sequenceNumber: sequenceNumber,
            minSeqAge: minSeqAge,
            minSeqLedgerGap: minSeqLedgerGap,
            extraSigners: [signerKey1, signerKey2, signerKey3]
        )
        let preconditions = PreconditionsXDR.v2(v2)

        let encoded = try XDREncoder.encode(preconditions)
        let decoded = try XDRDecoder.decode(PreconditionsXDR.self, data: encoded)

        switch decoded {
        case .v2(let decodedV2):
            XCTAssertNotNil(decodedV2.timeBounds)
            XCTAssertEqual(decodedV2.timeBounds?.minTime, 1609459200)
            XCTAssertEqual(decodedV2.timeBounds?.maxTime, 1609545600)
            XCTAssertNotNil(decodedV2.ledgerBounds)
            XCTAssertEqual(decodedV2.ledgerBounds?.minLedger, 50000)
            XCTAssertEqual(decodedV2.ledgerBounds?.maxLedger, 100000)
            XCTAssertNotNil(decodedV2.sequenceNumber)
            XCTAssertEqual(decodedV2.sequenceNumber, sequenceNumber)
            XCTAssertEqual(decodedV2.minSeqAge, minSeqAge)
            XCTAssertEqual(decodedV2.minSeqLedgerGap, minSeqLedgerGap)
            XCTAssertEqual(decodedV2.extraSigners.count, 3)
        default:
            XCTFail("Expected .v2 precondition")
        }
    }

    func testPreconditionsXDRFromBase64() throws {
        // Create a known precondition and encode to base64
        let timeBounds = TimeBoundsXDR(minTime: 1000, maxTime: 2000)
        let preconditions = PreconditionsXDR.time(timeBounds)

        let encoded = try XDREncoder.encode(preconditions)
        let base64String = Data(encoded).base64EncodedString()

        // Now decode from base64
        guard let decodedData = Data(base64Encoded: base64String) else {
            XCTFail("Failed to decode base64 string")
            return
        }

        let decoded = try XDRDecoder.decode(PreconditionsXDR.self, data: [UInt8](decodedData))

        switch decoded {
        case .time(let decodedTimeBounds):
            XCTAssertEqual(decodedTimeBounds.minTime, 1000)
            XCTAssertEqual(decodedTimeBounds.maxTime, 2000)
        default:
            XCTFail("Expected .time precondition")
        }
    }

    func testPreconditionsXDRV2MultipleExtraSigners() throws {
        let signerKey1 = SignerKeyXDR.ed25519(WrappedData32(Data(repeating: 0x11, count: 32)))
        let signerKey2 = SignerKeyXDR.preAuthTx(WrappedData32(Data(repeating: 0x22, count: 32)))
        let signerKey3 = SignerKeyXDR.hashX(WrappedData32(Data(repeating: 0x33, count: 32)))
        let signerKey4 = SignerKeyXDR.ed25519(WrappedData32(Data(repeating: 0x44, count: 32)))

        let v2 = PreconditionsV2XDR(
            timeBounds: nil,
            ledgerBounds: nil,
            sequenceNumber: nil,
            minSeqAge: 0,
            minSeqLedgerGap: 0,
            extraSigners: [signerKey1, signerKey2, signerKey3, signerKey4]
        )
        let preconditions = PreconditionsXDR.v2(v2)

        let encoded = try XDREncoder.encode(preconditions)
        let decoded = try XDRDecoder.decode(PreconditionsXDR.self, data: encoded)

        switch decoded {
        case .v2(let decodedV2):
            XCTAssertEqual(decodedV2.extraSigners.count, 4)

            // Verify each signer type
            if case .ed25519(let data) = decodedV2.extraSigners[0] {
                XCTAssertEqual(data.wrapped, Data(repeating: 0x11, count: 32))
            } else {
                XCTFail("Expected ed25519 signer at index 0")
            }

            if case .preAuthTx(let data) = decodedV2.extraSigners[1] {
                XCTAssertEqual(data.wrapped, Data(repeating: 0x22, count: 32))
            } else {
                XCTFail("Expected preAuthTx signer at index 1")
            }

            if case .hashX(let data) = decodedV2.extraSigners[2] {
                XCTAssertEqual(data.wrapped, Data(repeating: 0x33, count: 32))
            } else {
                XCTFail("Expected hashX signer at index 2")
            }

            if case .ed25519(let data) = decodedV2.extraSigners[3] {
                XCTAssertEqual(data.wrapped, Data(repeating: 0x44, count: 32))
            } else {
                XCTFail("Expected ed25519 signer at index 3")
            }
        default:
            XCTFail("Expected .v2 precondition")
        }
    }

    // MARK: - TimeBoundsXDR Tests

    func testTimeBoundsXDREncodeDecode() throws {
        let timeBounds = TimeBoundsXDR(minTime: 1609459200, maxTime: 1609545600)

        let encoded = try XDREncoder.encode(timeBounds)
        let decoded = try XDRDecoder.decode(TimeBoundsXDR.self, data: encoded)

        XCTAssertEqual(decoded.minTime, 1609459200)
        XCTAssertEqual(decoded.maxTime, 1609545600)
    }

    func testTimeBoundsXDRMinOnly() throws {
        let timeBounds = TimeBoundsXDR(minTime: 1609459200, maxTime: 0)

        let encoded = try XDREncoder.encode(timeBounds)
        let decoded = try XDRDecoder.decode(TimeBoundsXDR.self, data: encoded)

        XCTAssertEqual(decoded.minTime, 1609459200)
        XCTAssertEqual(decoded.maxTime, 0)
    }

    func testTimeBoundsXDRMaxOnly() throws {
        let timeBounds = TimeBoundsXDR(minTime: 0, maxTime: 1609545600)

        let encoded = try XDREncoder.encode(timeBounds)
        let decoded = try XDRDecoder.decode(TimeBoundsXDR.self, data: encoded)

        XCTAssertEqual(decoded.minTime, 0)
        XCTAssertEqual(decoded.maxTime, 1609545600)
    }

    func testTimeBoundsXDRBothBounds() throws {
        let minTime: UInt64 = 1609459200
        let maxTime: UInt64 = 1609545600

        let timeBounds = TimeBoundsXDR(minTime: minTime, maxTime: maxTime)

        let encoded = try XDREncoder.encode(timeBounds)
        let decoded = try XDRDecoder.decode(TimeBoundsXDR.self, data: encoded)

        XCTAssertEqual(decoded.minTime, minTime)
        XCTAssertEqual(decoded.maxTime, maxTime)
    }

    func testTimeBoundsXDRBoundaryValues() throws {
        // Test with minimum possible values
        let timeBoundsMin = TimeBoundsXDR(minTime: 0, maxTime: 0)
        let encodedMin = try XDREncoder.encode(timeBoundsMin)
        let decodedMin = try XDRDecoder.decode(TimeBoundsXDR.self, data: encodedMin)
        XCTAssertEqual(decodedMin.minTime, 0)
        XCTAssertEqual(decodedMin.maxTime, 0)

        // Test with maximum possible values
        let timeBoundsMax = TimeBoundsXDR(minTime: UInt64.max, maxTime: UInt64.max)
        let encodedMax = try XDREncoder.encode(timeBoundsMax)
        let decodedMax = try XDRDecoder.decode(TimeBoundsXDR.self, data: encodedMax)
        XCTAssertEqual(decodedMax.minTime, UInt64.max)
        XCTAssertEqual(decodedMax.maxTime, UInt64.max)

        // Test with mixed boundary values
        let timeBoundsMixed = TimeBoundsXDR(minTime: 0, maxTime: UInt64.max)
        let encodedMixed = try XDREncoder.encode(timeBoundsMixed)
        let decodedMixed = try XDRDecoder.decode(TimeBoundsXDR.self, data: encodedMixed)
        XCTAssertEqual(decodedMixed.minTime, 0)
        XCTAssertEqual(decodedMixed.maxTime, UInt64.max)
    }

    func testTimeBoundsXDRRoundTrip() throws {
        let originalTimeBounds = TimeBoundsXDR(minTime: 1609459200, maxTime: 1640995200)

        // Encode to bytes
        let encoded = try XDREncoder.encode(originalTimeBounds)

        // Convert to base64
        let base64String = Data(encoded).base64EncodedString()
        XCTAssertNotNil(base64String)

        // Decode from base64
        guard let decodedData = Data(base64Encoded: base64String) else {
            XCTFail("Failed to decode base64 string")
            return
        }

        // Decode back to TimeBoundsXDR
        let decoded = try XDRDecoder.decode(TimeBoundsXDR.self, data: [UInt8](decodedData))

        XCTAssertEqual(decoded.minTime, originalTimeBounds.minTime)
        XCTAssertEqual(decoded.maxTime, originalTimeBounds.maxTime)
    }
}
