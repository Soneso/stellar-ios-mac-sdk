import Foundation

extension PathPaymentOperationXDR {
    @available(*, deprecated, message: "use init(..., destination: MuxedAccountXDR, ...) instead")
    init(sendAsset: AssetXDR, sendMax: Int64, destination: PublicKey, destinationAsset: AssetXDR, destinationAmount: Int64, path: [AssetXDR]) {
        let mux = MuxedAccountXDR.ed25519(destination.bytes)
        self.init(sendAsset: sendAsset, sendMax: sendMax, destination: mux, destinationAsset: destinationAsset, destinationAmount: destinationAmount, path: path)
    }
}
