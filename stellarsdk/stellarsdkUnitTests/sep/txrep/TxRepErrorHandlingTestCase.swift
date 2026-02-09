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

        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: txRep)) { error in
            if case TxRepError.missingValue(let key) = error {
                XCTAssertTrue(key.contains("signatures.len"))
            } else {
                XCTFail("Expected missingValue error for signatures.len")
            }
        }
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
                XCTAssertTrue(key.contains("memo.return"))
            } else {
                XCTFail("Expected missingValue error for memo.return")
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
        tx.memo.return: not_valid_hex
        tx.operations.len: 0
        tx.ext.v: 0
        signatures.len: 0
        """

        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: txRep)) { error in
            if case TxRepError.invalidValue(let key) = error {
                XCTAssertTrue(key.contains("memo.return"))
            } else {
                XCTFail("Expected invalidValue error for memo.return")
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

        // The SDK enforces that transactions must have at least one operation.
        // This test verifies that fromTxRep correctly rejects TxRep with 0 operations.
        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: txRep)) { error in
            guard case StellarSDKError.invalidArgument(let message) = error else {
                XCTFail("Expected invalidArgument error")
                return
            }
            XCTAssertTrue(message.contains("At least one operation required"))
        }
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
        let issuer = try KeyPair(accountId: "GCMUFBSB6OB6R2MJKXB5G5UXZHE3XO4H5T4FNV2VDVMQRJZEQHWJFHZV")
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
        let issuer = try KeyPair(accountId: "GCMUFBSB6OB6R2MJKXB5G5UXZHE3XO4H5T4FNV2VDVMQRJZEQHWJFHZV")
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
}
