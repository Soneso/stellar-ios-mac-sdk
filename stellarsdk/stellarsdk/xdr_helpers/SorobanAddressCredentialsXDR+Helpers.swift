import Foundation

extension SorobanAddressCredentialsXDR {

    /// Appends `signature` to the credentials' signature vector.
    ///
    /// When the current signature is `.void`, it is replaced with a one-element vector.
    /// When it is already a vector, the new element is appended in call order. The vector
    /// is never re-sorted; callers are responsible for supplying signatures in the order
    /// required by the host (ascending public-key order for G-address verification).
    public mutating func appendSignature(signature: SCValXDR) {
        var sigs = [SCValXDR]()
        if let oldSigs = self.signature.vec {
            sigs = oldSigs
        }
        sigs.append(signature)
        self.signature = SCValXDR.vec(sigs)
    }
}

extension SorobanDelegateSignatureXDR {

    /// Appends `signature` to this delegate node's signature vector using the same
    /// semantics as `SorobanAddressCredentialsXDR.appendSignature`: `.void` becomes a
    /// one-element vector; an existing vector grows in call order without resorting.
    public mutating func appendSignature(signature: SCValXDR) {
        var sigs = [SCValXDR]()
        if let oldSigs = self.signature.vec {
            sigs = oldSigs
        }
        sigs.append(signature)
        self.signature = SCValXDR.vec(sigs)
    }
}
