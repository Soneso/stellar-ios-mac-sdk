import Foundation

extension Ed25519SignedPayload: Equatable {
    public static func ==(lhs: Ed25519SignedPayload, rhs: Ed25519SignedPayload) -> Bool {
        return lhs.ed25519 == rhs.ed25519 && lhs.payload == rhs.payload
    }
}

extension Ed25519SignedPayload {
    public func encodeSignedPayload() throws -> String {
        let data = try Data(XDREncoder.encode(self))
        return try data.encodeSignedPayload()
    }

    public func publicKey() throws -> PublicKey {
        return try PublicKey([UInt8](ed25519.wrapped))
    }
}
