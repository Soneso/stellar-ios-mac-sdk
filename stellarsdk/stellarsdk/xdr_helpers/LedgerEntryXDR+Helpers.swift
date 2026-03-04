import Foundation

extension LedgerEntryXDR {
    public init(lastModifiedLedgerSeq: UInt32, data: LedgerEntryDataXDR) {
        self.init(lastModifiedLedgerSeq: lastModifiedLedgerSeq, data: data, reserved: .void)
    }

    public init(fromBase64 xdr: String) throws {
        let xdrDecoder = XDRDecoder.init(data: [UInt8].init(base64: xdr))
        self = try LedgerEntryXDR(from: xdrDecoder)
    }
}
