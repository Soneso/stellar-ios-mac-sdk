//
//  File.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 04.08.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

public enum TxRepError: Error {
    case missingValue(key:String)
    case invalidValue(key:String)
}

public class TxRep: NSObject {
    
    public static func toTxRep(transactionEnvelope:String) throws ->String  {
        let xdrDecoder = XDRDecoder.init(data: [UInt8].init(base64: transactionEnvelope))
        let transactionEnvelopeXDR = try TransactionEnvelopeXDR(fromBinary: xdrDecoder)
        let transaction:Transaction = try Transaction(envelopeXdr: transactionEnvelope)
        var feeBumpTransaction:FeeBumpTransaction?
        var feeBumpSignatures = [DecoratedSignatureXDR]()
        switch transactionEnvelopeXDR {
        case .feeBump(let feeBumpXdr):
            let mux = try MuxedAccount(accountId: feeBumpXdr.tx.sourceAccount.accountId, sequenceNumber: 0, id: feeBumpXdr.tx.sourceAccount.id)
            feeBumpTransaction = try FeeBumpTransaction(sourceAccount: mux, fee: feeBumpXdr.tx.fee, innerTransaction: transaction)
            feeBumpSignatures = feeBumpXdr.signatures
        default:
            break;
        }
        let isFeeBump = feeBumpTransaction != nil
        var lines = [String]()
        let type = isFeeBump ? "ENVELOPE_TYPE_TX_FEE_BUMP" : "ENVELOPE_TYPE_TX";
        let prefix = isFeeBump ? "feeBump.tx.innerTx.tx." : "tx.";
        addLine(key: "type", value: type, lines: &lines);
        if let feeBump = feeBumpTransaction {
            addLine(key: "feeBump.tx.feeSource", value: feeBump.sourceAccount.keyPair.accountId, lines: &lines); //TODO: muxed
            addLine(key: "feeBump.tx.fee", value: String(feeBump.fee), lines: &lines);
            addLine(key: "feeBump.tx.innerTx.type", value: "ENVELOPE_TYPE_TX",lines: &lines);
        }
        addLine(key: prefix + "sourceAccount", value: transactionEnvelopeXDR.txSourceAccountId, lines: &lines) // TODO: muxed
        addLine(key: prefix + "fee", value: String(transactionEnvelopeXDR.txFee), lines: &lines)
        addLine(key: prefix + "seqNum", value: String(transactionEnvelopeXDR.txSeqNum), lines: &lines)
        addTimeBounds(timeBounds: transactionEnvelopeXDR.txTimeBounds, prefix: prefix, lines: &lines)
        try addMemo(memo: transactionEnvelopeXDR.txMemo, prefix: prefix, lines: &lines)
        addOperations(operations: transactionEnvelopeXDR.txOperations, prefix: prefix, lines: &lines)
        addLine(key: prefix + "ext.v", value: "0", lines: &lines)
        
        return lines.joined(separator: "\n");
    }
    
    private static func addOperation(operation:OperationXDR, index: Int, prefix:String, lines: inout [String]) -> Void {
        var operationPrefix = prefix + "operations[" + String(index) + "]."
        if let sourceAccount = operation.sourceAccount {
            addLine(key: operationPrefix + "sourceAccount._present", value: "true", lines: &lines)
            addLine(key: operationPrefix + "sourceAccount", value: sourceAccount.accountId, lines: &lines) // TODO change to M-StrKey
        } else {
            addLine(key: operationPrefix + "sourceAccount._present", value: "false", lines: &lines)
        }
        addLine(key: operationPrefix + "body.type", value: txRepOpTypeUpperCase(operation: operation), lines: &lines)
        
        operationPrefix = operationPrefix + "body." + txRepOpType(operation: operation) + "."
        
        switch operation.body {
        case .createAccount(let createAccountOp):
            addLine(key: operationPrefix + "destination", value: createAccountOp.destination.accountId, lines: &lines) // TODO "M..."
            addLine(key: operationPrefix + "startingBalance", value: String(createAccountOp.startingBalance), lines: &lines)
        case .payment(let paymentOperation):
            addLine(key: operationPrefix + "destination", value: paymentOperation.destination.accountId, lines: &lines) // TODO "M..."
            addLine(key: operationPrefix + "asset", value: encodeAsset(asset: paymentOperation.asset), lines: &lines)
            addLine(key: operationPrefix + "amount", value: String(paymentOperation.amount), lines: &lines)
        /*case .pathPayment(let pathPaymentStrictReceiveOp):
            break
        case .manageSellOffer(let manageSellOfferOp):
            break
        case .createPassiveSellOffer(let createPassiveSellOfferOp):
            break
        case .setOptions(let setOptionOp):
            break
        case .changeTrust(let changeTrustOp):
            break
        case .allowTrust(let allowTrustOp):
            break
        case .accountMerge(let accountMergeOp):
            break
        case .manageData(let manageDataOp):
            break
        case .inflation:
            break
        case .bumpSequence(let bumpOp):
            break
        case .manageBuyOffer(let manageBuyOfferOp):
            break
        case .pathPaymentStrictSend(let pathPaymentStrictSendOp):
            break*/
        default:
            break
        }
        
    }
    
    private static func encodeAsset(asset: AssetXDR) -> String {
        switch asset {
        case .native:
            return "XLM"
        default:
            return asset.assetCode + ":" + asset.issuer!.accountId
        }
    }
    
    private static func txRepOpType(operation: OperationXDR) -> String {
        switch operation.body {
        case .createAccount(_):
            return "createAccountOp"
        case .payment(_):
            return "paymentOp"
        case .pathPayment(_):
            return "pathPaymentStrictReceiveOp"
        case .manageSellOffer(_):
            return "manageSellOfferOp"
        case .createPassiveSellOffer(_):
            return "createPassiveSellOfferOp"
        case .setOptions(_):
            return "setOptionsOp"
        case .changeTrust(_):
            return "changeTrustOp"
        case .allowTrust(_):
            return "allowTrustOp"
        case .accountMerge(_):
            return "accountMergeOp"
        case .inflation:
            return "inflationOp"
        case .manageData(_):
            return "manageDataOp"
        case .bumpSequence(_):
            return "bumpSequenceOp"
        case .manageBuyOffer(_):
            return "manageBuyOfferOp"
        case .pathPaymentStrictSend(_):
            return "pathPaymentStrictSendOp"
        }
    }
    private static func txRepOpTypeUpperCase(operation: OperationXDR) -> String {
        switch operation.body {
        case .createAccount(_):
            return "CREATE_ACCOUNT"
        case .payment(_):
            return "PAYMENT"
        case .pathPayment(_):
            return "PATH_PAYMENT_STRICT_RECEIVE"
        case .manageSellOffer(_):
            return "MANAGE_SELL_OFFER"
        case .createPassiveSellOffer(_):
            return "CREATE_PASSIVE_SELL_OFFER"
        case .setOptions(_):
            return "SET_OPTIONS"
        case .changeTrust(_):
            return "CHANGE_TRUST"
        case .allowTrust(_):
            return "ALLOW_TRUST"
        case .accountMerge(_):
            return "ACCOUNT_MERGE"
        case .inflation:
            return "INFLATION"
        case .manageData(_):
            return "MANAGE_DATA"
        case .bumpSequence(_):
            return "BUMP_SEQUENCE"
        case .manageBuyOffer(_):
            return "MANAGE_BUY_OFFER"
        case .pathPaymentStrictSend(_):
            return "PATH_PAYMENT_STRICT_SEND"
        }
    }
    private static func addLine(key:String, value:String, lines: inout [String]) -> Void {
        lines.append(key + ": " + value);
    }
    
    private static func addTimeBounds(timeBounds:TimeBoundsXDR?, prefix:String, lines: inout [String]) -> Void {
        if let tb = timeBounds {
            addLine(key: prefix + "timeBounds._present", value: "true", lines: &lines)
            addLine(key: prefix + "timeBounds.minTime", value: String(tb.minTime), lines: &lines)
            addLine(key: prefix + "timeBounds.maxTime", value: String(tb.maxTime), lines: &lines)
        } else {
            addLine(key: prefix + "timeBounds._present", value: "false", lines: &lines)
        }
    }
    
    private static func addMemo(memo:MemoXDR, prefix:String, lines: inout [String])throws -> Void {
        switch memo {
        case .none:
            addLine(key: prefix + "memo.type", value: "MEMO_NONE", lines: &lines)
        case .text (let text):
            addLine(key: prefix + "memo.type", value: "MEMO_TEXT", lines: &lines)
            addLine(key: prefix + "memo.text", value: "\"" + text + "\"", lines: &lines) // TODO json encoder
        case .id (let id):
            addLine(key: prefix + "memo.type", value: "MEMO_ID", lines: &lines)
            addLine(key: prefix + "memo.id", value: String(id), lines: &lines)
        case .hash (_):
            addLine(key: prefix + "memo.type", value: "MEMO_HASH", lines: &lines)
            if let m = Memo(memoXDR: memo) {
                addLine(key: prefix + "memo.hash", value: try m.trimmedHexValue(), lines: &lines)
            }
        case .returnHash (_):
            addLine(key: prefix + "memo.type", value: "MEMO_RETURN", lines: &lines)
            if let m = Memo(memoXDR: memo) {
                addLine(key: prefix + "memo.retHash", value: try m.trimmedHexValue(), lines: &lines)
            }
        }
    }
    
    private static func addOperations(operations:[OperationXDR], prefix:String, lines: inout [String]) -> Void {
        addLine(key: prefix + "operations.len", value: String(operations.count), lines: &lines)
        var index = 0
        for operation in operations {
            addOperation(operation: operation, index: index, prefix: prefix, lines: &lines)
            index += 1
        }
    }
}
