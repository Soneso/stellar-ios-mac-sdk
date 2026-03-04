import Foundation

extension SorobanTransactionDataXDR {

    /// Convenience initializer with default ext (.void) and resourceFee (0).
    public init(resources: SorobanResourcesXDR) {
        self.init(ext: SorobanResourcesExt.void, resources: resources, resourceFee: 0)
    }

    /// Convenience initializer with default ext (.void).
    public init(resources: SorobanResourcesXDR, resourceFee: Int64) {
        self.init(ext: SorobanResourcesExt.void, resources: resources, resourceFee: resourceFee)
    }

    public init(fromBase64 xdr: String) throws {
        let xdrDecoder = XDRDecoder.init(data: [UInt8].init(base64: xdr))
        self = try SorobanTransactionDataXDR(from: xdrDecoder)
    }

    public var archivedSorobanEntries: [UInt32]? {
        switch ext {
        case .void:
            return nil
        case .resourceExt(let sorobanResourcesExtV0):
            return sorobanResourcesExtV0.archivedSorobanEntries
        }
    }
}
