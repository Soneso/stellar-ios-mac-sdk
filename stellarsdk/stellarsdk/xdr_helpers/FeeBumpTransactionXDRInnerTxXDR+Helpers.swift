import Foundation

extension FeeBumpTransactionXDRInnerTxXDR {
    public var tx: TransactionV1EnvelopeXDR {
        switch self {
        case .v1(let txv1):
            return txv1
        }
    }
}
