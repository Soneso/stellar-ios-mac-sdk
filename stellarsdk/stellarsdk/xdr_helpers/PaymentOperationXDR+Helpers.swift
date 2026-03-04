import Foundation

extension PaymentOperationXDR {
    @available(*, deprecated, message: "use init(destination: MuxedAccountXDR, asset: AssetXDR, amount: Int64) instead")
    init(destination: PublicKey, asset: AssetXDR, amount: Int64) {
        let mux = MuxedAccountXDR.ed25519(destination.bytes)
        self.init(destination: mux, asset: asset, amount: amount)
    }
}
