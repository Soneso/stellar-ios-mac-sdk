import Foundation

extension SorobanCredentialsXDR {

    public var address: SorobanAddressCredentialsXDR? {
        switch self {
        case .address(let addr):
            return addr
        default:
            return nil
        }
    }
}
