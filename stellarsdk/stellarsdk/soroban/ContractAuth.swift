//
//  ContractAuth.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 28.02.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

public class ContractAuth {
    
    public let rootInvocation:AuthorizedInvocation
    public var signatureArgs:[SCValXDR]
    public var address:Address?
    public var nonce:UInt64?
    
    public init(rootInvocation:AuthorizedInvocation, signatureArgs:[SCValXDR] = []) {
        self.rootInvocation = rootInvocation
        self.signatureArgs = signatureArgs
        self.address = nil
        self.nonce = nil
        
    }
    
    public convenience init(address:Address, nonce:UInt64, rootInvocation:AuthorizedInvocation, signatureArgs:[SCValXDR] = []) {
        self.init(rootInvocation: rootInvocation, signatureArgs: signatureArgs)
        self.address = address
        self.nonce = nonce
    }
    
    public convenience init(xdr: ContractAuthXDR) {
        let rootInvocation = AuthorizedInvocation(xdr: xdr.rootInvocation)
        let signatureArgs = xdr.signatureArgs

        if let addrNonce = xdr.addressWithNonce {
            let address = Address(xdr: addrNonce.address)
            let nonce = addrNonce.nonce
            self.init(address: address, nonce: nonce, rootInvocation: rootInvocation, signatureArgs: signatureArgs)
        } else {
            self.init(rootInvocation: rootInvocation, signatureArgs: signatureArgs)
        }
    }
    
    public convenience init(fromBase64Xdr xdr: String) throws {
        let xdrDecoder = XDRDecoder.init(data: [UInt8].init(base64: xdr))
        let xdrObj = try ContractAuthXDR(from: xdrDecoder)
        self.init(xdr: xdrObj)
    }
    
    public func sign(signer:KeyPair, network:Network) throws {
        if (address == nil || nonce == nil) {
            throw StellarSDKError.invalidArgument(message: "address and nonce must be set")
        }
        if (signer.privateKey == nil) {
            throw StellarSDKError.invalidArgument(message: "signer KeyPair must contain the private key to be able to sign")
        }
        
        let preimage = HashIDPreimageXDR.contractAuth(ContractAuthPreimage(networkID: WrappedData32(network.networkId),
                                                                           nonce: nonce!,
                                                                           invocation: try AuthorizedInvocationXDR(authorizedInvocation: rootInvocation)))
        let encoded = try XDREncoder.encode(preimage)
        let payload = Data(bytes: encoded, count: encoded.count).sha256()
        let signature = signer.sign([UInt8](payload))
        let accountEd25519Signature = AccountEd25519Signature(publicKey: signer.publicKey, signature: signature)
        let sigVal = SCValXDR(accountEd25519Signature: accountEd25519Signature)
        signatureArgs.append(sigVal)
    }
    
}
