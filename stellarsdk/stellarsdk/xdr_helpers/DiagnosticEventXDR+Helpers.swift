import Foundation

extension DiagnosticEventXDR {
    public init(fromBase64 xdr: String) throws {
        let xdrDecoder = XDRDecoder.init(data: [UInt8].init(base64: xdr))
        self = try DiagnosticEventXDR(from: xdrDecoder)
    }
}
