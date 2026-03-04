import Foundation

extension LedgerKeyContractCodeXDR {
    public init(wasmId: String) {
        self.init(hash: wasmId.wrappedData32FromHex())
    }
}
