import Foundation

public struct Sep24WithdrawRequest {

    /// jwt previously received from the anchor via the SEP-10 authentication flow
    public var jwt:String
    
    /// Code of the asset the user wants to withdraw. The value passed must match one of the codes listed in the /info response's withdraw object.
    /// 'native' is a special asset_code that represents the native XLM token.
    public var assetCode:String
    
    /// (optional) The issuer of the stellar asset the user wants to withdraw with the anchor.
    /// If asset_issuer is not provided, the anchor should use the asset issued by themselves as described in their TOML file.
    /// If 'native' is specified as the asset_code, asset_issuer must be not be set.
    public var assetIssuer:String?
    
    /// (optional) string in Asset Identification Format - The asset user wants to receive. It's an off-chain or fiat asset.
    /// If this is not provided, it will be collected in the interactive flow.
    /// When quote_id is specified, this parameter must match the quote's buy_asset asset code or be omitted.
    public var destinationAsset:String?
    
    /// (optional) Amount of asset requested to withdraw. If this is not provided it will be collected in the interactive flow.
    public var amount:String?
    
    /// (optional) The id returned from a SEP-38 POST /quote response.
    public var quoteId:String?
    
    /// (optional) The Stellar (G...) or muxed account (M...) the client wants to use as the destination of the payment sent by the anchor.
    /// Defaults to the account authenticated via SEP-10 if not specified.
    public var account:String?
    
    /// (deprecated, optional) This field was originally intended to differentiate users of the same Stellar account.
    /// However, the anchor should use the sub value included in the decoded SEP-10 JWT instead.
    /// Anchors should still support this parameter to maintain support for outdated clients.
    /// See the Shared Account Authentication section for more information.
    /// https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0024.md#shared-omnibus-or-pooled-accounts
    public var memo:String?
    
    /// (deprecated, optional) Type of memo. One of text, id or hash. Deprecated because memos used to identify users of the same Stellar account should always be of type of id.
    public var memoType:String?
    
    /// (optional) In communications / pages about the withdrawal, anchor should display the wallet name to the user to explain where funds are coming from.
    public var walletName:String?
    
    /// (optional) Anchor can show this to the user when referencing the wallet involved in the withdrawal (ex. in the anchor's transaction history).
    public var walletUrl:String?
    
    /// (optional) Defaults to en if not specified or if the specified language is not supported.
    /// Language code specified using RFC 4646 which means it can also accept locale in the format en-US.
    /// error fields in the response, as well as the interactive flow UI and any other user-facing
    /// strings returned for this transaction should be in this language.
    public var lang:String?
    
    /// (optional) The memo the anchor must use when sending refund payments back to the user.
    /// If not specified, the anchor should use the same memo used by the user to send the original payment.
    /// If specified, refund_memo_type must also be specified.
    public var refundMemo:String?
    
    /// (optional) The type of the refund_memo. Can be id, text, or hash.
    /// See the memos documentation for more information.
    /// If specified, refund_memo must also be specified.
    /// https://developers.stellar.org/docs/encyclopedia/memos
    public var refundMemoType:String?
    
    /// one or more of the fields listed in SEP-9
    public var kycFields:[KYCAMLFieldsEnum]?
    
    /// one or more of the fields listed in SEP-9
    public var kycOrganizationFields:[KYCAMLOrganizationFieldsEnum]?
    
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
        
        if let refundMemo = refundMemo {
            parameters["refund_memo"] = refundMemo.data(using: .utf8)
        }
        
        if let refundMemoType = refundMemoType {
            parameters["refund_memo_type"] = refundMemoType.data(using: .utf8)
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
        
        if let files = customFiles {
            for file in files {
                parameters[file.key] = file.value
            }
        }
                
        return parameters
    }
    
}
