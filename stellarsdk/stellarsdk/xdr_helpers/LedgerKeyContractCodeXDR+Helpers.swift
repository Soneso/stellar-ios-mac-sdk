import Foundation

extension LedgerKeyContractCodeXDR {
    /// Creates a contract code ledger key from the 64 character hex of the 32 byte wasm hash.
    ///
    /// - Throws: StellarSDKError.invalidArgument if the hash is not exactly 64 hexadecimal characters
    public init(wasmId: String) throws {
        self.init(hash: try wasmId.wrappedData32FromHex(idKind: "wasm id"))
    }
}
