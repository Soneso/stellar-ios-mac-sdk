import Foundation

extension ContractExecutableXDR {
    public var isWasm: Bool? {
        return type() == ContractExecutableType.wasm.rawValue
    }

    public var wasm: WrappedData32? {
        switch self {
        case .wasm(let val):
            return val
        default:
            return nil
        }
    }

    public var isStellarAsset: Bool? {
        return type() == ContractExecutableType.stellarAsset.rawValue
    }
}
