//
//  InvokeHostFunctionOperation.swift
//  stellarsdk
//
//  Created by Christian Rogobete.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

// Invokes soroban host function. Used to install (deploy), create and invoke smart contracts.
public class InvokeHostFunctionOperation:Operation {
    
    public let hostFunctionType:HostFunctionType
    
    // for invoking contracts
    public var contractId:String?
    public var functionName:String?
    public var arguments:[SCValXDR]?
    
    // for uploading contract wasm
    public var contractCode:Data?
    
    // for creating contracts
    public var wasmId:String?
    public var salt:WrappedData32?
    public var asset:Asset?
    
    // auth
    public var auth:[ContractAuthXDR] = []
    
    public init(hostFunctionType:HostFunctionType, sourceAccountId:String? = nil) {
        self.hostFunctionType = hostFunctionType;
        super.init(sourceAccountId: sourceAccountId)
    }
    
    public static func forInvokingContract(contractId:String, functionName:String, functionArguments:[SCValXDR]? = nil, sourceAccountId:String? = nil, auth: [ContractAuth]? = nil) throws -> InvokeHostFunctionOperation {
        let op = InvokeHostFunctionOperation(hostFunctionType: HostFunctionType.invokeContract, sourceAccountId:sourceAccountId)
        op.contractId = contractId
        op.functionName = functionName
        op.arguments = functionArguments
        op.auth = try contractAuthArrToXdr(arr: auth)
        return op
    }
    
    public static func forUploadingContractWasm(contractCode:Data, sourceAccountId:String? = nil) throws -> InvokeHostFunctionOperation {
        let op = InvokeHostFunctionOperation(hostFunctionType: HostFunctionType.uploadContractWasm, sourceAccountId:sourceAccountId)
        op.contractCode = contractCode
        return op
    }
    
    public static func forCreatingContract(wasmId:String, salt:WrappedData32? = nil, asset:Asset? = nil, sourceAccountId:String? = nil) throws -> InvokeHostFunctionOperation {
        let op = InvokeHostFunctionOperation(hostFunctionType: HostFunctionType.createContract, sourceAccountId:sourceAccountId)
        op.wasmId = wasmId
        op.salt = salt
        op.asset = asset
        return op
    }
    
    public static func forDeploySACWithSourceAccount(salt:WrappedData32? = nil, sourceAccountId:String? = nil) throws -> InvokeHostFunctionOperation {
        let op = InvokeHostFunctionOperation(hostFunctionType: HostFunctionType.createContract, sourceAccountId:sourceAccountId)
        op.salt = salt
        return op
    }
    
    public static func forDeploySACWithAsset(asset:Asset? = nil, footprint:LedgerFootprintXDR? = nil, sourceAccountId:String? = nil) throws -> InvokeHostFunctionOperation {
        let op = InvokeHostFunctionOperation(hostFunctionType: HostFunctionType.createContract, sourceAccountId:sourceAccountId)
        op.asset = asset
        return op
    }
    
    
    /// Creates a new InvokeHostFunctionOperation object from the given InvokeHostFunctionOpXDR object.
    ///
    /// - Parameter fromXDR: the InvokeHostFunctionOpXDR object to be used to create a new InvokeHostFunctionOperation object.
    /// - Parameter sourceAccountId: (optional) source account Id, must be valid, otherwise it will be ignored.
    public init(fromXDR:InvokeHostFunctionOpXDR, sourceAccountId:String?) throws {
        let function = fromXDR.functions.first!
        self.auth = function.auth
        
        switch function.args {
        case .invokeContract(let args):
            self.hostFunctionType = HostFunctionType.invokeContract
            for (index, arg) in args.enumerated() {
                if index == 0 {
                    self.contractId = InvokeHostFunctionOperation.contractIdFromArg(arg: arg)
                } else if index == 1 {
                    self.functionName = InvokeHostFunctionOperation.functionNameFromArg(arg: arg)
                } else {
                    if self.arguments == nil {
                        self.arguments = [SCValXDR]()
                    }
                    self.arguments?.append(arg)
                }
            }
            break
        case .uploadContractWasm(let args):
            self.hostFunctionType = HostFunctionType.uploadContractWasm
            self.contractCode = args.code
            break
        case .createContract(let args):
            self.hostFunctionType = HostFunctionType.createContract
            let contractId = args.contractId
            let source = args.executable
            switch contractId {
            case .fromSourceAccount(let wrappedData32):
                self.salt = wrappedData32
                switch source {
                case .wasmRef(let wrappedData32):
                    self.wasmId = wrappedData32.wrapped.hexEncodedString()
                case .token:
                    break
                }
            case .fromEd25519PublicKey(_):
                break
            case .fromAsset(let assetXDR):
                self.asset = try Asset.fromXDR(assetXDR: assetXDR)
            }
            break
        }
        super.init(sourceAccountId: sourceAccountId)
    }
    
    
    override func getOperationBodyXDR() throws -> OperationBodyXDR {
                
        if hostFunctionType == HostFunctionType.invokeContract { // invoke contract
            return try invokeContractBodyXDR()
        } else if hostFunctionType == HostFunctionType.uploadContractWasm { // install contract
            return try uploadContractWasmBodyXDR()
        } else if hostFunctionType == HostFunctionType.createContract, let wasmId = wasmId { // create contract
            return try createContractBodyXDR(wasmId: wasmId)
        } else if hostFunctionType == HostFunctionType.createContract, let asset = asset { // deploy create token contract with asset
            return try deploySACWithAssetBodyXDR(asset: asset)
        } else if hostFunctionType == HostFunctionType.createContract { // deploy create token contract with source account
            return try deploySACWithSourceAccountBodyXDR()
        } else {
            throw StellarSDKError.encodingError(message: "error xdr encoding invoke host function operation , incomplete data")
        }
    }
    
    private static func contractAuthArrToXdr(arr:[ContractAuth]?) throws -> [ContractAuthXDR] {
        if(arr == nil) {
            return []
        }
        var xdrArr:[ContractAuthXDR] = []
        for val in arr! {
            xdrArr.append(try ContractAuthXDR(contractAuth: val))
        }
        return xdrArr
    }
    
    private func invokeContractBodyXDR() throws -> OperationBodyXDR {
        if let contractId = contractId, let functionName = functionName {
            var invokeArgs = [SCValXDR]()
            if let contractIdData = contractId.data(using: .hexadecimal) {
                invokeArgs.append(SCValXDR.bytes(contractIdData))
                invokeArgs.append(SCValXDR.symbol(functionName))
                if arguments != nil {
                    invokeArgs.append(contentsOf: arguments!)
                }
                let xdrHostFunctionArgs = HostFunctionArgsXDR.invokeContract(invokeArgs);
                let xdrHostFunction = HostFunctionXDR(args: xdrHostFunctionArgs, auth: auth)
                let xdrFuncOp = InvokeHostFunctionOpXDR(functions: [xdrHostFunction])
                return OperationBodyXDR.invokeHostFunction(xdrFuncOp)
            } else {
                throw StellarSDKError.encodingError(message: "error xdr encoding invoke host function operation, invalid contract id")
            }
        } else {
            throw StellarSDKError.encodingError(message: "error xdr encoding invoke host function operation (invoke), incomplete data")
        }
    }
    
    private func uploadContractWasmBodyXDR() throws -> OperationBodyXDR {
        if let contractCode = contractCode {
            let args = UploadContractWasmArgsXDR(code: contractCode)
            let xdrHostFunctionArgs = HostFunctionArgsXDR.uploadContractWasm(args);
            let xdrHostFunction = HostFunctionXDR(args: xdrHostFunctionArgs, auth: auth)
            let xdrFuncOp = InvokeHostFunctionOpXDR(functions: [xdrHostFunction])
            
            return OperationBodyXDR.invokeHostFunction(xdrFuncOp)
        } else {
            throw StellarSDKError.encodingError(message: "error xdr encoding invoke host function operation (install), incomplete data")
        }
    }
    
    private func createContractBodyXDR(wasmId:String) throws -> OperationBodyXDR {
        if salt == nil {
            var saltData = Data(count: 32)
            let result = saltData.withUnsafeMutableBytes {
                SecRandomCopyBytes(kSecRandomDefault, 32, $0.baseAddress!)
            }
            if result != errSecSuccess {
                throw StellarSDKError.encodingError(message: "error xdr encoding invoke host function operation , unable to generate salt")
            }
            salt = WrappedData32(saltData)
        }
        let args = CreateContractArgsXDR(contractId: ContractIDXDR.fromSourceAccount(salt!), source: SCContractExecutableXDR.wasmRef(wasmId.wrappedData32FromHex()))
        let xdrHostFunctionArgs = HostFunctionArgsXDR.createContract(args);
        let xdrHostFunction = HostFunctionXDR(args: xdrHostFunctionArgs, auth: auth)
        let xdrFuncOp = InvokeHostFunctionOpXDR(functions: [xdrHostFunction])
        
        return OperationBodyXDR.invokeHostFunction(xdrFuncOp)
    }
    
    private func deploySACWithAssetBodyXDR(asset:Asset) throws -> OperationBodyXDR {
        let args = CreateContractArgsXDR(contractId: ContractIDXDR.fromAsset(try asset.toXDR()), source: SCContractExecutableXDR.token)
        let xdrHostFunctionArgs = HostFunctionArgsXDR.createContract(args);
        let xdrHostFunction = HostFunctionXDR(args: xdrHostFunctionArgs, auth: auth)
        let xdrFuncOp = InvokeHostFunctionOpXDR(functions: [xdrHostFunction])
        return OperationBodyXDR.invokeHostFunction(xdrFuncOp)
    }
    
    private func deploySACWithSourceAccountBodyXDR() throws -> OperationBodyXDR {
        if salt == nil {
            var saltData = Data(count: 32)
            let result = saltData.withUnsafeMutableBytes {
                SecRandomCopyBytes(kSecRandomDefault, 32, $0.baseAddress!)
            }
            if result != errSecSuccess {
                throw StellarSDKError.encodingError(message: "error xdr encoding invoke host function operation , unable to generate salt")
            }
            salt = WrappedData32(saltData)
        }
        let args = CreateContractArgsXDR(contractId: ContractIDXDR.fromSourceAccount(salt!), source: SCContractExecutableXDR.token)
        let xdrHostFunctionArgs = HostFunctionArgsXDR.createContract(args);
        let xdrHostFunction = HostFunctionXDR(args: xdrHostFunctionArgs, auth: auth)
        let xdrFuncOp = InvokeHostFunctionOpXDR(functions: [xdrHostFunction])
        return OperationBodyXDR.invokeHostFunction(xdrFuncOp)
    }
    
    private static func contractIdFromArg(arg:SCValXDR) -> String? {
        return arg.bytes?.hexEncodedString()
    }
    
    private static func functionNameFromArg(arg:SCValXDR) -> String? {
        switch arg {
            case .symbol(let sym):
                return sym
            default:
                break;
        }
        return nil
    }
}
