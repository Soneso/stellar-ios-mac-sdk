import Foundation

extension OperationXDR {
    @available(*, deprecated, message: "use init(sourceAccount: MuxedAccountXDR?, body: OperationBodyXDR) instead")
    public init(sourceAccount: PublicKey?, body: OperationBodyXDR) {
        var mux: MuxedAccountXDR? = nil
        if let sa = sourceAccount {
            mux = MuxedAccountXDR.ed25519(sa.bytes)
        }
        self.init(sourceAccount: mux, body: body)
    }

    public mutating func setSorobanAuth(auth: [SorobanAuthorizationEntryXDR]) {
        switch body {
        case .invokeHostFunctionOp(var invokeFunc):
            invokeFunc.auth = auth
            self.body = OperationBodyXDR.invokeHostFunctionOp(invokeFunc)
        default:
            break
        }
    }
}
