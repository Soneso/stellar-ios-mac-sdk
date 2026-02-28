import Foundation

extension SorobanAuthorizationEntryXDR {

    public init(fromBase64 xdr: String) throws {
        let xdrDecoder = XDRDecoder.init(data: [UInt8].init(base64: xdr))
        self = try SorobanAuthorizationEntryXDR(from: xdrDecoder)
    }

    public mutating func sign(signer: KeyPair, network: Network, signatureExpirationLedger: UInt32? = nil) throws {
        if (credentials.address == nil) {
            throw StellarSDKError.invalidArgument(message: "credentials must be of type address")
        }
        if (signer.privateKey == nil) {
            throw StellarSDKError.invalidArgument(message: "signer KeyPair must contain the private key to be able to sign")
        }

        if let sigExpLedger = signatureExpirationLedger, var address = credentials.address {
            address.signatureExpirationLedger = sigExpLedger
            self.credentials = SorobanCredentialsXDR.address(address)
        }

        let authPreimage = HashIDPreimageSorobanAuthorizationXDR(networkID: WrappedData32(network.networkId), nonce: credentials.address!.nonce, signatureExpirationLedger: credentials.address!.signatureExpirationLedger, invocation: rootInvocation)

        let preimage = HashIDPreimageXDR.sorobanAuthorization(authPreimage)

        let encoded = try XDREncoder.encode(preimage)
        let payload = Data(bytes: encoded, count: encoded.count).sha256Hash
        let signature = signer.sign([UInt8](payload))
        let accountEd25519Signature = AccountEd25519Signature(publicKey: signer.publicKey, signature: signature)
        let sigVal = SCValXDR(accountEd25519Signature: accountEd25519Signature)
        var address = credentials.address!
        address.appendSignature(signature: sigVal)
        self.credentials = SorobanCredentialsXDR.address(address)
    }
}
