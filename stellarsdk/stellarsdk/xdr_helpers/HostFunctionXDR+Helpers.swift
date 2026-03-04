import Foundation

extension HostFunctionXDR {

    public var invokeContract: InvokeContractArgsXDR? {
        switch self {
        case .invokeContract(let val):
            return val
        default:
            return nil
        }
    }

    public var createContract: CreateContractArgsXDR? {
        switch self {
        case .createContract(let val):
            return val
        default:
            return nil
        }
    }

    public var uploadContractWasm: Data? {
        switch self {
        case .uploadContractWasm(let val):
            return val
        default:
            return nil
        }
    }

    public var createContractV2: CreateContractV2ArgsXDR? {
        switch self {
        case .createContractV2(let val):
            return val
        default:
            return nil
        }
    }
}
