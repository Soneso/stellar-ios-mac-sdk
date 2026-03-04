import Foundation

extension LedgerFootprintXDR {

    public init(fromBase64 xdr: String) throws {
        let xdrDecoder = XDRDecoder.init(data: [UInt8].init(base64: xdr))
        self = try LedgerFootprintXDR(from: xdrDecoder)
    }
}
