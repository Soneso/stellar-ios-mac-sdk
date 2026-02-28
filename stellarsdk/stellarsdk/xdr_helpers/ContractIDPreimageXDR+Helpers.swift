import Foundation

extension ContractIDPreimageXDR {

    public var fromAddress: ContractIDPreimageFromAddressXDR? {
        switch self {
        case .fromAddress(let addr):
            return addr
        default:
            return nil
        }
    }

    public var fromAsset: AssetXDR? {
        switch self {
        case .fromAsset(let asset):
            return asset
        default:
            return nil
        }
    }
}
