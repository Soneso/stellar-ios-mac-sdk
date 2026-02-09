//
//  File.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 04.08.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

/// Errors that can occur during TxRep parsing or generation.
public enum TxRepError: Error {
    /// A required value is missing for the specified key.
    case missingValue(key:String)

    /// The value for the specified key is invalid or cannot be parsed.
    case invalidValue(key:String)
}

/// TxRep is a human-readable text format for Stellar transactions.
///
/// TxRep provides a readable low-level representation of Stellar transactions that can be
/// used for debugging, auditing, or manual transaction construction. It converts between
/// the standard base64-encoded XDR format and a human-readable key-value format.
///
/// Example:
/// ```swift
/// let txEnvelopeXdr = "AAAAAC..." // Base64 XDR
/// let txRep = try TxRep.toTxRep(transactionEnvelope: txEnvelopeXdr)
/// // Returns human-readable format:
/// // type: ENVELOPE_TYPE_TX
/// // tx.sourceAccount: GBZX...
/// // tx.fee: 100
/// // ...
///
/// // Convert back to XDR
/// let xdrAgain = try TxRep.fromTxRep(txRep: txRep)
/// ```
///
/// See: [SEP-0011](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0011.md) for the TxRep specification.
public class TxRep: NSObject {

    /// Converts a transaction envelope XDR to TxRep format.
    ///
    /// Takes a base64-encoded transaction envelope XDR and converts it to a human-readable
    /// TxRep representation. Supports both regular transactions and fee bump transactions.
    ///
    /// - Parameter transactionEnvelope: Base64-encoded transaction envelope XDR
    /// - Returns: Human-readable TxRep string with key-value pairs
    /// - Throws: TxRepError if the XDR cannot be parsed
    ///
    /// Example:
    /// ```swift
    /// let xdr = "AAAAAC..." // Base64 XDR
    /// let txRep = try TxRep.toTxRep(transactionEnvelope: xdr)
    /// print(txRep)
    /// // Output:
    /// // type: ENVELOPE_TYPE_TX
    /// // tx.sourceAccount: GBZX...
    /// // tx.fee: 100
    /// // ...
    /// ```
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
            addLine(key: "feeBump.tx.feeSource", value: feeBump.sourceAccountId, lines: &lines);
            addLine(key: "feeBump.tx.fee", value: String(feeBump.fee), lines: &lines);
            addLine(key: "feeBump.tx.innerTx.type", value: "ENVELOPE_TYPE_TX",lines: &lines);
        }
        addLine(key: prefix + "sourceAccount", value: transactionEnvelopeXDR.txSourceAccountId, lines: &lines)
        addLine(key: prefix + "fee", value: String(transactionEnvelopeXDR.txFee), lines: &lines)
        addLine(key: prefix + "seqNum", value: String(transactionEnvelopeXDR.txSeqNum), lines: &lines)
        addPreconditions(cond: transactionEnvelopeXDR.cond, prefix: prefix, lines: &lines)
        try addMemo(memo: transactionEnvelopeXDR.txMemo, prefix: prefix, lines: &lines)
        addOperations(operations: transactionEnvelopeXDR.txOperations, prefix: prefix, lines: &lines)
        if let txExt = transactionEnvelopeXDR.txExt {
            addLine(key: prefix + "ext.v", value: String(txExt.type()), lines: &lines)
            switch txExt {
            case .sorobanTransactionData(let sorobanTransactionDataXDR):
                addSorobanTransactionData(data: sorobanTransactionDataXDR, prefix: prefix + "sorobanData.", lines: &lines);
            default:
                break
            }
        } else {
            addLine(key: prefix + "ext.v", value: "0", lines: &lines)
        }
        
        addSignatures(signatures: transactionEnvelopeXDR.txSignatures, prefix: isFeeBump ? "feeBump.tx.innerTx." : "", lines: &lines)
        
        if (isFeeBump) {
            addLine(key: "feeBump.tx.ext.v", value: "0", lines: &lines)
            addSignatures(signatures: feeBumpSignatures, prefix: "feeBump.", lines: &lines)
        }
        
        return lines.joined(separator: "\n");
    }
    
    /// This function parses txrep and returns the corresponding transaction envelope xdr (base64 encoded)
    ///
    /// - Parameter txRep: human-readable low-level representation of Stellar transaction to be parsed
    /// - Returns: base64 encoded transaction envelope xdr
    public static func fromTxRep(txRep:String) throws ->String  {
        let lines = txRep.components(separatedBy: "\n")
        var dic:Dictionary = [String: String]()
        for line in lines {
            let parts = line.components(separatedBy: ":")
            if (parts.count > 1) {
                let key = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let values = parts[1...parts.count - 1]
                let value = values.joined(separator: ":").trimmingCharacters(in: .whitespacesAndNewlines)
                dic.updateValue(removeComment(val: value), forKey: key)
            }
        }
        var prefix = "tx."
        let isFeeBump = dic["type"] == "ENVELOPE_TYPE_TX_FEE_BUMP";
        var feeBumpFee:UInt64? = nil
        let feeBumpSource = dic["feeBump.tx.feeSource"]
        
        if isFeeBump {
            prefix = "feeBump.tx.innerTx.tx."
            if let feeBumpFeeStr = dic["feeBump.tx.fee"] {
                if let val = UInt64(feeBumpFeeStr) {
                    feeBumpFee = val
                } else {
                    throw TxRepError.invalidValue(key: "feeBump.tx.fee")
                }
            } else {
                throw TxRepError.missingValue(key: "feeBump.tx.fee")
            }
            if let fbs = feeBumpSource {
                do {
                    let _ = try MuxedAccount(accountId: fbs)
                } catch {
                    throw TxRepError.invalidValue(key: "feeBump.tx.feeSource")
                }
            } else {
                throw TxRepError.missingValue(key: "feeBump.tx.feeSource")
            }
        }
        
        let fee:UInt32
        var key = prefix + "fee"
        if let feeStr = dic[key] {
            if let val = UInt32(feeStr) {
                fee = val
            } else {
                throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
        
        let seqNr:Int64
        key = prefix + "seqNum"
        if let seqNrStr = dic[key] {
            if let val = Int64(seqNrStr) {
                seqNr = val - 1
            } else {
                throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
        
        let sourceAccount:MuxedAccount
        key = prefix + "sourceAccount"
        if let sourceAccountId = dic[key] {
            do {
                sourceAccount = try MuxedAccount(accountId:sourceAccountId, sequenceNumber:seqNr, id:nil)
            } catch {
                throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
        
        let memo:Memo? = try getMemo(dic:dic, prefix:prefix)
        let operations:[Operation] = try getOperations(dic:dic, prefix:prefix)
        let maxOperationFee = operations.count > 1 ? fee /  UInt32(operations.count) : fee
        let preconditions = try getPreconditions(dic: dic, prefix: prefix)
        let sorobanTransactionData = try getSorobanTransactionData(dic: dic, prefix: prefix)
        let transaction = try Transaction(sourceAccount: sourceAccount,
                                          operations: operations,
                                          memo: memo,
                                          preconditions: preconditions,
                                          maxOperationFee: maxOperationFee,
                                          sorobanTransactionData: sorobanTransactionData)
        
        prefix = isFeeBump ? "feeBump.tx.innerTx." : "";
        let signatures:[DecoratedSignatureXDR] = try getSignatures(dic: dic, prefix: prefix)
        for sig in signatures {
            transaction.addSignature(signature: sig)
        }
        
        if isFeeBump, let fbf = feeBumpFee, let src = feeBumpSource {
            //let baseFee =  fbf / UInt64(operations.count + 1)
            let feeBumpSourceAcc = try MuxedAccount(accountId: src)
            let feeBumpTransaction = try FeeBumpTransaction(sourceAccount: feeBumpSourceAcc, fee: fbf
                                                            , innerTransaction: transaction)
            let fSignatures = try getSignatures(dic: dic, prefix: "feeBump.")
            for sig in fSignatures {
                feeBumpTransaction.addSignature(signature: sig)
            }
            return try feeBumpTransaction.encodedEnvelope()
        }
        return try transaction.encodedEnvelope()
    }
    private static func getSignatures(dic:Dictionary<String,String>, prefix:String) throws -> [DecoratedSignatureXDR] {
        var signatures:[DecoratedSignatureXDR] = [DecoratedSignatureXDR]()
        let key = prefix + "signatures.len"
        if let sigLengthStr = dic[key] {
            if let sigCount = Int(sigLengthStr) {
                if sigCount > 20 {
                    throw TxRepError.invalidValue(key: key + " > 20")
                }
                for i in 0..<sigCount{
                    if let nextSignature = try getSignature(dic: dic, prefix: prefix, index: i) {
                        signatures.append(nextSignature)
                    }
                }
            } else {
                throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
        return signatures
    }
    
    private static func getOperations(dic:Dictionary<String,String>, prefix:String) throws -> [Operation] {
        var operations:[Operation] = [Operation]()
        let key = prefix + "operations.len"
        if let opLengthStr = dic[key] {
            if let opCount = Int(opLengthStr) {
                if opCount > 100 {
                    throw TxRepError.invalidValue(key: key + " > 100")
                }
                for i in 0..<opCount{
                    if let nextOperation = try getOperation(dic: dic, txPrefix: prefix, index: i) {
                        operations.append(nextOperation)
                    }
                }
            } else {
                throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
        return operations
    }
    
    private static func getSignature(dic:Dictionary<String,String>, prefix:String, index:Int) throws -> DecoratedSignatureXDR? {
        let sigPrefix = prefix + "signatures[" + String(index) + "]."
        var key = sigPrefix + "hint"
        let hint:Data
        if let hintu = dic[key] {
            if let data = hintu.data(using: .hexadecimal) {
                hint = data
            }
            else {
                throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
        key = sigPrefix + "signature"
        let signature:Data
        if let sig = dic[key] {
            if let data = sig.data(using: .hexadecimal) {
                signature = data
            }
            else {
                throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
        return DecoratedSignatureXDR(hint: WrappedData4(hint), signature: signature)
    }
    
    private static func getOperation(dic:Dictionary<String,String>, txPrefix:String, index:Int) throws -> Operation? {
        let prefix = txPrefix + "operations[" + String(index) + "].body."
        var key = txPrefix + "operations[" + String(index) + "].sourceAccount._present"
        var sourceAccount:MuxedAccount? = nil
        if let present = dic[key], present == "true" {
            key = txPrefix + "operations[" + String(index) + "].sourceAccount"
            if let sourceAccountId = dic[key] {
                do {
                    sourceAccount = try MuxedAccount(accountId:sourceAccountId)
                } catch {
                    throw TxRepError.invalidValue(key: key)
                }
            } else {
                throw TxRepError.missingValue(key: key)
            }
        }
        key = prefix + "type"
        if let type = dic[key] {
            switch type {
            case "CREATE_ACCOUNT":
                let opPrefix = prefix + "createAccountOp."
                return try getCreateAccountOperation(dic: dic, opPrefix: opPrefix, sourceAccount: sourceAccount)
            case "PAYMENT":
                let opPrefix = prefix + "paymentOp."
                return try getPaymentOperation(dic: dic, opPrefix: opPrefix, sourceAccount: sourceAccount)
            case "PATH_PAYMENT_STRICT_RECEIVE":
                let opPrefix = prefix + "pathPaymentStrictReceiveOp."
                return try getPaymentStrictReceiveOperation(dic: dic, opPrefix: opPrefix, sourceAccount: sourceAccount)
            case "PATH_PAYMENT_STRICT_SEND":
                let opPrefix = prefix + "pathPaymentStrictSendOp."
                return try getPaymentStrictSendOperation(dic: dic, opPrefix: opPrefix, sourceAccount: sourceAccount)
            case "MANAGE_SELL_OFFER":
                let opPrefix = prefix + "manageSellOfferOp."
                return try getManageSellOfferOperation(dic: dic, opPrefix: opPrefix, sourceAccount: sourceAccount)
            case "CREATE_PASSIVE_SELL_OFFER":
                let opPrefix = prefix + "createPassiveSellOfferOp."
                return try getCreatePassiveSellOfferOperation(dic: dic, opPrefix: opPrefix, sourceAccount: sourceAccount)
            case "SET_OPTIONS":
                let opPrefix = prefix + "setOptionsOp."
                return try getSetOptionsOperation(dic: dic, opPrefix: opPrefix, sourceAccount: sourceAccount)
            case "CHANGE_TRUST":
                let opPrefix = prefix + "changeTrustOp."
                return try getChangeTrustOperation(dic: dic, opPrefix: opPrefix, sourceAccount: sourceAccount)
            case "ALLOW_TRUST":
                let opPrefix = prefix + "allowTrustOp."
                return try getAllowTrustOperation(dic: dic, opPrefix: opPrefix, sourceAccount: sourceAccount)
            case "ACCOUNT_MERGE":
                // account merge does not include 'accountMergeOp' prefix
                return try getAccountMergeOperation(dic: dic, txPrefix: txPrefix, index:index, sourceAccount: sourceAccount)
            case "MANAGE_DATA":
                let opPrefix = prefix + "manageDataOp."
                return try getManageDataOperation(dic: dic, opPrefix: opPrefix, sourceAccount: sourceAccount)
            case "BUMP_SEQUENCE":
                let opPrefix = prefix + "bumpSequenceOp."
                return try getBumpSequenceOperation(dic: dic, opPrefix: opPrefix, sourceAccount: sourceAccount)
            case "MANAGE_BUY_OFFER":
                let opPrefix = prefix + "manageBuyOfferOp."
                return try getManageBuyOfferOperation(dic: dic, opPrefix: opPrefix, sourceAccount: sourceAccount)
            case "CREATE_CLAIMABLE_BALANCE":
                let opPrefix = prefix + "createClaimableBalanceOp."
                return try getCreateClaimableBalanceOp(dic: dic, opPrefix: opPrefix, sourceAccount: sourceAccount)
            case "CLAIM_CLAIMABLE_BALANCE":
                let opPrefix = prefix + "claimClaimableBalanceOp."
                return try getClaimClaimableBalanceOp(dic: dic, opPrefix: opPrefix, sourceAccount: sourceAccount)
            case "BEGIN_SPONSORING_FUTURE_RESERVES":
                let opPrefix = prefix + "beginSponsoringFutureReservesOp."
                return try getBeginSponsoringFutureReservesOp(dic: dic, opPrefix: opPrefix, sourceAccount: sourceAccount)
            case "END_SPONSORING_FUTURE_RESERVES":
                return try getEndSponsoringFutureReservesOp(sourceAccount: sourceAccount)
            case "REVOKE_SPONSORSHIP":
                let opPrefix = prefix + "revokeSponsorshipOp."
                return try getRevokeSponsorshipOp(dic: dic, opPrefix: opPrefix, sourceAccount: sourceAccount)
            case "CLAWBACK":
                let opPrefix = prefix + "clawbackOp."
                return try getClawbackOp(dic: dic, opPrefix: opPrefix, sourceAccount: sourceAccount)
            case "CLAWBACK_CLAIMABLE_BALANCE":
                let opPrefix = prefix + "clawbackClaimableBalanceOp."
                return try getClawbackClaimableBalanceOp(dic: dic, opPrefix: opPrefix, sourceAccount: sourceAccount)
            case "SET_TRUST_LINE_FLAGS":
                let opPrefix = prefix + "setTrustLineFlagsOp."
                return try getSetTrustlineFlagsOp(dic: dic, opPrefix: opPrefix, sourceAccount: sourceAccount)
            case "LIQUIDITY_POOL_DEPOSIT":
                let opPrefix = prefix + "liquidityPoolDepositOp."
                return try getLiquidityPoolDepositOp(dic: dic, opPrefix: opPrefix, sourceAccount: sourceAccount)
            case "LIQUIDITY_POOL_WITHDRAW":
                let opPrefix = prefix + "liquidityPoolWithdrawOp."
                return try getLiquidityPoolWithdrawOp(dic: dic, opPrefix: opPrefix, sourceAccount: sourceAccount)
            case "INVOKE_HOST_FUNCTION":
                let opPrefix = prefix + "invokeHostFunctionOp."
                return try getInvokeHostFunctionOp(dic: dic, opPrefix: opPrefix, sourceAccount: sourceAccount)
            case "EXTEND_FOOTPRINT_TTL":
                let opPrefix = prefix + "extendFootprintTTLOp."
                return try getExtendFootprintTTLOp(dic: dic, opPrefix: opPrefix, sourceAccount: sourceAccount)
            case "RESTORE_FOOTPRINT":
                return RestoreFootprintOperation(sourceAccountId: sourceAccount?.accountId)
            default:
                throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
    }
    
    private static func getInvokeHostFunctionOp(dic:Dictionary<String,String>, opPrefix:String, sourceAccount:MuxedAccount?) throws -> InvokeHostFunctionOperation {
        let hostFunction = try getHostFunction(dic: dic, prefix: opPrefix + "hostFunction.")
        let authEntries = try getSorobanAuthEntries(dic: dic, prefix: opPrefix + "auth")
        return InvokeHostFunctionOperation(hostFunction: hostFunction, auth: authEntries, sourceAccountId: sourceAccount?.accountId)
    }
    
    private static func getExtendFootprintTTLOp(dic:Dictionary<String,String>, opPrefix:String, sourceAccount:MuxedAccount?) throws -> ExtendFootprintTTLOperation{
        let key = opPrefix + "extendTo"
        let extendToStr = try getString(dic: dic, key: key)
        if let ledgersToExpire = UInt32(extendToStr) {
            return ExtendFootprintTTLOperation(ledgersToExpire: ledgersToExpire, sourceAccountId: sourceAccount?.accountId)
        } else {
            throw TxRepError.invalidValue(key: key)
        }
    }
    
    private static func getHostFunction(dic:Dictionary<String,String>, prefix:String) throws -> HostFunctionXDR {
        let key = prefix + "type";
        let hostFunctionType = try getString(dic: dic, key: key)
        switch hostFunctionType {
        case "HOST_FUNCTION_TYPE_INVOKE_CONTRACT":
            let args = try getInvokeContractArgs(dic: dic, prefix: prefix + "invokeContract.")
            return HostFunctionXDR.invokeContract(args)
        case "HOST_FUNCTION_TYPE_CREATE_CONTRACT":
            let args = try getCreateContractArgs(dic: dic, prefix: prefix +  "createContract.")
            return HostFunctionXDR.createContract(args)
        case "HOST_FUNCTION_TYPE_CREATE_CONTRACT_V2":
            let args = try getCreateContractV2Args(dic: dic, prefix: prefix +  "createContractV2.")
            return HostFunctionXDR.createContractV2(args)
        case "HOST_FUNCTION_TYPE_UPLOAD_CONTRACT_WASM":
            let wasmStr = try getString(dic: dic, key: prefix +  "wasm")
            return HostFunctionXDR.uploadContractWasm(Data(hex: wasmStr))
        default:
            throw TxRepError.invalidValue(key: key)
        }
    }
    
    private static func getSorobanAuthEntries(dic:Dictionary<String,String>, prefix:String) throws -> [SorobanAuthorizationEntryXDR] {
        let key = prefix + ".len"
        let lenStr = try getString(dic: dic, key: key)
        var entries:[SorobanAuthorizationEntryXDR] = []
        if let count = Int(lenStr) {
            for i in 0..<count{
                try entries.append(getSorobanAuthorizationEntry(dic:dic, prefix:prefix + "[\(i)]."))
            }
        } else {
            throw TxRepError.invalidValue(key: key)
        }
        return entries
    }
    
    private static func getSorobanAddressCredentials(dic:Dictionary<String,String>, prefix:String) throws -> SorobanAddressCredentialsXDR {
        let address = try getSCAddress(dic: dic, prefix: prefix + "address.")
        let nonceKey = prefix + "nonce"
        let nonceStr = try getString(dic: dic, key: nonceKey)
        let expKey = prefix + "signatureExpirationLedger"
        let expStr = try getString(dic: dic, key: expKey)
        let signature = try getSCVal(dic: dic, prefix: prefix + "signature.")
        if let nonce = Int64(nonceStr) {
            if let exp = UInt32(expStr) {
                return SorobanAddressCredentialsXDR(address: address, nonce: nonce, signatureExpirationLedger: exp, signature: signature)
            } else {
                throw TxRepError.invalidValue(key: expKey)
            }
        } else {
            throw TxRepError.invalidValue(key: nonceKey)
        }
    }
    
    private static func getSorobanCredentials(dic:Dictionary<String,String>, prefix:String) throws -> SorobanCredentialsXDR {
        let key = prefix + "type";
        let credentialsType = try getString(dic: dic, key: key)
        switch credentialsType {
        case "SOROBAN_CREDENTIALS_SOURCE_ACCOUNT":
            return SorobanCredentialsXDR.sourceAccount
        case "SOROBAN_CREDENTIALS_ADDRESS":
            let addressCredentials = try getSorobanAddressCredentials(dic: dic, prefix: prefix + "address.")
            return SorobanCredentialsXDR.address(addressCredentials)
        default:
            throw TxRepError.invalidValue(key: key)
        }
    }
    
    private static func getSorobanAuthorizedFunction(dic:Dictionary<String,String>, prefix:String) throws -> SorobanAuthorizedFunctionXDR {
        let key = prefix + "type";
        let functionType = try getString(dic: dic, key: key)
        switch functionType {
        case "SOROBAN_AUTHORIZED_FUNCTION_TYPE_CONTRACT_FN":
            let args = try getInvokeContractArgs(dic: dic, prefix: prefix + "contractFn.")
            return SorobanAuthorizedFunctionXDR.contractFn(args)
        case "SOROBAN_AUTHORIZED_FUNCTION_TYPE_CREATE_CONTRACT_HOST_FN":
            let args = try getCreateContractArgs(dic: dic, prefix: prefix + "createContractHostFn.")
            return SorobanAuthorizedFunctionXDR.createContractHostFn(args)
        case "SOROBAN_AUTHORIZED_FUNCTION_TYPE_CREATE_CONTRACT_V2_HOST_FN":
            let args = try getCreateContractV2Args(dic: dic, prefix: prefix + "createContractV2HostFn.")
            return SorobanAuthorizedFunctionXDR.createContractV2HostFn(args)
        default:
            throw TxRepError.invalidValue(key: key)
        }
    }
    
    private static func getSorobanAuthorizedInvocation(dic:Dictionary<String,String>, prefix:String) throws -> SorobanAuthorizedInvocationXDR {
        let function = try getSorobanAuthorizedFunction(dic: dic, prefix: prefix + "function.")
        let key = prefix + "subInvocations.len"
        let lenStr = try getString(dic: dic, key: key)
        var subs:[SorobanAuthorizedInvocationXDR] = []
        if let count = Int(lenStr) {
            for i in 0..<count{
                try subs.append(getSorobanAuthorizedInvocation(dic: dic, prefix: prefix + "subInvocations[\(i)]."))
            }
        } else {
            throw TxRepError.invalidValue(key: key)
        }
        return SorobanAuthorizedInvocationXDR(function: function, subInvocations: subs)
    }
    
    private static func getSorobanAuthorizationEntry(dic:Dictionary<String,String>, prefix:String) throws -> SorobanAuthorizationEntryXDR {
        let credentials = try getSorobanCredentials(dic: dic, prefix: prefix + "credentials.")
        let rootInvocation = try getSorobanAuthorizedInvocation(dic: dic, prefix: prefix + "rootInvocation.")
        return SorobanAuthorizationEntryXDR(credentials: credentials, rootInvocation: rootInvocation)
    }
    
    private static func getInvokeContractArgs(dic:Dictionary<String,String>, prefix:String) throws -> InvokeContractArgsXDR {
        let address = try getSCAddress(dic: dic, prefix: prefix + "contractAddress.")
        let functionName = try getString(dic: dic, key: prefix + "functionName")
        let key = prefix + "args.len"
        let lenStr = try getString(dic: dic, key: key)
        var invokeArgs:[SCValXDR] = []
        if let count = Int(lenStr) {
            for i in 0..<count{
                try invokeArgs.append(getSCVal(dic:dic, prefix:prefix + "args[\(i)]."))
            }
        } else {
            throw TxRepError.invalidValue(key: key)
        }
        return InvokeContractArgsXDR(contractAddress: address, functionName: functionName, args: invokeArgs)
    }
    
    private static func getString(dic:Dictionary<String,String>, key:String) throws -> String {
        if let str = dic[key] {
            return str
        } else {
            throw TxRepError.missingValue(key: key)
        }
    }
    
    private static func getSCError(dic:Dictionary<String,String>, prefix:String) throws -> SCErrorXDR {
        var key = prefix + "type";
        let errorType = try getString(dic: dic, key: key)
        switch errorType {
        case "SCE_CONTRACT":
            key = prefix + "contractCode"
            let contractCodeStr = try getString(dic: dic, key: key)
            if let contractCode = UInt32(contractCodeStr) {
                return SCErrorXDR.contract(contractCode)
            } else {
                throw TxRepError.invalidValue(key: key)
            }
        case "SCE_WASM_VM":
            return SCErrorXDR.wasmVm
        case "SCE_CONTEXT":
            return SCErrorXDR.context
        case "SCE_STORAGE":
            return SCErrorXDR.storage
        case "SCE_OBJECT":
            return SCErrorXDR.object
        case "SCE_CRYPTO":
            return SCErrorXDR.crypto
        case "SCE_EVENTS":
            return SCErrorXDR.events
        case "SCE_BUDGET":
            return SCErrorXDR.budget
        case "SCE_VALUE":
            return SCErrorXDR.value
        case "SCE_AUTH":
            key = prefix + "code"
            let code = try getString(dic: dic, key: key)
            switch code {
            case "SCEC_ARITH_DOMAIN":
                return SCErrorXDR.auth(0)
            case "SCEC_INDEX_BOUNDS":
                return SCErrorXDR.auth(1)
            case "SCEC_INVALID_INPUT":
                return SCErrorXDR.auth(2)
            case "SCEC_MISSING_VALUE":
                return SCErrorXDR.auth(3)
            case "SCEC_EXISTING_VALUE":
                return SCErrorXDR.auth(4)
            case "SCEC_EXCEEDED_LIMIT":
                return SCErrorXDR.auth(5)
            case "SCEC_INVALID_ACTION":
                return SCErrorXDR.auth(6)
            case "SCEC_INTERNAL_ERROR":
                return SCErrorXDR.auth(7)
            case "SCEC_UNEXPECTED_TYPE":
                return SCErrorXDR.auth(8)
            case "SCEC_UNEXPECTED_SIZE":
                return SCErrorXDR.auth(9)
            default:
                throw TxRepError.invalidValue(key: key)
            }
        default:
            throw TxRepError.invalidValue(key: key)
        }
    }
    
    private static func getSCVal(dic:Dictionary<String,String>, prefix:String) throws -> SCValXDR {
        var key = prefix + "type"
        let type = try getString(dic: dic, key: key)
        switch type {
        case "SCV_BOOL":
            key = prefix + "b"
            let bStr = try getString(dic: dic, key: key)
            if let b = Bool(bStr) {
                return SCValXDR.bool(b)
            } else {
                throw TxRepError.invalidValue(key: key)
            }
        case "SCV_VOID":
            return SCValXDR.void
        case "SCV_ERROR":
            return SCValXDR.error(try getSCError(dic: dic, prefix: prefix + "error"))
        case "SCV_U32":
            key = prefix + "u32"
            let u32Str = try getString(dic: dic, key: key)
            if let u32 = UInt32(u32Str) {
                return SCValXDR.u32(u32)
            } else {
                throw TxRepError.invalidValue(key: key)
            }
        case "SCV_I32":
            key = prefix + "i32"
            let i32Str = try getString(dic: dic, key: key)
            if let i32 = Int32(i32Str) {
                return SCValXDR.i32(i32)
            } else {
                throw TxRepError.invalidValue(key: key)
            }
        case "SCV_U64":
            key = prefix + "u64"
            let u64Str = try getString(dic: dic, key: key)
            if let u64 = UInt64(u64Str) {
                return SCValXDR.u64(u64)
            } else {
                throw TxRepError.invalidValue(key: key)
            }
        case "SCV_I64":
            key = prefix + "i64"
            let i64Str = try getString(dic: dic, key: key)
            if let i64 = Int64(i64Str) {
                return SCValXDR.i64(i64)
            } else {
                throw TxRepError.invalidValue(key: key)
            }
        case "SCV_TIMEPOINT":
            key = prefix + "timepoint"
            let u64Str = try getString(dic: dic, key: key)
            if let u64 = UInt64(u64Str) {
                return SCValXDR.timepoint(u64)
            } else {
                throw TxRepError.invalidValue(key: key)
            }
        case "SCV_DURATION":
            key = prefix + "duration"
            let u64Str = try getString(dic: dic, key: key)
            if let u64 = UInt64(u64Str) {
                return SCValXDR.duration(u64)
            } else {
                throw TxRepError.invalidValue(key: key)
            }
        case "SCV_U128":
            return try SCValXDR.u128(getUI128Parts(dic: dic, prefix: prefix + "u128."))
        case "SCV_I128":
            return try SCValXDR.i128(getI128Parts(dic: dic, prefix: prefix + "i128."))
        case "SCV_U256":
            return try SCValXDR.u256(getUI256Parts(dic: dic, prefix: prefix + "u256."))
        case "SCV_I256":
            return try SCValXDR.i256(getI256Parts(dic: dic, prefix: prefix + "i256."))
        case "SCV_BYTES":
            key = prefix + "bytes"
            let bytesStr = try getString(dic: dic, key: key)
            return SCValXDR.bytes(Data(hex: bytesStr))
        case "SCV_STRING":
            key = prefix + "str"
            let str = try getString(dic: dic, key: key)
            return SCValXDR.string(str)
        case "SCV_SYMBOL":
            key = prefix + "sym"
            let sym = try getString(dic: dic, key: key)
            return SCValXDR.symbol(sym)
        case "SCV_VEC":
            key = prefix + "vec._present"
            let present = try getString(dic: dic, key: key)
            if "false" == present {
                return SCValXDR.vec(nil)
            }
            return try SCValXDR.vec(getSCVec(dic: dic, prefix: prefix))
        case "SCV_MAP":
            key = prefix + "map._present"
            let present = try getString(dic: dic, key: key)
            if "false" == present {
                return SCValXDR.map(nil)
            }
            return try SCValXDR.map(getSCMapEntries(dic: dic, prefix: prefix + "map"))
        case "SCV_ADDRESS":
            return try SCValXDR.address(getSCAddress(dic: dic, prefix: prefix + "address."))
        case "SCV_LEDGER_KEY_CONTRACT_INSTANCE":
            return SCValXDR.ledgerKeyContractInstance
        case "SCV_LEDGER_KEY_NONCE":
            key = prefix +  "nonce_key.nonce"
            let nonceStr = try getString(dic: dic, key: key)
            if let nonceInt64 = Int64(nonceStr) {
                return SCValXDR.ledgerKeyNonce(SCNonceKeyXDR(nonce: nonceInt64))
            } else {
                throw TxRepError.invalidValue(key: key)
            }
        case "SCV_CONTRACT_INSTANCE":
            key = prefix + "contractInstance.executable."
            let executable = try getContractExecutable(dic: dic, prefix: prefix)
            key = prefix + "storage._present"
            let present = try getString(dic: dic, key: key)
            if "true" == present {
                let mapEntries = try getSCMapEntries(dic: dic, prefix: prefix + "storage")
                let instance =  SCContractInstanceXDR(executable: executable, storage: mapEntries)
                return SCValXDR.contractInstance(instance)
            } else {
                let instance = SCContractInstanceXDR(executable: executable, storage: nil)
                return SCValXDR.contractInstance(instance)
            }
        default:
            throw TxRepError.invalidValue(key: key)
        }
    }
    
    private static func getContractExecutable(dic:Dictionary<String,String>, prefix:String) throws -> ContractExecutableXDR {
        var key = prefix + "type"
        let type = try getString(dic: dic, key: key)
        switch type {
        case "CONTRACT_EXECUTABLE_WASM":
            key = prefix + "wasm_hash"
            if let hashStr = dic[key] {
                return ContractExecutableXDR.wasm(WrappedData32(Data(hex: hashStr)))
            } else {
                throw TxRepError.missingValue(key: key)
            }
        case "CONTRACT_EXECUTABLE_STELLAR_ASSET":
            return ContractExecutableXDR.token
        default:
            throw TxRepError.invalidValue(key: key)
        }
    }
    
    private static func getSCMapEntries(dic:Dictionary<String,String>, prefix:String) throws -> [SCMapEntryXDR] {
        let key = prefix + ".len"
        let mapLen = try getString(dic: dic, key: key)
        if let count = Int(mapLen) {
            var map:[SCMapEntryXDR] = []
            for i in 0..<count{
                let key = try getSCVal(dic: dic, prefix:prefix + "[\(i)].key.")
                let val = try getSCVal(dic: dic, prefix:prefix + "[\(i)].val.")
                map.append(SCMapEntryXDR(key: key, val: val))
            }
            return map
        } else {
            throw TxRepError.invalidValue(key: key)
        }
    }
    
    private static func getSCVec(dic:Dictionary<String,String>, prefix:String) throws -> [SCValXDR] {
        let key = prefix + "vec.len"
        let vecLen = try getString(dic: dic, key: key)
        if let count = Int(vecLen) {
            var vec:[SCValXDR] = []
            for i in 0..<count{
                try vec.append(getSCVal(dic: dic, prefix:prefix + "vec[\(i)]."))
            }
            return vec
        } else {
            throw TxRepError.invalidValue(key: key)
        }
    }
                                 
    private static func getI128Parts(dic:Dictionary<String,String>, prefix:String) throws -> Int128PartsXDR {
        var key = prefix + "lo"
        let loStr = try getString(dic: dic, key: key)
        if let lo = UInt64(loStr) {
            key = prefix + "hi"
            let hiStr = try getString(dic: dic, key: key)
            if let hi = Int64(hiStr) {
                return Int128PartsXDR(hi: hi, lo: lo)
            } else {
                throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.invalidValue(key: key)
        }
    }
    
    private static func getUI128Parts(dic:Dictionary<String,String>, prefix:String) throws -> UInt128PartsXDR {
        var key = prefix + "lo"
        let loStr = try getString(dic: dic, key: key)
        if let lo = UInt64(loStr) {
            key = prefix + "hi"
            let hiStr = try getString(dic: dic, key: key)
            if let hi = UInt64(hiStr) {
                return UInt128PartsXDR(hi: hi, lo: lo)
            } else {
                throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.invalidValue(key: key)
        }
    }
    
    private static func getI256Parts(dic:Dictionary<String,String>, prefix:String) throws -> Int256PartsXDR {
        var key = prefix + "lo_lo"
        let loLoStr = try getString(dic: dic, key: key)
        if let loLo = UInt64(loLoStr) {
            key = prefix + "lo_hi"
            let loHiStr = try getString(dic: dic, key: key)
            if let loHi = UInt64(loHiStr) {
                key = prefix + "hi_lo"
                let hiLoStr = try getString(dic: dic, key: key)
                if let hiLo = UInt64(hiLoStr) {
                    key = prefix + "hi_hi"
                    let hiHiStr = try getString(dic: dic, key: key)
                    if let hiHi = Int64(hiHiStr) {
                        return Int256PartsXDR(hiHi: hiHi, hiLo: hiLo, loHi: loHi, loLo: loLo)
                    } else {
                        throw TxRepError.invalidValue(key: key)
                    }
                } else {
                    throw TxRepError.invalidValue(key: key)
                }
            } else {
                throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.invalidValue(key: key)
        }
    }
    
    private static func getUI256Parts(dic:Dictionary<String,String>, prefix:String) throws -> UInt256PartsXDR {
        var key = prefix + "lo_lo"
        let loLoStr = try getString(dic: dic, key: key)
        if let loLo = UInt64(loLoStr) {
            key = prefix + "lo_hi"
            let loHiStr = try getString(dic: dic, key: key)
            if let loHi = UInt64(loHiStr) {
                key = prefix + "hi_lo"
                let hiLoStr = try getString(dic: dic, key: key)
                if let hiLo = UInt64(hiLoStr) {
                    key = prefix + "hi_hi"
                    let hiHiStr = try getString(dic: dic, key: key)
                    if let hiHi = UInt64(hiHiStr) {
                        return UInt256PartsXDR(hiHi: hiHi, hiLo: hiLo, loHi: loHi, loLo: loLo)
                    } else {
                        throw TxRepError.invalidValue(key: key)
                    }
                } else {
                    throw TxRepError.invalidValue(key: key)
                }
            } else {
                throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.invalidValue(key: key)
        }
    }
    
    private static func getSCAddress(dic:Dictionary<String,String>, prefix:String) throws -> SCAddressXDR {
        var key = prefix + "type"
        let type = try getString(dic: dic, key: key)
        if "SC_ADDRESS_TYPE_ACCOUNT" == type {
            key = prefix + "accountId"
            if let accountId = dic[key] {
                return try SCAddressXDR(accountId: accountId)
            } else {
                throw TxRepError.missingValue(key: key)
            }
        } else if "SC_ADDRESS_TYPE_CONTRACT" == type {
            key = prefix + "contractId"
            if let contractId = dic[key] {
                return try SCAddressXDR(contractId: contractId)
            } else {
                throw TxRepError.missingValue(key: key)
            }
        } else if "SC_ADDRESS_TYPE_MUXED_ACCOUNT" == type {
            key = prefix + "muxedAccount"
            if let accountId = dic[key] {
                return try SCAddressXDR(accountId: accountId)
            } else {
                key = prefix + "accountId"
                if let accountId = dic[key] {
                    return try SCAddressXDR(accountId: accountId)
                } else {
                    throw TxRepError.missingValue(key: key)
                }
            }
        } else if "SC_ADDRESS_TYPE_CLAIMABLE_BALANCE" == type {
            let key = prefix + "claimableBalanceId.balanceID.v0"
            let balanceId = try getString(dic: dic, key: key)
            return try SCAddressXDR(claimableBalanceId: balanceId)
        } else if "SC_ADDRESS_TYPE_LIQUIDITY_POOL" == type {
            let key = prefix + "liquidityPoolId"
            let liquidityPoolId = try getString(dic: dic, key: key)
            return try SCAddressXDR(liquidityPoolId: liquidityPoolId)
        } else {
            throw TxRepError.invalidValue(key: key)
        }
    }
    
    private static func getContractIDPreimage(dic:Dictionary<String,String>, prefix:String) throws -> ContractIDPreimageXDR {
        let type = try getString(dic: dic, key: prefix + "type")
        switch type {
        case "CONTRACT_ID_PREIMAGE_FROM_ADDRESS":
            let address = try getSCAddress(dic: dic, prefix: prefix + "fromAddress.address.")
            let saltStr = try getString(dic: dic, key: prefix + "fromAddress.salt")
            let xdr = ContractIDPreimageFromAddressXDR(address: address, salt: WrappedData32(Data(hex: saltStr)))
            return ContractIDPreimageXDR.fromAddress(xdr)
        case "CONTRACT_ID_PREIMAGE_FROM_ASSET":
            let key = prefix + "fromAsset"
            let assetStr = try getString(dic: dic, key: key)
            if let asset = decodeAsset(asset: assetStr), let assetXdr = try? asset.toXDR() {
                return ContractIDPreimageXDR.fromAsset(assetXdr)
            } else {
                throw TxRepError.invalidValue(key: key)
            }
        default:
            throw TxRepError.invalidValue(key: prefix + "type")
        }
    }

    private static func getCreateContractArgs(dic:Dictionary<String,String>, prefix:String) throws -> CreateContractArgsXDR {
        let preimage = try getContractIDPreimage(dic: dic, prefix: prefix + "contractIDPreimage.")
        let executable = try getContractExecutable(dic: dic, prefix: prefix + "executable.")
        return CreateContractArgsXDR(contractIDPreimage: preimage, executable: executable)
    }
    
    private static func getCreateContractV2Args(dic:Dictionary<String,String>, prefix:String) throws -> CreateContractV2ArgsXDR {
        let preimage = try getContractIDPreimage(dic: dic, prefix: prefix + "contractIDPreimage.")
        let executable = try getContractExecutable(dic: dic, prefix: prefix + "executable.")
        let key = prefix + "constructorArgs.len"
        let lenStr = try getString(dic: dic, key: key)
        var constructorArgs:[SCValXDR] = []
        if let count = Int(lenStr) {
            for i in 0..<count{
                try constructorArgs.append(getSCVal(dic:dic, prefix:prefix + "constructorArgs[\(i)]."))
            }
        } else {
            throw TxRepError.invalidValue(key: key)
        }
        return CreateContractV2ArgsXDR(contractIDPreimage: preimage, executable: executable, constructorArgs: constructorArgs)
    }
    
    private static func getSorobanTransactionData(dic:Dictionary<String,String>, prefix:String) throws -> SorobanTransactionDataXDR? {
        let key = prefix + "ext.v";
        let vStr = try getString(dic: dic, key: key)
        if let v = UInt8(vStr) {
            if v == 1 {
                var ext = SorobanResourcesExt.void
                let extStr = try getString(dic: dic, key: prefix + "sorobanData.ext.v")
                if let extV = Int(extStr), extV == 1 {
                    let key = prefix + "sorobanData.ext.archivedSorobanEntries.len"
                    let lenStr = try getString(dic: dic, key: key)
                    var archivedSorobanEntries:[UInt32] = []
                    if let count = Int(lenStr) {
                        for i in 0..<count{
                            let key = prefix + "sorobanData.ext.archivedSorobanEntries[\(i)]"
                            let valStr = try getString(dic: dic, key: key)
                            if let val = UInt32(valStr) {
                                archivedSorobanEntries.append(val)
                            } else {
                                throw TxRepError.invalidValue(key: key)
                            }
                        }
                    } else {
                        throw TxRepError.invalidValue(key: key)
                    }
                    ext = SorobanResourcesExt.resourceExt(SorobanResourcesExtV0(archivedSorobanEntries: archivedSorobanEntries))
                }
                let sorobanResources = try getSorobanResources(dic: dic, prefix: prefix + "sorobanData.resources.")
                let resourceFeeStr = try getString(dic: dic, key: prefix + "sorobanData.resourceFee")
                if let resourceFee = Int64(resourceFeeStr) {
                    return SorobanTransactionDataXDR(ext: ext, resources: sorobanResources, resourceFee: resourceFee)
                }
            }
            return nil
        } else {
            throw TxRepError.invalidValue(key: key)
        }
    }
    
    private static func getSorobanResources(dic:Dictionary<String,String>, prefix:String) throws -> SorobanResourcesXDR {
        let footprint = try getFootprint(dic: dic, prefix: prefix + "footprint.")

        let key = prefix + "instructions"
        let instructionsStr = try getString(dic: dic, key: key)
        if let instructions = UInt32(instructionsStr) {
            var key = prefix + "readBytes"
            var readBytesStr = dic[key]
            if (readBytesStr == nil) {
                key = prefix + "diskReadBytes"
                readBytesStr = try getString(dic: dic, key: key)
            }
            if let readBytes = UInt32(readBytesStr!) {
                let key = prefix + "writeBytes"
                let writeBytesStr = try getString(dic: dic, key: key)
                if let writeBytes = UInt32(writeBytesStr) {
                    return SorobanResourcesXDR(footprint: footprint, instructions: instructions, diskReadBytes: readBytes, writeBytes: writeBytes)
                } else {
                    throw TxRepError.invalidValue(key: key)
                }
            } else {
                throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.invalidValue(key: key)
        }
    }

    private static func getFootprint(dic:Dictionary<String,String>, prefix:String) throws -> LedgerFootprintXDR {
        var readOnly:[LedgerKeyXDR] = []
        var readWrite:[LedgerKeyXDR] = []
        var key = prefix + "readOnly.len"
        let readOnlyLen = try getString(dic: dic, key: key)
        if let count = Int(readOnlyLen) {
            for i in 0..<count{
                try readOnly.append(getLedgerKey(dic:dic, prefix:prefix + "readOnly[\(i)]."))
            }
        } else {
            throw TxRepError.invalidValue(key: key)
        }
        key = prefix + "readWrite.len"
        let readWriteLen = try getString(dic: dic, key: key)
        if let count = Int(readWriteLen) {
            for i in 0..<count{
                try readWrite.append(getLedgerKey(dic:dic, prefix:prefix + "readWrite[\(i)]."))
            }
        } else {
            throw TxRepError.invalidValue(key: key)
        }
        return LedgerFootprintXDR(readOnly: readOnly, readWrite: readWrite)
    }
    
    private static func getLedgerKey(dic:Dictionary<String,String>, prefix:String) throws -> LedgerKeyXDR {
        var key = prefix + "type"
        let ledgerKeyType = try getString(dic: dic, key: key)
        if (ledgerKeyType == "ACCOUNT") {
            key = prefix + "account.accountID";
            let accountIdStr = try getString(dic: dic, key: key)
            do {
                let pk = try PublicKey(accountId: accountIdStr)
                return LedgerKeyXDR.account(LedgerKeyAccountXDR(accountID: pk))
            } catch {
                throw TxRepError.invalidValue(key: key)
            }
        } else if (ledgerKeyType == "TRUSTLINE") {
            key = prefix + "trustLine.accountID";
            let pk:PublicKey
            let accountIdStr = try getString(dic: dic, key: key)
            do {
                pk = try PublicKey(accountId: accountIdStr)
            } catch {
                throw TxRepError.invalidValue(key: key)
            }
            key = prefix + "trustLine.asset"
            let asset:TrustlineAssetXDR
            let assetStr = try getString(dic: dic, key: key)
            if let decodedAssset = decodeAsset(asset: assetStr) {
                do {
                    asset = try decodedAssset.toTrustlineAssetXDR()
                } catch {
                    throw TxRepError.invalidValue(key: key)
                }
            } else {
               throw TxRepError.invalidValue(key: key)
            }
            
            let value = LedgerKeyTrustLineXDR(accountID: pk, asset: asset)
            return LedgerKeyXDR.trustline(value)
        } else if (ledgerKeyType == "OFFER") {
            key = prefix + "offer.sellerID";
            let pk:PublicKey
            let accountIdStr = try getString(dic: dic, key: key)
            do {
                pk = try PublicKey(accountId: accountIdStr)
            } catch {
                throw TxRepError.invalidValue(key: key)
            }
            key = prefix + "offer.offerID"
            let offerIdStr = try getString(dic: dic, key: key)
            if let offerId = UInt64(offerIdStr) {
                let value = LedgerKeyOfferXDR(sellerId: pk, offerId: offerId)
                return LedgerKeyXDR.offer(value)
            } else {
                throw TxRepError.invalidValue(key: key)
            }
        } else if (ledgerKeyType == "DATA") {
            key = prefix + "data.accountID";
            let pk:PublicKey
            let accountIdStr = try getString(dic: dic, key: key)
            do {
                pk = try PublicKey(accountId: accountIdStr)
            } catch {
                throw TxRepError.invalidValue(key: key)
            }
            let jsonDecoder = JSONDecoder()
            key = prefix + "data.dataName"
            var dataName:String
            let text = try getString(dic: dic, key: key)
            do {
                if let textData = text.data(using: .utf8) {
                    dataName = try jsonDecoder.decode(String.self, from:textData)
                } else {
                    dataName = text.replacingOccurrences(of: "\"", with: "")
                }
            } catch {
                throw TxRepError.invalidValue(key: key)
            }
            let value = LedgerKeyDataXDR(accountId: pk, dataName: dataName)
            return LedgerKeyXDR.data(value)
        } else if (ledgerKeyType == "CLAIMABLE_BALANCE") {
            let key = prefix + "claimableBalance.balanceID.v0"
            let balanceId = try getString(dic: dic, key: key)
            let value = ClaimableBalanceIDXDR.claimableBalanceIDTypeV0(balanceId.wrappedData32FromHex())
            return LedgerKeyXDR.claimableBalance(value)
        } else if (ledgerKeyType == "LIQUIDITY_POOL") {
            let key = prefix + "liquidityPool.liquidityPoolID"
            let liquidityPoolId = try getString(dic: dic, key: key)
            var lidHex = liquidityPoolId
            if liquidityPoolId.hasPrefix("L"), let idHex = try? liquidityPoolId.decodeLiquidityPoolIdToHex() {
                lidHex = idHex
            }
            let value = LiquidityPoolIDXDR(id: lidHex.wrappedData32FromHex())
            return LedgerKeyXDR.liquidityPool(value)
        } else if (ledgerKeyType == "CONTRACT_DATA") {
            let address = try getSCAddress(dic: dic, prefix: prefix + "contractData.contract.")
            let keyVal = try getSCVal(dic: dic, prefix: prefix + "contractData.key.")
            let key = prefix + "contractData.durability"
            let durabilityStr = try getString(dic: dic, key: key)
            var durability = ContractDataDurability.persistent
            if (durabilityStr == "TEMPORARY") {
                durability = ContractDataDurability.temporary
            } else if (durabilityStr != "PERSISTENT") {
                throw TxRepError.invalidValue(key: key)
            }
            let value = LedgerKeyContractDataXDR(contract: address, key: keyVal, durability: durability)
            return LedgerKeyXDR.contractData(value)
        }  else if (ledgerKeyType == "CONTRACT_CODE") {
            let hashStr = try getString(dic: dic, key: prefix + "contractCode.hash")
            let value = LedgerKeyContractCodeXDR(hash: hashStr.wrappedData32FromHex())
            return LedgerKeyXDR.contractCode(value)
        } else if (ledgerKeyType == "CONFIG_SETTING") {
            let id = try getConfigSettingID(dic: dic, key: prefix + "configSetting.configSettingID")
            return LedgerKeyXDR.configSetting(id.rawValue)
        } else if (ledgerKeyType == "TTL") {
            let hashStr = try getString(dic: dic, key: prefix + "ttl.keyHash")
            let value = LedgerKeyTTLXDR(keyHash: hashStr.wrappedData32FromHex())
            return LedgerKeyXDR.ttl(value)
        } else {
            throw TxRepError.invalidValue(key: key)
        }
    }
    
    private static func getConfigSettingID(dic:Dictionary<String,String>, key:String) throws -> ConfigSettingID {
        let value = try getString(dic: dic, key: key)
        switch value {
        case "CONFIG_SETTING_CONTRACT_MAX_SIZE_BYTES":
            return ConfigSettingID.contractMaxSizeBytes
        case "CONFIG_SETTING_CONTRACT_COMPUTE_V0":
            return ConfigSettingID.contractComputeV0
        case "CONFIG_SETTING_CONTRACT_LEDGER_COST_V0":
            return ConfigSettingID.contractLedgerCostV0
        case "CONFIG_SETTING_CONTRACT_HISTORICAL_DATA_V0":
            return ConfigSettingID.contractHistoricalDataV0
        case "CONFIG_SETTING_CONTRACT_EVENTS_V0":
            return ConfigSettingID.contractEventsV0
        case "CONFIG_SETTING_CONTRACT_BANDWIDTH_V0":
            return ConfigSettingID.contractBandwidthV0
        case "CONFIG_SETTING_CONTRACT_COST_PARAMS_CPU_INSTRUCTIONS":
            return ConfigSettingID.contractCostParamsCpuInstructions
        case "CONFIG_SETTING_CONTRACT_COST_PARAMS_MEMORY_BYTES":
            return ConfigSettingID.contractCostParamsMemoryBytes
        case "CONFIG_SETTING_CONTRACT_DATA_KEY_SIZE_BYTES":
            return ConfigSettingID.contractDataKeySizeBytes
        case "CONFIG_SETTING_CONTRACT_DATA_ENTRY_SIZE_BYTES":
            return ConfigSettingID.contractDataEntrySizeBytes
        case "CONFIG_SETTING_STATE_ARCHIVAL":
            return ConfigSettingID.stateArchival
        case "CONFIG_SETTING_CONTRACT_EXECUTION_LANES":
            return ConfigSettingID.contractExecutionLanes
        case "CONFIG_SETTING_BUCKETLIST_SIZE_WINDOW":
            return ConfigSettingID.liveSorobanStateSizeWindow
        case "CONFIG_SETTING_LIVE_SOROBAN_STATE_SIZE_WINDOW":
            return ConfigSettingID.liveSorobanStateSizeWindow
        case "CONFIG_SETTING_EVICTION_ITERATOR":
            return ConfigSettingID.evictionIterator
        case "CONFIG_SETTING_CONTRACT_PARALLEL_COMPUTE_V0":
            return ConfigSettingID.contractParallelComputeV0
        case "CONFIG_SETTING_CONTRACT_LEDGER_COST_EXT_V0":
            return ConfigSettingID.contractLedgerCostExtV0
        case "CONFIG_SETTING_SCP_TIMING":
            return ConfigSettingID.scpTiming
        default:
            throw TxRepError.invalidValue(key: key)
        }
    }
    
    private static func getLiquidityPoolWithdrawOp(dic:Dictionary<String,String>, opPrefix:String, sourceAccount:MuxedAccount?) throws -> LiquidityPoolWithdrawOperation? {
        var key = opPrefix + "liquidityPoolID";
        let liquidityPoolID:String
        if let liquidityPoolIDStr = dic[key] {
            liquidityPoolID = liquidityPoolIDStr
        } else {
            throw TxRepError.missingValue(key: key)
        }
        key = opPrefix + "amount"
        let amount:Decimal
        if let amountStr = dic[key], let amounta = Int64(amountStr) {
            amount = fromAmount(amounta)
        } else {
            throw TxRepError.missingValue(key: key)
        }
        key = opPrefix + "minAmountA"
        let minAmountA:Decimal
        if let amountStr = dic[key], let amounta = Int64(amountStr) {
            minAmountA = fromAmount(amounta)
        } else {
            throw TxRepError.missingValue(key: key)
        }
        key = opPrefix + "minAmountB"
        let minAmountB:Decimal
        if let amountStr = dic[key], let amounta = Int64(amountStr) {
            minAmountB = fromAmount(amounta)
        } else {
            throw TxRepError.missingValue(key: key)
        }
        return LiquidityPoolWithdrawOperation(sourceAccountId: sourceAccount?.accountId,
                                              liquidityPoolId: liquidityPoolID,
                                              amount:amount,
                                              minAmountA: minAmountA,
                                              minAmountB: minAmountB)
    }
    
    private static func getLiquidityPoolDepositOp(dic:Dictionary<String,String>, opPrefix:String, sourceAccount:MuxedAccount?) throws -> LiquidityPoolDepositOperation? {
        var key = opPrefix + "liquidityPoolID";
        let liquidityPoolID:String
        if let liquidityPoolIDStr = dic[key] {
            liquidityPoolID = liquidityPoolIDStr
        } else {
            throw TxRepError.missingValue(key: key)
        }
        key = opPrefix + "maxAmountA"
        let maxAmountA:Decimal
        if let amountStr = dic[key], let amounta = Int64(amountStr) {
            maxAmountA = fromAmount(amounta)
        } else {
            throw TxRepError.missingValue(key: key)
        }
        key = opPrefix + "maxAmountB"
        let maxAmountB:Decimal
        if let amountStr = dic[key], let amounta = Int64(amountStr) {
            maxAmountB = fromAmount(amounta)
        } else {
            throw TxRepError.missingValue(key: key)
        }
        key = opPrefix + "minPrice.n"
        let minPriceN:Int32
        if let minPriceNStr = dic[key] {
            if let minPriceNI = Int32(minPriceNStr) {
                minPriceN = minPriceNI
            } else {
                throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
        key = opPrefix + "minPrice.d"
        let minPriceD:Int32
        if let minPriceDStr = dic[key] {
            if let minPriceDI = Int32(minPriceDStr) {
                minPriceD = minPriceDI
            } else {
                throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
        key = opPrefix + "maxPrice.n"
        let maxPriceN:Int32
        if let maxPriceNStr = dic[key] {
            if let maxPriceNI = Int32(maxPriceNStr) {
                maxPriceN = maxPriceNI
            } else {
                throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
        key = opPrefix + "maxPrice.d"
        let maxPriceD:Int32
        if let maxPriceDStr = dic[key] {
            if let maxPriceDI = Int32(maxPriceDStr) {
                maxPriceD = maxPriceDI
            } else {
                throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
        return LiquidityPoolDepositOperation(sourceAccountId: sourceAccount?.accountId, liquidityPoolId: liquidityPoolID,
                                             maxAmountA: maxAmountA, maxAmountB: maxAmountB,
                                             minPrice: Price(numerator: minPriceN, denominator: minPriceD),
                                             maxPrice: Price(numerator: maxPriceN, denominator: maxPriceD))
    }
    
    private static func getSetTrustlineFlagsOp(dic:Dictionary<String,String>, opPrefix:String, sourceAccount:MuxedAccount?) throws -> SetTrustlineFlagsOperation? {
        var key = opPrefix + "asset"
        let asset:Asset
        if let assetStr = dic[key] {
            if let asseta = decodeAsset(asset: assetStr) {
                asset = asseta
            } else {
               throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
        key = opPrefix + "trustor";
        let accountId:String
        if let accountIdStr = dic[key] {
            do {
                let kp = try KeyPair(accountId:accountIdStr)
                accountId = kp.accountId;
            } catch {
                throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
        key = opPrefix + "clearFlags"
        let clearFlags:UInt32
        if let clearFlagsStr = dic[key] {
            if let clearFlagsI = UInt32(clearFlagsStr) {
                clearFlags = clearFlagsI
            } else {
                throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
        key = opPrefix + "setFlags"
        let setFlags:UInt32
        if let setFlagsStr = dic[key] {
            if let setFlagsI = UInt32(setFlagsStr) {
                setFlags = setFlagsI
            } else {
                throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
        return SetTrustlineFlagsOperation(sourceAccountId: sourceAccount?.accountId, asset: asset, trustorAccountId: accountId, setFlags: setFlags, clearFlags: clearFlags)
    }
    
    private static func getClawbackClaimableBalanceOp(dic:Dictionary<String,String>, opPrefix:String, sourceAccount:MuxedAccount?) throws -> ClawbackClaimableBalanceOperation? {
        let key = opPrefix + "balanceID.v0"
        if let balanceId = dic[key] {
            return ClawbackClaimableBalanceOperation(claimableBalanceID: balanceId, sourceAccountId: sourceAccount?.accountId)
        } else {
            throw TxRepError.missingValue(key: key)
        }
    }
    
    private static func getClawbackOp(dic:Dictionary<String,String>, opPrefix:String, sourceAccount:MuxedAccount?) throws -> ClawbackOperation? {
        var key = opPrefix + "asset"
        let asset:Asset
        if let assetStr = dic[key] {
            if let asseta = decodeAsset(asset: assetStr) {
                asset = asseta
            } else {
               throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
        
        key = opPrefix + "amount"
        let amount:Decimal
        if let amountStr = dic[key], let amounta = Int64(amountStr) {
            amount = fromAmount(amounta)
        } else {
            throw TxRepError.missingValue(key: key)
        }
        key = opPrefix + "from";
        let accountId:String
        if let accountIdStr = dic[key] {
            do {
                let kp = try KeyPair(accountId:accountIdStr)
                accountId = kp.accountId;
            } catch {
                throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
        return ClawbackOperation(sourceAccountId: sourceAccount?.accountId, asset: asset, fromAccountId: accountId, amount: amount)
    }
    
    private static func getRevokeSponsorshipOp(dic:Dictionary<String,String>, opPrefix:String, sourceAccount:MuxedAccount?) throws -> RevokeSponsorshipOperation? {
        var key = opPrefix + "type"
        let type = try getString(dic: dic, key: key)
        if (type == "REVOKE_SPONSORSHIP_LEDGER_ENTRY") {
            let ledgerKey = try getLedgerKey(dic: dic, prefix: opPrefix + "ledgerKey.")
            return RevokeSponsorshipOperation(ledgerKey: ledgerKey, sourceAccountId: sourceAccount?.accountId);
        } else if (type == "REVOKE_SPONSORSHIP_SIGNER") {
            key = opPrefix + "signer.accountID";
            let accountId:String
            if let accountIdStr = dic[key] {
                do {
                    let kp = try KeyPair(accountId:accountIdStr)
                    accountId = kp.accountId;
                } catch {
                    throw TxRepError.invalidValue(key: key)
                }
                
                key = opPrefix + "signer.signerKey"
                let signer:SignerKeyXDR
                if let sKeyStr = dic[key] {
                    do {
                        if sKeyStr.hasPrefix("G") {
                            signer = SignerKeyXDR.ed25519(WrappedData32(try sKeyStr.decodeEd25519PublicKey()))
                        } else if sKeyStr.hasPrefix("T") {
                            signer = SignerKeyXDR.preAuthTx(WrappedData32(try sKeyStr.decodePreAuthTx()))
                        } else if sKeyStr.hasPrefix("X") {
                            signer = SignerKeyXDR.hashX(WrappedData32(try sKeyStr.decodeSha256Hash()))
                        } else {
                           throw TxRepError.invalidValue(key: key)
                        }
                    } catch {
                        throw TxRepError.invalidValue(key: key)
                    }
                } else {
                    throw TxRepError.missingValue(key: key)
                }
                return RevokeSponsorshipOperation(signerAccountId: accountId, signerKey: signer, sourceAccountId: sourceAccount?.accountId)
            } else {
                throw TxRepError.missingValue(key: key)
            }
        }
        return nil;
    }
    
    private static func getEndSponsoringFutureReservesOp(sourceAccount:MuxedAccount?) throws -> EndSponsoringFutureReservesOperation? {
        return EndSponsoringFutureReservesOperation(sponsoredAccountId: sourceAccount?.accountId);
    }
    
    private static func getBeginSponsoringFutureReservesOp(dic:Dictionary<String,String>, opPrefix:String, sourceAccount:MuxedAccount?) throws -> BeginSponsoringFutureReservesOperation? {
        let key = opPrefix + "sponsoredID"
        if let accId = dic[key] {
            return BeginSponsoringFutureReservesOperation(sponsoredAccountId: accId, sponsoringAccountId: sourceAccount?.accountId);
        } else {
            throw TxRepError.missingValue(key: key)
        }
    }
    
    private static func getClaimClaimableBalanceOp(dic:Dictionary<String,String>, opPrefix:String, sourceAccount:MuxedAccount?) throws -> ClaimClaimableBalanceOperation? {
        let key = opPrefix + "balanceID.v0"
        if let balanceId = dic[key] {
            return ClaimClaimableBalanceOperation(balanceId: balanceId, sourceAccountId: sourceAccount?.accountId);
        } else {
            throw TxRepError.missingValue(key: key)
        }
    }
    
    private static func getCreateClaimableBalanceOp(dic:Dictionary<String,String>, opPrefix:String, sourceAccount:MuxedAccount?) throws -> CreateClaimableBalanceOperation? {
       
        var key = opPrefix + "asset"
        let asset:Asset
        if let assetStr = dic[key] {
            if let asseta = decodeAsset(asset: assetStr) {
                asset = asseta
            } else {
               throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
        
        key = opPrefix + "amount"
        let amount:Decimal
        if let amountStr = dic[key], let amounta = Int64(amountStr) {
            amount = fromAmount(amounta)
        } else {
            throw TxRepError.missingValue(key: key)
        }
        key = opPrefix + "claimants.len"
        var claimants:[Claimant] = [Claimant]()
        if let claimantsLen = dic[key] {
            if let count = Int(claimantsLen) {
                for i in 0..<count{
                    try claimants.append(getClaimant(dic:dic, opPrefix: opPrefix, index: i))
                }
            } else {
                throw TxRepError.invalidValue(key: key)
            }
        }
        return CreateClaimableBalanceOperation(asset:asset, amount:amount, claimants:claimants, sourceAccountId: sourceAccount?.accountId);
    }
    
    private static func getClaimant(dic:Dictionary<String,String>, opPrefix:String, index:Int) throws -> Claimant {
        var key = opPrefix + "claimants[" + String(index) + "].v0.destination";
        let destination:String
        if let destinationd = dic[key] {
            do {
                let kp = try KeyPair(accountId:destinationd)
                destination = kp.accountId;
            } catch {
                throw TxRepError.invalidValue(key: key)
            }
            
        } else {
            throw TxRepError.missingValue(key: key)
        }
        key = opPrefix + "claimants[" + String(index) + "].v0.predicate."
        let predicate = try getClaimPredicate(dic: dic, opPrefix: key)
        return Claimant(destination: destination, predicate: predicate)
    }
    
    private static func getClaimPredicate(dic:Dictionary<String,String>, opPrefix:String) throws -> ClaimPredicateXDR {
        var key = opPrefix + "type"
        let type:String
        if let typeStr = dic[key] {
            type = typeStr
        } else {
            throw TxRepError.missingValue(key: key)
        }
        switch (type) {
        case "CLAIM_PREDICATE_UNCONDITIONAL":
            return ClaimPredicateXDR.claimPredicateUnconditional;
        case "CLAIM_PREDICATE_AND":
            key = opPrefix + "andPredicates.len"
            var andPredicates:[ClaimPredicateXDR] = [ClaimPredicateXDR]()
            if let predLen = dic[key] {
                if let count = Int(predLen), count == 2 {
                    for i in 0..<count{
                        try andPredicates.append(getClaimPredicate(dic:dic, opPrefix: opPrefix + "andPredicates[" + String(i) + "]."));
                    }
                } else {
                    throw TxRepError.invalidValue(key: key)
                }
            } else {
                throw TxRepError.missingValue(key: key)
            }
            return ClaimPredicateXDR.claimPredicateAnd(andPredicates)
        case "CLAIM_PREDICATE_OR":
            key = opPrefix + "orPredicates.len"
            var orPredicates:[ClaimPredicateXDR] = [ClaimPredicateXDR]()
            if let predLen = dic[key] {
                if let count = Int(predLen), count == 2 {
                    for i in 0..<count{
                        try orPredicates.append(getClaimPredicate(dic:dic, opPrefix: opPrefix + "orPredicates[" + String(i) + "]."));
                    }
                } else {
                    throw TxRepError.invalidValue(key: key)
                }
            } else {
                throw TxRepError.missingValue(key: key)
            }
            return ClaimPredicateXDR.claimPredicateOr(orPredicates)
        case "CLAIM_PREDICATE_NOT":
            return try ClaimPredicateXDR.claimPredicateNot(getClaimPredicate(dic: dic, opPrefix: opPrefix + "notPredicate."))
        case "CLAIM_PREDICATE_BEFORE_ABSOLUTE_TIME":
            key = opPrefix + "absBefore"
            if let timeStr = dic[key] {
                if let time64 = Int64(timeStr) {
                    return ClaimPredicateXDR.claimPredicateBeforeAbsTime(time64)
                } else {
                    throw TxRepError.invalidValue(key: key)
                }
            } else {
                throw TxRepError.missingValue(key: key)
            }
        case "CLAIM_PREDICATE_BEFORE_RELATIVE_TIME":
            key = opPrefix + "relBefore"
            if let timeStr = dic[key] {
                if let time64 = Int64(timeStr) {
                    return ClaimPredicateXDR.claimPredicateBeforeRelTime(time64)
                } else {
                    throw TxRepError.invalidValue(key: key)
                }
            } else {
                throw TxRepError.missingValue(key: key)
            }
        default:
            throw TxRepError.missingValue(key: key)
        }
    }
    
    private static func getCreateAccountOperation(dic:Dictionary<String,String>, opPrefix:String, sourceAccount:MuxedAccount?) throws -> CreateAccountOperation? {
        var key = opPrefix + "destination"
        let destinationKeyPair:KeyPair
        if let destination = dic[key] {
            do {
                destinationKeyPair = try KeyPair(accountId:destination)
            } catch {
                throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
        key = opPrefix + "startingBalance"
        if let strStartingBalance = dic[key], let startingBalance = Int64(strStartingBalance) {
            return CreateAccountOperation(sourceAccountId: sourceAccount?.accountId, destination: destinationKeyPair, startBalance: fromAmount(startingBalance))
        } else {
            throw TxRepError.missingValue(key: key)
        }
    }
    
    private static func getPaymentOperation(dic:Dictionary<String,String>, opPrefix:String, sourceAccount:MuxedAccount?) throws -> PaymentOperation? {
        var key = opPrefix + "destination"
        let destinationId:String
        if let destination = dic[key] {
            do {
                _ = try MuxedAccount(accountId:destination)
                destinationId = destination
            } catch {
                throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
        key = opPrefix + "asset"
        let asset:Asset
        if let assetStr = dic[key] {
            if let asseta = decodeAsset(asset: assetStr) {
                asset = asseta
            } else {
               throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
        
        key = opPrefix + "amount"
        if let amountStr = dic[key], let amount = Int64(amountStr) {
            return try PaymentOperation(sourceAccountId: sourceAccount?.accountId, destinationAccountId: destinationId, asset: asset, amount: fromAmount(amount))
        } else {
            throw TxRepError.missingValue(key: key)
        }
    }
    
    private static func getPaymentStrictReceiveOperation(dic:Dictionary<String,String>, opPrefix:String, sourceAccount:MuxedAccount?) throws -> PathPaymentStrictReceiveOperation? {
        var key = opPrefix + "sendAsset"
        let sendAsset:Asset
        if let assetStr = dic[key] {
            if let asseta = decodeAsset(asset: assetStr) {
                sendAsset = asseta
            } else {
               throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
        key = opPrefix + "sendMax"
        let sendMax:Decimal
        if let amountStr = dic[key], let amount = Int64(amountStr) {
            sendMax = fromAmount(amount)
        } else {
            throw TxRepError.missingValue(key: key)
        }
        key = opPrefix + "destination"
        let destinationId:String
        if let destination = dic[key] {
            do {
                _ = try MuxedAccount(accountId:destination)
                destinationId = destination
            } catch {
                throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
        key = opPrefix + "destAsset"
        let destAsset:Asset
        if let assetStr = dic[key] {
            if let asseta = decodeAsset(asset: assetStr) {
                destAsset = asseta
            } else {
               throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
        key = opPrefix + "destAmount"
        let destAmount:Decimal
        if let amountStr = dic[key], let amount = Int64(amountStr) {
            destAmount = fromAmount(amount)
        } else {
            throw TxRepError.missingValue(key: key)
        }
        key = opPrefix + "path.len"
        var pathAssets:[Asset] = [Asset]()
        if let pathLen = dic[key] {
            if let count = Int(pathLen) {
                if count > 5 {
                    throw TxRepError.invalidValue(key: key)
                }
                for i in 0..<count{
                    let kkey = opPrefix + "path[" + String(i) + "]"
                    if let nextAssetStr = dic[kkey] {
                        if let nextAsset = decodeAsset(asset: nextAssetStr) {
                            pathAssets.append(nextAsset)
                        } else {
                            throw TxRepError.invalidValue(key: kkey)
                        }
                    } else {
                        throw TxRepError.missingValue(key: kkey)
                    }
                }
            } else {
                throw TxRepError.invalidValue(key: key)
            }
        }
        return try PathPaymentStrictReceiveOperation(sourceAccountId: sourceAccount?.accountId, sendAsset: sendAsset, sendMax: sendMax, destinationAccountId: destinationId, destAsset: destAsset, destAmount: destAmount, path: pathAssets)
    }
    
    private static func getPaymentStrictSendOperation(dic:Dictionary<String,String>, opPrefix:String, sourceAccount:MuxedAccount?) throws -> PathPaymentStrictSendOperation? {
        var key = opPrefix + "sendAsset"
        let sendAsset:Asset
        if let assetStr = dic[key] {
            if let asseta = decodeAsset(asset: assetStr) {
                sendAsset = asseta
            } else {
               throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
        key = opPrefix + "sendAmount"
        let sendAmount:Decimal
        if let amountStr = dic[key], let amount = Int64(amountStr) {
            sendAmount = fromAmount(amount)
        } else {
            throw TxRepError.missingValue(key: key)
        }
        key = opPrefix + "destination"
        let destinationId:String
        if let destination = dic[key] {
            do {
                _ = try MuxedAccount(accountId:destination)
                destinationId = destination
            } catch {
                throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
        key = opPrefix + "destAsset"
        let destAsset:Asset
        if let assetStr = dic[key] {
            if let asseta = decodeAsset(asset: assetStr) {
                destAsset = asseta
            } else {
               throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
        key = opPrefix + "destMin"
        let destMin:Decimal
        if let amountStr = dic[key], let amount = Int64(amountStr) {
            destMin = fromAmount(amount)
        } else {
            throw TxRepError.missingValue(key: key)
        }
        key = opPrefix + "path.len"
        var pathAssets:[Asset] = [Asset]()
        if let pathLen = dic[key] {
            if let count = Int(pathLen) {
                if count > 5 {
                    throw TxRepError.invalidValue(key: key)
                }
                for i in 0..<count{
                    let kkey = opPrefix + "path[" + String(i) + "]"
                    if let nextAssetStr = dic[kkey] {
                        if let nextAsset = decodeAsset(asset: nextAssetStr) {
                            pathAssets.append(nextAsset)
                        } else {
                            throw TxRepError.invalidValue(key: kkey)
                        }
                    } else {
                        throw TxRepError.missingValue(key: kkey)
                    }
                }
            } else {
                throw TxRepError.invalidValue(key: key)
            }
        }
        return try PathPaymentStrictSendOperation(sourceAccountId: sourceAccount?.accountId, sendAsset: sendAsset, sendMax: sendAmount, destinationAccountId: destinationId, destAsset: destAsset, destAmount: destMin, path: pathAssets)
    }
    
    private static func getManageSellOfferOperation(dic:Dictionary<String,String>, opPrefix:String, sourceAccount:MuxedAccount?) throws -> ManageSellOfferOperation? {
        var key = opPrefix + "selling"
        let selling:Asset
        if let assetStr = dic[key] {
            if let asseta = decodeAsset(asset: assetStr) {
                selling = asseta
            } else {
               throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
        key = opPrefix + "buying"
        let buying:Asset
        if let assetStr = dic[key] {
            if let asseta = decodeAsset(asset: assetStr) {
                buying = asseta
            } else {
               throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
        key = opPrefix + "amount"
        let amount:Decimal
        if let amountStr = dic[key], let damount = Int64(amountStr) {
            amount = fromAmount(damount)
        } else {
            throw TxRepError.missingValue(key: key)
        }
        key = opPrefix + "price.n"
        let priceN:Int32
        if let pricetStr = dic[key], let price = Int32(pricetStr) {
            priceN = price
        } else {
            throw TxRepError.missingValue(key: key)
        }
        key = opPrefix + "price.d"
        let priceD:Int32
        if let pricetStr = dic[key], let price = Int32(pricetStr) {
            priceD = price
            if priceD == 0 {
                throw TxRepError.invalidValue(key: key + " price.d can not be 0")
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
        key = opPrefix + "offerID"
        var offerId:Int64 = 0
        if let offerIdStr = dic[key] {
            if let offerIdi = Int64(offerIdStr) {
                offerId = offerIdi
            } else {
                throw TxRepError.invalidValue(key: key)
            }
        }
        return ManageSellOfferOperation(sourceAccountId: sourceAccount?.accountId, selling: selling, buying: buying, amount: amount, price: Price(numerator: priceN, denominator: priceD), offerId: offerId)
    }
    
    private static func getManageBuyOfferOperation(dic:Dictionary<String,String>, opPrefix:String, sourceAccount:MuxedAccount?) throws -> ManageBuyOfferOperation? {
        var key = opPrefix + "selling"
        let selling:Asset
        if let assetStr = dic[key] {
            if let asseta = decodeAsset(asset: assetStr) {
                selling = asseta
            } else {
               throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
        key = opPrefix + "buying"
        let buying:Asset
        if let assetStr = dic[key] {
            if let asseta = decodeAsset(asset: assetStr) {
                buying = asseta
            } else {
               throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
        key = opPrefix + "buyAmount"
        let amount:Decimal
        if let amountStr = dic[key], let damount = Int64(amountStr) {
            amount = fromAmount(damount)
        } else {
            throw TxRepError.missingValue(key: key)
        }
        key = opPrefix + "price.n"
        let priceN:Int32
        if let pricetStr = dic[key], let price = Int32(pricetStr) {
            priceN = price
        } else {
            throw TxRepError.missingValue(key: key)
        }
        key = opPrefix + "price.d"
        let priceD:Int32
        if let pricetStr = dic[key], let price = Int32(pricetStr) {
            priceD = price
            if priceD == 0 {
                throw TxRepError.invalidValue(key: key + " price.d can not be 0")
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
        key = opPrefix + "offerID"
        var offerId:Int64 = 0
        if let offerIdStr = dic[key] {
            if let offerIdi = Int64(offerIdStr) {
                offerId = offerIdi
            } else {
                throw TxRepError.invalidValue(key: key)
            }
        }
        return ManageBuyOfferOperation(sourceAccountId: sourceAccount?.accountId, selling: selling, buying: buying, amount: amount, price: Price(numerator: priceN, denominator: priceD), offerId: offerId)
    }
    
    private static func getCreatePassiveSellOfferOperation(dic:Dictionary<String,String>, opPrefix:String, sourceAccount:MuxedAccount?) throws -> CreatePassiveOfferOperation? {
        var key = opPrefix + "selling"
        let selling:Asset
        if let assetStr = dic[key] {
            if let asseta = decodeAsset(asset: assetStr) {
                selling = asseta
            } else {
               throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
        key = opPrefix + "buying"
        let buying:Asset
        if let assetStr = dic[key] {
            if let asseta = decodeAsset(asset: assetStr) {
                buying = asseta
            } else {
               throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
        key = opPrefix + "amount"
        let amount:Decimal
        if let amountStr = dic[key], let damount = Int64(amountStr) {
            amount = fromAmount(damount)
        } else {
            throw TxRepError.missingValue(key: key)
        }
        key = opPrefix + "price.n"
        let priceN:Int32
        if let pricetStr = dic[key], let price = Int32(pricetStr) {
            priceN = price
        } else {
            throw TxRepError.missingValue(key: key)
        }
        key = opPrefix + "price.d"
        let priceD:Int32
        if let pricetStr = dic[key], let price = Int32(pricetStr) {
            priceD = price
            if priceD == 0 {
                throw TxRepError.invalidValue(key: key + " price.d can not be 0")
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
        return CreatePassiveSellOfferOperation(sourceAccountId: sourceAccount?.accountId, selling: selling, buying: buying, amount: amount, price: Price(numerator: priceN, denominator: priceD))
    }
    
    private static func getSetOptionsOperation(dic:Dictionary<String,String>, opPrefix:String, sourceAccount:MuxedAccount?) throws -> SetOptionsOperation? {
        var key = opPrefix + "inflationDest._present"
        var inflationDest:KeyPair? = nil
        if let present = dic[key], present == "true" {
            key = opPrefix + "inflationDest"
            if let destination =  dic[key] {
                do {
                    inflationDest = try KeyPair(accountId: destination)
                } catch {
                    throw TxRepError.invalidValue(key: key)
                }
            } else {
                throw TxRepError.missingValue(key: key)
            }
        }
        key = opPrefix + "clearFlags._present"
        var clearFlags:UInt32? = nil
        if let present = dic[key], present == "true" {
            key = opPrefix + "clearFlags"
            if let flagsStr = dic[key] {
                if let flags = UInt32(flagsStr){
                    clearFlags = flags
                } else {
                    throw TxRepError.invalidValue(key: key)
                }
            } else {
                throw TxRepError.missingValue(key: key)
            }
        }
        key = opPrefix + "setFlags._present"
        var setFlags:UInt32? = nil
        if let present = dic[key], present == "true" {
            key = opPrefix + "setFlags"
            if let flagsStr = dic[key] {
                if let flags = UInt32(flagsStr){
                    setFlags = flags
                } else {
                    throw TxRepError.invalidValue(key: key)
                }
            } else {
                throw TxRepError.missingValue(key: key)
            }
        }
        key = opPrefix + "masterWeight._present"
        var masterKeyWeight:UInt32? = nil
        if let present = dic[key], present == "true" {
            key = opPrefix + "masterWeight"
            if let weightStr = dic[key] {
                if let weight = UInt32(weightStr){
                    masterKeyWeight = weight
                } else {
                    throw TxRepError.invalidValue(key: key)
                }
            } else {
                throw TxRepError.missingValue(key: key)
            }
        }
        key = opPrefix + "lowThreshold._present"
        var lowThreshold:UInt32? = nil
        if let present = dic[key], present == "true" {
            key = opPrefix + "lowThreshold"
            if let tStr = dic[key] {
                if let t = UInt32(tStr){
                    lowThreshold = t
                } else {
                    throw TxRepError.invalidValue(key: key)
                }
            } else {
                throw TxRepError.missingValue(key: key)
            }
        }
        key = opPrefix + "medThreshold._present"
        var medThreshold:UInt32? = nil
        if let present = dic[key], present == "true" {
            key = opPrefix + "medThreshold"
            if let tStr = dic[key] {
                if let t = UInt32(tStr){
                    medThreshold = t
                } else {
                    throw TxRepError.invalidValue(key: key)
                }
            } else {
                throw TxRepError.missingValue(key: key)
            }
        }
        key = opPrefix + "highThreshold._present"
        var highThreshold:UInt32? = nil
        if let present = dic[key], present == "true" {
            key = opPrefix + "highThreshold"
            if let tStr = dic[key] {
                if let t = UInt32(tStr){
                    highThreshold = t
                } else {
                    throw TxRepError.invalidValue(key: key)
                }
            } else {
                throw TxRepError.missingValue(key: key)
            }
        }
        
        key = opPrefix + "homeDomain._present"
        var homeDomain:String?
        if let present = dic[key], present == "true" {
            key = opPrefix + "homeDomain"
            if let text = dic[key] {
                do {
                    let jsonDecoder = JSONDecoder()
                    if let textData = text.data(using: .utf8) {
                        homeDomain = try jsonDecoder.decode(String.self, from:textData)
                    } else {
                        homeDomain = text.replacingOccurrences(of: "\"", with: "")
                    }
                } catch {
                    throw TxRepError.invalidValue(key: key)
                }
            } else {
                throw TxRepError.missingValue(key: key)
            }
        }
    
        key = opPrefix + "signer._present"
        var signer:SignerKeyXDR?
        var signerWeight:UInt32?
        if let present = dic[key], present == "true" {
            key = opPrefix + "signer.weight"
            if let tStr = dic[key] {
                if let t = UInt32(tStr){
                    signerWeight = t
                } else {
                    throw TxRepError.invalidValue(key: key)
                }
            } else {
                throw TxRepError.missingValue(key: key)
            }
            key = opPrefix + "signer.key"
            if let sKeyStr = dic[key] {
                do {
                    if sKeyStr.hasPrefix("G") {
                        signer = SignerKeyXDR.ed25519(WrappedData32(try sKeyStr.decodeEd25519PublicKey()))
                    } else if sKeyStr.hasPrefix("T") {
                        signer = SignerKeyXDR.preAuthTx(WrappedData32(try sKeyStr.decodePreAuthTx()))
                    } else if sKeyStr.hasPrefix("X") {
                        signer = SignerKeyXDR.hashX(WrappedData32(try sKeyStr.decodeSha256Hash()))
                    } else {
                       throw TxRepError.invalidValue(key: key)
                    }
                } catch {
                    throw TxRepError.invalidValue(key: key)
                }
            } else {
                throw TxRepError.missingValue(key: key)
            }
        }
        
        return try SetOptionsOperation(sourceAccountId: sourceAccount?.accountId, inflationDestination: inflationDest, clearFlags: clearFlags, setFlags: setFlags, masterKeyWeight: masterKeyWeight, lowThreshold: lowThreshold, mediumThreshold: medThreshold, highThreshold: highThreshold, homeDomain: homeDomain, signer: signer, signerWeight: signerWeight)
    }
    
    private static func getChangeTrustOperation(dic:Dictionary<String,String>, opPrefix:String, sourceAccount:MuxedAccount?) throws -> ChangeTrustOperation? {
        var key = opPrefix + "line"
        let asset:ChangeTrustAsset
        if let assetStr = dic[key] {
           if let asseta = decodeChangeTrustAsset(asset: assetStr) {
               asset = asseta
           } else {
              throw TxRepError.invalidValue(key: key)
           }
        } else {
           throw TxRepError.missingValue(key: key)
        }
        key = opPrefix + "limit"
        var limit:Decimal? = nil
        if let amountStr = dic[key] {
            if let damount = Int64(amountStr) {
                limit = fromAmount(damount)
            } else {
                throw TxRepError.invalidValue(key: key)
            }
        }
        return ChangeTrustOperation(sourceAccountId: sourceAccount?.accountId, asset: asset, limit: limit)
    }
    
    private static func getAllowTrustOperation(dic:Dictionary<String,String>, opPrefix:String, sourceAccount:MuxedAccount?) throws -> AllowTrustOperation? {
        var key = opPrefix + "trustor"
        let trustorKeyPair:KeyPair
        if let trustor = dic[key] {
            do {
                trustorKeyPair = try KeyPair(accountId:trustor)
            } catch {
                throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
        key = opPrefix + "asset"
        let asset:String
        if let assetStr = dic[key] {
           asset = assetStr
        } else {
           throw TxRepError.missingValue(key: key)
        }
        key = opPrefix + "authorize"
        let authorize:UInt32
        if let authStr = dic[key], let auth = UInt32(authStr) {
            authorize = auth
            if authorize < 0 || authorize > 2 {
                throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
        return try AllowTrustOperation(sourceAccountId: sourceAccount?.accountId, trustor: trustorKeyPair, assetCode: asset, authorize: authorize)
    }
    
    private static func getAccountMergeOperation(dic:Dictionary<String,String>, txPrefix:String, index:Int, sourceAccount:MuxedAccount?) throws -> AccountMergeOperation? {
        let key = txPrefix + "operations[" + String(index) + "].body.destination"
        let destinationId:String
        if let destination = dic[key] {
            do {
                _ = try MuxedAccount(accountId:destination)
                destinationId = destination
            } catch {
                throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
        return try AccountMergeOperation(destinationAccountId: destinationId, sourceAccountId: sourceAccount?.accountId)
    }
    
    private static func getManageDataOperation(dic:Dictionary<String,String>, opPrefix:String, sourceAccount:MuxedAccount?) throws -> ManageDataOperation? {
        let jsonDecoder = JSONDecoder()
        var key = opPrefix + "dataName"
        var dataName:String
        if let text = dic[key] {
          do {
              if let textData = text.data(using: .utf8) {
                  dataName = try jsonDecoder.decode(String.self, from:textData)
              } else {
                  dataName = text.replacingOccurrences(of: "\"", with: "")
              }
          } catch {
              throw TxRepError.invalidValue(key: key)
          }
        } else {
          throw TxRepError.missingValue(key: key)
        }
    
        key = opPrefix + "dataValue"
        var dataValue:Data?
        if let text = dic[key], let value = text.data(using: .hexadecimal) {
          dataValue = value
        }
        
        return ManageDataOperation(sourceAccountId: sourceAccount?.accountId, name: dataName, data: dataValue)
    }
    
    private static func getBumpSequenceOperation(dic:Dictionary<String,String>, opPrefix:String, sourceAccount:MuxedAccount?) throws -> BumpSequenceOperation? {
        let key = opPrefix + "bumpTo"
        let bumpTo:Int64
        if let bumpToStr = dic[key] {
            if let b2 = Int64(bumpToStr) {
                bumpTo = b2
            } else {
                throw TxRepError.invalidValue(key: key)
            }
        } else {
           throw TxRepError.missingValue(key: key)
        }
        return BumpSequenceOperation(bumpTo: bumpTo, sourceAccountId: sourceAccount?.accountId)
    }
    
    private static func getPreconditions(dic:Dictionary<String,String>, prefix:String) throws -> TransactionPreconditions {
        var timeBounds:TimeBounds? = nil
        var precondPrefix = prefix + "cond."
        var key = precondPrefix + "type"
        if let type = dic[key] {
            if "PRECOND_NONE" == type {
                return TransactionPreconditions()
            }
            
            if "PRECOND_TIME" == type {
                if let min = dic[precondPrefix + "timeBounds.minTime"], let max = dic[precondPrefix + "timeBounds.maxTime"],
                    let minTime = UInt64(min), let maxTime = UInt64(max) {
                    timeBounds = TimeBounds(minTime: minTime, maxTime: maxTime)
                } else {
                    throw TxRepError.invalidValue(key: precondPrefix + "timeBounds")
                }
                if let tb = timeBounds {
                    return TransactionPreconditions(timeBounds: tb)
                } else {
                    throw TxRepError.missingValue(key: precondPrefix + "timeBounds")
                }
            }

            if "PRECOND_V2" != type {
                throw TxRepError.invalidValue(key: key)
            } else {
                precondPrefix += "v2."
            }
            
            timeBounds = try getTimeBounds(dic: dic, prefix: precondPrefix)
            let ledgerBounds:LedgerBounds? = try getLedgerBounds(dic: dic, prefix: precondPrefix)
            
            var minSeqNr:Int64? = nil
            key = precondPrefix + "minSeqNum._present"
            if let present = dic[key], present == "true" {
                if let strVal = dic[precondPrefix + "minSeqNum"], let iVal = Int64(strVal) {
                    minSeqNr = iVal
                } else {
                    throw TxRepError.invalidValue(key: precondPrefix + "minSeqNum")
                }
            }
            
            var minSeqAge:UInt64? = nil
            key = precondPrefix + "minSeqAge"
            if let strVal = dic[key] {
                if let iVal = UInt64(strVal) {
                    minSeqAge = iVal
                } else {
                    throw TxRepError.invalidValue(key: precondPrefix + "minSeqNum")
                }
            } else {
               throw TxRepError.missingValue(key: precondPrefix + "minSeqNum")
            }
            
            var minSeqLedgerGap:UInt32? = nil
            key = precondPrefix + "minSeqLedgerGap"
            if let strVal = dic[key] {
                if let iVal = UInt32(strVal) {
                    minSeqLedgerGap = iVal
                } else {
                    throw TxRepError.invalidValue(key: precondPrefix + "minSeqLedgerGap")
                }
            } else {
               throw TxRepError.missingValue(key: precondPrefix + "minSeqLedgerGap")
            }
            var extraSigners:[SignerKeyXDR] = [SignerKeyXDR]()
            key = precondPrefix + "extraSigners.len"
            if let sLengthStr = dic[key] {
                if let sCount = Int(sLengthStr) {
                    if sCount > 2 {
                        throw TxRepError.invalidValue(key: key + " > 2")
                    }
                    for i in 0..<sCount{
                        key = precondPrefix + "extraSigners[" + String(i) + "]"
                        if let sKeyStr = dic[key] {
                            do {
                                if sKeyStr.hasPrefix("G") {
                                    extraSigners.append(SignerKeyXDR.ed25519(WrappedData32(try sKeyStr.decodeEd25519PublicKey())))
                                } else if sKeyStr.hasPrefix("T") {
                                    extraSigners.append(SignerKeyXDR.preAuthTx(WrappedData32(try sKeyStr.decodePreAuthTx())))
                                } else if sKeyStr.hasPrefix("X") {
                                    extraSigners.append(SignerKeyXDR.hashX(WrappedData32(try sKeyStr.decodeSha256Hash())))
                                } else if sKeyStr.hasPrefix("P") {
                                    extraSigners.append(SignerKeyXDR.signedPayload(try sKeyStr.decodeSignedPayload()))
                                } else {
                                   throw TxRepError.invalidValue(key: key)
                                }
                            } catch {
                                throw TxRepError.invalidValue(key: key)
                            }
                        } else {
                            throw TxRepError.missingValue(key: key)
                        }
                    }
                } else {
                   throw TxRepError.invalidValue(key: key)
                }
            }
            return TransactionPreconditions(ledgerBounds: ledgerBounds, timeBounds: timeBounds, minSeqNumber: minSeqNr, minSeqAge: minSeqAge!, minSeqLedgerGap: minSeqLedgerGap!, extraSigners: extraSigners)
        }
        else {
            timeBounds = try getTimeBounds(dic: dic, prefix: prefix)
            if let tB = timeBounds {
                return TransactionPreconditions(timeBounds:tB)
            } else {
                throw TxRepError.missingValue(key: precondPrefix + "type")
            }
        }
    }
    
    private static func getTimeBounds(dic:Dictionary<String,String>, prefix:String) throws -> TimeBounds? {
        var timeBounds:TimeBounds? = nil
        let key = prefix + "timeBounds._present"
        if let present = dic[key], present == "true" {
            if let min = dic[prefix + "timeBounds.minTime"], let max = dic[prefix + "timeBounds.maxTime"],
                let minTime = UInt64(min), let maxTime = UInt64(max) {
                timeBounds = TimeBounds(minTime: minTime, maxTime: maxTime)
            } else {
                throw TxRepError.invalidValue(key: prefix + "timeBounds")
            }
        }
        return timeBounds
    }
    
    private static func getLedgerBounds(dic:Dictionary<String,String>, prefix:String) throws -> LedgerBounds? {
        var ledgerBounds:LedgerBounds? = nil
        let key = prefix + "ledgerBounds._present"
        if let present = dic[key], present == "true" {
            if let min = dic[prefix + "ledgerBounds.minLedger"], let max = dic[prefix + "ledgerBounds.maxLedger"],
                let minLedger = UInt32(min), let maxLedger = UInt32(max) {
                ledgerBounds = LedgerBounds(minLedger: minLedger, maxLedger: maxLedger)
            } else {
                throw TxRepError.invalidValue(key: prefix + "ledgerBounds")
            }
        }
        return ledgerBounds
    }
    
    private static func getMemo(dic:Dictionary<String,String>, prefix:String) throws -> Memo? {
        var memo:Memo? = nil
        var key = prefix + "memo.type"
        if let type = dic[key] {
            switch type {
            case "MEMO_TEXT":
                key = prefix + "memo.text"
                if let text = dic[key] {
                    do {
                        let jsonDecoder = JSONDecoder()
                        if let textData = text.data(using: .utf8) {
                            let decodedText = try jsonDecoder.decode(String.self, from:textData)
                            memo = try Memo.init(text: decodedText)
                        } else {
                            memo = try Memo.init(text: text.replacingOccurrences(of: "\"", with: ""))
                        }
                    } catch {
                        throw TxRepError.invalidValue(key: key)
                    }
                } else {
                    throw TxRepError.missingValue(key: key)
                }
                break
            case "MEMO_ID":
                key = prefix + "memo.id"
                if let id = dic[key] {
                    if let uI64Id = UInt64(id) {
                        memo = Memo.id(uI64Id)
                    } else {
                       throw TxRepError.invalidValue(key: key)
                    }
                } else {
                    throw TxRepError.missingValue(key: key)
                }
                break
            case "MEMO_HASH":
                key = prefix + "memo.hash"
                if let hashStr = dic[key] {
                    if let data = hashStr.data(using: .hexadecimal) {
                        do {
                            memo = try Memo(hash:data)
                        } catch {
                            throw TxRepError.invalidValue(key: key)
                        }
                    } else {
                        throw TxRepError.invalidValue(key: key)
                    }
                } else {
                    throw TxRepError.missingValue(key: key)
                }
                break
            case "MEMO_RETURN":
                key = prefix + "memo.return"
                if let hashStr = dic[key] {
                    if let data = hashStr.data(using: .hexadecimal) {
                        do {
                            memo = try Memo(returnHash:data)
                        } catch {
                            throw TxRepError.invalidValue(key: key)
                        }
                    } else {
                        throw TxRepError.invalidValue(key: key)
                    }
                } else {
                    throw TxRepError.missingValue(key: key)
                }
                break
            default:
                break
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
        
        return memo
    }
    
    private static func removeComment(val:String) -> String {
        if let range = val.range(of: "(") {
          return val[..<range.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return val
    }
        
    private static func addSignatures(signatures:[DecoratedSignatureXDR], prefix:String, lines: inout [String]) -> Void {
        addLine(key: prefix + "signatures.len", value: String(signatures.count), lines: &lines)
        var index = 0
        for signature in signatures {
            addSignature(signature: signature, index: index, prefix: prefix, lines: &lines)
            index += 1
        }
    }
    
    private static func addSignature(signature:DecoratedSignatureXDR, index: Int, prefix:String, lines: inout [String]) -> Void {
        addLine(key: prefix + "signatures[" + String(index) + "].hint", value: signature.hint.wrapped.base16EncodedString(), lines: &lines)
        addLine(key: prefix + "signatures[" + String(index) + "].signature", value: signature.signature.base16EncodedString() , lines: &lines)
    }
    
    private static func addOperations(operations:[OperationXDR], prefix:String, lines: inout [String]) -> Void {
        addLine(key: prefix + "operations.len", value: String(operations.count), lines: &lines)
        var index = 0
        for operation in operations {
            addOperation(operation: operation, index: index, prefix: prefix, lines: &lines)
            index += 1
        }
    }
    
    private static func addOperation(operation:OperationXDR, index: Int, prefix:String, lines: inout [String]) -> Void {
        var operationPrefix = prefix + "operations[" + String(index) + "]."
        if let sourceAccount = operation.sourceAccount {
            addLine(key: operationPrefix + "sourceAccount._present", value: "true", lines: &lines)
            addLine(key: operationPrefix + "sourceAccount", value: sourceAccount.accountId, lines: &lines)
        } else {
            addLine(key: operationPrefix + "sourceAccount._present", value: "false", lines: &lines)
        }
        addLine(key: operationPrefix + "body.type", value: txRepOpTypeUpperCase(operation: operation), lines: &lines)
        
        operationPrefix = operationPrefix + "body." + txRepOpType(operation: operation) + "."
        
        switch operation.body {
        case .createAccount(let createAccountOp):
            addLine(key: operationPrefix + "destination", value: createAccountOp.destination.accountId, lines: &lines)
            addLine(key: operationPrefix + "startingBalance", value: String(createAccountOp.startingBalance), lines: &lines)
            break
        case .payment(let paymentOperation):
            addLine(key: operationPrefix + "destination", value: paymentOperation.destination.accountId, lines: &lines)
            addLine(key: operationPrefix + "asset", value: encodeAsset(asset: paymentOperation.asset), lines: &lines)
            addLine(key: operationPrefix + "amount", value: String(paymentOperation.amount), lines: &lines)
            break
        case .pathPayment(let pathPaymentStrictReceiveOp):
            addLine(key: operationPrefix + "sendAsset", value: encodeAsset(asset: pathPaymentStrictReceiveOp.sendAsset), lines: &lines)
            addLine(key: operationPrefix + "sendMax", value: String(pathPaymentStrictReceiveOp.sendMax), lines: &lines)
            addLine(key: operationPrefix + "destination", value: pathPaymentStrictReceiveOp.destination.accountId, lines: &lines)
            // TODO "M..."
            addLine(key: operationPrefix + "destAsset", value: encodeAsset(asset: pathPaymentStrictReceiveOp.destinationAsset), lines: &lines)
            addLine(key: operationPrefix + "destAmount", value: String(pathPaymentStrictReceiveOp.destinationAmount), lines: &lines)
            addLine(key: operationPrefix + "path.len", value: String(pathPaymentStrictReceiveOp.path.count), lines: &lines)
            var assetIndex = 0
            for asset in pathPaymentStrictReceiveOp.path {
                addLine(key: operationPrefix + "path[" + String(assetIndex) + "]", value: encodeAsset(asset: asset), lines: &lines)
                assetIndex += 1
            }
            break
        case .pathPaymentStrictSend(let pathPaymentStrictSendOp):
            addLine(key: operationPrefix + "sendAsset", value: encodeAsset(asset: pathPaymentStrictSendOp.sendAsset), lines: &lines)
            addLine(key: operationPrefix + "sendAmount", value: String(pathPaymentStrictSendOp.sendMax), lines: &lines)
            addLine(key: operationPrefix + "destination", value: pathPaymentStrictSendOp.destination.accountId, lines: &lines)
            addLine(key: operationPrefix + "destAsset", value: encodeAsset(asset: pathPaymentStrictSendOp.destinationAsset), lines: &lines)
            addLine(key: operationPrefix + "destMin", value: String(pathPaymentStrictSendOp.destinationAmount), lines: &lines)
            addLine(key: operationPrefix + "path.len", value: String(pathPaymentStrictSendOp.path.count), lines: &lines)
            var assetIndex = 0
            for asset in pathPaymentStrictSendOp.path {
                addLine(key: operationPrefix + "path[" + String(assetIndex) + "]", value: encodeAsset(asset: asset), lines: &lines)
                assetIndex += 1
            }
            break
        case .manageSellOffer(let manageSellOfferOp):
            addLine(key: operationPrefix + "selling", value: encodeAsset(asset: manageSellOfferOp.selling), lines: &lines)
            addLine(key: operationPrefix + "buying", value: encodeAsset(asset: manageSellOfferOp.buying), lines: &lines)
            addLine(key: operationPrefix + "amount", value: String(manageSellOfferOp.amount), lines: &lines)
            addLine(key: operationPrefix + "price.n", value: String(manageSellOfferOp.price.n), lines: &lines)
            addLine(key: operationPrefix + "price.d", value: String(manageSellOfferOp.price.d), lines: &lines)
            addLine(key: operationPrefix + "offerID", value: String(manageSellOfferOp.offerID), lines: &lines)
            break
        case .manageBuyOffer(let manageBuyOfferOp):
            addLine(key: operationPrefix + "selling", value: encodeAsset(asset: manageBuyOfferOp.selling), lines: &lines)
            addLine(key: operationPrefix + "buying", value: encodeAsset(asset: manageBuyOfferOp.buying), lines: &lines)
            addLine(key: operationPrefix + "buyAmount", value: String(manageBuyOfferOp.amount), lines: &lines)
            addLine(key: operationPrefix + "price.n", value: String(manageBuyOfferOp.price.n), lines: &lines)
            addLine(key: operationPrefix + "price.d", value: String(manageBuyOfferOp.price.d), lines: &lines)
            addLine(key: operationPrefix + "offerID", value: String(manageBuyOfferOp.offerID), lines: &lines)
            break
        case .createPassiveSellOffer(let createPassiveSellOfferOp):
            addLine(key: operationPrefix + "selling", value: encodeAsset(asset: createPassiveSellOfferOp.selling), lines: &lines)
            addLine(key: operationPrefix + "buying", value: encodeAsset(asset: createPassiveSellOfferOp.buying), lines: &lines)
            addLine(key: operationPrefix + "amount", value: String(createPassiveSellOfferOp.amount), lines: &lines)
            addLine(key: operationPrefix + "price.n", value: String(createPassiveSellOfferOp.price.n), lines: &lines)
            addLine(key: operationPrefix + "price.d", value: String(createPassiveSellOfferOp.price.d), lines: &lines)
            break
        case .setOptions(let setOptionOp):
            if let inflationDest = setOptionOp.inflationDestination {
                addLine(key: operationPrefix + "inflationDest._present", value: "true", lines: &lines)
                addLine(key: operationPrefix + "inflationDest", value: inflationDest.accountId, lines: &lines)
            } else {
                addLine(key: operationPrefix + "inflationDest._present", value: "false", lines: &lines)
            }
            if let clearFlags = setOptionOp.clearFlags {
                addLine(key: operationPrefix + "clearFlags._present", value: "true", lines: &lines)
                addLine(key: operationPrefix + "clearFlags", value: String(clearFlags), lines: &lines)
            } else {
                addLine(key: operationPrefix + "clearFlags._present", value: "false", lines: &lines)
            }
            if let setFlags = setOptionOp.setFlags {
                addLine(key: operationPrefix + "setFlags._present", value: "true", lines: &lines)
                addLine(key: operationPrefix + "setFlags", value: String(setFlags), lines: &lines)
            } else {
                addLine(key: operationPrefix + "setFlags._present", value: "false", lines: &lines)
            }
            if let masterWeight = setOptionOp.masterWeight {
                addLine(key: operationPrefix + "masterWeight._present", value: "true", lines: &lines)
                addLine(key: operationPrefix + "masterWeight", value: String(masterWeight), lines: &lines)
            } else {
                addLine(key: operationPrefix + "masterWeight._present", value: "false", lines: &lines)
            }
            if let lowThreshold = setOptionOp.lowThreshold {
                addLine(key: operationPrefix + "lowThreshold._present", value: "true", lines: &lines)
                addLine(key: operationPrefix + "lowThreshold", value: String(lowThreshold), lines: &lines)
            } else {
                addLine(key: operationPrefix + "lowThreshold._present", value: "false", lines: &lines)
            }
            if let medThreshold = setOptionOp.medThreshold {
                addLine(key: operationPrefix + "medThreshold._present", value: "true", lines: &lines)
                addLine(key: operationPrefix + "medThreshold", value: String(medThreshold), lines: &lines)
            } else {
                addLine(key: operationPrefix + "medThreshold._present", value: "false", lines: &lines)
            }
            if let highThreshold = setOptionOp.highThreshold {
                addLine(key: operationPrefix + "highThreshold._present", value: "true", lines: &lines)
                addLine(key: operationPrefix + "highThreshold", value: String(highThreshold), lines: &lines)
            } else {
                addLine(key: operationPrefix + "highThreshold._present", value: "false", lines: &lines)
            }
            if let homeDomain = setOptionOp.homeDomain {
                addLine(key: operationPrefix + "homeDomain._present", value: "true", lines: &lines)
                let jsonEncoder = JSONEncoder()
                if let textData = try? jsonEncoder.encode(homeDomain), let textVal = String(data:textData, encoding: .utf8) {
                    addLine(key: operationPrefix + "homeDomain", value: textVal, lines: &lines)
                } else {
                    addLine(key: operationPrefix + "homeDomain", value: "\"" + homeDomain + "\"", lines: &lines)
                }
            } else {
                addLine(key: operationPrefix + "homeDomain._present", value: "false", lines: &lines)
            }
            if let signer = setOptionOp.signer {
                addLine(key: operationPrefix + "signer._present", value: "true", lines: &lines)
                switch signer.key {
                case .ed25519(let data):
                    addLine(key: operationPrefix + "signer.key", value: try! data.wrapped.encodeEd25519PublicKey(), lines: &lines)
                    break
                case .preAuthTx(let data):
                    addLine(key: operationPrefix + "signer.key", value: try! data.wrapped.encodePreAuthTx(), lines: &lines)
                    break
                case .hashX(let data):
                    addLine(key: operationPrefix + "signer.key", value: try! data.wrapped.encodeSha256Hash(), lines: &lines)
                    break
                case .signedPayload(let payload):
                    addLine(key: operationPrefix + "signer.key", value: try! payload.encodeSignedPayload(), lines: &lines)
                    break
                }
                addLine(key: operationPrefix + "signer.weight", value: String(signer.weight), lines: &lines)
            } else {
                addLine(key: operationPrefix + "signer._present", value: "false", lines: &lines)
            }
            break
        case .changeTrust(let changeTrustOp):
            addLine(key: operationPrefix + "line", value: encodeChangeTrustAsset(asset: changeTrustOp.asset), lines: &lines)
            addLine(key: operationPrefix + "limit", value: String(changeTrustOp.limit), lines: &lines)
            break
        case .allowTrust(let allowTrustOp):
            addLine(key: operationPrefix + "trustor", value: allowTrustOp.trustor.accountId, lines: &lines)
            addLine(key: operationPrefix + "asset", value: allowTrustOp.asset.assetCode, lines: &lines)
            addLine(key: operationPrefix + "authorize", value: String(allowTrustOp.authorize), lines: &lines)
            break
        case .accountMerge(let accountMergeOp):
            // account merge does not include 'accountMergeOp' prefix
            let amKey = prefix + "operations[" + String(index) + "].body.destination"
            addLine(key: amKey, value: accountMergeOp.accountId, lines: &lines)
            break
        case .manageData(let manageDataOp):
            let jsonEncoder = JSONEncoder()
            if let textData = try? jsonEncoder.encode(manageDataOp.dataName), let textVal = String(data:textData, encoding: .utf8) {
                addLine(key: operationPrefix + "dataName", value: textVal, lines: &lines)
            } else {
                addLine(key: operationPrefix + "dataName", value: "\"" + manageDataOp.dataName + "\"", lines: &lines)
            }
            if let dataValue = manageDataOp.dataValue {
                addLine(key: operationPrefix + "dataValue._present", value: "true", lines: &lines)
                addLine(key: operationPrefix + "dataValue", value: dataValue.base16EncodedString(), lines: &lines)
            } else {
                addLine(key: operationPrefix + "dataValue._present", value: "false", lines: &lines)
            }
            break
        case .bumpSequence(let bumpOp):
            addLine(key: operationPrefix + "bumpTo", value: String(bumpOp.bumpTo), lines: &lines)
            break
        case .createClaimableBalance(let createOp):
            addLine(key: operationPrefix + "asset", value: encodeAsset(asset: createOp.asset), lines: &lines)
            addLine(key: operationPrefix + "amount", value: String(createOp.amount), lines: &lines)
            addLine(key: operationPrefix + "claimants.len", value: String(createOp.claimants.count), lines: &lines)
            var index = 0;
            for claimant in createOp.claimants {
                switch claimant {
                case .claimantTypeV0(let c):
                    addLine(key: operationPrefix + "claimants["+String(index)+"].type", value: "CLAIMANT_TYPE_V0", lines: &lines)
                    addLine(key: operationPrefix + "claimants["+String(index)+"].v0.destination", value: c.accountID.accountId, lines: &lines)
                    let px = operationPrefix + "claimants["+String(index)+"].v0.predicate."
                    addClaimPredicate(predicate: c.predicate, prefix: px, lines: &lines)
                }
                index += 1;
            }
            break;
        case .claimClaimableBalance(let claimOp):
            addLine(key: operationPrefix + "balanceID.type", value: "CLAIMABLE_BALANCE_ID_TYPE_V0", lines: &lines)
            switch claimOp.balanceID {
            case .claimableBalanceIDTypeV0(let data):
                let balanceId = data.wrapped.base16EncodedString()
                addLine(key: operationPrefix + "balanceID.v0", value: balanceId, lines: &lines)
            }
            break
        case .beginSponsoringFutureReserves(let begOp):
            addLine(key: operationPrefix + "sponsoredID", value: begOp.sponsoredId.accountId, lines: &lines)
            break
        case .revokeSponsorship(let revokeOp):
            switch revokeOp {
            case .revokeSponsorshipLedgerEntry(let ledgerKeyXDR):
                addLine(key: operationPrefix + "type", value: "REVOKE_SPONSORSHIP_LEDGER_ENTRY", lines: &lines)
                addLedgerKey(ledgerKey: ledgerKeyXDR, prefix: operationPrefix + "ledgerKey.", lines: &lines)
                break
            case .revokeSponsorshipSignerEntry(let revokeSponsorshipSignerXDR):
                addLine(key: operationPrefix + "type", value: "REVOKE_SPONSORSHIP_SIGNER", lines: &lines)
                addLine(key: operationPrefix + "signer.accountID", value: revokeSponsorshipSignerXDR.accountID.accountId, lines: &lines)
                let signerKey = revokeSponsorshipSignerXDR.signerKey
                switch signerKey {
                case .ed25519(let data):
                    addLine(key: operationPrefix + "signer.signerKey", value: try! data.wrapped.encodeEd25519PublicKey(), lines: &lines)
                    break
                case .preAuthTx(let data):
                    addLine(key: operationPrefix + "signer.signerKey", value: try! data.wrapped.encodePreAuthTx(), lines: &lines)
                    break
                case .hashX(let data):
                    addLine(key: operationPrefix + "signer.signerKey", value: try! data.wrapped.encodeSha256Hash(), lines: &lines)
                    break
                case .signedPayload(let payload):
                    addLine(key: operationPrefix + "signer.signerKey", value: try! payload.encodeSignedPayload(), lines: &lines)
                    break
                }
                break
            }
            break
        case .clawback(let clawbackOp):
            addLine(key: operationPrefix + "asset", value: encodeAsset(asset: clawbackOp.asset), lines: &lines)
            addLine(key: operationPrefix + "from", value: clawbackOp.from.accountId, lines: &lines)
            addLine(key: operationPrefix + "amount", value: String(clawbackOp.amount), lines: &lines)
            break
        case .clawbackClaimableBalance(let cOp):
            addLine(key: operationPrefix + "balanceID.type", value: "CLAIMABLE_BALANCE_ID_TYPE_V0", lines: &lines)
            let claimableBalanceIDXDR = cOp.claimableBalanceID
            switch claimableBalanceIDXDR {
            case .claimableBalanceIDTypeV0(let wrappedData32):
                let balanceId = wrappedData32.wrapped.base16EncodedString()
                addLine(key: operationPrefix + "balanceID.v0", value: balanceId, lines: &lines)
                break
            }
            break
        case .setTrustLineFlags(let sOp):
            addLine(key: operationPrefix + "trustor", value: sOp.accountID.accountId, lines: &lines)
            addLine(key: operationPrefix + "asset", value: encodeAsset(asset: sOp.asset), lines: &lines)
            addLine(key: operationPrefix + "clearFlags", value: String(sOp.clearFlags), lines: &lines)
            addLine(key: operationPrefix + "setFlags", value: String(sOp.setFlags), lines: &lines)
            break
        case .liquidityPoolDeposit(let lOp):
            addLine(key: operationPrefix + "liquidityPoolID", value: lOp.liquidityPoolID.wrapped.base16EncodedString(), lines: &lines)
            addLine(key: operationPrefix + "maxAmountA", value: String(lOp.maxAmountA), lines: &lines)
            addLine(key: operationPrefix + "maxAmountB", value: String(lOp.maxAmountB), lines: &lines)
            addLine(key: operationPrefix + "minPrice.n", value: String(lOp.minPrice.n), lines: &lines)
            addLine(key: operationPrefix + "minPrice.d", value: String(lOp.minPrice.d), lines: &lines)
            addLine(key: operationPrefix + "maxPrice.n", value: String(lOp.maxPrice.n), lines: &lines)
            addLine(key: operationPrefix + "maxPrice.d", value: String(lOp.maxPrice.d), lines: &lines)
            break
        case .liquidityPoolWithdraw(let lOp):
            addLine(key: operationPrefix + "liquidityPoolID", value: lOp.liquidityPoolID.wrapped.base16EncodedString(), lines: &lines)
            addLine(key: operationPrefix + "amount", value: String(lOp.amount), lines: &lines)
            addLine(key: operationPrefix + "minAmountA", value: String(lOp.minAmountA), lines: &lines)
            addLine(key: operationPrefix + "minAmountB", value: String(lOp.minAmountB), lines: &lines)
            break
        case .invokeHostFunction(let iOp):
            let fcPrefix = operationPrefix + "hostFunction.";
            let function = iOp.hostFunction;
            addLine(key: fcPrefix + "type" , value: txRepHostFuncType(function: function), lines: &lines)
            
            switch iOp.hostFunction {
            case .invokeContract(let invokeArgs):
                let prefix = fcPrefix + "invokeContract."
                addInvokeContractArgs(invokeArgs: invokeArgs, prefix: prefix, lines: &lines)
            case .createContract(let xdr):
                let prefix = fcPrefix + "createContract."
                addCreateContractArgs(args: xdr, prefix: prefix, lines: &lines)
            case .createContractV2(let xdr):
                let prefix = fcPrefix + "createContractV2."
                addCreateContractV2Args(args: xdr, prefix: prefix, lines: &lines)
            case .uploadContractWasm(let data):
                addLine(key: fcPrefix + "wasm" , value: data.base16EncodedString(), lines: &lines)
            }
            
            addLine(key: operationPrefix + "auth.len" , value: String(iOp.auth.count), lines: &lines)
            var index = 0
            for val in iOp.auth {
                addSorobanAuthorizationEntry(auth: val, prefix: operationPrefix + "auth[\(index)].", lines: &lines)
                index += 1
            }
        case .extendFootprintTTL(let eOp):
            addLine(key: operationPrefix + "ext.v", value: "0", lines: &lines)
            addLine(key: operationPrefix + "extendTo", value: String(eOp.extendTo), lines: &lines)
        case.restoreFootprint(_):
            addLine(key: operationPrefix + "ext.v", value: "0", lines: &lines)
        default:
            break
        }
    }
    
    private static func txRepHostFuncType(function:HostFunctionXDR) -> String {
        switch function {
        case .invokeContract(_):
            return "HOST_FUNCTION_TYPE_INVOKE_CONTRACT"
        case .createContract(_):
            return "HOST_FUNCTION_TYPE_CREATE_CONTRACT"
        case .createContractV2(_):
            return "HOST_FUNCTION_TYPE_CREATE_CONTRACT_V2"
        case .uploadContractWasm(_):
            return "HOST_FUNCTION_TYPE_UPLOAD_CONTRACT_WASM"
        }
    }
    
    private static func addSCAddress(addr:SCAddressXDR, prefix:String, lines: inout [String]) -> Void {
        switch addr {
        case .account(let publicKey):
            addLine(key: prefix + "type" , value: "SC_ADDRESS_TYPE_ACCOUNT", lines: &lines)
            addLine(key: prefix + "accountId" , value: KeyPair(publicKey: publicKey).accountId, lines: &lines)
            break
        case .contract(let wrappedData32):
            addLine(key: prefix + "type" , value: "SC_ADDRESS_TYPE_CONTRACT", lines: &lines)
            addLine(key: prefix + "contractId" , value: try! (wrappedData32.wrapped.base16EncodedString()).encodeContractIdHex(), lines: &lines)
            break
        case .muxedAccount(let muxed):
            let muxedAccount = MuxedAccountXDR.med25519(muxed)
            addLine(key: prefix + "type" , value: "SC_ADDRESS_TYPE_MUXED_ACCOUNT", lines: &lines)
            addLine(key: prefix + "muxedAccount" , value: muxedAccount.accountId, lines: &lines)
            break
        case .claimableBalanceId(let claimableBalanceId):
            addLine(key: prefix + "type", value: "SC_ADDRESS_TYPE_CLAIMABLE_BALANCE", lines: &lines)
            addLine(key: prefix + "claimableBalanceId.balanceID.type", value: "CLAIMABLE_BALANCE_ID_TYPE_V0", lines: &lines)
            addLine(key: prefix + "claimableBalanceId.balanceID.v0", value: claimableBalanceId.claimableBalanceIdString, lines: &lines)
        case .liquidityPoolId(let poolId):
            addLine(key: prefix + "type", value: "SC_ADDRESS_TYPE_LIQUIDITY_POOL", lines: &lines)
            addLine(key: prefix + "liquidityPoolId", value: poolId.poolIDString, lines: &lines)
        }
    }
    
    private static func addSCError(val:SCErrorXDR, prefix:String, lines: inout [String]) -> Void {
        switch val {
        case .contract(let contractCode):
            addLine(key: prefix + "type" , value: "SCE_CONTRACT", lines: &lines)
            addLine(key: prefix + "contractCode" , value: String(contractCode), lines: &lines)
        case .wasmVm:
            addLine(key: prefix + "type" , value: "SCE_WASM_VM", lines: &lines)
        case .context:
            addLine(key: prefix + "type" , value: "SCE_CONTEXT", lines: &lines)
        case .storage:
            addLine(key: prefix + "type" , value: "SCE_STORAGE", lines: &lines)
        case .object:
            addLine(key: prefix + "type" , value: "SCE_OBJECT", lines: &lines)
        case .crypto:
            addLine(key: prefix + "type" , value: "SCE_CRYPTO", lines: &lines)
        case .events:
            addLine(key: prefix + "type" , value: "SCE_EVENTS", lines: &lines)
        case .budget:
            addLine(key: prefix + "type" , value: "SCE_BUDGET", lines: &lines)
        case .value:
            addLine(key: prefix + "type" , value: "SCE_VALUE", lines: &lines)
        case .auth(let errorCode):
            addLine(key: prefix + "type" , value: "SCE_AUTH", lines: &lines)
            switch errorCode {
            case 0:
                addLine(key: prefix + "code" , value: "SCEC_ARITH_DOMAIN", lines: &lines)
            case 1:
                addLine(key: prefix + "code" , value: "SCEC_INDEX_BOUNDS", lines: &lines)
            case 2:
                addLine(key: prefix + "code" , value: "SCEC_INVALID_INPUT", lines: &lines)
            case 3:
                addLine(key: prefix + "code" , value: "SCEC_MISSING_VALUE", lines: &lines)
            case 4:
                addLine(key: prefix + "code" , value: "SCEC_EXISTING_VALUE", lines: &lines)
            case 5:
                addLine(key: prefix + "code" , value: "SCEC_EXCEEDED_LIMIT", lines: &lines)
            case 6:
                addLine(key: prefix + "code" , value: "SCEC_INVALID_ACTION", lines: &lines)
            case 7:
                addLine(key: prefix + "code" , value: "SCEC_INTERNAL_ERROR", lines: &lines)
            case 8:
                addLine(key: prefix + "code" , value: "SCEC_UNEXPECTED_TYPE", lines: &lines)
            case 9:
                addLine(key: prefix + "code" , value: "SCEC_UNEXPECTED_SIZE", lines: &lines)
            default:
                break
            }
        }
    }
    
    private static func addSCVal(val:SCValXDR, prefix:String, lines: inout [String]) -> Void {
        switch val {
        case .bool(let b):
            addLine(key: prefix + "type" , value: "SCV_BOOL", lines: &lines)
            addLine(key: prefix + "b" , value: String(b), lines: &lines)
            break
        case .void:
            addLine(key: prefix + "type" , value: "SCV_VOID", lines: &lines)
            break
        case .error(let err):
            addLine(key: prefix + "type" , value: "SCV_ERROR", lines: &lines)
            addSCError(val: err, prefix: prefix + "error.", lines: &lines)
            break
        case .u32(let uInt32):
            addLine(key: prefix + "type" , value: "SCV_U32", lines: &lines)
            addLine(key: prefix + "u32" , value: String(uInt32), lines: &lines)
            break
        case .i32(let int32):
            addLine(key: prefix + "type" , value: "SCV_I32", lines: &lines)
            addLine(key: prefix + "i32" , value: String(int32), lines: &lines)
            break
        case .u64(let uInt64):
            addLine(key: prefix + "type" , value: "SCV_U64", lines: &lines)
            addLine(key: prefix + "u64" , value: String(uInt64), lines: &lines)
            break
        case .i64(let int64):
            addLine(key: prefix + "type" , value: "SCV_I64", lines: &lines)
            addLine(key: prefix + "i64" , value: String(int64), lines: &lines)
            break
        case .timepoint(let uInt64):
            addLine(key: prefix + "type" , value: "SCV_TIMEPOINT", lines: &lines)
            addLine(key: prefix + "timepoint" , value: String(uInt64), lines: &lines)
            break
        case .duration(let uInt64):
            addLine(key: prefix + "type" , value: "SCV_DURATION", lines: &lines)
            addLine(key: prefix + "duration" , value: String(uInt64), lines: &lines)
            break
        case .u128(let int128PartsXDR):
            addLine(key: prefix + "type" , value: "SCV_U128", lines: &lines)
            addLine(key: prefix + "u128.hi" , value: String(int128PartsXDR.hi), lines: &lines)
            addLine(key: prefix + "u128.lo" , value: String(int128PartsXDR.lo), lines: &lines)
            break
        case .i128(let int128PartsXDR):
            addLine(key: prefix + "type" , value: "SCV_I128", lines: &lines)
            addLine(key: prefix + "i128.hi" , value: String(int128PartsXDR.hi), lines: &lines)
            addLine(key: prefix + "i128.lo" , value: String(int128PartsXDR.lo), lines: &lines)
            break
        case .u256(let u256PartsXDR):
            addLine(key: prefix + "type" , value: "SCV_U256", lines: &lines)
            addLine(key: prefix + "u256.hi_hi" , value: String(u256PartsXDR.hiHi), lines: &lines)
            addLine(key: prefix + "u256.hi_lo" , value: String(u256PartsXDR.hiLo), lines: &lines)
            addLine(key: prefix + "u256.lo_hi" , value: String(u256PartsXDR.loHi), lines: &lines)
            addLine(key: prefix + "u256.lo_lo" , value: String(u256PartsXDR.loLo), lines: &lines)
        case .i256(let i256PartsXDR):
            addLine(key: prefix + "type" , value: "SCV_I256", lines: &lines)
            addLine(key: prefix + "i256.hi_hi" , value: String(i256PartsXDR.hiHi), lines: &lines)
            addLine(key: prefix + "i256.hi_lo" , value: String(i256PartsXDR.hiLo), lines: &lines)
            addLine(key: prefix + "i256.lo_hi" , value: String(i256PartsXDR.loHi), lines: &lines)
            addLine(key: prefix + "i256.lo_lo" , value: String(i256PartsXDR.loLo), lines: &lines)
        case .bytes(let data):
            addLine(key: prefix + "type" , value: "SCV_BYTES", lines: &lines)
            addLine(key: prefix + "bytes" , value: data.base16EncodedString(), lines: &lines)
        case .string(let str):
            addLine(key: prefix + "type" , value: "SCV_STRING", lines: &lines)
            addLine(key: prefix + "str" , value: str, lines: &lines)
        case .symbol(let symbol):
            addLine(key: prefix + "type" , value: "SCV_SYMBOL", lines: &lines)
            addLine(key: prefix + "sym" , value: symbol, lines: &lines)
        case .vec(let vec):
            addLine(key: prefix + "type" , value: "SCV_VEC", lines: &lines)
            if let vec = vec {
                addLine(key: prefix + "vec._present", value: "true", lines: &lines)
                addLine(key: prefix + "vec.len" , value: String(vec.count), lines: &lines)
                var index = 0
                for val in vec {
                    addSCVal(val: val, prefix: prefix + "vec[\(index)].", lines: &lines)
                    index += 1
                }
            } else {
                addLine(key: prefix + "vec._present", value: "false", lines: &lines)
            }
        case .map(let map):
            addLine(key: prefix + "type" , value: "SCV_MAP", lines: &lines)
            if let map = map {
                addLine(key: prefix + "map._present", value: "true", lines: &lines)
                addLine(key: prefix + "map.len" , value: String(map.count), lines: &lines)
                var index = 0
                for entry in map {
                    addSCVal(val: entry.key, prefix: prefix + "map[\(index)].key.", lines: &lines)
                    addSCVal(val: entry.val, prefix: prefix + "map[\(index)].val.", lines: &lines)
                    index += 1
                }
            } else {
                addLine(key: prefix + "map._present", value: "false", lines: &lines)
            }
        case .address(let address):
            addLine(key: prefix + "type" , value: "SCV_ADDRESS", lines: &lines)
            addSCAddress(addr: address, prefix: prefix + "address.", lines: &lines)
        case .ledgerKeyContractInstance:
            addLine(key: prefix + "type" , value: "SCV_LEDGER_KEY_CONTRACT_INSTANCE", lines: &lines)
        case .ledgerKeyNonce(let n):
            addLine(key: prefix + "type" , value: "SCV_LEDGER_KEY_NONCE", lines: &lines)
            addLine(key: prefix + "nonce_key.nonce" , value: String(n.nonce), lines: &lines)
        case .contractInstance(let contractInstance):
            addLine(key: prefix + "type" , value: "SCV_CONTRACT_INSTANCE", lines: &lines)
            addContractExecutable(val: contractInstance.executable, prefix: prefix + "executable.", lines: &lines)
            if let storage = contractInstance.storage {
                addLine(key: prefix + "storage._present", value: "true", lines: &lines)
                addLine(key: prefix + "storage.len" , value: String(storage.count), lines: &lines)
                var index = 0
                for entry in storage {
                    addSCVal(val: entry.key, prefix: prefix + "storage[\(index)].key.", lines: &lines)
                    addSCVal(val: entry.val, prefix: prefix + "storage[\(index)].val.", lines: &lines)
                    index += 1
                }
            } else {
                addLine(key: prefix + "storage._present", value: "false", lines: &lines)
            }
        }
    }
    
    private static func addContractExecutable(val:ContractExecutableXDR, prefix:String, lines: inout [String]) -> Void {
        switch val {
        case .wasm(let wrappedData32):
            addLine(key: prefix + "type" , value: "CONTRACT_EXECUTABLE_WASM", lines: &lines)
            addLine(key: prefix + "wasm_hash" , value: wrappedData32.wrapped.base16EncodedString(), lines: &lines)
        case .token:
            addLine(key: prefix + "type" , value: "CONTRACT_EXECUTABLE_STELLAR_ASSET", lines: &lines)
        }
    }
    
    private static func addContractIDPreimage(val:ContractIDPreimageXDR, prefix:String, lines: inout [String]) -> Void {
        switch val {
        case .fromAddress(let xdr):
            addLine(key: prefix + "type" , value: "CONTRACT_ID_PREIMAGE_FROM_ADDRESS", lines: &lines)
            addSCAddress(addr: xdr.address, prefix: prefix + "fromAddress.address.", lines: &lines)
            addLine(key: prefix + "fromAddress.salt", value: xdr.salt.wrapped.base16EncodedString(), lines: &lines)
        case .fromAsset(let asset):
            addLine(key: prefix + "type" , value: "CONTRACT_ID_PREIMAGE_FROM_ASSET", lines: &lines)
            addLine(key: prefix + "fromAsset", value: encodeAsset(asset: asset), lines: &lines)
        }
    }
    
    private static func addCreateContractArgs(args:CreateContractArgsXDR, prefix:String, lines: inout [String]) -> Void {
        addContractIDPreimage(val: args.contractIDPreimage, prefix: prefix + "contractIDPreimage.", lines: &lines)
        addContractExecutable(val: args.executable, prefix: prefix + "executable.", lines: &lines)
    }
    
    private static func addCreateContractV2Args(args:CreateContractV2ArgsXDR, prefix:String, lines: inout [String]) -> Void {
        addContractIDPreimage(val: args.contractIDPreimage, prefix: prefix + "contractIDPreimage.", lines: &lines)
        addContractExecutable(val: args.executable, prefix: prefix + "executable.", lines: &lines)
        addLine(key: prefix + "constructorArgs.len" , value: String(args.constructorArgs.count), lines: &lines)
        var index = 0
        for val in args.constructorArgs {
            addSCVal(val: val, prefix: prefix  + "constructorArgs[\(index)]." , lines: &lines)
            index += 1
        }
    }
    
    private static func addSorobanAuthorizationEntry(auth:SorobanAuthorizationEntryXDR, prefix:String, lines: inout [String]) -> Void {
        addSorobanCredentials(credentials: auth.credentials, prefix: prefix + "credentials.", lines: &lines)
        addSorobanAuthorizedInvocation(invocation: auth.rootInvocation, prefix: prefix + "rootInvocation.", lines: &lines)
    }
    
    private static func addInvokeContractArgs(invokeArgs: InvokeContractArgsXDR, prefix:String, lines: inout [String]) -> Void {
        addSCAddress(addr: invokeArgs.contractAddress, prefix: prefix + "contractAddress.", lines: &lines)
        addLine(key: prefix + "functionName", value: invokeArgs.functionName, lines: &lines)
        addLine(key: prefix + "args.len" , value: String(invokeArgs.args.count), lines: &lines)
        var index = 0
        for val in invokeArgs.args {
            addSCVal(val: val, prefix: prefix  + "args[\(index)]." , lines: &lines)
            index += 1
        }
    }
    
    private static func addSorobanCredentials(credentials:SorobanCredentialsXDR, prefix:String, lines: inout [String]) -> Void {
        switch credentials {
        case .sourceAccount:
            addLine(key: prefix + "type" , value: "SOROBAN_CREDENTIALS_SOURCE_ACCOUNT", lines: &lines)
        case .address(let xdr):
            addLine(key: prefix + "type" , value: "SOROBAN_CREDENTIALS_ADDRESS", lines: &lines)
            addSorobanAddressCredentials(credentials: xdr, prefix: prefix + "address.", lines: &lines)
        }
    }
    
    private static func addSorobanAddressCredentials(credentials:SorobanAddressCredentialsXDR, prefix:String, lines: inout [String]) -> Void {
        addSCAddress(addr: credentials.address, prefix: prefix + "address.", lines: &lines)
        addLine(key: prefix + "nonce" , value: String(credentials.nonce), lines: &lines)
        addLine(key: prefix + "signatureExpirationLedger" , value: String(credentials.signatureExpirationLedger), lines: &lines)
        addSCVal(val: credentials.signature, prefix: prefix + "signature.", lines: &lines)
    }
    
    private static func addSorobanAuthorizedFunction(function: SorobanAuthorizedFunctionXDR, prefix:String, lines: inout [String]) -> Void {
        switch function {
        case .contractFn(let invokeContractArgsXDR):
            addLine(key: prefix + "type" , value: "SOROBAN_AUTHORIZED_FUNCTION_TYPE_CONTRACT_FN", lines: &lines)
            addInvokeContractArgs(invokeArgs: invokeContractArgsXDR, prefix: prefix + "contractFn.", lines: &lines)
        case .createContractHostFn(let createContractArgsXDR):
            addLine(key: prefix + "type" , value: "SOROBAN_AUTHORIZED_FUNCTION_TYPE_CREATE_CONTRACT_HOST_FN", lines: &lines)
            addCreateContractArgs(args: createContractArgsXDR, prefix: prefix + "createContractHostFn.", lines: &lines)
        case .createContractV2HostFn(let createContractV2ArgsXDR):
            addLine(key: prefix + "type" , value: "SOROBAN_AUTHORIZED_FUNCTION_TYPE_CREATE_CONTRACT_V2_HOST_FN", lines: &lines)
            addCreateContractV2Args(args: createContractV2ArgsXDR, prefix: prefix + "createContractV2HostFn.", lines: &lines)
        }
    }
    
    private static func addSorobanAuthorizedInvocation(invocation:SorobanAuthorizedInvocationXDR, prefix:String, lines: inout [String]) -> Void {
        addSorobanAuthorizedFunction(function: invocation.function, prefix: prefix + "function.", lines: &lines)
        
        let subInvocations = invocation.subInvocations
        addLine(key: prefix + "subInvocations.len" , value: String(subInvocations.count), lines: &lines)
        var index = 0
        for sub in subInvocations {
            addSorobanAuthorizedInvocation(invocation: sub, prefix: prefix + "subInvocations[\(index)].", lines: &lines)
            index += 1
        }
    }
    
    private static func addSorobanTransactionData(data: SorobanTransactionDataXDR, prefix:String, lines: inout [String]) -> Void {
        switch data.ext {
        case .void:
            addLine(key: prefix + "ext.v", value: "0" , lines: &lines)
        case .resourceExt(let sorobanResourcesExtV0):
            addLine(key: prefix + "ext.v", value: "1" , lines: &lines)
            let archivedSorobanEntries = sorobanResourcesExtV0.archivedSorobanEntries
            addLine(key: prefix + "ext.archivedSorobanEntries.len" , value: String(archivedSorobanEntries.count), lines: &lines)
            var index = 0
            for entry in archivedSorobanEntries {
                addLine(key: prefix + "ext.archivedSorobanEntries[\(index)]" , value: String(entry), lines: &lines)
                index += 1
            }
        }
        
        addSorobanResources(resources: data.resources, prefix: prefix + "resources.", lines: &lines)
        addLine(key: prefix + "resourceFee" , value: String(data.resourceFee), lines: &lines)
    }
    
    private static func addSorobanResources(resources: SorobanResourcesXDR, prefix:String, lines: inout [String]) -> Void {
        addLedgerFootprint(footprint: resources.footprint, prefix: prefix + "footprint.", lines: &lines)
        addLine(key: prefix + "instructions" , value: String(resources.instructions), lines: &lines)
        addLine(key: prefix + "diskReadBytes" , value: String(resources.diskReadBytes), lines: &lines)
        addLine(key: prefix + "writeBytes" , value: String(resources.writeBytes), lines: &lines)
    }
    
    private static func addLedgerFootprint(footprint: LedgerFootprintXDR, prefix:String, lines: inout [String]) -> Void {
        addLine(key: prefix + "readOnly.len" , value: String(footprint.readOnly.count), lines: &lines)
        var index = 0
        for key in footprint.readOnly {
            addLedgerKey(ledgerKey: key, prefix: prefix + "readOnly[\(index)].", lines: &lines)
            index += 1
        }
        
        addLine(key: prefix + "readWrite.len" , value: String(footprint.readWrite.count), lines: &lines)
        index = 0
        for key in footprint.readWrite {
            addLedgerKey(ledgerKey: key, prefix: prefix + "readWrite[\(index)].", lines: &lines)
            index += 1
        }
    }
    
    private static func addLedgerKey(ledgerKey: LedgerKeyXDR, prefix:String, lines: inout [String]) -> Void {
        switch ledgerKey {
        case .account(let ledgerKeyAccountXDR):
            addLine(key: prefix + "type", value: "ACCOUNT", lines: &lines)
            addLine(key: prefix + "account.accountID", value: ledgerKeyAccountXDR.accountID.accountId, lines: &lines)
        case .trustline(let ledgerKeyTrustLineXDR):
            addLine(key: prefix + "type", value: "TRUSTLINE", lines: &lines)
            addLine(key: prefix + "trustLine.accountID", value: ledgerKeyTrustLineXDR.accountID.accountId, lines: &lines)
            addLine(key: prefix + "trustLine.asset", value: encodeTrustlineAsset(asset: ledgerKeyTrustLineXDR.asset), lines: &lines)
        case .offer(let ledgerKeyOfferXDR):
            addLine(key: prefix + "type", value: "OFFER", lines: &lines)
            addLine(key: prefix + "offer.sellerID", value: ledgerKeyOfferXDR.sellerId.accountId, lines: &lines)
            addLine(key: prefix + "offer.offerID", value: String(ledgerKeyOfferXDR.offerId), lines: &lines)
        case .data(let ledgerKeyDataXDR):
            addLine(key: prefix + "type", value: "DATA", lines: &lines)
            addLine(key: prefix + "data.accountID", value: ledgerKeyDataXDR.accountId.accountId, lines: &lines)
            addLine(key: prefix + "data.dataName", value: "\"" + ledgerKeyDataXDR.dataName + "\"", lines: &lines)
        case .claimableBalance(let claimableBalanceIDXDR):
            addLine(key: prefix + "type", value: "CLAIMABLE_BALANCE", lines: &lines)
            addLine(key: prefix + "claimableBalance.balanceID.type", value: "CLAIMABLE_BALANCE_ID_TYPE_V0", lines: &lines)
            switch claimableBalanceIDXDR {
            case .claimableBalanceIDTypeV0(let wrappedData32):
                let balanceId = wrappedData32.wrapped.base16EncodedString()
                addLine(key: prefix + "claimableBalance.balanceID.v0", value: balanceId, lines: &lines)
            }
        case .liquidityPool(let xdr):
            addLine(key: prefix + "type", value: "LIQUIDITY_POOL", lines: &lines)
            addLine(key: prefix + "liquidityPool.liquidityPoolID", value: xdr.liquidityPoolID.wrapped.base16EncodedString(), lines: &lines)
        case .contractData(let xdr):
            addLine(key: prefix + "type", value: "CONTRACT_DATA", lines: &lines)
            addSCAddress(addr: xdr.contract, prefix: prefix + "contractData.contract.", lines: &lines)
            addSCVal(val: xdr.key, prefix: prefix + "contractData.key.", lines: &lines)
            switch xdr.durability {
            case .temporary:
                addLine(key: prefix + "contractData.durability", value: "TEMPORARY", lines: &lines)
            case .persistent:
                addLine(key: prefix + "contractData.durability", value: "PERSISTENT", lines: &lines)
            }
        case .contractCode(let xdr):
            addLine(key: prefix + "type", value: "CONTRACT_CODE", lines: &lines)
            addLine(key: prefix + "contractCode.hash", value: xdr.hash.wrapped.base16EncodedString(), lines: &lines)
        case .configSetting(let id):
            addLine(key: prefix + "type", value: "CONFIG_SETTING", lines: &lines)
            addConfigSettingID(id: id, prefix: prefix + "configSetting.configSettingID", lines: &lines)
        case .ttl(let xdr):
            addLine(key: prefix + "type", value: "TTL", lines: &lines)
            addLine(key: prefix + "ttl.keyHash", value: xdr.keyHash.wrapped.base16EncodedString(), lines: &lines)
        }
    }
    
    private static func addConfigSettingID(id: Int32, prefix:String, lines: inout [String]) -> Void {
        switch id {
        case 0:
            addLine(key: prefix, value: "CONFIG_SETTING_CONTRACT_MAX_SIZE_BYTES", lines: &lines)
        case 1:
            addLine(key: prefix, value: "CONFIG_SETTING_CONTRACT_COMPUTE_V0", lines: &lines)
        case 2:
            addLine(key: prefix, value: "CONFIG_SETTING_CONTRACT_LEDGER_COST_V0", lines: &lines)
        case 3:
            addLine(key: prefix, value: "CONFIG_SETTING_CONTRACT_HISTORICAL_DATA_V0", lines: &lines)
        case 4:
            addLine(key: prefix, value: "CONFIG_SETTING_CONTRACT_EVENTS_V0", lines: &lines)
        case 5:
            addLine(key: prefix, value: "CONFIG_SETTING_CONTRACT_BANDWIDTH_V0", lines: &lines)
        case 6:
            addLine(key: prefix, value: "CONFIG_SETTING_CONTRACT_COST_PARAMS_CPU_INSTRUCTIONS", lines: &lines)
        case 7:
            addLine(key: prefix, value: "CONFIG_SETTING_CONTRACT_COST_PARAMS_MEMORY_BYTES", lines: &lines)
        case 8:
            addLine(key: prefix, value: "CONFIG_SETTING_CONTRACT_DATA_KEY_SIZE_BYTES", lines: &lines)
        case 9:
            addLine(key: prefix, value: "CONFIG_SETTING_CONTRACT_DATA_ENTRY_SIZE_BYTES", lines: &lines)
        case 10:
            addLine(key: prefix, value: "CONFIG_SETTING_STATE_ARCHIVAL", lines: &lines)
        case 11:
            addLine(key: prefix, value: "CONFIG_SETTING_CONTRACT_EXECUTION_LANES", lines: &lines)
        case 12:
            addLine(key: prefix, value: "CONFIG_SETTING_LIVE_SOROBAN_STATE_SIZE_WINDOW", lines: &lines)
        case 13:
            addLine(key: prefix, value: "CONFIG_SETTING_EVICTION_ITERATOR", lines: &lines)
        case 14:
            addLine(key: prefix, value: "CONFIG_SETTING_CONTRACT_PARALLEL_COMPUTE_V0", lines: &lines)
        case 15:
            addLine(key: prefix, value: "CONFIG_SETTING_CONTRACT_LEDGER_COST_EXT_V0", lines: &lines)
        case 16:
            addLine(key: prefix, value: "CONFIG_SETTING_SCP_TIMING", lines: &lines)
        default:
            break
        }
    }
    
    private static func addClaimPredicate(predicate:ClaimPredicateXDR, prefix:String, lines: inout [String]) -> Void {
        switch predicate {
        case .claimPredicateUnconditional:
            addLine(key: prefix + "type", value: "CLAIM_PREDICATE_UNCONDITIONAL", lines: &lines)
            break
        case .claimPredicateAnd(let array):
            addLine(key: prefix + "type", value: "CLAIM_PREDICATE_AND", lines: &lines)
            addLine(key: prefix + "andPredicates.len", value: String(array.count), lines: &lines)
            var index = 0
            for pred in array {
                let px = prefix + "andPredicates[" + String(index) + "]."
                addClaimPredicate(predicate: pred, prefix: px, lines: &lines)
                index += 1
            }
            break
        case .claimPredicateOr(let array):
            addLine(key: prefix + "type", value: "CLAIM_PREDICATE_OR", lines: &lines)
            addLine(key: prefix + "orPredicates.len", value: String(array.count), lines: &lines)
            var index = 0
            for pred in array {
                let px = prefix + "orPredicates[" + String(index) + "]."
                addClaimPredicate(predicate: pred, prefix: px, lines: &lines)
                index += 1
            }
            break
        case .claimPredicateNot(let optional):
            addLine(key: prefix + "type", value: "CLAIM_PREDICATE_NOT", lines: &lines)
            if let pred = optional {
                addLine(key: prefix + "notPredicate._present", value: "true", lines: &lines)
                addClaimPredicate(predicate: pred, prefix: prefix + "notPredicate.", lines: &lines)
            } else {
                addLine(key: prefix + "notPredicate._present", value: "false", lines: &lines)
            }
            break
        case .claimPredicateBeforeAbsTime(let int64):
            addLine(key: prefix + "type", value: "CLAIM_PREDICATE_BEFORE_ABSOLUTE_TIME", lines: &lines)
            addLine(key: prefix + "absBefore", value: String(int64), lines: &lines)
            break
        case .claimPredicateBeforeRelTime(let int64):
            addLine(key: prefix + "type", value: "CLAIM_PREDICATE_BEFORE_RELATIVE_TIME", lines: &lines)
            addLine(key: prefix + "relBefore", value: String(int64), lines: &lines)
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
    
    private static func encodeChangeTrustAsset(asset: ChangeTrustAssetXDR) -> String {
        switch asset {
        case .native:
            return "XLM"
        case .poolShare:
            return "TODO" //TODO
        default:
            return asset.assetCode! + ":" + asset.issuer!.accountId
        }
    }
    
    private static func encodeTrustlineAsset(asset: TrustlineAssetXDR) -> String {
        switch asset {
        case .native:
            return "XLM"
        case .poolShare(let data):
            return data.wrapped.base16EncodedString()
        default:
            return asset.assetCode! + ":" + asset.issuer!.accountId
        }
    }
    
    private static func decodeAsset(asset: String) -> Asset? {
        if asset == "XLM" {
            return Asset(type: AssetType.ASSET_TYPE_NATIVE)!
        }
        let components = asset.components(separatedBy: ":")
        if components.count != 2 {
            return nil
        }
        let code = components[0].trimmingCharacters(in: .whitespaces)
        let issuer = components[1].trimmingCharacters(in: .whitespaces)
        let type = code.count < 5 ? AssetType.ASSET_TYPE_CREDIT_ALPHANUM4 : AssetType.ASSET_TYPE_CREDIT_ALPHANUM12
        do {
            let kp = try KeyPair(accountId: issuer)
            return Asset(type: type, code: code, issuer: kp)
        } catch {
            return nil
        }
    }
    
    private static func decodeChangeTrustAsset(asset: String) -> ChangeTrustAsset? {
        //TODO: poolshare
        if asset == "XLM" {
            return ChangeTrustAsset(type: AssetType.ASSET_TYPE_NATIVE)!
        }
        let components = asset.components(separatedBy: ":")
        if components.count != 2 {
            return nil
        }
        let code = components[0].trimmingCharacters(in: .whitespaces)
        let issuer = components[1].trimmingCharacters(in: .whitespaces)
        let type = code.count < 5 ? AssetType.ASSET_TYPE_CREDIT_ALPHANUM4 : AssetType.ASSET_TYPE_CREDIT_ALPHANUM12
        do {
            let kp = try KeyPair(accountId: issuer)
            return ChangeTrustAsset(type: type, code: code, issuer: kp)
        } catch {
            return nil
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
        case .createClaimableBalance(_):
            return "createClaimableBalanceOp"
        case .claimClaimableBalance(_):
            return "claimClaimableBalanceOp"
        case .beginSponsoringFutureReserves(_):
            return "beginSponsoringFutureReservesOp"
        case .endSponsoringFutureReserves:
            return "endSponsoringFutureReservesOp"
        case .revokeSponsorship(_):
            return "revokeSponsorshipOp"
        case .clawback(_):
            return "clawbackOp"
        case .clawbackClaimableBalance(_):
            return "clawbackClaimableBalanceOp"
        case .setTrustLineFlags(_):
            return "setTrustLineFlagsOp"
        case .liquidityPoolDeposit(_):
            return "liquidityPoolDepositOp"
        case .liquidityPoolWithdraw(_):
            return "liquidityPoolWithdrawOp"
        case .invokeHostFunction(_):
            return "invokeHostFunctionOp"
        case .extendFootprintTTL(_):
            return "extendFootprintTTLOp"
        case .restoreFootprint(_):
            return "restoreFootprintOp"
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
        case .createClaimableBalance(_):
            return "CREATE_CLAIMABLE_BALANCE"
        case .claimClaimableBalance(_):
            return "CLAIM_CLAIMABLE_BALANCE"
        case .beginSponsoringFutureReserves(_):
            return "BEGIN_SPONSORING_FUTURE_RESERVES"
        case .endSponsoringFutureReserves:
            return "END_SPONSORING_FUTURE_RESERVES"
        case .revokeSponsorship(_):
            return "REVOKE_SPONSORSHIP"
        case .clawback(_):
            return "CLAWBACK"
        case .clawbackClaimableBalance(_):
            return "CLAWBACK_CLAIMABLE_BALANCE"
        case .setTrustLineFlags(_):
            return "SET_TRUST_LINE_FLAGS"
        case .liquidityPoolDeposit(_):
            return "LIQUIDITY_POOL_DEPOSIT"
        case .liquidityPoolWithdraw(_):
            return "LIQUIDITY_POOL_WITHDRAW"
        case .invokeHostFunction(_):
            return "INVOKE_HOST_FUNCTION"
        case .extendFootprintTTL(_):
            return "EXTEND_FOOTPRINT_TTL"
        case .restoreFootprint(_):
            return "RESTORE_FOOTPRINT"
        }
    }
    private static func addLine(key:String, value:String, lines: inout [String]) -> Void {
        lines.append(key + ": " + value);
    }
    
    private static func addPreconditions(cond:PreconditionsXDR?, prefix:String, lines: inout [String]) -> Void {
        if let preCond = cond {
            switch preCond {
            case .none:
                addLine(key: prefix + "cond.type", value: "PRECOND_NONE", lines: &lines)
            case .time(let timeBoundsXDR):
                addLine(key: prefix + "cond.type", value: "PRECOND_TIME", lines: &lines)
                addLine(key: prefix + "cond.timeBounds.minTime", value: String(timeBoundsXDR.minTime), lines: &lines)
                addLine(key: prefix + "cond.timeBounds.maxTime", value: String(timeBoundsXDR.maxTime), lines: &lines)
            case .v2(let preconditionsV2XDR):
                addLine(key: prefix + "cond.type", value: "PRECOND_V2", lines: &lines)
                addTimeBounds(timeBounds: preconditionsV2XDR.timeBounds, prefix: prefix + "cond.v2.", lines: &lines)
                addLedgerBounds(ledgerBounds: preconditionsV2XDR.ledgerBounds, prefix: prefix + "cond.v2.", lines: &lines)
                
                if let minSeqNum = preconditionsV2XDR.sequenceNumber {
                    addLine(key: prefix + "cond.v2.minSeqNum._present", value: "true", lines: &lines)
                    addLine(key: prefix + "cond.v2.minSeqNum", value: String(minSeqNum), lines: &lines)
                } else {
                    addLine(key: prefix + "cond.v2.minSeqNum._present", value: "false", lines: &lines)
                }
                addLine(key: prefix + "cond.v2.minSeqAge", value: String(preconditionsV2XDR.minSeqAge), lines: &lines)
                addLine(key: prefix + "cond.v2.minSeqLedgerGap", value: String(preconditionsV2XDR.minSeqLedgerGap), lines: &lines)
                addLine(key: prefix + "cond.v2.extraSigners.len", value: String(preconditionsV2XDR.extraSigners.count), lines: &lines)
                var count = 0
                for extraSigner in preconditionsV2XDR.extraSigners {
                    switch extraSigner {
                    case .ed25519(let data):
                        addLine(key: prefix + "cond.v2.extraSigners[\(String(count))]" , value: try! data.wrapped.encodeEd25519PublicKey(), lines: &lines)
                        break
                    case .preAuthTx(let data):
                        addLine(key: prefix + "cond.v2.extraSigners[\(String(count))]", value: try! data.wrapped.encodePreAuthTx(), lines: &lines)
                        break
                    case .hashX(let data):
                        addLine(key: prefix + "cond.v2.extraSigners[\(String(count))]", value: try! data.wrapped.encodeSha256Hash(), lines: &lines)
                        break
                    case .signedPayload(let payload):
                        addLine(key: prefix + "cond.v2.extraSigners[\(String(count))]", value: try! payload.encodeSignedPayload(), lines: &lines)
                        break
                    }
                    count += 1
                }
            }
        } else {
            addLine(key: prefix + "cond.type", value: "PRECOND_NONE", lines: &lines)
        }
    }
    
    private static func addLedgerBounds(ledgerBounds:LedgerBoundsXDR?, prefix:String, lines: inout [String]) -> Void {
        if let lb = ledgerBounds {
            addLine(key: prefix + "ledgerBounds._present", value: "true", lines: &lines)
            addLine(key: prefix + "ledgerBounds.minLedger", value: String(lb.minLedger), lines: &lines)
            addLine(key: prefix + "ledgerBounds.maxLedger", value: String(lb.maxLedger), lines: &lines)
        } else {
            addLine(key: prefix + "ledgerBounds._present", value: "false", lines: &lines)
        }
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
            let jsonEncoder = JSONEncoder()
            if let textData = try? jsonEncoder.encode(text), let textVal = String(data:textData, encoding: .utf8) {
                addLine(key: prefix + "memo.text", value: textVal , lines: &lines)
            } else {
                addLine(key: prefix + "memo.text", value: "\"" + text + "\"" , lines: &lines)
            }
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
    
    static func fromAmount(_ amount:Int64) -> Decimal {
        var decimal = Decimal(amount)
        decimal = decimal / 10000000
        return decimal
    }
}
