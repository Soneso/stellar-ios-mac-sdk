import Foundation

extension SorobanAddressCredentialsXDR {

    public mutating func appendSignature(signature: SCValXDR) {
        var sigs = [SCValXDR]()
        if let oldSigs = self.signature.vec {
            sigs = oldSigs
        }
        sigs.append(signature)
        self.signature = SCValXDR.vec(sigs)
    }
}
