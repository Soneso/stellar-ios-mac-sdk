import Foundation

public struct Sep24DepositRequest {

    /// jwt previously received from the anchor via the SEP-10 authentication flow
    public var jwt:String
    
    /// The code of the stellar asset the user wants to receive for their deposit with the anchor.
    /// The value passed must match one of the codes listed in the /info response's deposit object.
    /// 'native' is a special asset_code that represents the native XLM token.
    public var assetCode:String
    
    /// (optional) The issuer of the stellar asset the user wants to receive for their deposit with the anchor.
    /// If assetIssuer is not provided, the anchor will use the asset issued by themselves as described in their TOML file.
    /// If 'native' is specified as the assetCode, assetIssuer must be not be set.
    public var assetIssuer:String?
    
    /// (optional) - string in Asset Identification Format - The asset user wants to send. Note, that this is the asset user initially holds (off-chain or fiat asset).
    /// If this is not provided, it will be collected in the interactive flow.
    /// When quote_id is specified, this parameter must match the quote's sell_asset asset code or be omitted.
    public var sourceAsset:String?
    
    /// (optional) Amount of asset requested to deposit. If this is not provided it will be collected in the interactive flow.
    public var amount:String?
    
    /// (optional) The id returned from a SEP-38 POST /quote response.
    public var quoteId:String?
    
    /// (optional) The Stellar (G...) or muxed account (M...) the client will use as the source of the withdrawal payment to the anchor.
    /// Defaults to the account authenticated via SEP-10 if not specified.
    public var account:String?
    
    /// (optional) Value of memo to attach to transaction, for hash this should be base64-encoded.
    /// Because a memo can be specified in the SEP-10 JWT for Shared Accounts, this field can be different than the value included in the SEP-10 JWT.
    /// For example, a client application could use the value passed for this parameter as a reference number used to match payments made to account.
    public var memo:String?
    
    /// (optional) type of memo that anchor should attach to the Stellar payment transaction, one of text, id or hash
    public var memoType:String?
    
    /// (optional) In communications / pages about the deposit, anchor should display the wallet name to the user to explain where funds are going.
    public var walletName:String?
    
    /// (optional) Anchor should link to this when notifying the user that the transaction has completed.
    public var walletUrl:String?
    
    /// (optional) Defaults to en if not specified or if the specified language is not supported.
    /// Language code specified using RFC 4646 which means it can also accept locale in the format en-US.
    /// error fields in the response, as well as the interactive flow UI and any other user-facing strings
    /// returned for this transaction should be in this language.
    public var lang:String?
    
    /// (optional) " true" if the client supports receiving deposit transactions as a claimable balance, false otherwise.
    public var claimableBalanceSupported:String?
    
    /// one or more of the fields listed in SEP-9
    public var kycFields:[KYCNaturalPersonFieldsEnum]?
    
    /// one or more of the fields listed in SEP-9
    public var kycOrganizationFields:[KYCOrganizationFieldsEnum]?
    
    /// one or more of the fields listed in SEP-9
    public var kycFinancialAccountFields:[KYCFinancialAccountFieldsEnum]?
    
    // additional custom fields to be added
    public var customFields:[String:String]?
    
    // additional custom files to be added
    public var customFiles:[String:Data]?
    
    public init(jwt:String, assetCode:String) {
        self.assetCode = assetCode
        self.jwt = jwt
    }
    
    public func toParameters() -> [String:Data] {
        var parameters = [String:Data]()
        parameters["asset_code"] = assetCode.data(using: .utf8)
        
        if let assetIssuer = assetIssuer {
            parameters["asset_issuer"] = assetIssuer.data(using: .utf8)
        }
        
        if let amount = amount {
            parameters["amount"] = amount.data(using: .utf8)
        }
        
        if let quoteId = quoteId {
            parameters["quote_id"] = quoteId.data(using: .utf8)
        }
        
        if let account = account {
            parameters["account"] = account.data(using: .utf8)
        }
        
        if let memo = memo {
            parameters["memo"] = memo.data(using: .utf8)
        }
        
        if let memoType = memoType {
            parameters["memo_type"] = memoType.data(using: .utf8)
        }
        
        if let walletName = walletName {
            parameters["wallet_name"] = walletName.data(using: .utf8)
        }
        
        if let walletUrl = walletUrl {
            parameters["wallet_url"] = walletUrl.data(using: .utf8)
        }
        
        if let lang = lang {
            parameters["lang"] = lang.data(using: .utf8)
        }
        
        if let claimableBalanceSupported = claimableBalanceSupported {
            parameters["claimable_balance_supported"] = claimableBalanceSupported.data(using: .utf8)
        }
        
        if let fields = customFields {
            for field in fields {
                parameters[field.key] = field.value.data(using: .utf8)
            }
        }
        
        if let fields = kycFields {
            for field in fields {
                parameters[field.parameter.0] = field.parameter.1
            }
        }
        if let fields = kycOrganizationFields {
            for field in fields {
                parameters[field.parameter.0] = field.parameter.1
            }
        }
        
        if let fields = kycFinancialAccountFields {
            for field in fields {
                parameters[field.parameter.0] = field.parameter.1
            }
        }
        
        if let files = customFiles {
            for file in files {
                parameters[file.key] = file.value
            }
        }
                
        return parameters
    }
}
