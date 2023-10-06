import Foundation

public struct Sep24FeeRequest {

    /// Kind of operation (deposit or withdraw).
    public var operation:String
    
    /// (optional) Type of deposit or withdrawal (SEPA, bank_account, cash, etc...).
    public var type:String?
    
    /// Asset code.
    public var assetCode:String
    
    /// Amount of the asset that will be deposited/withdrawn.
    public var amount:Double
    
    /// jwt previously received from the anchor via the SEP-10 authentication flow
    public var jwt:String?
    
    public init(operation:String, type:String? = nil, assetCode:String, amount:Double, jwt:String? = nil) {
        self.type = type
        self.assetCode = assetCode
        self.amount = amount
        self.operation = operation
        self.jwt = jwt
    }
}
