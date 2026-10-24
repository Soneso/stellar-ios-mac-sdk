//
//  TxRepErrorHandlingTestCase.swift
//  stellarsdkTests
//
//  Created by Christian Rogobete.
//  Copyright © 2024 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class TxRepErrorHandlingTestCase: XCTestCase {

    // MARK: - Error Handling Tests

    func testFromTxRepMissingFee() throws {
        let txRep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: GAVRMS4QIOCC4QMOSKILOOOHCSO4FEKOXZPNLKFFN6W7SD2KUB7NBPLN
        tx.seqNum: 46489056724385793
        tx.memo.type: MEMO_NONE
        tx.operations.len: 0
        tx.ext.v: 0
        signatures.len: 0
        """

        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: txRep)) { error in
            if case TxRepError.missingValue(let key) = error {
                XCTAssertTrue(key.contains("fee"))
            } else {
                XCTFail("Expected missingValue error for fee")
            }
        }
    }

    func testFromTxRepInvalidFee() throws {
        let txRep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: GAVRMS4QIOCC4QMOSKILOOOHCSO4FEKOXZPNLKFFN6W7SD2KUB7NBPLN
        tx.fee: not_a_number
        tx.seqNum: 46489056724385793
        tx.memo.type: MEMO_NONE
        tx.operations.len: 0
        tx.ext.v: 0
        signatures.len: 0
        """

        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: txRep)) { error in
            if case TxRepError.invalidValue(let key) = error {
                XCTAssertTrue(key.contains("fee"))
            } else {
                XCTFail("Expected invalidValue error for fee")
            }
        }
    }

    func testFromTxRepMissingSeqNum() throws {
        let txRep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: GAVRMS4QIOCC4QMOSKILOOOHCSO4FEKOXZPNLKFFN6W7SD2KUB7NBPLN
        tx.fee: 100
        tx.memo.type: MEMO_NONE
        tx.operations.len: 0
        tx.ext.v: 0
        signatures.len: 0
        """

        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: txRep)) { error in
            if case TxRepError.missingValue(let key) = error {
                XCTAssertTrue(key.contains("seqNum"))
            } else {
                XCTFail("Expected missingValue error for seqNum")
            }
        }
    }

    func testFromTxRepInvalidSeqNum() throws {
        let txRep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: GAVRMS4QIOCC4QMOSKILOOOHCSO4FEKOXZPNLKFFN6W7SD2KUB7NBPLN
        tx.fee: 100
        tx.seqNum: invalid
        tx.memo.type: MEMO_NONE
        tx.operations.len: 0
        tx.ext.v: 0
        signatures.len: 0
        """

        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: txRep)) { error in
            if case TxRepError.invalidValue(let key) = error {
                XCTAssertTrue(key.contains("seqNum"))
            } else {
                XCTFail("Expected invalidValue error for seqNum")
            }
        }
    }

    func testFromTxRepMissingSourceAccount() throws {
        let txRep = """
        type: ENVELOPE_TYPE_TX
        tx.fee: 100
        tx.seqNum: 46489056724385793
        tx.memo.type: MEMO_NONE
        tx.operations.len: 0
        tx.ext.v: 0
        signatures.len: 0
        """

        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: txRep)) { error in
            if case TxRepError.missingValue(let key) = error {
                XCTAssertTrue(key.contains("sourceAccount"))
            } else {
                XCTFail("Expected missingValue error for sourceAccount")
            }
        }
    }

    func testFromTxRepInvalidSourceAccount() throws {
        let txRep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: INVALID
        tx.fee: 100
        tx.seqNum: 46489056724385793
        tx.memo.type: MEMO_NONE
        tx.operations.len: 0
        tx.ext.v: 0
        signatures.len: 0
        """

        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: txRep)) { error in
            if case TxRepError.invalidValue(let key) = error {
                XCTAssertTrue(key.contains("sourceAccount"))
            } else {
                XCTFail("Expected invalidValue error for sourceAccount")
            }
        }
    }

    func testFromTxRepMissingSignaturesLen() throws {
        // Absent signatures.len is valid — unsigned transactions (for inspection or
        // multi-sig preparation) may omit the signature block entirely.
        // Flutter and PHP both accept this and return an empty signature array.
        let txRep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: GAVRMS4QIOCC4QMOSKILOOOHCSO4FEKOXZPNLKFFN6W7SD2KUB7NBPLN
        tx.fee: 100
        tx.seqNum: 46489056724385793
        tx.cond.type: PRECOND_NONE
        tx.memo.type: MEMO_NONE
        tx.operations.len: 1
        tx.operations[0].sourceAccount._present: false
        tx.operations[0].body.type: BUMP_SEQUENCE
        tx.operations[0].body.bumpSequenceOp.bumpTo: 46489056724385800
        tx.ext.v: 0
        """

        let base64 = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertFalse(base64.isEmpty, "Expected non-empty base64 for unsigned envelope")

        // Decode and verify signatures array is empty.
        let envelope = try TransactionEnvelopeXDR(fromBase64: base64)
        switch envelope {
        case .v1(let v1env):
            XCTAssertEqual(v1env.signatures.count, 0, "Unsigned envelope must have 0 signatures")
        default:
            XCTFail("Expected V1 envelope type")
        }

        // Roundtrip: toTxRep then fromTxRep must produce identical XDR.
        let txRep2 = try TxRep.toTxRep(transactionEnvelope: base64)
        XCTAssertTrue(txRep2.contains("signatures.len: 0"), "toTxRep must emit signatures.len: 0")
        let base64Again = try TxRep.fromTxRep(txRep: txRep2)
        XCTAssertEqual(base64, base64Again, "Unsigned envelope must roundtrip to identical XDR")
    }

    func testFromTxRepInvalidSignaturesLen() throws {
        let txRep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: GAVRMS4QIOCC4QMOSKILOOOHCSO4FEKOXZPNLKFFN6W7SD2KUB7NBPLN
        tx.fee: 100
        tx.seqNum: 46489056724385793
        tx.cond.type: PRECOND_NONE
        tx.memo.type: MEMO_NONE
        tx.operations.len: 1
        tx.operations[0].sourceAccount._present: false
        tx.operations[0].body.type: BUMP_SEQUENCE
        tx.operations[0].body.bumpSequenceOp.bumpTo: 46489056724385800
        tx.ext.v: 0
        signatures.len: not_a_number
        """

        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: txRep)) { error in
            if case TxRepError.invalidValue(let key) = error {
                XCTAssertTrue(key.contains("signatures.len"))
            } else {
                XCTFail("Expected invalidValue error for signatures.len")
            }
        }
    }

    func testFromTxRepTooManySignatures() throws {
        let txRep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: GAVRMS4QIOCC4QMOSKILOOOHCSO4FEKOXZPNLKFFN6W7SD2KUB7NBPLN
        tx.fee: 100
        tx.seqNum: 46489056724385793
        tx.cond.type: PRECOND_NONE
        tx.memo.type: MEMO_NONE
        tx.operations.len: 1
        tx.operations[0].sourceAccount._present: false
        tx.operations[0].body.type: BUMP_SEQUENCE
        tx.operations[0].body.bumpSequenceOp.bumpTo: 46489056724385800
        tx.ext.v: 0
        signatures.len: 21
        """

        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: txRep)) { error in
            if case TxRepError.invalidValue(let key) = error {
                XCTAssertTrue(key.contains("> 20"))
            } else {
                XCTFail("Expected invalidValue error for signatures > 20")
            }
        }
    }

    func testFromTxRepMissingOperationsLen() throws {
        let txRep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: GAVRMS4QIOCC4QMOSKILOOOHCSO4FEKOXZPNLKFFN6W7SD2KUB7NBPLN
        tx.fee: 100
        tx.seqNum: 46489056724385793
        tx.memo.type: MEMO_NONE
        tx.ext.v: 0
        signatures.len: 0
        """

        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: txRep)) { error in
            if case TxRepError.missingValue(let key) = error {
                XCTAssertTrue(key.contains("operations.len"))
            } else {
                XCTFail("Expected missingValue error for operations.len")
            }
        }
    }

    func testFromTxRepInvalidOperationsLen() throws {
        let txRep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: GAVRMS4QIOCC4QMOSKILOOOHCSO4FEKOXZPNLKFFN6W7SD2KUB7NBPLN
        tx.fee: 100
        tx.seqNum: 46489056724385793
        tx.memo.type: MEMO_NONE
        tx.operations.len: invalid
        tx.ext.v: 0
        signatures.len: 0
        """

        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: txRep)) { error in
            if case TxRepError.invalidValue(let key) = error {
                XCTAssertTrue(key.contains("operations.len"))
            } else {
                XCTFail("Expected invalidValue error for operations.len")
            }
        }
    }

    func testFromTxRepTooManyOperations() throws {
        let txRep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: GAVRMS4QIOCC4QMOSKILOOOHCSO4FEKOXZPNLKFFN6W7SD2KUB7NBPLN
        tx.fee: 100
        tx.seqNum: 46489056724385793
        tx.memo.type: MEMO_NONE
        tx.operations.len: 101
        tx.ext.v: 0
        signatures.len: 0
        """

        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: txRep)) { error in
            if case TxRepError.invalidValue(let key) = error {
                XCTAssertTrue(key.contains("> 100"))
            } else {
                XCTFail("Expected invalidValue error for operations > 100")
            }
        }
    }

    // MARK: - Memo Tests

    func testFromTxRepMissingMemoType() throws {
        let txRep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: GAVRMS4QIOCC4QMOSKILOOOHCSO4FEKOXZPNLKFFN6W7SD2KUB7NBPLN
        tx.fee: 100
        tx.seqNum: 46489056724385793
        tx.operations.len: 0
        tx.ext.v: 0
        signatures.len: 0
        """

        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: txRep)) { error in
            if case TxRepError.missingValue(let key) = error {
                XCTAssertTrue(key.contains("memo.type"))
            } else {
                XCTFail("Expected missingValue error for memo.type")
            }
        }
    }

    func testFromTxRepMissingMemoTextValue() throws {
        let txRep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: GAVRMS4QIOCC4QMOSKILOOOHCSO4FEKOXZPNLKFFN6W7SD2KUB7NBPLN
        tx.fee: 100
        tx.seqNum: 46489056724385793
        tx.memo.type: MEMO_TEXT
        tx.operations.len: 0
        tx.ext.v: 0
        signatures.len: 0
        """

        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: txRep)) { error in
            if case TxRepError.missingValue(let key) = error {
                XCTAssertTrue(key.contains("memo.text"))
            } else {
                XCTFail("Expected missingValue error for memo.text")
            }
        }
    }

    func testFromTxRepMissingMemoIdValue() throws {
        let txRep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: GAVRMS4QIOCC4QMOSKILOOOHCSO4FEKOXZPNLKFFN6W7SD2KUB7NBPLN
        tx.fee: 100
        tx.seqNum: 46489056724385793
        tx.memo.type: MEMO_ID
        tx.operations.len: 0
        tx.ext.v: 0
        signatures.len: 0
        """

        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: txRep)) { error in
            if case TxRepError.missingValue(let key) = error {
                XCTAssertTrue(key.contains("memo.id"))
            } else {
                XCTFail("Expected missingValue error for memo.id")
            }
        }
    }

    func testFromTxRepInvalidMemoIdValue() throws {
        let txRep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: GAVRMS4QIOCC4QMOSKILOOOHCSO4FEKOXZPNLKFFN6W7SD2KUB7NBPLN
        tx.fee: 100
        tx.seqNum: 46489056724385793
        tx.memo.type: MEMO_ID
        tx.memo.id: not_a_number
        tx.operations.len: 0
        tx.ext.v: 0
        signatures.len: 0
        """

        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: txRep)) { error in
            if case TxRepError.invalidValue(let key) = error {
                XCTAssertTrue(key.contains("memo.id"))
            } else {
                XCTFail("Expected invalidValue error for memo.id")
            }
        }
    }

    func testFromTxRepMissingMemoHashValue() throws {
        let txRep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: GAVRMS4QIOCC4QMOSKILOOOHCSO4FEKOXZPNLKFFN6W7SD2KUB7NBPLN
        tx.fee: 100
        tx.seqNum: 46489056724385793
        tx.memo.type: MEMO_HASH
        tx.operations.len: 0
        tx.ext.v: 0
        signatures.len: 0
        """

        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: txRep)) { error in
            if case TxRepError.missingValue(let key) = error {
                XCTAssertTrue(key.contains("memo.hash"))
            } else {
                XCTFail("Expected missingValue error for memo.hash")
            }
        }
    }

    func testFromTxRepInvalidMemoHashValue() throws {
        let txRep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: GAVRMS4QIOCC4QMOSKILOOOHCSO4FEKOXZPNLKFFN6W7SD2KUB7NBPLN
        tx.fee: 100
        tx.seqNum: 46489056724385793
        tx.memo.type: MEMO_HASH
        tx.memo.hash: not_valid_hex
        tx.operations.len: 0
        tx.ext.v: 0
        signatures.len: 0
        """

        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: txRep)) { error in
            if case TxRepError.invalidValue(let key) = error {
                XCTAssertTrue(key.contains("memo.hash"))
            } else {
                XCTFail("Expected invalidValue error for memo.hash")
            }
        }
    }

    func testFromTxRepMissingMemoReturnValue() throws {
        let txRep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: GAVRMS4QIOCC4QMOSKILOOOHCSO4FEKOXZPNLKFFN6W7SD2KUB7NBPLN
        tx.fee: 100
        tx.seqNum: 46489056724385793
        tx.memo.type: MEMO_RETURN
        tx.operations.len: 0
        tx.ext.v: 0
        signatures.len: 0
        """

        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: txRep)) { error in
            if case TxRepError.missingValue(let key) = error {
                XCTAssertTrue(key.contains("memo.retHash"))
            } else {
                XCTFail("Expected missingValue error for memo.retHash")
            }
        }
    }

    func testFromTxRepInvalidMemoReturnValue() throws {
        let txRep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: GAVRMS4QIOCC4QMOSKILOOOHCSO4FEKOXZPNLKFFN6W7SD2KUB7NBPLN
        tx.fee: 100
        tx.seqNum: 46489056724385793
        tx.memo.type: MEMO_RETURN
        tx.memo.retHash: not_valid_hex
        tx.operations.len: 0
        tx.ext.v: 0
        signatures.len: 0
        """

        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: txRep)) { error in
            if case TxRepError.invalidValue(let key) = error {
                XCTAssertTrue(key.contains("memo.retHash"))
            } else {
                XCTFail("Expected invalidValue error for memo.retHash")
            }
        }
    }

    // MARK: - Fee Bump Transaction Tests

    func testFromTxRepFeeBumpMissingFee() throws {
        let txRep = """
        type: ENVELOPE_TYPE_TX_FEE_BUMP
        feeBump.tx.feeSource: GAVRMS4QIOCC4QMOSKILOOOHCSO4FEKOXZPNLKFFN6W7SD2KUB7NBPLN
        feeBump.tx.innerTx.type: ENVELOPE_TYPE_TX
        feeBump.tx.innerTx.tx.sourceAccount: GAVRMS4QIOCC4QMOSKILOOOHCSO4FEKOXZPNLKFFN6W7SD2KUB7NBPLN
        feeBump.tx.innerTx.tx.fee: 100
        feeBump.tx.innerTx.tx.seqNum: 46489056724385793
        feeBump.tx.innerTx.tx.memo.type: MEMO_NONE
        feeBump.tx.innerTx.tx.operations.len: 0
        feeBump.tx.innerTx.tx.ext.v: 0
        feeBump.tx.innerTx.signatures.len: 0
        feeBump.tx.ext.v: 0
        feeBump.signatures.len: 0
        """

        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: txRep)) { error in
            if case TxRepError.missingValue(let key) = error {
                XCTAssertTrue(key.contains("feeBump.tx.fee"))
            } else {
                XCTFail("Expected missingValue error for feeBump.tx.fee")
            }
        }
    }

    func testFromTxRepFeeBumpInvalidFee() throws {
        let txRep = """
        type: ENVELOPE_TYPE_TX_FEE_BUMP
        feeBump.tx.feeSource: GAVRMS4QIOCC4QMOSKILOOOHCSO4FEKOXZPNLKFFN6W7SD2KUB7NBPLN
        feeBump.tx.fee: invalid
        feeBump.tx.innerTx.type: ENVELOPE_TYPE_TX
        feeBump.tx.innerTx.tx.sourceAccount: GAVRMS4QIOCC4QMOSKILOOOHCSO4FEKOXZPNLKFFN6W7SD2KUB7NBPLN
        feeBump.tx.innerTx.tx.fee: 100
        feeBump.tx.innerTx.tx.seqNum: 46489056724385793
        feeBump.tx.innerTx.tx.memo.type: MEMO_NONE
        feeBump.tx.innerTx.tx.operations.len: 0
        feeBump.tx.innerTx.tx.ext.v: 0
        feeBump.tx.innerTx.signatures.len: 0
        feeBump.tx.ext.v: 0
        feeBump.signatures.len: 0
        """

        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: txRep)) { error in
            if case TxRepError.invalidValue(let key) = error {
                XCTAssertTrue(key.contains("feeBump.tx.fee"))
            } else {
                XCTFail("Expected invalidValue error for feeBump.tx.fee")
            }
        }
    }

    func testFromTxRepFeeBumpMissingFeeSource() throws {
        let txRep = """
        type: ENVELOPE_TYPE_TX_FEE_BUMP
        feeBump.tx.fee: 200
        feeBump.tx.innerTx.type: ENVELOPE_TYPE_TX
        feeBump.tx.innerTx.tx.sourceAccount: GAVRMS4QIOCC4QMOSKILOOOHCSO4FEKOXZPNLKFFN6W7SD2KUB7NBPLN
        feeBump.tx.innerTx.tx.fee: 100
        feeBump.tx.innerTx.tx.seqNum: 46489056724385793
        feeBump.tx.innerTx.tx.memo.type: MEMO_NONE
        feeBump.tx.innerTx.tx.operations.len: 0
        feeBump.tx.innerTx.tx.ext.v: 0
        feeBump.tx.innerTx.signatures.len: 0
        feeBump.tx.ext.v: 0
        feeBump.signatures.len: 0
        """

        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: txRep)) { error in
            if case TxRepError.missingValue(let key) = error {
                XCTAssertTrue(key.contains("feeBump.tx.feeSource"))
            } else {
                XCTFail("Expected missingValue error for feeBump.tx.feeSource")
            }
        }
    }

    func testFromTxRepFeeBumpInvalidFeeSource() throws {
        let txRep = """
        type: ENVELOPE_TYPE_TX_FEE_BUMP
        feeBump.tx.feeSource: INVALID
        feeBump.tx.fee: 200
        feeBump.tx.innerTx.type: ENVELOPE_TYPE_TX
        feeBump.tx.innerTx.tx.sourceAccount: GAVRMS4QIOCC4QMOSKILOOOHCSO4FEKOXZPNLKFFN6W7SD2KUB7NBPLN
        feeBump.tx.innerTx.tx.fee: 100
        feeBump.tx.innerTx.tx.seqNum: 46489056724385793
        feeBump.tx.innerTx.tx.memo.type: MEMO_NONE
        feeBump.tx.innerTx.tx.operations.len: 0
        feeBump.tx.innerTx.tx.ext.v: 0
        feeBump.tx.innerTx.signatures.len: 0
        feeBump.tx.ext.v: 0
        feeBump.signatures.len: 0
        """

        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: txRep)) { error in
            if case TxRepError.invalidValue(let key) = error {
                XCTAssertTrue(key.contains("feeBump.tx.feeSource"))
            } else {
                XCTFail("Expected invalidValue error for feeBump.tx.feeSource")
            }
        }
    }

    // MARK: - Signature Tests

    func testFromTxRepMissingSignatureHint() throws {
        let txRep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: GAVRMS4QIOCC4QMOSKILOOOHCSO4FEKOXZPNLKFFN6W7SD2KUB7NBPLN
        tx.fee: 100
        tx.seqNum: 46489056724385793
        tx.cond.type: PRECOND_NONE
        tx.memo.type: MEMO_NONE
        tx.operations.len: 1
        tx.operations[0].sourceAccount._present: false
        tx.operations[0].body.type: BUMP_SEQUENCE
        tx.operations[0].body.bumpSequenceOp.bumpTo: 46489056724385800
        tx.ext.v: 0
        signatures.len: 1
        signatures[0].signature: abcd1234
        """

        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: txRep)) { error in
            if case TxRepError.missingValue(let key) = error {
                XCTAssertTrue(key.contains("hint"))
            } else {
                XCTFail("Expected missingValue error for signature hint")
            }
        }
    }

    func testFromTxRepInvalidSignatureHint() throws {
        let txRep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: GAVRMS4QIOCC4QMOSKILOOOHCSO4FEKOXZPNLKFFN6W7SD2KUB7NBPLN
        tx.fee: 100
        tx.seqNum: 46489056724385793
        tx.cond.type: PRECOND_NONE
        tx.memo.type: MEMO_NONE
        tx.operations.len: 1
        tx.operations[0].sourceAccount._present: false
        tx.operations[0].body.type: BUMP_SEQUENCE
        tx.operations[0].body.bumpSequenceOp.bumpTo: 46489056724385800
        tx.ext.v: 0
        signatures.len: 1
        signatures[0].hint: not_hex
        signatures[0].signature: abcd1234
        """

        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: txRep)) { error in
            if case TxRepError.invalidValue(let key) = error {
                XCTAssertTrue(key.contains("hint"))
            } else {
                XCTFail("Expected invalidValue error for signature hint")
            }
        }
    }

    func testFromTxRepMissingSignatureValue() throws {
        let txRep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: GAVRMS4QIOCC4QMOSKILOOOHCSO4FEKOXZPNLKFFN6W7SD2KUB7NBPLN
        tx.fee: 100
        tx.seqNum: 46489056724385793
        tx.cond.type: PRECOND_NONE
        tx.memo.type: MEMO_NONE
        tx.operations.len: 1
        tx.operations[0].sourceAccount._present: false
        tx.operations[0].body.type: BUMP_SEQUENCE
        tx.operations[0].body.bumpSequenceOp.bumpTo: 46489056724385800
        tx.ext.v: 0
        signatures.len: 1
        signatures[0].hint: 4aa07ed0
        """

        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: txRep)) { error in
            if case TxRepError.missingValue(let key) = error {
                XCTAssertTrue(key.contains("signature"))
            } else {
                XCTFail("Expected missingValue error for signature")
            }
        }
    }

    func testFromTxRepInvalidSignatureValue() throws {
        let txRep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: GAVRMS4QIOCC4QMOSKILOOOHCSO4FEKOXZPNLKFFN6W7SD2KUB7NBPLN
        tx.fee: 100
        tx.seqNum: 46489056724385793
        tx.cond.type: PRECOND_NONE
        tx.memo.type: MEMO_NONE
        tx.operations.len: 1
        tx.operations[0].sourceAccount._present: false
        tx.operations[0].body.type: BUMP_SEQUENCE
        tx.operations[0].body.bumpSequenceOp.bumpTo: 46489056724385800
        tx.ext.v: 0
        signatures.len: 1
        signatures[0].hint: 4aa07ed0
        signatures[0].signature: not_hex
        """

        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: txRep)) { error in
            if case TxRepError.invalidValue(let key) = error {
                XCTAssertTrue(key.contains("signature"))
            } else {
                XCTFail("Expected invalidValue error for signature")
            }
        }
    }

    // MARK: - Preconditions with Ledger Bounds Tests

    func testTxRepWithLedgerBoundsPreconditions() throws {
        let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let destination = try KeyPair(accountId: "GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR")
        let account = Account(keyPair: source, sequenceNumber: 555555)

        let payment = try PaymentOperation(
            sourceAccountId: nil,
            destinationAccountId: destination.accountId,
            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
            amount: Decimal(20)
        )

        let ledgerBounds = LedgerBounds(minLedger: 100, maxLedger: 200)
        let preconditions = TransactionPreconditions(ledgerBounds: ledgerBounds)

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [payment],
            memo: Memo.none,
            preconditions: preconditions
        )

        try transaction.sign(keyPair: source, network: Network.testnet)

        let txRep = try TxRep.toTxRep(transactionEnvelope: transaction.encodedEnvelope())

        XCTAssertTrue(txRep.contains("tx.cond.type: PRECOND_V2"))
        XCTAssertTrue(txRep.contains("tx.cond.v2.ledgerBounds._present: true"))
        XCTAssertTrue(txRep.contains("tx.cond.v2.ledgerBounds.minLedger: 100"))
        XCTAssertTrue(txRep.contains("tx.cond.v2.ledgerBounds.maxLedger: 200"))

        let reconstructed = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(try transaction.encodedEnvelope(), reconstructed)
    }

    func testTxRepWithTimeBoundsAndLedgerBounds() throws {
        let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let destination = try KeyPair(accountId: "GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR")
        let account = Account(keyPair: source, sequenceNumber: 666666)

        let payment = try PaymentOperation(
            sourceAccountId: nil,
            destinationAccountId: destination.accountId,
            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
            amount: Decimal(30)
        )

        let timeBounds = TimeBounds(minTime: 1640000000, maxTime: 1650000000)
        let ledgerBounds = LedgerBounds(minLedger: 500, maxLedger: 1000)
        let preconditions = TransactionPreconditions(ledgerBounds: ledgerBounds, timeBounds: timeBounds)

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [payment],
            memo: Memo.none,
            preconditions: preconditions
        )

        try transaction.sign(keyPair: source, network: Network.testnet)

        let txRep = try TxRep.toTxRep(transactionEnvelope: transaction.encodedEnvelope())

        XCTAssertTrue(txRep.contains("tx.cond.type: PRECOND_V2"))
        XCTAssertTrue(txRep.contains("tx.cond.v2.timeBounds._present: true"))
        XCTAssertTrue(txRep.contains("tx.cond.v2.timeBounds.minTime: 1640000000"))
        XCTAssertTrue(txRep.contains("tx.cond.v2.timeBounds.maxTime: 1650000000"))
        XCTAssertTrue(txRep.contains("tx.cond.v2.ledgerBounds._present: true"))
        XCTAssertTrue(txRep.contains("tx.cond.v2.ledgerBounds.minLedger: 500"))
        XCTAssertTrue(txRep.contains("tx.cond.v2.ledgerBounds.maxLedger: 1000"))

        let reconstructed = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(try transaction.encodedEnvelope(), reconstructed)
    }

    func testTxRepWithMinSeqNumPrecondition() throws {
        let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let destination = try KeyPair(accountId: "GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR")
        let account = Account(keyPair: source, sequenceNumber: 777777)

        let payment = try PaymentOperation(
            sourceAccountId: nil,
            destinationAccountId: destination.accountId,
            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
            amount: Decimal(40)
        )

        let preconditions = TransactionPreconditions(minSeqNumber: 100000)

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [payment],
            memo: Memo.none,
            preconditions: preconditions
        )

        try transaction.sign(keyPair: source, network: Network.testnet)

        let txRep = try TxRep.toTxRep(transactionEnvelope: transaction.encodedEnvelope())

        XCTAssertTrue(txRep.contains("tx.cond.type: PRECOND_V2"))
        XCTAssertTrue(txRep.contains("tx.cond.v2.minSeqNum._present: true"))
        XCTAssertTrue(txRep.contains("tx.cond.v2.minSeqNum: 100000"))

        let reconstructed = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(try transaction.encodedEnvelope(), reconstructed)
    }

    func testTxRepWithMinSeqAgeAndMinSeqLedgerGap() throws {
        let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let destination = try KeyPair(accountId: "GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR")
        let account = Account(keyPair: source, sequenceNumber: 888888)

        let payment = try PaymentOperation(
            sourceAccountId: nil,
            destinationAccountId: destination.accountId,
            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
            amount: Decimal(50)
        )

        let preconditions = TransactionPreconditions(minSeqAge: 3600, minSeqLedgerGap: 10)

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [payment],
            memo: Memo.none,
            preconditions: preconditions
        )

        try transaction.sign(keyPair: source, network: Network.testnet)

        let txRep = try TxRep.toTxRep(transactionEnvelope: transaction.encodedEnvelope())

        XCTAssertTrue(txRep.contains("tx.cond.type: PRECOND_V2"))
        XCTAssertTrue(txRep.contains("tx.cond.v2.minSeqAge: 3600"))
        XCTAssertTrue(txRep.contains("tx.cond.v2.minSeqLedgerGap: 10"))

        let reconstructed = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(try transaction.encodedEnvelope(), reconstructed)
    }

    // MARK: - Operation Source Account Tests

    func testTxRepOperationWithSourceAccount() throws {
        let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let destination = try KeyPair(accountId: "GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR")
        let opSource = try KeyPair.generateRandomKeyPair()
        let account = Account(keyPair: source, sequenceNumber: 999999)

        let payment = try PaymentOperation(
            sourceAccountId: opSource.accountId,
            destinationAccountId: destination.accountId,
            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
            amount: Decimal(60)
        )

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [payment],
            memo: Memo.none
        )

        try transaction.sign(keyPair: source, network: Network.testnet)

        let txRep = try TxRep.toTxRep(transactionEnvelope: transaction.encodedEnvelope())

        XCTAssertTrue(txRep.contains("tx.operations[0].sourceAccount._present: true"))
        XCTAssertTrue(txRep.contains("tx.operations[0].sourceAccount: \(opSource.accountId)"))

        let reconstructed = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(try transaction.encodedEnvelope(), reconstructed)
    }

    // MARK: - Comment Removal Tests

    func testFromTxRepWithComments() throws {
        let txRep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: GAVRMS4QIOCC4QMOSKILOOOHCSO4FEKOXZPNLKFFN6W7SD2KUB7NBPLN
        tx.fee: 100 (comment here)
        tx.seqNum: 46489056724385793
        tx.cond.type: PRECOND_NONE
        tx.memo.type: MEMO_NONE
        tx.operations.len: 1
        tx.operations[0].sourceAccount._present: false
        tx.operations[0].body.type: BUMP_SEQUENCE
        tx.operations[0].body.bumpSequenceOp.bumpTo: 46489056724385800
        tx.ext.v: 0
        signatures.len: 0
        """

        let envelope = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertFalse(envelope.isEmpty)

        let transaction = try Transaction(envelopeXdr: envelope)
        XCTAssertEqual(transaction.fee, 100)
    }

    func testFromTxRepWithMultipleColons() throws {
        let txRep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: GAVRMS4QIOCC4QMOSKILOOOHCSO4FEKOXZPNLKFFN6W7SD2KUB7NBPLN
        tx.fee: 100
        tx.seqNum: 46489056724385793
        tx.cond.type: PRECOND_NONE
        tx.memo.type: MEMO_TEXT
        tx.memo.text: "test:value:with:colons"
        tx.operations.len: 1
        tx.operations[0].sourceAccount._present: false
        tx.operations[0].body.type: BUMP_SEQUENCE
        tx.operations[0].body.bumpSequenceOp.bumpTo: 46489056724385800
        tx.ext.v: 0
        signatures.len: 0
        """

        let envelope = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertFalse(envelope.isEmpty)

        let transaction = try Transaction(envelopeXdr: envelope)
        if case .text(let text) = transaction.memo {
            XCTAssertEqual(text, "test:value:with:colons")
        } else {
            XCTFail("Expected MEMO_TEXT")
        }
    }

    // MARK: - Empty Transaction Tests

    func testTxRepWithNoOperations() throws {
        // XDR spec allows 0 operations; TxRep must accept them for interop with
        // Flutter/PHP and for pre-submission inspection of unsigned transactions.
        let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")

        let txRep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: \(source.accountId)
        tx.fee: 100
        tx.seqNum: 100001
        tx.cond.type: PRECOND_NONE
        tx.memo.type: MEMO_NONE
        tx.operations.len: 0
        tx.ext.v: 0
        signatures.len: 0
        """

        let base64 = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertFalse(base64.isEmpty, "Expected non-empty base64 for 0-operation envelope")

        // Decode and verify the envelope has exactly 0 operations.
        let envelope = try TransactionEnvelopeXDR(fromBase64: base64)
        switch envelope {
        case .v1(let v1env):
            XCTAssertEqual(v1env.tx.operations.count, 0, "Envelope must have 0 operations")
        default:
            XCTFail("Expected V1 envelope type")
        }

        // Roundtrip: re-serialise and parse again, confirming idempotence.
        let txRep2 = try TxRep.toTxRep(transactionEnvelope: base64)
        let base64Again = try TxRep.fromTxRep(txRep: txRep2)
        XCTAssertEqual(base64, base64Again, "Zero-operation envelope must roundtrip to identical XDR")
    }

    func testTxRepWithNoSignatures() throws {
        let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let destination = try KeyPair(accountId: "GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR")
        let account = Account(keyPair: source, sequenceNumber: 200000)

        let payment = try PaymentOperation(
            sourceAccountId: nil,
            destinationAccountId: destination.accountId,
            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
            amount: Decimal(70)
        )

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [payment],
            memo: Memo.none
        )

        let txRep = try TxRep.toTxRep(transactionEnvelope: transaction.encodedEnvelope())

        XCTAssertTrue(txRep.contains("signatures.len: 0"))

        let reconstructed = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(try transaction.encodedEnvelope(), reconstructed)
    }

    // MARK: - Asset Encoding Tests

    func testTxRepWithNativeAsset() throws {
        let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let destination = try KeyPair(accountId: "GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR")
        let account = Account(keyPair: source, sequenceNumber: 300000)

        let payment = try PaymentOperation(
            sourceAccountId: nil,
            destinationAccountId: destination.accountId,
            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
            amount: Decimal(80)
        )

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [payment],
            memo: Memo.none
        )

        try transaction.sign(keyPair: source, network: Network.testnet)

        let txRep = try TxRep.toTxRep(transactionEnvelope: transaction.encodedEnvelope())

        XCTAssertTrue(txRep.contains("tx.operations[0].body.paymentOp.asset: XLM"))

        let reconstructed = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(try transaction.encodedEnvelope(), reconstructed)
    }

    func testTxRepWithCreditAlphanum4Asset() throws {
        let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let destination = try KeyPair(accountId: "GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR")
        let issuer = try KeyPair(accountId: "GCMUFBSB6OB6R2MJKXB5G5UXZHE3XO4H5T4FNV2VDVMQRJZEQHWJFRP5")
        let account = Account(keyPair: source, sequenceNumber: 400000)

        let asset = Asset(canonicalForm: "USD:\(issuer.accountId)")!
        let payment = try PaymentOperation(
            sourceAccountId: nil,
            destinationAccountId: destination.accountId,
            asset: asset,
            amount: Decimal(90)
        )

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [payment],
            memo: Memo.none
        )

        try transaction.sign(keyPair: source, network: Network.testnet)

        let txRep = try TxRep.toTxRep(transactionEnvelope: transaction.encodedEnvelope())

        XCTAssertTrue(txRep.contains("tx.operations[0].body.paymentOp.asset: USD:\(issuer.accountId)"))

        let reconstructed = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(try transaction.encodedEnvelope(), reconstructed)
    }

    func testTxRepWithCreditAlphanum12Asset() throws {
        let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let destination = try KeyPair(accountId: "GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR")
        let issuer = try KeyPair(accountId: "GCMUFBSB6OB6R2MJKXB5G5UXZHE3XO4H5T4FNV2VDVMQRJZEQHWJFRP5")
        let account = Account(keyPair: source, sequenceNumber: 500000)

        let asset = Asset(canonicalForm: "LONGASSET123:\(issuer.accountId)")!
        let payment = try PaymentOperation(
            sourceAccountId: nil,
            destinationAccountId: destination.accountId,
            asset: asset,
            amount: Decimal(100)
        )

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [payment],
            memo: Memo.none
        )

        try transaction.sign(keyPair: source, network: Network.testnet)

        let txRep = try TxRep.toTxRep(transactionEnvelope: transaction.encodedEnvelope())

        XCTAssertTrue(txRep.contains("tx.operations[0].body.paymentOp.asset: LONGASSET123:\(issuer.accountId)"))

        let reconstructed = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(try transaction.encodedEnvelope(), reconstructed)
    }

    // MARK: - Operation Missing Type Test

    func testFromTxRepOperationMissingType() throws {
        let txRep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: GAVRMS4QIOCC4QMOSKILOOOHCSO4FEKOXZPNLKFFN6W7SD2KUB7NBPLN
        tx.fee: 100
        tx.seqNum: 46489056724385793
        tx.memo.type: MEMO_NONE
        tx.operations.len: 1
        tx.operations[0].sourceAccount._present: false
        tx.ext.v: 0
        signatures.len: 0
        """

        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: txRep)) { error in
            if case TxRepError.missingValue(let key) = error {
                XCTAssertTrue(key.contains("type"))
            } else {
                XCTFail("Expected missingValue error for operation type")
            }
        }
    }

    func testFromTxRepInvalidOperationType() throws {
        let txRep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: GAVRMS4QIOCC4QMOSKILOOOHCSO4FEKOXZPNLKFFN6W7SD2KUB7NBPLN
        tx.fee: 100
        tx.seqNum: 46489056724385793
        tx.memo.type: MEMO_NONE
        tx.operations.len: 1
        tx.operations[0].sourceAccount._present: false
        tx.operations[0].body.type: INVALID_OPERATION
        tx.ext.v: 0
        signatures.len: 0
        """

        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: txRep)) { error in
            if case TxRepError.invalidValue(let key) = error {
                XCTAssertTrue(key.contains("type"))
            } else {
                XCTFail("Expected invalidValue error for operation type")
            }
        }
    }

    // MARK: - Large Transaction Tests

    func testTxRepWithMaxOperations() throws {
        let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let destination = try KeyPair(accountId: "GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR")
        let account = Account(keyPair: source, sequenceNumber: 600000)

        var operations: [stellarsdk.Operation] = []
        for _ in 0..<100 {
            let payment = try PaymentOperation(
                sourceAccountId: nil,
                destinationAccountId: destination.accountId,
                asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
                amount: Decimal(1)
            )
            operations.append(payment)
        }

        let transaction = try Transaction(
            sourceAccount: account,
            operations: operations,
            memo: Memo.none
        )

        try transaction.sign(keyPair: source, network: Network.testnet)

        let txRep = try TxRep.toTxRep(transactionEnvelope: transaction.encodedEnvelope())

        XCTAssertTrue(txRep.contains("tx.operations.len: 100"))

        let reconstructed = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(try transaction.encodedEnvelope(), reconstructed)
    }

    func testTxRepWithMaxSignatures() throws {
        let source = try KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        let destination = try KeyPair(accountId: "GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR")
        let account = Account(keyPair: source, sequenceNumber: 700000)

        let payment = try PaymentOperation(
            sourceAccountId: nil,
            destinationAccountId: destination.accountId,
            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
            amount: Decimal(110)
        )

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [payment],
            memo: Memo.none
        )

        try transaction.sign(keyPair: source, network: Network.testnet)

        for _ in 1..<20 {
            let signer = try KeyPair.generateRandomKeyPair()
            try transaction.sign(keyPair: signer, network: Network.testnet)
        }

        let txRep = try TxRep.toTxRep(transactionEnvelope: transaction.encodedEnvelope())

        XCTAssertTrue(txRep.contains("signatures.len: 20"))

        let reconstructed = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(try transaction.encodedEnvelope(), reconstructed)
    }

    // MARK: - Invalid XDR Tests

    func testToTxRepInvalidXDR() throws {
        let invalidXDR = "THIS_IS_NOT_VALID_XDR"

        XCTAssertThrowsError(try TxRep.toTxRep(transactionEnvelope: invalidXDR)) { error in
            // Should throw an error when parsing invalid XDR
        }
    }

    func testToTxRepEmptyString() throws {
        let emptyXDR = ""

        XCTAssertThrowsError(try TxRep.toTxRep(transactionEnvelope: emptyXDR)) { error in
            // Should throw an error for empty string
        }
    }

    private let numericArrayKey = "tx.sorobanData.ext.resourceExt.archivedSorobanEntries"

    private func numericTxRep(_ fields: [String: String]) -> String {
        var values = [
            "type": "ENVELOPE_TYPE_TX",
            "tx.sourceAccount": "GAVRMS4QIOCC4QMOSKILOOOHCSO4FEKOXZPNLKFFN6W7SD2KUB7NBPLN",
            "tx.fee": "100", "tx.seqNum": "1", "tx.cond.type": "PRECOND_NONE",
            "tx.memo.type": "MEMO_NONE", "tx.operations.len": "0", "tx.ext.v": "1",
            "tx.sorobanData.ext.v": "1", "signatures.len": "0"
        ]
        values.merge(fields) { _, new in new }
        return values.keys.sorted().map { "\($0): \(values[$0]!)" }.joined(separator: "\n")
    }

    private func assertInvalidNumericTxRep(_ fields: [String: String], key: String, line: UInt = #line) {
        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: numericTxRep(fields)), key, line: line) { error in
            guard case TxRepError.invalidValue(let actual) = error else {
                return XCTFail("Expected invalidValue, got \(error)", line: line)
            }
            XCTAssertEqual(actual, key, line: line)
        }
    }

    private func priceFields(_ value: String) -> [String: String] {
        let prefix = "tx.operations[0].body.manageSellOfferOp"
        return ["tx.operations.len": "1", "tx.operations[0].body.type": "MANAGE_SELL_OFFER",
                "\(prefix).selling": "native", "\(prefix).buying": "native",
                "\(prefix).price.n": value, "\(prefix).price.d": "1"]
    }

    func testInt32FieldRejectsLargeHexMagnitude() throws {
        for input in ["0x8000000000000000", "-0x8000000000000001"] {
            assertInvalidNumericTxRep(priceFields(input), key: input)
        }
        for input in [Int32.min, Int32.max] {
            let xdr = try TxRep.fromTxRep(txRep: numericTxRep(priceFields(String(input))))
            let values = TxRepHelper.parse(try TxRep.toTxRep(transactionEnvelope: xdr))
            XCTAssertEqual(values["tx.operations[0].body.manageSellOfferOp.price.n"], String(input))
        }
    }

    func testNegativeNumericArrayLength() {
        assertInvalidNumericTxRep(["\(numericArrayKey).len": "-1"], key: "\(numericArrayKey).len: -1")

        let body = "tx.operations[0].body"
        let hostFunction = "\(body).invokeHostFunctionOp.hostFunction"
        let invoke = "\(hostFunction).invokeContract"
        let argument = "\(invoke).args[0]"
        let invokeFields = [
            "tx.operations.len": "1", "\(body).type": "INVOKE_HOST_FUNCTION",
            "\(hostFunction).type": "HOST_FUNCTION_TYPE_INVOKE_CONTRACT",
            "\(invoke).contractAddress.type": "SC_ADDRESS_TYPE_CONTRACT",
            "\(invoke).contractAddress.contractId": String(repeating: "0", count: 64),
            "\(invoke).functionName": "\"test\"", "\(invoke).args.len": "1"
        ]
        for (fields, lengthKey) in [
            (["\(argument).type": "SCV_VEC", "\(argument).vec._present": "true",
              "\(argument).vec.len": "-1"], "\(argument).vec.len"),
            (["\(argument).type": "SCV_CONTRACT_INSTANCE",
              "\(argument).instance.executable.type": "CONTRACT_EXECUTABLE_STELLAR_ASSET",
              "\(argument).instance.storage._present": "true",
              "\(argument).instance.storage.len": "-1"], "\(argument).instance.storage.len")
        ] {
            assertInvalidNumericTxRep(invokeFields.merging(fields) { _, new in new }, key: "\(lengthKey): -1")
        }

        let destination = "GAVRMS4QIOCC4QMOSKILOOOHCSO4FEKOXZPNLKFFN6W7SD2KUB7NBPLN"
        let pathPayment = "\(body).pathPaymentStrictSendOp"
        assertInvalidNumericTxRep([
            "tx.operations.len": "1", "\(body).type": "PATH_PAYMENT_STRICT_SEND",
            "\(pathPayment).sendAsset": "native", "\(pathPayment).sendAmount": "1",
            "\(pathPayment).destination": destination, "\(pathPayment).destAsset": "native",
            "\(pathPayment).destMin": "1", "\(pathPayment).path.len": "-1"
        ], key: "\(pathPayment).path.len: -1")

        let balance = "\(body).createClaimableBalanceOp"
        let claimant = "\(balance).claimants[0]"
        let predicate = "\(claimant).v0.predicate"
        assertInvalidNumericTxRep([
            "tx.operations.len": "1", "\(body).type": "CREATE_CLAIMABLE_BALANCE",
            "\(balance).asset": "native", "\(balance).amount": "1", "\(balance).claimants.len": "1",
            "\(claimant).type": "CLAIMANT_TYPE_V0", "\(claimant).v0.destination": destination,
            "\(predicate).type": "CLAIM_PREDICATE_AND", "\(predicate).andPredicates.len": "-1"
        ], key: "\(predicate).andPredicates.len: -1")
    }

    func testBoundedArrayMaximums() throws {
        let destination = "GAVRMS4QIOCC4QMOSKILOOOHCSO4FEKOXZPNLKFFN6W7SD2KUB7NBPLN"
        let body = "tx.operations[0].body"
        let balance = "\(body).createClaimableBalanceOp"
        let predicate = "\(balance).claimants[0].v0.predicate"
        var cases: [(key: String, maximum: Int, fields: [String: String])] = []
        for (operation, arm, amount) in [("PATH_PAYMENT_STRICT_SEND", "pathPaymentStrictSendOp", "destMin"),
                                         ("PATH_PAYMENT_STRICT_RECEIVE", "pathPaymentStrictReceiveOp", "destAmount")] {
            let prefix = "\(body).\(arm)"
            var fields = ["tx.operations.len": "1", "\(body).type": operation,
                          "\(prefix).sendAsset": "native", "\(prefix).sendAmount": "1", "\(prefix).sendMax": "1",
                          "\(prefix).destination": destination, "\(prefix).destAsset": "native", "\(prefix).\(amount)": "1"]
            for i in 0..<6 { fields["\(prefix).path[\(i)]"] = "native" }
            cases.append(("\(prefix).path", 5, fields))
        }
        var claimants = ["tx.operations.len": "1", "\(body).type": "CREATE_CLAIMABLE_BALANCE",
                         "\(balance).asset": "native", "\(balance).amount": "1"]
        for i in 0..<11 {
            claimants["\(balance).claimants[\(i)].type"] = "CLAIMANT_TYPE_V0"
            claimants["\(balance).claimants[\(i)].v0.destination"] = destination
            claimants["\(balance).claimants[\(i)].v0.predicate.type"] = "CLAIM_PREDICATE_UNCONDITIONAL"
        }
        cases.append(("\(balance).claimants", 10, claimants))
        for (type, arm) in [("CLAIM_PREDICATE_AND", "andPredicates"), ("CLAIM_PREDICATE_OR", "orPredicates")] {
            var fields = claimants.merging(["\(balance).claimants.len": "1", "\(predicate).type": type]) { _, new in new }
            for i in 0..<3 { fields["\(predicate).\(arm)[\(i)].type"] = "CLAIM_PREDICATE_UNCONDITIONAL" }
            cases.append(("\(predicate).\(arm)", 2, fields))
        }
        var signers = ["tx.cond.type": "PRECOND_V2"]
        for i in 0..<3 { signers["tx.cond.v2.extraSigners[\(i)]"] = destination }
        cases.append(("tx.cond.v2.extraSigners", 2, signers))
        for (key, maximum, fixture) in cases {
            var fields = fixture
            fields["\(key).len"] = String(maximum + 1)
            assertInvalidNumericTxRep(fields, key: "\(key).len: \(maximum + 1)")
            fields["\(key).len"] = String(maximum)
            fields = fields.filter { !$0.key.hasPrefix("\(key)[\(maximum)]") }
            let xdr = try TxRep.fromTxRep(txRep: numericTxRep(fields))
            let values = TxRepHelper.parse(try TxRep.toTxRep(transactionEnvelope: xdr))
            XCTAssertEqual(values["\(key).len"], String(maximum), key)
        }
    }

    func testDirectPathPaymentArrayMaximum() throws {
        let prefix = "tx.operations[0].body.pathPaymentStrictReceiveOp"
        var fields = ["\(prefix).sendAsset": "native", "\(prefix).sendMax": "1",
                      "\(prefix).destination": "GAVRMS4QIOCC4QMOSKILOOOHCSO4FEKOXZPNLKFFN6W7SD2KUB7NBPLN",
                      "\(prefix).destAsset": "native", "\(prefix).destAmount": "1", "\(prefix).path.len": "6"]
        for i in 0..<6 { fields["\(prefix).path[\(i)]"] = "native" }
        XCTAssertThrowsError(try PathPaymentOperationXDR.fromTxRep(fields, prefix: prefix)) { error in
            guard case TxRepError.invalidValue(let key) = error else {
                return XCTFail("Expected invalidValue, got \(error)")
            }
            XCTAssertEqual(key, "\(prefix).path.len: 6")
        }
        fields["\(prefix).path.len"] = "5"
        fields.removeValue(forKey: "\(prefix).path[5]")
        let operation = try PathPaymentOperationXDR.fromTxRep(fields, prefix: prefix)
        XCTAssertEqual(operation.path.count, 5)
    }

    func testUInt32ScalarOverflow() {
        assertInvalidNumericTxRep(["tx.sorobanData.resources.instructions": "4294967296"], key: "4294967296")
    }

    func testUInt32ArrayLengthRejectsInt32Max() {
        assertInvalidNumericTxRep(["\(numericArrayKey).len": "2147483647"],
                                 key: "\(numericArrayKey).len: 2147483647")
    }

    func testUInt32ArrayLengthLineCountBoundary() throws {
        let key = "\(numericArrayKey).len"
        var fields = [key: "0"]
        let lineCount = numericTxRep(fields).split(separator: "\n").count
        fields[key] = String(lineCount)
        let xdr = try TxRep.fromTxRep(txRep: numericTxRep(fields))
        let values = TxRepHelper.parse(try TxRep.toTxRep(transactionEnvelope: xdr))
        XCTAssertEqual(values[key], String(lineCount))
        for i in 0..<lineCount {
            XCTAssertEqual(values["\(numericArrayKey)[\(i)]"], "0")
        }
        fields[key] = String(lineCount + 1)
        assertInvalidNumericTxRep(fields, key: "\(key): \(lineCount + 1)")
    }

    func testUInt32ArrayElementRangeAndSparseDefaults() throws {
        assertInvalidNumericTxRep(["\(numericArrayKey).len": "1", "\(numericArrayKey)[0]": "4294967296"], key: "4294967296")
        for count in [0, 3] {
            var fields = ["\(numericArrayKey).len": String(count), "tx.sorobanData.resources.instructions": "4294967295"]
            if count > 0 { fields["\(numericArrayKey)[1]"] = "4294967295" }
            let xdr = try TxRep.fromTxRep(txRep: numericTxRep(fields))
            let values = TxRepHelper.parse(try TxRep.toTxRep(transactionEnvelope: xdr))
            XCTAssertEqual(values["\(numericArrayKey).len"], String(count))
            XCTAssertEqual(values["tx.sorobanData.resources.instructions"], "4294967295")
            if count > 0 {
                XCTAssertEqual(values["\(numericArrayKey)[0]"], "0")
                XCTAssertEqual(values["\(numericArrayKey)[1]"], "4294967295")
                XCTAssertEqual(values["\(numericArrayKey)[2]"], "0")
            }
        }
    }
}
