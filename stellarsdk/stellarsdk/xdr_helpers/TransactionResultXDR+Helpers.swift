import Foundation

// Convenience extensions for TransactionResultXDR and InnerTransactionResultXDR.
// The generated structs use `result` (union) and `ext` fields; these computed
// properties provide quick access to the discriminant code and a base64 decoder.

extension TransactionResultXDR {
  public var code: TransactionResultCode {
    TransactionResultCode(rawValue: result.type())!
  }

  public init(feeCharged: Int64, result: TransactionResultBodyXDR) {
    self.init(feeCharged: feeCharged, result: result, ext: .void)
  }

  public static func fromXdr(base64: String) throws -> TransactionResultXDR {
    let xdrDecoder = XDRDecoder(data: [UInt8](base64: base64))
    return try TransactionResultXDR(from: xdrDecoder)
  }
}

extension InnerTransactionResultXDR {
  public var code: TransactionResultCode {
    TransactionResultCode(rawValue: result.type())!
  }

  public init(feeCharged: Int64, result: InnerTransactionResultBodyXDR) {
    self.init(feeCharged: feeCharged, result: result, ext: .void)
  }
}
