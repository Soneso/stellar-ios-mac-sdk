//
//  PreconditionsArmUnitTests.swift
//  stellarsdkUnitTests
//
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

/// A decoded `PRECOND_V2` precondition encodes as `PRECOND_V2` again, so a decoded transaction keeps
/// its bytes and its hash; built preconditions choose `PRECOND_NONE`, `PRECOND_TIME` or `PRECOND_V2`
/// from their values. The fixtures are raw XDR, and each expected hash is
/// sha256(sha256(passphrase) || envelope type || transaction bytes), computed outside the SDK.
final class PreconditionsArmUnitTests: XCTestCase {

    /// A public network path payment with two signatures whose `PRECOND_V2` holds only time bounds.
    private let publicTimeBoundsV2Envelope = "AAAAAgAAAAAjIV2QSjkjVC2NRbEBkV2PJmIBq2UKJLQ8WtBuCDXJ2wAAAfQCynanAAIn3gAAAAIAAAABAAAAAAAAAAAAAAAAZ21qPwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAQAAAAA7ngKfAUS0/FGZa4KJx3HXU6lwFOcBJPM4wex7LzuKWQAAAAIAAAAAAAAAAACVE5oAAAAAO54CnwFEtPxRmWuCicdx11OpcBTnASTzOMHsey87ilkAAAABeVhMTQAAAAAiNtdw/g0+AVIZddXPesSEK3CV1rGp12jT6aYy6ZkGvgAAAAAAlROaAAAAAgAAAAFQWUJDAAAAAGoebauqH6pI95KR+EBZVmms+p4HXgOxFvrW2rIJm6+gAAAAAUdPTEQAAAAARdyZXmQpu5u4/qV3g+/setPieuf7JpEh1TZIeT30F1MAAAAAAAAAAgg1ydsAAABA4b8Q29wH2OARp5SSjIFp68OG8fXL40Ds16TjPsspD1GqyAx4GDfjfZ+IEeSnYa7Qr/xzCdVk0fyJh4qwfHBFAi87ilkAAABAuutRndzo0SxfqbLK4IYQFwOr0blwGWSv4RMDO8x9uYwESqNHCtL43vMIjrpB3/irBxisBvjqMwATggWhAB4wCA=="
    /// Public network hash of the transaction in `publicTimeBoundsV2Envelope`.
    private let publicTimeBoundsV2Hash = "b4a6d6a2dfc62268a5f864f51d761207641e0c72bd8eb277159005f0f3503db9"
    /// A payment transaction whose `PRECOND_V2` has every field at its default value.
    private let defaultV2Transaction = "AAAAAGV+lDNEWJN2FhmJZgrrObjhhYYF80e+hc48z6KYhQxNAAAAZAAEYtU8irrBAAAAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAABAAAAAO3gUmG83C+VCqO6FztuMtXJF/l7grZA7MjRzqdZ9W8QAAAAAAAAAAAAmJaAAAAAAA=="
    /// `defaultV2Transaction` in a V1 envelope with one signature.
    private let defaultV2Envelope = "AAAAAgAAAABlfpQzRFiTdhYZiWYK6zm44YWGBfNHvoXOPM+imIUMTQAAAGQABGLVPIq6wQAAAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAQAAAADt4FJhvNwvlQqjuhc7bjLVyRf5e4K2QOzI0c6nWfVvEAAAAAAAAAAAAJiWgAAAAAAAAAABmIUMTQAAAEARERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERER"
    /// Testnet hash of `defaultV2Transaction`.
    private let defaultV2Hash = "314950c2ee5f935abf54a68aaa5852e828ddfe373b320808c994729010bc1b57"
    /// `defaultV2Envelope` bumped by GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ to fee 400,
    /// with one outer signature.
    private let feeBumpEnvelope = "AAAABQAAAAA/DDS/k60NmXHQTMyQ9wVRHIOKrZc0pKL7DXoD/H/omgAAAAAAAAGQAAAAAgAAAABlfpQzRFiTdhYZiWYK6zm44YWGBfNHvoXOPM+imIUMTQAAAGQABGLVPIq6wQAAAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAQAAAADt4FJhvNwvlQqjuhc7bjLVyRf5e4K2QOzI0c6nWfVvEAAAAAAAAAAAAJiWgAAAAAAAAAABmIUMTQAAAEARERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERAAAAAAAAAAH8f+iaAAAAQCIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiI="
    /// Testnet hash of the fee bump transaction in `feeBumpEnvelope` (envelope type 5).
    private let feeBumpHash = "73e3cd69ac89ff145cd219b3203e06ad4e79034b55f13ba2738012b45ca4e465"
    /// The payment of `defaultV2Envelope` with `PRECOND_NONE`.
    private let noneEnvelope = "AAAAAgAAAABlfpQzRFiTdhYZiWYK6zm44YWGBfNHvoXOPM+imIUMTQAAAGQABGLVPIq6wQAAAAAAAAAAAAAAAQAAAAAAAAABAAAAAO3gUmG83C+VCqO6FztuMtXJF/l7grZA7MjRzqdZ9W8QAAAAAAAAAAAAmJaAAAAAAAAAAAGYhQxNAAAAQBERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERE="
    /// The payment of `defaultV2Envelope` with `PRECOND_TIME` from 1700000000 to 1700000300.
    private let timeEnvelope = "AAAAAgAAAABlfpQzRFiTdhYZiWYK6zm44YWGBfNHvoXOPM+imIUMTQAAAGQABGLVPIq6wQAAAAEAAAAAZVPxAAAAAABlU/IsAAAAAAAAAAEAAAAAAAAAAQAAAADt4FJhvNwvlQqjuhc7bjLVyRf5e4K2QOzI0c6nWfVvEAAAAAAAAAAAAJiWgAAAAAAAAAABmIUMTQAAAEARERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERER"

    func testPublicTimeBoundsV2EnvelopeKeepsBytesAndHash() throws {
        let transaction = try Transaction(envelopeXdr: publicTimeBoundsV2Envelope)
        XCTAssertEqual(try transaction.getTransactionHash(network: .public), publicTimeBoundsV2Hash)
        XCTAssertEqual(try transaction.encodedEnvelope(), publicTimeBoundsV2Envelope)
        XCTAssertEqual(transaction.preconditions?.hasV2(), true)
    }

    func testDefaultV2EnvelopeKeepsBytesAndHash() throws {
        let transaction = try Transaction(envelopeXdr: defaultV2Envelope)
        XCTAssertEqual(try transaction.encodedEnvelope(), defaultV2Envelope)
        XCTAssertEqual(try transaction.getTransactionHash(network: .testnet), defaultV2Hash)
        XCTAssertEqual(transaction.preconditions?.hasV2(), true)
    }

    func testDefaultV2TransactionXdrKeepsBytesAndHash() throws {
        let transaction = try Transaction(xdr: defaultV2Transaction)
        XCTAssertEqual(transaction.xdrEncoded, defaultV2Transaction)
        XCTAssertEqual(try transaction.getTransactionHash(network: .testnet), defaultV2Hash)
        XCTAssertEqual(transaction.preconditions?.hasV2(), true)
    }

    func testFeeBumpInnerTransactionKeepsBytesAndHash() throws {
        let inner = try Transaction(envelopeXdr: feeBumpEnvelope)
        XCTAssertEqual(try inner.getTransactionHash(network: .testnet), defaultV2Hash)
        XCTAssertEqual(inner.preconditions?.hasV2(), true)

        guard case .feeBump(let original) = try TransactionEnvelopeXDR(xdr: feeBumpEnvelope) else {
            return XCTFail("The fixture is not a fee bump envelope")
        }
        let rebuilt = try FeeBumpTransaction(sourceAccount: try MuxedAccount(accountId: original.tx.sourceAccount.accountId),
                                             fee: original.tx.fee, innerTransaction: inner)
        original.signatures.forEach { rebuilt.addSignature(signature: $0) }
        XCTAssertEqual(try rebuilt.getTransactionHash(network: .testnet), feeBumpHash)
        XCTAssertEqual(try rebuilt.encodedEnvelope(), feeBumpEnvelope)
    }

    func testNoneAndTimeEnvelopesKeepTheirArms() throws {
        for envelope in [noneEnvelope, timeEnvelope] {
            let transaction = try Transaction(envelopeXdr: envelope)
            XCTAssertEqual(try transaction.encodedEnvelope(), envelope)
            XCTAssertEqual(transaction.preconditions?.hasV2(), false)
        }
    }

    func testBuiltPreconditionsChooseTheArmFromTheirValues() throws {
        let signer = try Signer.ed25519PublicKey(accountId: "GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR")
        let cases: [(TransactionPreconditions, String, Bool)] = [
            (TransactionPreconditions(timeBounds: TimeBounds(minTime: 1700000000, maxTime: 1700000300)),
             "AAAAAQAAAABlU/EAAAAAAGVT8iw=", false),
            (TransactionPreconditions(), "AAAAAA==", false),
            (TransactionPreconditions(ledgerBounds: LedgerBounds(minLedger: 0, maxLedger: 0)),
             "AAAAAgAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==", true),
            (TransactionPreconditions(minSeqNumber: 0),
             "AAAAAgAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==", true),
            (TransactionPreconditions(minSeqAge: 1), "AAAAAgAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAA=", true),
            (TransactionPreconditions(minSeqLedgerGap: 1), "AAAAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAA=", true),
            (TransactionPreconditions(extraSigners: [signer]),
             "AAAAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAA7eBSYbzcL5UKo7oXO24y1ckX+XuCtkDsyNHOp1n1bxA=", true),
        ]
        for (index, (preconditions, expectedXdr, expectedV2)) in cases.enumerated() {
            XCTAssertEqual(preconditions.toXdr().xdrEncoded, expectedXdr, "case \(index)")
            XCTAssertEqual(preconditions.hasV2(), expectedV2, "case \(index)")
        }
    }
}
