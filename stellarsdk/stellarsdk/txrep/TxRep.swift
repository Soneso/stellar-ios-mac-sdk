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
        addLine(key: prefix + "ext.v", value: "0", lines: &lines)
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
        let transaction = try Transaction(sourceAccount: sourceAccount, operations: operations, memo: memo, preconditions: preconditions, maxOperationFee: maxOperationFee)
        
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
            /*case "INVOKE_HOST_FUNCTION":
                let opPrefix = prefix + "invokeHostFunctionOp."
                return try getInvokeHostFunctionOp(dic: dic, opPrefix: opPrefix, sourceAccount: sourceAccount)*/
            default:
                throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
    }
    /*
    private static func getInvokeHostFunctionOp(dic:Dictionary<String,String>, opPrefix:String, sourceAccount:MuxedAccount?) throws -> InvokeHostFunctionOperation? {
        var key = opPrefix + "function.type";
        let fcType:String
        if let fcTypeStr = dic[key] {
            fcType = fcTypeStr
        } else {
            throw TxRepError.missingValue(key: key)
        }
        
        var hostFunctionXdr:HostFunctionXDR?
        
        switch fcType {
        case "HOST_FUNCTION_TYPE_INSTALL_CONTRACT_CODE":
            key = opPrefix + "function.installContractCodeArgs.code"
            if let code = dic[key] {
                hostFunctionXdr = HostFunctionXDR.installContractCode(UploadContractWasmArgsXDR(code: Data(hex: code)))
            } else {
                throw TxRepError.missingValue(key: key)
            }
        case "HOST_FUNCTION_TYPE_INVOKE_CONTRACT":
            key = opPrefix + "function.invokeArgs.len"
            var invokeArgs:[SCValXDR] = []
            if let argsLen = dic[key] {
                if let count = Int(argsLen) {
                    for i in 0..<count{
                        try invokeArgs.append(getSCVal(dic:dic, prefix:opPrefix + "function.invokeArgs[\(i)]."))
                    }
                } else {
                    throw TxRepError.invalidValue(key: key)
                }
            } else {
                throw TxRepError.missingValue(key: key)
            }
            hostFunctionXdr = HostFunctionXDR.invokeContract(invokeArgs)
        case "HOST_FUNCTION_TYPE_CREATE_CONTRACT":
            key = opPrefix + "function.createContractArgs."
            hostFunctionXdr = HostFunctionXDR.createContract(try getCreateContractArgs(dic: dic, prefix: key))
        default:
            throw TxRepError.invalidValue(key: key)
        }
        
        let xdrOp = InvokeHostFunctionOpXDR(function: hostFunctionXdr!,
                                         ledgerFootprint: try getFootprint(dic: dic, prefix: opPrefix + "footprint."),
                                         auth: try getContractAuthArr(dic:dic, prefix: opPrefix))
        
        
        return try InvokeHostFunctionOperation(fromXDR: xdrOp, sourceAccountId: sourceAccount?.accountId)
    }
    
    private static func getCreateContractArgs(dic:Dictionary<String,String>, prefix:String) throws -> CreateContractArgsXDR {
        var key = prefix + "source.type"
        var contractCodeType:String?
        if let typeStr = dic[key] {
            contractCodeType = typeStr
        } else {
            throw TxRepError.missingValue(key: key)
        }
        
        switch contractCodeType {
        case "SCCONTRACT_CODE_WASM_REF":
            key = prefix + "source.wasm_id"
            if let wasmId = dic[key] {
                key = prefix + "contractID.salt"
                if let salt = dic[key] {
                    let cID = ContractIDXDR.fromSourceAccount(WrappedData32(Data(hex: salt)))
                    let src = SCContractExecutableXDR.wasmRef(WrappedData32(Data(hex: wasmId)))
                    return CreateContractArgsXDR(contractId: cID, source: src)
                } else {
                    throw TxRepError.missingValue(key: key)
                }
            } else {
                throw TxRepError.missingValue(key: key)
            }
        case "SCCONTRACT_CODE_TOKEN":
            key = prefix + "contractID.type"
            var contractIdType:String?
            if let typeStr = dic[key] {
                contractIdType = typeStr
            } else {
                throw TxRepError.missingValue(key: key)
            }
            switch contractIdType {
            case "CONTRACT_ID_FROM_SOURCE_ACCOUNT":
                key = prefix + "contractID.salt"
                if let salt = dic[key] {
                    let cID = ContractIDXDR.fromSourceAccount(WrappedData32(Data(hex: salt)))
                    let src = SCContractExecutableXDR.token
                    return CreateContractArgsXDR(contractId: cID, source: src)
                } else {
                    throw TxRepError.missingValue(key: key)
                }
            case "CONTRACT_ID_FROM_ASSET":
                key = prefix + "contractID.asset"
                if let assetStr = dic[key] {
                    if let asset = decodeAsset(asset: assetStr) {
                        let cID = ContractIDXDR.fromAsset(try asset.toXDR())
                        let src = SCContractExecutableXDR.token
                        return CreateContractArgsXDR(contractId: cID, source: src)
                    } else {
                        throw TxRepError.invalidValue(key: key)
                    }
                } else {
                    throw TxRepError.missingValue(key: key)
                }
            default:
                throw TxRepError.invalidValue(key: key)
            }
        default:
            throw TxRepError.invalidValue(key: key)
        }
    }
    
    private static func getFootprint(dic:Dictionary<String,String>, prefix:String) throws -> LedgerFootprintXDR {
        var readOnly:[LedgerKeyXDR] = []
        var readWrite:[LedgerKeyXDR] = []
        var key = prefix + "readOnly.len"
        if let readOnlyLen = dic[key] {
            if let count = Int(readOnlyLen) {
                for i in 0..<count{
                    try readOnly.append(getContractLedgerKey(dic:dic, prefix:prefix + "readOnly[\(i)]."))
                }
            } else {
                throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
        key = prefix + "readWrite.len"
        if let readWriteLen = dic[key] {
            if let count = Int(readWriteLen) {
                for i in 0..<count{
                    try readWrite.append(getContractLedgerKey(dic:dic, prefix:prefix + "readWrite[\(i)]."))
                }
            } else {
                throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
        return LedgerFootprintXDR(readOnly: readOnly, readWrite: readWrite)
    }
    
    private static func getContractLedgerKey(dic:Dictionary<String,String>, prefix:String) throws -> LedgerKeyXDR {
        var key = prefix + "type"
        var type:String?
        if let typeStr = dic[key] {
            type = typeStr
        } else {
            throw TxRepError.missingValue(key: key)
        }
        switch type {
        case "ACCOUNT":
            key = prefix + "account.accountID"
            if let accountId = dic[key] {
                return try LedgerKeyXDR.account(LedgerKeyAccountXDR(accountID: KeyPair(accountId: accountId).publicKey))
            } else {
                throw TxRepError.missingValue(key: key)
            }
        case "TRUSTLINE":
            key = prefix + "trustLine.accountID"
            if let accountId = dic[key] {
                key = prefix + "trustLine.asset"
                if let assetStr = dic[key] {
                    let pk = try KeyPair(accountId: accountId).publicKey
                    if let asset = decodeAsset(asset: assetStr) {
                        return try LedgerKeyXDR.trustline(LedgerKeyTrustLineXDR(accountID: pk, asset: asset.toTrustlineAssetXDR()))
                    } else {
                        throw TxRepError.missingValue(key: key)
                    }
                } else {
                    throw TxRepError.missingValue(key: key)
                }
            } else {
                throw TxRepError.missingValue(key: key)
            }
        case "CONTRACT_DATA":
            key = prefix + "contractData.contractID"
            if let contractId = dic[key] {
                let key = try getSCVal(dic: dic, prefix: prefix + "contractData.key.")
                return LedgerKeyXDR.contractData(WrappedData32(Data(hex: contractId)), key)
            } else {
                throw TxRepError.missingValue(key: key)
            }
        case "CONTRACT_CODE":
            key = prefix + "contractCode.hash"
            if let code = dic[key] {
                return LedgerKeyXDR.contractCode(WrappedData32(Data(hex: code)))
            } else {
                throw TxRepError.missingValue(key: key)
            }
        default:
            throw TxRepError.invalidValue(key: key)
        }
    }
    
    private static func getContractAuthArr(dic:Dictionary<String,String>, prefix:String) throws -> [ContractAuthXDR] {
        var result:[ContractAuthXDR] = []
        let key = prefix + "auth.len"
        if let authLen = dic[key] {
            if let count = Int(authLen) {
                for i in 0..<count{
                    try result.append(getContractAuth(dic:dic, prefix:prefix + "auth[\(i)]."))
                }
            } else {
                throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
        return result;
    }
    
    private static func getContractAuth(dic:Dictionary<String,String>, prefix:String) throws -> ContractAuthXDR {
        var addrWithNonce:AddressWithNonceXDR?
        var key = prefix + "addressWithNonce._present"
        if let present = dic[key] {
            if "true" == present {
                addrWithNonce = try getAddressWithNonce(dic: dic, prefix: prefix + "addressWithNonce.")
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
        let rootInvocation = try getAuthorizedInvocation(dic:dic, prefix: prefix + "rootInvocation.")
        
        var signatureArgs:[SCValXDR] = []
        key = prefix + "signatureArgs.len"
        if let argsLen = dic[key] {
            if let count = Int(argsLen) {
                for i in 0..<count{
                    try signatureArgs.append(getSCVal(dic:dic, prefix:prefix + "signatureArgs[\(i)]."))
                }
            } else {
                throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
        
        // PATCH see https://discord.com/channels/897514728459468821/1076723574884282398/1078095366890729595
        if (signatureArgs.count > 0) {
            signatureArgs = [SCValXDR.vec(signatureArgs)]
        }
        
        return ContractAuthXDR(addressWithNonce: addrWithNonce, rootInvocation: rootInvocation, signatureArgs: signatureArgs);
    }
    
    private static func getAuthorizedInvocation(dic:Dictionary<String,String>, prefix:String) throws -> AuthorizedInvocationXDR {
        var cId:WrappedData32?
        var key = prefix + "contractID"
        if let contractId = dic[key] {
            cId = WrappedData32(Data(hex: contractId))
        } else {
            throw TxRepError.missingValue(key: key)
        }
        
        var functionName:String?
        key = prefix + "functionName"
        if let functionNameStr = dic[key] {
            functionName = functionNameStr
        } else {
            throw TxRepError.missingValue(key: key)
        }
        
        var args:[SCValXDR] = []
        key = prefix + "args.len"
        if let argsLen = dic[key] {
            if let count = Int(argsLen) {
                for i in 0..<count{
                    try args.append(getSCVal(dic:dic, prefix:prefix + "args[\(i)]."))
                }
            } else {
                throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
        
        var subInvocations:[AuthorizedInvocationXDR] = []
        key = prefix + "subInvocations.len"
        if let subInvocationsLen = dic[key] {
            if let count = Int(subInvocationsLen) {
                for i in 0..<count{
                    try subInvocations.append(getAuthorizedInvocation(dic:dic, prefix:prefix + "subInvocations[\(i)]."))
                }
            } else {
                throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
        
        return AuthorizedInvocationXDR(contractID: cId!, functionName: functionName!, args: args, subInvocations: subInvocations)
    }
    
    private static func getSCVal(dic:Dictionary<String,String>, prefix:String) throws -> SCValXDR {
        var key = prefix + "type"
        var type:String?
        if let typeStr = dic[key] {
            type = typeStr
        } else {
            throw TxRepError.missingValue(key: key)
        }
        switch type {
        case "SCV_BOOL":
            key = prefix + "b"
            if let bStr = dic[key] {
                if let b = Bool(bStr) {
                    return SCValXDR.bool(b)
                } else {
                    throw TxRepError.invalidValue(key: key)
                }
            } else {
                throw TxRepError.missingValue(key: key)
            }
        case "SCV_VOID":
            return SCValXDR.void
        case "SCV_U32":
            key = prefix + "u32"
            if let u32Str = dic[key] {
                if let u32 = UInt32(u32Str) {
                    return SCValXDR.u32(u32)
                } else {
                    throw TxRepError.invalidValue(key: key)
                }
            } else {
                throw TxRepError.missingValue(key: key)
            }
        case "SCV_I32":
            key = prefix + "i32"
            if let i32Str = dic[key] {
                if let i32 = Int32(i32Str) {
                    return SCValXDR.i32(i32)
                } else {
                    throw TxRepError.invalidValue(key: key)
                }
            } else {
                throw TxRepError.missingValue(key: key)
            }
        case "SCV_U64":
            key = prefix + "u64"
            if let u64Str = dic[key] {
                if let u64 = UInt64(u64Str) {
                    return SCValXDR.u64(u64)
                } else {
                    throw TxRepError.invalidValue(key: key)
                }
            } else {
                throw TxRepError.missingValue(key: key)
            }
        case "SCV_I64":
            key = prefix + "i64"
            if let i64Str = dic[key] {
                if let i64 = Int64(i64Str) {
                    return SCValXDR.i64(i64)
                } else {
                    throw TxRepError.invalidValue(key: key)
                }
            } else {
                throw TxRepError.missingValue(key: key)
            }
        case "SCV_TIMEPOINT":
            key = prefix + "timepoint"
            if let u64Str = dic[key] {
                if let u64 = UInt64(u64Str) {
                    return SCValXDR.timepoint(u64)
                } else {
                    throw TxRepError.invalidValue(key: key)
                }
            } else {
                throw TxRepError.missingValue(key: key)
            }
        case "SCV_DURATION":
            key = prefix + "duration"
            if let u64Str = dic[key] {
                if let u64 = UInt64(u64Str) {
                    return SCValXDR.duration(u64)
                } else {
                    throw TxRepError.invalidValue(key: key)
                }
            } else {
                throw TxRepError.missingValue(key: key)
            }
        case "SCV_U128":
            return try SCValXDR.u128(getI128Parts(dic: dic, prefix: prefix + "u128."))
        case "SCV_I128":
            return try SCValXDR.i128(getI128Parts(dic: dic, prefix: prefix + "i128."))
        case "SCV_U256":
            return SCValXDR.u256(WrappedData32()) // TODO add parts as soon as available
        case "SCV_I256":
            return SCValXDR.i256(WrappedData32()) // TODO add parts as soon as available
        case "SCV_BYTES":
            key = prefix + "bytes"
            if let bytesStr = dic[key] {
                return SCValXDR.bytes(Data(hex: bytesStr))
            } else {
                throw TxRepError.missingValue(key: key)
            }
        case "SCV_STRING":
            key = prefix + "str"
            if let str = dic[key] {
                return SCValXDR.string(str)
            } else {
                throw TxRepError.missingValue(key: key)
            }
        case "SCV_SYMBOL":
            key = prefix + "sym"
            if let sym = dic[key] {
                return SCValXDR.symbol(sym)
            } else {
                throw TxRepError.missingValue(key: key)
            }
        case "SCV_VEC":
            var key = prefix + "vec._present"
            if let present = dic[key] {
                if "false" == present {
                    return SCValXDR.vec(nil)
                }
            } else {
                throw TxRepError.missingValue(key: key)
            }
            return try SCValXDR.vec(getSCVec(dic: dic, prefix: prefix))
        case "SCV_MAP":
            var key = prefix + "map._present"
            if let present = dic[key] {
                if "false" == present {
                    return SCValXDR.map(nil)
                }
            } else {
                throw TxRepError.missingValue(key: key)
            }
            return try SCValXDR.map(getSCMap(dic: dic, prefix: prefix))
        case "SCV_CONTRACT_EXECUTABLE":
            return try SCValXDR.contractExecutable(getSCContractExecutable(dic: dic, prefix: prefix + "exec."))
        case "SCV_ADDRESS":
            return try SCValXDR.address(getSCAddress(dic: dic, prefix: prefix + "address."))
        case "SCV_LEDGER_KEY_CONTRACT_EXECUTABLE":
            return SCValXDR.ledgerKeyContractExecutable
        case "SCV_LEDGER_KEY_NONCE":
            return try SCValXDR.ledgerKeyNonce(SCNonceKeyXDR(nonceAddress: getSCAddress(dic: dic, prefix: prefix + "nonce_key.nonce_address.")))
        case "SCV_STATUS":
            return try SCValXDR.status(getSCStatus(dic: dic, prefix: prefix + "error."))
        default:
            throw TxRepError.invalidValue(key: key)
        }
    }
        
    private static func getSCContractExecutable(dic:Dictionary<String,String>, prefix:String) throws -> SCContractExecutableXDR {
        var key = prefix + "type"
        if let type = dic[key] {
            if "SCCONTRACT_EXECUTABLE_WASM_REF" == type {
                key = prefix + "wasm_id"
                if let wasmIdStr = dic[key] {
                    return SCContractExecutableXDR.wasmRef(WrappedData32(Data(hex: wasmIdStr)))
                } else {
                    throw TxRepError.missingValue(key: key)
                }
            } else if "SCCONTRACT_EXECUTABLE_TOKEN" == type {
                return SCContractExecutableXDR.token
            } else {
                throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
    }
    
    private static func getI128Parts(dic:Dictionary<String,String>, prefix:String) throws -> Int128PartsXDR {
        var key = prefix + "lo"
        if let loStr = dic[key] {
            if let lo = UInt64(loStr) {
                key = prefix + "hi"
                if let hiStr = dic[key] {
                    if let hi = Int64(hiStr) {
                        return Int128PartsXDR(hi: hi, lo: lo)
                    } else {
                        throw TxRepError.invalidValue(key: key)
                    }
                } else {
                    throw TxRepError.missingValue(key: key)
                }
            } else {
                throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
    }
    
    private static func getSCMap(dic:Dictionary<String,String>, prefix:String) throws -> [SCMapEntryXDR] {
        let key = prefix + "map.len"
        if let mapLen = dic[key] {
            if let count = Int(mapLen) {
                var map:[SCMapEntryXDR] = []
                for i in 0..<count{
                    let key = try getSCVal(dic: dic, prefix:prefix + "map[\(i)].key.")
                    let val = try getSCVal(dic: dic, prefix:prefix + "map[\(i)].val.")
                    map.append(SCMapEntryXDR(key: key, val: val))
                }
                return map
            } else {
                throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
    }
    
    private static func getSCVec(dic:Dictionary<String,String>, prefix:String) throws -> [SCValXDR] {
        let key = prefix + "vec.len"
        if let vecLen = dic[key] {
            if let count = Int(vecLen) {
                var vec:[SCValXDR] = []
                for i in 0..<count{
                    try vec.append(getSCVal(dic: dic, prefix:prefix + "vec[\(i)]."))
                }
                return vec
            } else {
                throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
    }
    
    private static func getAddressWithNonce(dic:Dictionary<String,String>, prefix:String) throws -> AddressWithNonceXDR {
        let address = try getSCAddress(dic: dic, prefix: prefix + "address.")
        let key = prefix + "nonce"
        if let nonceStr = dic[key] {
            if let nonceU64 = UInt64(nonceStr) {
                return AddressWithNonceXDR(address: address, nonce: nonceU64)
            } else {
                throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
    }
    
    private static func getSCAddress(dic:Dictionary<String,String>, prefix:String) throws -> SCAddressXDR {
        var key = prefix + "type"
        if let type = dic[key] {
            if "SC_ADDRESS_TYPE_ACCOUNT" == type {
                key = prefix + "accountId"
                if let accountId = dic[key] {
                    return try SCAddressXDR(address: Address.accountId(accountId))
                } else {
                    throw TxRepError.missingValue(key: key)
                }
            } else if "SC_ADDRESS_TYPE_CONTRACT" == type {
                key = prefix + "contractId"
                if let contractId = dic[key] {
                    return try SCAddressXDR(address: Address.contractId(contractId))
                } else {
                    throw TxRepError.missingValue(key: key)
                }
            } else {
                throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
    }
    
    private static func getSCStatus(dic:Dictionary<String,String>, prefix:String) throws -> SCStatusXDR {
        var key = prefix + "type"
        if let type = dic[key] {
            switch type {
            case "SST_OK":
                return SCStatusXDR.ok
            case "SST_UNKNOWN_ERROR":
                return try SCStatusXDR.unknownError(getSCUnknownErrorCode(dic: dic, prefix: prefix).rawValue)
            case "SST_HOST_VALUE_ERROR":
                return try SCStatusXDR.hostValueError(getSCHostValueErrorCode(dic: dic, prefix: prefix).rawValue)
            case "SST_HOST_OBJECT_ERROR":
                return try SCStatusXDR.hostObjectError(getSCHostObjectErrorCode(dic: dic, prefix: prefix).rawValue)
            case "SST_HOST_FUNCTION_ERROR":
                return try SCStatusXDR.hostFunctionError(getSCHostFunctionErrorCode(dic: dic, prefix: prefix).rawValue)
            case "SST_HOST_STORAGE_ERROR":
                return try SCStatusXDR.hostStorageError(getSCHostStorageErrorCode(dic: dic, prefix: prefix).rawValue)
            case "SST_HOST_CONTEXT_ERROR":
                return try SCStatusXDR.hostContextError(getSCHostContextErrorCode(dic: dic, prefix: prefix).rawValue)
            case "SST_VM_ERROR":
                return try SCStatusXDR.vmError(getSCVMErrorCode(dic: dic, prefix: prefix).rawValue)
            default:
                throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
    }
    
    private static func getSCVMErrorCode(dic:Dictionary<String,String>, prefix:String) throws -> SCVmErrorCode {
        let key = prefix + "vmCode"
        if let code = dic[key] {
            switch code {
            case "VM_UNKNOWN":
                return SCVmErrorCode.unknownError
            case "VM_VALIDATION":
                return SCVmErrorCode.validation
            case "VM_INSTANTIATION":
                return SCVmErrorCode.instantiation
            case "VM_FUNCTION":
                return SCVmErrorCode.function
            case "VM_TABLE":
                return SCVmErrorCode.table
            case "VM_MEMORY":
                return SCVmErrorCode.memory
            case "VM_GLOBAL":
                return SCVmErrorCode.global
            case "VM_VALUE":
                return SCVmErrorCode.value
            case "VM_TRAP_UNREACHABLE":
                return SCVmErrorCode.trapUnreachable
            case "VM_TRAP_MEMORY_ACCESS_OUT_OF_BOUNDS":
                return SCVmErrorCode.memoryAccessOutOfBounds
            case "VM_TRAP_TABLE_ACCESS_OUT_OF_BOUNDS":
                return SCVmErrorCode.tableAccessOutOfBounds
            case "VM_TRAP_ELEM_UNINITIALIZED":
                return SCVmErrorCode.elemUnitialized
            case "VM_TRAP_DIVISION_BY_ZERO":
                return SCVmErrorCode.divisionByZero
            case "VM_TRAP_INTEGER_OVERFLOW":
                return SCVmErrorCode.integerOverflow
            case "VM_TRAP_INVALID_CONVERSION_TO_INT":
                return SCVmErrorCode.invalidConversionToInt
            case "VM_TRAP_STACK_OVERFLOW":
                return SCVmErrorCode.stackOverflow
            case "VM_TRAP_UNEXPECTED_SIGNATURE":
                return SCVmErrorCode.unexpectedSignature
            case "VM_TRAP_MEM_LIMIT_EXCEEDED":
                return SCVmErrorCode.memLimitExceeded
            case "VM_TRAP_CPU_LIMIT_EXCEEDED":
                return SCVmErrorCode.cpuLimitExceeded
            default:
                throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
    }
    
    private static func getSCHostContextErrorCode(dic:Dictionary<String,String>, prefix:String) throws -> SCHostContextErrorCode {
        let key = prefix + "contextCode"
        if let code = dic[key] {
            switch code {
            case "HOST_CONTEXT_UNKNOWN_ERROR":
                return SCHostContextErrorCode.unknownError
            case "HOST_CONTEXT_NO_CONTRACT_RUNNING":
                return SCHostContextErrorCode.noContractRunning
            default:
                throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
    }
    
    private static func getSCHostStorageErrorCode(dic:Dictionary<String,String>, prefix:String) throws -> SCHostStorageErrorCode {
        let key = prefix + "storageCode"
        if let code = dic[key] {
            switch code {
            case "HOST_STORAGE_UNKNOWN_ERROR":
                return SCHostStorageErrorCode.unknownError
            case "HOST_STORAGE_EXPECT_CONTRACT_DATA":
                return SCHostStorageErrorCode.expectContractData
            case "HOST_STORAGE_READWRITE_ACCESS_TO_READONLY_ENTRY":
                return SCHostStorageErrorCode.readwriteAccessToReadonlyEntry
            case "HOST_STORAGE_ACCESS_TO_UNKNOWN_ENTRY":
                return SCHostStorageErrorCode.accessToUnknownEntry
            case "HOST_STORAGE_MISSING_KEY_IN_GET":
                return SCHostStorageErrorCode.missingKeyInGet
            case "HOST_STORAGE_GET_ON_DELETED_KEY":
                return SCHostStorageErrorCode.getOnDeletedKey
            default:
                throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
    }
    
    private static func getSCHostFunctionErrorCode(dic:Dictionary<String,String>, prefix:String) throws -> SCHostFnErrorCode {
        let key = prefix + "fnCode"
        if let code = dic[key] {
            switch code {
            case "HOST_FN_UNKNOWN_ERROR":
                return SCHostFnErrorCode.unknownError
            case "HOST_FN_UNEXPECTED_HOST_FUNCTION_ACTION":
                return SCHostFnErrorCode.hostFunctionAction
            case "HOST_FN_INPUT_ARGS_WRONG_LENGTH":
                return SCHostFnErrorCode.inputArgsWrongLenght
            case "HOST_FN_INPUT_ARGS_WRONG_TYPE":
                return SCHostFnErrorCode.inputArgsWrongType
            case "HOST_FN_INPUT_ARGS_INVALID":
                return SCHostFnErrorCode.inputArgsInvalid
            default:
                throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
    }
    
    private static func getSCHostObjectErrorCode(dic:Dictionary<String,String>, prefix:String) throws -> SCHostObjErrorCode {
        let key = prefix + "objCode"
        if let code = dic[key] {
            switch code {
            case "HOST_OBJECT_UNKNOWN_ERROR":
                return SCHostObjErrorCode.unknownError
            case "HOST_OBJECT_UNKNOWN_REFERENCE":
                return SCHostObjErrorCode.unknownReference
            case "HOST_OBJECT_UNEXPECTED_TYPE":
                return SCHostObjErrorCode.unexpectedType
            case "HOST_OBJECT_OBJECT_COUNT_EXCEEDS_U32_MAX":
                return SCHostObjErrorCode.objectCountExceedsU32Max
            case "HOST_OBJECT_VEC_INDEX_OUT_OF_BOUND":
                return SCHostObjErrorCode.vecIndexOutOfBound
            case "HOST_OBJECT_CONTRACT_HASH_WRONG_LENGTH":
                return SCHostObjErrorCode.contractHashWrongLenght
            default:
                throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
    }
    
    private static func getSCHostValueErrorCode(dic:Dictionary<String,String>, prefix:String) throws -> SCHostValErrorCode {
        let key = prefix + "valCode"
        if let code = dic[key] {
            switch code {
            case "HOST_VALUE_UNKNOWN_ERROR":
                return SCHostValErrorCode.unknownError
            case "HOST_VALUE_RESERVED_TAG_VALUE":
                return SCHostValErrorCode.reservedTagValue
            case "HOST_VALUE_UNEXPECTED_VAL_TYPE":
                return SCHostValErrorCode.unexpectedValType
            case "HOST_VALUE_U63_OUT_OF_RANGE":
                return SCHostValErrorCode.u63OutOfRange
            case "HOST_VALUE_U32_OUT_OF_RANGE":
                return SCHostValErrorCode.u32OutOfRange
            case "HOST_VALUE_STATIC_UNKNOWN":
                return SCHostValErrorCode.staticUnknown
            case "HOST_VALUE_MISSING_OBJECT":
                return SCHostValErrorCode.missingObject
            case "HOST_VALUE_SYMBOL_TOO_LONG":
                return SCHostValErrorCode.symbolTooLong
            case "HOST_VALUE_SYMBOL_BAD_CHAR":
                return SCHostValErrorCode.symbolBadChar
            case "HOST_VALUE_SYMBOL_CONTAINS_NON_UTF8":
                return SCHostValErrorCode.symbolContainsNonUTF8
            case "HOST_VALUE_BITSET_TOO_MANY_BITS":
                return SCHostValErrorCode.bitsetTooManyBits
            case "HOST_VALUE_STATUS_UNKNOWN":
                return SCHostValErrorCode.statusUnknown
            default:
                throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
    }
    
    private static func getSCUnknownErrorCode(dic:Dictionary<String,String>, prefix:String) throws -> SCUnknownErrorCode {
        let key = prefix + "unknownCode"
        if let code = dic[key] {
            switch code {
            case "UNKNOWN_ERROR_GENERAL":
                return SCUnknownErrorCode.errorGeneral
            case "UNKNOWN_ERROR_XDR":
                return SCUnknownErrorCode.errorXDR
            default:
                throw TxRepError.invalidValue(key: key)
            }
        } else {
            throw TxRepError.missingValue(key: key)
        }
    }
    */
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
        let type:String
        if let typeStr = dic[key] {
            type = typeStr
        } else {
            throw TxRepError.missingValue(key: key)
        }
        if (type == "REVOKE_SPONSORSHIP_LEDGER_ENTRY") {
            key = opPrefix + "ledgerKey.type"
            let ledgerKeyType:String
            if let ledgerKeyTypeStr = dic[key] {
                ledgerKeyType = ledgerKeyTypeStr
            } else {
                throw TxRepError.missingValue(key: key)
            }
            if (ledgerKeyType == "ACCOUNT") {
                key = opPrefix + "ledgerKey.account.accountID";
                let accountId:String
                if let accountIdStr = dic[key] {
                    do {
                        let kp = try KeyPair(accountId:accountIdStr)
                        accountId = kp.accountId;
                    } catch {
                        throw TxRepError.invalidValue(key: key)
                    }
                    let ledgerKey = try RevokeSponsorshipOperation.revokeAccountSponsorshipLedgerKey(accountId: accountId);
                    return RevokeSponsorshipOperation(ledgerKey: ledgerKey, sourceAccountId: sourceAccount?.accountId);
                } else {
                    throw TxRepError.missingValue(key: key)
                }
            } else if (ledgerKeyType == "TRUSTLINE") {
                key = opPrefix + "ledgerKey.trustLine.accountID";
                let accountId:String
                if let accountIdStr = dic[key] {
                    do {
                        let kp = try KeyPair(accountId:accountIdStr)
                        accountId = kp.accountId;
                    } catch {
                        throw TxRepError.invalidValue(key: key)
                    }
                    key = opPrefix + "ledgerKey.trustLine.asset"
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
                    let ledgerKey = try RevokeSponsorshipOperation.revokeTrustlineSponsorshipLedgerKey(accountId: accountId, asset: asset)
                    return RevokeSponsorshipOperation(ledgerKey: ledgerKey, sourceAccountId: sourceAccount?.accountId);
                } else {
                    throw TxRepError.missingValue(key: key)
                }
            } else if (ledgerKeyType == "OFFER") {
                key = opPrefix + "ledgerKey.offer.sellerID";
                let accountId:String
                if let accountIdStr = dic[key] {
                    do {
                        let kp = try KeyPair(accountId:accountIdStr)
                        accountId = kp.accountId;
                    } catch {
                        throw TxRepError.invalidValue(key: key)
                    }
                    key = opPrefix + "ledgerKey.offer.offerID"
                    var offerId:UInt64 = 0
                    if let offerIdStr = dic[key] {
                        if let offerIdi = UInt64(offerIdStr) {
                            offerId = offerIdi
                        } else {
                            throw TxRepError.invalidValue(key: key)
                        }
                    }
                    let ledgerKey = try RevokeSponsorshipOperation.revokeOfferSponsorshipLedgerKey(sellerAccountId: accountId, offerId: offerId)
                    return RevokeSponsorshipOperation(ledgerKey: ledgerKey, sourceAccountId: sourceAccount?.accountId);
                } else {
                    throw TxRepError.missingValue(key: key)
                }
            } else if (ledgerKeyType == "DATA") {
                key = opPrefix + "ledgerKey.data.accountID";
                let accountId:String
                if let accountIdStr = dic[key] {
                    do {
                        let kp = try KeyPair(accountId:accountIdStr)
                        accountId = kp.accountId;
                    } catch {
                        throw TxRepError.invalidValue(key: key)
                    }
                    let jsonDecoder = JSONDecoder()
                    key = opPrefix + "ledgerKey.data.dataName"
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
                    let ledgerKey = try RevokeSponsorshipOperation.revokeDataSponsorshipLedgerKey(accountId: accountId, dataName: dataName)
                    return RevokeSponsorshipOperation(ledgerKey: ledgerKey, sourceAccountId: sourceAccount?.accountId);
                } else {
                    throw TxRepError.missingValue(key: key)
                }
            } else if (ledgerKeyType == "CLAIMABLE_BALANCE") {
                let key = opPrefix + "ledgerKey.claimableBalance.balanceID.v0"
                if let balanceId = dic[key] {
                    let ledgerKey = try RevokeSponsorshipOperation.revokeClaimableBalanceSponsorshipLedgerKey(balanceId: balanceId)
                    return RevokeSponsorshipOperation(ledgerKey: ledgerKey, sourceAccountId: sourceAccount?.accountId);
                } else {
                    throw TxRepError.missingValue(key: key)
                }
            }
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
        addLine(key: prefix + "signatures[" + String(index) + "].hint", value: signature.hint.wrapped.hexEncodedString(), lines: &lines)
        addLine(key: prefix + "signatures[" + String(index) + "].signature", value: signature.signature.hexEncodedString() , lines: &lines)
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
                addLine(key: operationPrefix + "dataValue", value: dataValue.hexEncodedString(), lines: &lines)
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
                let balanceId = data.wrapped.hexEncodedString()
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
                switch ledgerKeyXDR {
                case .account(let ledgerKeyAccountXDR):
                    addLine(key: operationPrefix + "ledgerKey.type", value: "ACCOUNT", lines: &lines)
                    addLine(key: operationPrefix + "ledgerKey.account.accountID", value: ledgerKeyAccountXDR.accountID.accountId, lines: &lines)
                    break
                case .trustline(let ledgerKeyTrustLineXDR):
                    addLine(key: operationPrefix + "ledgerKey.type", value: "TRUSTLINE", lines: &lines)
                    addLine(key: operationPrefix + "ledgerKey.trustLine.accountID", value: ledgerKeyTrustLineXDR.accountID.accountId, lines: &lines)
                    addLine(key: operationPrefix + "ledgerKey.trustLine.asset", value: encodeTrustlineAsset(asset: ledgerKeyTrustLineXDR.asset), lines: &lines)
                    break
                case .offer(let ledgerKeyOfferXDR):
                    addLine(key: operationPrefix + "ledgerKey.type", value: "OFFER", lines: &lines)
                    addLine(key: operationPrefix + "ledgerKey.offer.sellerID", value: ledgerKeyOfferXDR.sellerId.accountId, lines: &lines)
                    addLine(key: operationPrefix + "ledgerKey.offer.offerID", value: String(ledgerKeyOfferXDR.offerId), lines: &lines)
                    break
                case .data(let ledgerKeyDataXDR):
                    addLine(key: operationPrefix + "ledgerKey.type", value: "DATA", lines: &lines)
                    addLine(key: operationPrefix + "ledgerKey.data.accountID", value: ledgerKeyDataXDR.accountId.accountId, lines: &lines)
                    addLine(key: operationPrefix + "ledgerKey.data.dataName", value: "\"" + ledgerKeyDataXDR.dataName + "\"", lines: &lines)
                    break
                case .claimableBalance(let claimableBalanceIDXDR):
                    addLine(key: operationPrefix + "ledgerKey.type", value: "CLAIMABLE_BALANCE", lines: &lines)
                    addLine(key: operationPrefix + "ledgerKey.claimableBalance.balanceID.type", value: "CLAIMABLE_BALANCE_ID_TYPE_V0", lines: &lines)
                    switch claimableBalanceIDXDR {
                    case .claimableBalanceIDTypeV0(let wrappedData32):
                        let balanceId = wrappedData32.wrapped.hexEncodedString()
                        addLine(key: operationPrefix + "ledgerKey.claimableBalance.balanceID.v0", value: balanceId, lines: &lines)
                        break
                    }
                    break
                default:
                    break
                }
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
                let balanceId = wrappedData32.wrapped.hexEncodedString()
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
            addLine(key: operationPrefix + "liquidityPoolID", value: lOp.liquidityPoolID.wrapped.hexEncodedString(), lines: &lines)
            addLine(key: operationPrefix + "maxAmountA", value: String(lOp.maxAmountA), lines: &lines)
            addLine(key: operationPrefix + "maxAmountB", value: String(lOp.maxAmountB), lines: &lines)
            addLine(key: operationPrefix + "minPrice.n", value: String(lOp.minPrice.n), lines: &lines)
            addLine(key: operationPrefix + "minPrice.d", value: String(lOp.minPrice.d), lines: &lines)
            addLine(key: operationPrefix + "maxPrice.n", value: String(lOp.maxPrice.n), lines: &lines)
            addLine(key: operationPrefix + "maxPrice.d", value: String(lOp.maxPrice.d), lines: &lines)
            break
        case .liquidityPoolWithdraw(let lOp):
            addLine(key: operationPrefix + "liquidityPoolID", value: lOp.liquidityPoolID.wrapped.hexEncodedString(), lines: &lines)
            addLine(key: operationPrefix + "amount", value: String(lOp.amount), lines: &lines)
            addLine(key: operationPrefix + "minAmountA", value: String(lOp.minAmountA), lines: &lines)
            addLine(key: operationPrefix + "minAmountB", value: String(lOp.minAmountB), lines: &lines)
            break
        /*case .invokeHostFunction(let iOp):
            let fcPrefix = operationPrefix + "function.";
            let function = iOp.function;
            addLine(key: fcPrefix + "type" , value: txRepHostFuncType(function: function), lines: &lines)
            switch function {
            case .invokeContract(let invokeArgs):
                addLine(key: fcPrefix + "invokeArgs.len" , value: String(invokeArgs.count), lines: &lines)
                var index = 0
                for val in invokeArgs {
                    addSCVal(val: val, prefix: fcPrefix + "invokeArgs[\(index)]." , lines: &lines)
                    index += 1
                }
                break
            case .createContract(let args):
                switch args.executable {
                case .wasmRef(let wrappedData32):
                    addLine(key: fcPrefix + "createContractArgs.source.type" , value: "SCCONTRACT_CODE_WASM_REF", lines: &lines)
                    addLine(key: fcPrefix + "createContractArgs.source.wasm_id" , value: wrappedData32.wrapped.hexEncodedString(), lines: &lines)
                case .token:
                    addLine(key: fcPrefix + "createContractArgs.source.type" , value: "SCCONTRACT_CODE_TOKEN", lines: &lines)
                    break
                }
                switch args.contractId {
                case .fromSourceAccount(let wrappedData32):
                    addLine(key: fcPrefix + "createContractArgs.contractID.type", value: "CONTRACT_ID_FROM_SOURCE_ACCOUNT", lines: &lines)
                    addLine(key: fcPrefix + "createContractArgs.contractID.salt", value: wrappedData32.wrapped.hexEncodedString(), lines: &lines)
                    break
                case .fromAsset(let asset):
                    addLine(key: fcPrefix + "createContractArgs.contractID.type", value: "CONTRACT_ID_FROM_ASSET", lines: &lines)
                    addLine(key: fcPrefix + "createContractArgs.contractID.asset", value: encodeAsset(asset: asset), lines: &lines)
                default:
                    break
                }
                break
            case .installContractCode(let args):
                addLine(key: fcPrefix + "installContractCodeArgs.code" , value: args.code.hexEncodedString(), lines: &lines)
                break
            }
            
            addFootprint(footprint: iOp.ledgerFootprint, prefix: operationPrefix + "footprint.", lines: &lines)
            addLine(key: operationPrefix + "auth.len" , value: String(iOp.auth.count), lines: &lines)
            var index = 0
            for val in iOp.auth {
                addContractAuth(auth: val, prefix: operationPrefix + "auth[\(index)].", lines: &lines)
                index += 1
            }*/
        default:
            break
        }
    }
    /*
    private static func addContractAuth(auth:ContractAuthXDR, prefix:String, lines: inout [String]) -> Void {
        if let addrWithNonce = auth.addressWithNonce {
            addLine(key: prefix + "addressWithNonce._present", value: "true", lines: &lines)
            addAddressWithNonce(addr: addrWithNonce, prefix: prefix + "addressWithNonce.", lines: &lines)
        } else {
            addLine(key: prefix + "addressWithNonce._present", value: "false", lines: &lines)
        }
        addAuthorizedInvocation(invocation: auth.rootInvocation, prefix: prefix + "rootInvocation.", lines: &lines)
        
        var signatureArgs:[SCValXDR] = []
        // prev 7 fix see: https://discord.com/channels/897514728459468821/1076723574884282398/1078095366890729595
        if (auth.signatureArgs.count > 0) {
            let first = auth.signatureArgs.first
            if let vec = first?.vec {
                signatureArgs = vec
            }
            else {
                signatureArgs = auth.signatureArgs
            }
        }
        addLine(key: prefix + "signatureArgs.len" , value: String(signatureArgs.count), lines: &lines)
        var index = 0
        for arg in signatureArgs {
            addSCVal(val: arg, prefix: prefix + "signatureArgs[\(index)].", lines: &lines)
            index += 1
        }
    }
    
    private static func addAuthorizedInvocation(invocation:AuthorizedInvocationXDR, prefix:String, lines: inout [String]) -> Void {
        addLine(key: prefix + "contractID", value: invocation.contractID.wrapped.hexEncodedString(), lines: &lines)
        addLine(key: prefix + "functionName", value: invocation.functionName, lines: &lines)
        
        let args = invocation.args
        addLine(key: prefix + "args.len" , value: String(args.count), lines: &lines)
        var index = 0
        for arg in args {
            addSCVal(val: arg, prefix: prefix + "args[\(index)].", lines: &lines)
            index += 1
        }
        
        let subInvocations = invocation.subInvocations
        addLine(key: prefix + "subInvocations.len" , value: String(subInvocations.count), lines: &lines)
        index = 0
        for sub in subInvocations {
            addAuthorizedInvocation(invocation: sub, prefix: prefix + "subInvocations[\(index)].", lines: &lines)
            index += 1
        }
    }
    
    private static func addAddressWithNonce(addr:AddressWithNonceXDR, prefix:String, lines: inout [String]) -> Void {
        addSCAddress(addr: addr.address, prefix: prefix + "address.", lines: &lines)
        addLine(key: prefix + "nonce", value: String(addr.nonce), lines: &lines)
    }
    
    private static func addFootprint(footprint:LedgerFootprintXDR, prefix:String, lines: inout [String]) -> Void {
        addLine(key: prefix + "readOnly.len" , value: String(footprint.readOnly.count), lines: &lines)
        var index = 0
        for key in footprint.readOnly {
            addContractLedgerKey(key: key, prefix: prefix + "readOnly[\(index)].", lines: &lines)
            index += 1
        }
        
        addLine(key: prefix + "readWrite.len" , value: String(footprint.readWrite.count), lines: &lines)
        index = 0
        for key in footprint.readWrite {
            addContractLedgerKey(key: key, prefix: prefix + "readWrite[\(index)].", lines: &lines)
            index += 1
        }
    }
    
    private static func addContractLedgerKey(key:LedgerKeyXDR, prefix:String, lines: inout [String]) -> Void {
        switch key {
        case .account(let ledgerKeyAccountXDR):
            addLine(key: prefix + "type" , value: "ACCOUNT", lines: &lines)
            addLine(key: prefix + "account.accountID" , value: ledgerKeyAccountXDR.accountID.accountId, lines: &lines)
            break
        case .trustline(let ledgerKeyTrustLineXDR):
            addLine(key: prefix + "type" , value: "TRUSTLINE", lines: &lines)
            addLine(key: prefix + "trustLine.accountID" , value: ledgerKeyTrustLineXDR.accountID.accountId, lines: &lines)
            addLine(key: prefix + "trustLine.asset" , value: encodeTrustlineAsset(asset: ledgerKeyTrustLineXDR.asset), lines: &lines)
            break
        case .contractData(let wrappedData32, let sCValXDR):
            addLine(key: prefix + "type" , value: "CONTRACT_DATA", lines: &lines)
            addLine(key: prefix + "contractData.contractID" , value: wrappedData32.wrapped.hexEncodedString(), lines: &lines)
            addSCVal(val: sCValXDR, prefix: prefix + "contractData.key." , lines: &lines)
            break
        case .contractCode(let wrappedData32):
            addLine(key: prefix + "type" , value: "CONTRACT_CODE", lines: &lines)
            addLine(key: prefix + "contractCode.hash" , value: wrappedData32.wrapped.hexEncodedString(), lines: &lines)
            break
        default :
            break
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
        case .u32(let uInt32):
            addLine(key: prefix + "type" , value: "SCV_U32", lines: &lines)
            addLine(key: prefix + "u32" , value: String(uInt32), lines: &lines)
            break
        case .i32(let int32):
            addLine(key: prefix + "type" , value: "SCV_I32", lines: &lines)
            addLine(key: prefix + "u32" , value: String(int32), lines: &lines)
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
        case .u256(_):
            addLine(key: prefix + "type" , value: "SCV_U256", lines: &lines)
            // TODO: add parts as soon as available in xdr
        case .i256(_):
            addLine(key: prefix + "type" , value: "SCV_I256", lines: &lines)
            // TODO: add parts as soon as available in xdr
        case .bytes(let data):
            addLine(key: prefix + "type" , value: "SCV_BYTES", lines: &lines)
            addLine(key: prefix + "bytes" , value: data.hexEncodedString(), lines: &lines)
            break
        case .string(let str):
            addLine(key: prefix + "type" , value: "SCV_STRING", lines: &lines)
            addLine(key: prefix + "str" , value: str, lines: &lines)
            break
        case .symbol(let symbol):
            addLine(key: prefix + "type" , value: "SCV_SYMBOL", lines: &lines)
            addLine(key: prefix + "sym" , value: symbol, lines: &lines)
            break
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
            break
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
            break
        case .contractExecutable(let sCContractCodeXDR):
            addLine(key: prefix + "type" , value: "SCV_CONTRACT_EXECUTABLE", lines: &lines)
            switch sCContractCodeXDR {
            case .wasmRef(let wrappedData32):
                addLine(key: prefix + "exec.type" , value: "SCCONTRACT_EXECUTABLE_WASM_REF", lines: &lines)
                addLine(key: prefix + "exec.wasm_id" , value: wrappedData32.wrapped.hexEncodedString(), lines: &lines)
                break
            case .token:
                addLine(key: prefix + "exec.type" , value: "SCCONTRACT_EXECUTABLE_TOKEN", lines: &lines)
                break
            }
        case .address(let address):
            addLine(key: prefix + "type" , value: "SCV_ADDRESS", lines: &lines)
            addSCAddress(addr: address, prefix: prefix + "address.", lines: &lines)
            break
        case .ledgerKeyContractExecutable:
            addLine(key: prefix + "type" , value: "SCV_LEDGER_KEY_CONTRACT_EXECUTABLE", lines: &lines)
            break
        case .ledgerKeyNonce(let n):
            addLine(key: prefix + "type" , value: "SCV_LEDGER_KEY_NONCE", lines: &lines)
            addSCAddress(addr: n.nonceAddress, prefix: prefix + "nonce_key.nonce_address.", lines: &lines)
            break
        case .status(let sCStatusXDR):
            addLine(key: prefix + "type" , value: "SCV_STATUS", lines: &lines)
            addSCStatus(status: sCStatusXDR, prefix: prefix + "error.", lines: &lines)
            break
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
            addLine(key: prefix + "contractId" , value: wrappedData32.wrapped.hexEncodedString(), lines: &lines)
            break
        }
    }
    private static func addSCStatus(status:SCStatusXDR, prefix:String, lines: inout [String]) -> Void {
        switch status {
        case .ok:
            addLine(key: prefix + "type" , value: "SST_OK", lines: &lines)
            break
        case .unknownError(let code):
            addLine(key: prefix + "error.type" , value: "SST_UNKNOWN_ERROR", lines: &lines)
            if code == SCUnknownErrorCode.errorGeneral.rawValue {
                addLine(key: prefix + "error.unknownCode" , value: "UNKNOWN_ERROR_GENERAL", lines: &lines)
            } else if code == SCUnknownErrorCode.errorXDR.rawValue {
                addLine(key: prefix + "error.unknownCode" , value: "UNKNOWN_ERROR_XDR", lines: &lines)
            }
            break
        case .hostValueError(let code):
            addSCHostValueError(code: code, prefix: prefix, lines: &lines)
            break
        case .hostObjectError(let code):
            addSCHostObjectError(code: code, prefix: prefix, lines: &lines)
            break
        case .hostFunctionError(let code):
            addSCHostFunctionError(code: code, prefix: prefix, lines: &lines)
            break
        case .hostStorageError(let code):
            addSCHostStorageError(code: code, prefix: prefix, lines: &lines)
            break
        case .hostContextError(let code):
            addSCHostContextError(code: code, prefix: prefix, lines: &lines)
            break
        case .vmError(let code):
            addSCVMError(code: code, prefix: prefix, lines: &lines)
            break
        case .contractError(let code):
            addSCContractError(code: code, prefix: prefix, lines: &lines)
            break
        case .hostAuthError(let code):
            addSCHostAuthError(code: code, prefix: prefix, lines: &lines)
            break
        }
    }
    
    private static func addSCHostAuthError(code:Int32, prefix:String, lines: inout [String]) -> Void {
        addLine(key: prefix + "error.type" , value: "SST_HOST_AUTH_ERROR", lines: &lines)
        switch code {
        case SCHostAuthErrorCode.unknownError.rawValue:
            addLine(key: prefix + "error.authCode" , value: "HOST_AUTH_UNKNOWN_ERROR", lines: &lines)
            break
        case SCHostAuthErrorCode.nonceError.rawValue:
            addLine(key: prefix + "error.authCode" , value: "HOST_AUTH_NONCE_ERROR", lines: &lines)
            break
        case SCHostAuthErrorCode.duplicateAthorization.rawValue:
            addLine(key: prefix + "error.authCode" , value: "HOST_AUTH_DUPLICATE_AUTHORIZATION", lines: &lines)
            break
        case SCHostAuthErrorCode.authNotAuthorized.rawValue:
            addLine(key: prefix + "error.authCode" , value: "HOST_AUTH_NOT_AUTHORIZED", lines: &lines)
            break
        default:
            break
        }
    }
    
    private static func addSCContractError(code:Int32, prefix:String, lines: inout [String]) -> Void {
        addLine(key: prefix + "error.type" , value: "SST_CONTRACT_ERROR", lines: &lines)
        addLine(key: prefix + "error.contractCode" , value: String(code), lines: &lines)
    }
    
    private static func addSCVMError(code:Int32, prefix:String, lines: inout [String]) -> Void {
        addLine(key: prefix + "error.type" , value: "SST_VM_ERROR", lines: &lines)
        switch code {
        case SCVmErrorCode.unknownError.rawValue:
            addLine(key: prefix + "error.vmCode" , value: "VM_UNKNOWN", lines: &lines)
            break
        case SCVmErrorCode.validation.rawValue:
            addLine(key: prefix + "error.vmCode" , value: "VM_VALIDATION", lines: &lines)
            break
        case SCVmErrorCode.instantiation.rawValue:
            addLine(key: prefix + "error.vmCode" , value: "VM_INSTANTIATION", lines: &lines)
            break
        case SCVmErrorCode.function.rawValue:
            addLine(key: prefix + "error.vmCode" , value: "VM_FUNCTION", lines: &lines)
            break
        case SCVmErrorCode.table.rawValue:
            addLine(key: prefix + "error.vmCode" , value: "VM_TABLE", lines: &lines)
            break
        case SCVmErrorCode.memory.rawValue:
            addLine(key: prefix + "error.vmCode" , value: "VM_MEMORY", lines: &lines)
            break
        case SCVmErrorCode.global.rawValue:
            addLine(key: prefix + "error.vmCode" , value: "VM_GLOBAL", lines: &lines)
            break
        case SCVmErrorCode.value.rawValue:
            addLine(key: prefix + "error.vmCode" , value: "VM_VALUE", lines: &lines)
            break
        case SCVmErrorCode.trapUnreachable.rawValue:
            addLine(key: prefix + "error.vmCode" , value: "VM_TRAP_UNREACHABLE", lines: &lines)
            break
        case SCVmErrorCode.tableAccessOutOfBounds.rawValue:
            addLine(key: prefix + "error.vmCode" , value: "VM_TRAP_TABLE_ACCESS_OUT_OF_BOUNDS", lines: &lines)
            break
        case SCVmErrorCode.memoryAccessOutOfBounds.rawValue:
            addLine(key: prefix + "error.vmCode" , value: "VM_TRAP_MEMORY_ACCESS_OUT_OF_BOUNDS", lines: &lines)
            break
        case SCVmErrorCode.elemUnitialized.rawValue:
            addLine(key: prefix + "error.vmCode" , value: "VM_TRAP_ELEM_UNINITIALIZED", lines: &lines)
            break
        case SCVmErrorCode.divisionByZero.rawValue:
            addLine(key: prefix + "error.vmCode" , value: "VM_TRAP_DIVISION_BY_ZERO", lines: &lines)
            break
        case SCVmErrorCode.integerOverflow.rawValue:
            addLine(key: prefix + "error.vmCode" , value: "VM_TRAP_INTEGER_OVERFLOW", lines: &lines)
            break
        case SCVmErrorCode.invalidConversionToInt.rawValue:
            addLine(key: prefix + "error.vmCode" , value: "VM_TRAP_INVALID_CONVERSION_TO_INT", lines: &lines)
            break
        case SCVmErrorCode.stackOverflow.rawValue:
            addLine(key: prefix + "error.vmCode" , value: "VM_TRAP_STACK_OVERFLOW", lines: &lines)
            break
        case SCVmErrorCode.unexpectedSignature.rawValue:
            addLine(key: prefix + "error.vmCode" , value: "VM_TRAP_UNEXPECTED_SIGNATURE", lines: &lines)
            break
        case SCVmErrorCode.memLimitExceeded.rawValue:
            addLine(key: prefix + "error.vmCode" , value: "VM_TRAP_MEM_LIMIT_EXCEEDED", lines: &lines)
            break
        case SCVmErrorCode.cpuLimitExceeded.rawValue:
            addLine(key: prefix + "error.vmCode" , value: "VM_TRAP_CPU_LIMIT_EXCEEDED", lines: &lines)
            break
        default:
            break
        }
    }
    
    private static func addSCHostContextError(code:Int32, prefix:String, lines: inout [String]) -> Void {
        addLine(key: prefix + "error.type" , value: "SST_HOST_CONTEXT_ERROR", lines: &lines)
        switch code {
        case SCHostContextErrorCode.unknownError.rawValue:
            addLine(key: prefix + "error.contextCode" , value: "HOST_CONTEXT_UNKNOWN_ERROR", lines: &lines)
            break
        case SCHostContextErrorCode.noContractRunning.rawValue:
            addLine(key: prefix + "error.contextCode" , value: "HOST_CONTEXT_NO_CONTRACT_RUNNING", lines: &lines)
            break
        default:
            break
        }
    }
    
    private static func addSCHostStorageError(code:Int32, prefix:String, lines: inout [String]) -> Void {
        addLine(key: prefix + "error.type" , value: "SST_HOST_STORAGE_ERROR", lines: &lines)
        switch code {
        case SCHostStorageErrorCode.unknownError.rawValue:
            addLine(key: prefix + "error.storageCode" , value: "HOST_STORAGE_UNKNOWN_ERROR", lines: &lines)
            break
        case SCHostStorageErrorCode.expectContractData.rawValue:
            addLine(key: prefix + "error.storageCode" , value: "HOST_STORAGE_EXPECT_CONTRACT_DATA", lines: &lines)
            break
        case SCHostStorageErrorCode.readwriteAccessToReadonlyEntry.rawValue:
            addLine(key: prefix + "error.storageCode" , value: "HOST_STORAGE_READWRITE_ACCESS_TO_READONLY_ENTRY", lines: &lines)
            break
        case SCHostStorageErrorCode.accessToUnknownEntry.rawValue:
            addLine(key: prefix + "error.storageCode" , value: "HOST_STORAGE_ACCESS_TO_UNKNOWN_ENTRY", lines: &lines)
            break
        case SCHostStorageErrorCode.missingKeyInGet.rawValue:
            addLine(key: prefix + "error.storageCode" , value: "HOST_STORAGE_MISSING_KEY_IN_GET", lines: &lines)
            break
        case SCHostStorageErrorCode.getOnDeletedKey.rawValue:
            addLine(key: prefix + "error.storageCode" , value: "HOST_STORAGE_GET_ON_DELETED_KEY", lines: &lines)
            break
        default:
            break
        }
    }
    
    private static func addSCHostFunctionError(code:Int32, prefix:String, lines: inout [String]) -> Void {
        addLine(key: prefix + "error.type" , value: "SST_HOST_FUNCTION_ERROR", lines: &lines)
        switch code {
        case SCHostFnErrorCode.unknownError.rawValue:
            addLine(key: prefix + "error.fnCode" , value: "HOST_FN_UNKNOWN_ERROR", lines: &lines)
            break
        case SCHostFnErrorCode.hostFunctionAction.rawValue:
            addLine(key: prefix + "error.fnCode" , value: "HOST_FN_UNEXPECTED_HOST_FUNCTION_ACTION", lines: &lines)
            break
        case SCHostFnErrorCode.inputArgsWrongLenght.rawValue:
            addLine(key: prefix + "error.fnCode" , value: "HOST_FN_INPUT_ARGS_WRONG_LENGTH", lines: &lines)
            break
        case SCHostFnErrorCode.inputArgsWrongType.rawValue:
            addLine(key: prefix + "error.fnCode" , value: "HOST_FN_INPUT_ARGS_WRONG_TYPE", lines: &lines)
            break
        case SCHostFnErrorCode.inputArgsInvalid.rawValue:
            addLine(key: prefix + "error.fnCode" , value: "HOST_FN_INPUT_ARGS_INVALID", lines: &lines)
            break
        default:
            break
        }
    }
    
    private static func addSCHostObjectError(code:Int32, prefix:String, lines: inout [String]) -> Void {
        addLine(key: prefix + "error.type" , value: "SST_HOST_OBJECT_ERROR", lines: &lines)
        switch code {
        case SCHostObjErrorCode.unknownError.rawValue:
            addLine(key: prefix + "error.objCode" , value: "HOST_OBJECT_UNKNOWN_ERROR", lines: &lines)
            break
        case SCHostObjErrorCode.unknownReference.rawValue:
            addLine(key: prefix + "error.objCode" , value: "HOST_OBJECT_UNKNOWN_REFERENCE", lines: &lines)
            break
        case SCHostObjErrorCode.unexpectedType.rawValue:
            addLine(key: prefix + "error.objCode" , value: "HOST_OBJECT_UNEXPECTED_TYPE", lines: &lines)
            break
        case SCHostObjErrorCode.objectCountExceedsU32Max.rawValue:
            addLine(key: prefix + "error.objCode" , value: "HOST_OBJECT_OBJECT_COUNT_EXCEEDS_U32_MAX", lines: &lines)
            break
        case SCHostObjErrorCode.objectNotExists.rawValue:
            addLine(key: prefix + "error.objCode" , value: "HOST_OBJECT_OBJECT_NOT_EXIST", lines: &lines)
            break
        case SCHostObjErrorCode.vecIndexOutOfBound.rawValue:
            addLine(key: prefix + "error.objCode" , value: "HOST_OBJECT_VEC_INDEX_OUT_OF_BOUND", lines: &lines)
            break
        case SCHostObjErrorCode.contractHashWrongLenght.rawValue:
            addLine(key: prefix + "error.objCode" , value: "HOST_OBJECT_CONTRACT_HASH_WRONG_LENGTH", lines: &lines)
            break
        default:
            break
        }
    }
    
    private static func addSCHostValueError(code:Int32, prefix:String, lines: inout [String]) -> Void {
        addLine(key: prefix + "error.type" , value: "SST_HOST_VALUE_ERROR", lines: &lines)
        switch code {
        case SCHostValErrorCode.unknownError.rawValue:
            addLine(key: prefix + "error.valCode" , value: "HOST_VALUE_UNKNOWN_ERROR", lines: &lines)
            break
        case SCHostValErrorCode.reservedTagValue.rawValue:
            addLine(key: prefix + "error.valCode" , value: "HOST_VALUE_RESERVED_TAG_VALUE", lines: &lines)
            break
        case SCHostValErrorCode.unexpectedValType.rawValue:
            addLine(key: prefix + "error.valCode" , value: "HOST_VALUE_UNEXPECTED_VAL_TYPE", lines: &lines)
            break
        case SCHostValErrorCode.u63OutOfRange.rawValue:
            addLine(key: prefix + "error.valCode" , value: "HOST_VALUE_U63_OUT_OF_RANGE", lines: &lines)
            break
        case SCHostValErrorCode.u32OutOfRange.rawValue:
            addLine(key: prefix + "error.valCode" , value: "HOST_VALUE_U32_OUT_OF_RANGE", lines: &lines)
            break
        case SCHostValErrorCode.staticUnknown.rawValue:
            addLine(key: prefix + "error.valCode" , value: "HOST_VALUE_STATIC_UNKNOWN", lines: &lines)
            break
        case SCHostValErrorCode.missingObject.rawValue:
            addLine(key: prefix + "error.valCode" , value: "HOST_VALUE_MISSING_OBJECT", lines: &lines)
            break
        case SCHostValErrorCode.symbolTooLong.rawValue:
            addLine(key: prefix + "error.valCode" , value: "HOST_VALUE_SYMBOL_BAD_CHAR", lines: &lines)
            break
        case SCHostValErrorCode.symbolContainsNonUTF8.rawValue:
            addLine(key: prefix + "error.valCode" , value: "HOST_VALUE_SYMBOL_CONTAINS_NON_UTF8", lines: &lines)
            break
        case SCHostValErrorCode.bitsetTooManyBits.rawValue:
            addLine(key: prefix + "error.valCode" , value: "HOST_VALUE_BITSET_TOO_MANY_BITS", lines: &lines)
            break
        case SCHostValErrorCode.statusUnknown.rawValue:
            addLine(key: prefix + "error.valCode" , value: "HOST_VALUE_STATUS_UNKNOWN", lines: &lines)
            break
        case SCHostValErrorCode.symbolBadChar.rawValue:
            addLine(key: prefix + "error.valCode" , value: "HOST_VALUE_SYMBOL_TOO_LONG", lines: &lines)
            break
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
        case .installContractCode(_):
            return "HOST_FUNCTION_TYPE_INSTALL_CONTRACT_CODE"
        }
    }*/
    
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
            return data.wrapped.hexEncodedString()
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
        case .bumpFootprintExpiration(_):
            return "bumpFootprintExpirationOp"
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
        case .bumpFootprintExpiration(_):
            return "BUMP_FOOTPRINT_EXPIRATION"
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
