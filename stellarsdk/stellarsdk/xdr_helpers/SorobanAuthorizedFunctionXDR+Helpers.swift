import Foundation

extension SorobanAuthorizedFunctionXDR {

    public var contractFn: InvokeContractArgsXDR? {
        switch self {
        case .contractFn(let val):
            return val
        default:
            return nil
        }
    }

    public var contractHostFn: CreateContractArgsXDR? {
        switch self {
        case .createContractHostFn(let val):
            return val
        default:
            return nil
        }
    }

    public var contractV2HostFn: CreateContractV2ArgsXDR? {
        switch self {
        case .createContractV2HostFn(let val):
            return val
        default:
            return nil
        }
    }
}
