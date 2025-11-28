import Foundation

/// Request parameters for uploading customer information via SEP-0012.
///
/// This struct encapsulates all the parameters needed to upload KYC information to an anchor
/// in an authenticated and idempotent fashion. The endpoint is used to register new customers
/// or update existing customer information. It supports submitting SEP-9 fields for natural
/// persons, organizations, financial accounts, and cards, as well as custom fields and files.
///
/// When uploading binary fields such as photo_id_front, the request uses multipart/form-data
/// content type. Binary fields should be submitted after all other fields as some web servers
/// require this for proper stream processing.
///
/// See also:
/// - [SEP-0012](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0012.md)
/// - [SEP-0009](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0009.md)
public struct PutCustomerInfoRequest: Sendable {

    /// JWT previously received from the anchor via the SEP-10 authentication flow.
    public var jwt:String

    /// The id value returned from a previous call to this endpoint.
    /// If specified, no other parameter is required.
    public var id:String?

    /// The server should infer the account from the sub value in the SEP-10 JWT to identify the customer.
    /// The account parameter is only used for backwards compatibility, and if explicitly provided in
    /// the request body it should match the sub value of the decoded SEP-10 JWT.
    public var account:String?

    /// The client-generated memo that uniquely identifies the customer.
    /// If a memo is present in the decoded SEP-10 JWT's sub value, it must match this parameter value.
    /// If a muxed account is used as the JWT's sub value, memos sent in requests must match the
    /// 64-bit integer subaccount ID of the muxed account.
    public var memo:String?

    /// Type of memo. One of text, id or hash.
    /// Deprecated because memos should always be of type id, although anchors should continue to
    /// support this parameter for outdated clients. If hash, memo should be base64-encoded.
    /// If a memo is present in the decoded SEP-10 JWT's sub value, this parameter can be ignored.
    public var memoType:String?

    /// The type of the customer as defined in the SEP-12 Type Specification.
    /// Different types of customers may require different KYC fields.
    public var type:String?

    /// The transaction id with which the customer's info is associated.
    /// This is used when information from the customer depends on the transaction,
    /// such as when more information is required for larger amounts.
    public var transactionId:String?

    /// One or more of the natural person KYC fields as defined in SEP-9.
    public var fields:[KYCNaturalPersonFieldsEnum]?

    /// One or more of the organization KYC fields as defined in SEP-9.
    public var organizationFields:[KYCOrganizationFieldsEnum]?

    /// One or more of the financial account KYC fields as defined in SEP-9.
    public var financialAccountFields:[KYCFinancialAccountFieldsEnum]?

    /// One or more of the card KYC fields as defined in SEP-9.
    public var cardFields:[KYCCardFieldsEnum]?

    /// Additional custom fields to be submitted with the request.
    public var extraFields:[String:String]?

    /// Additional custom binary files to be submitted with the request.
    public var extraFiles:[String:Data]?

    /// Creates a new customer information upload request.
    ///
    /// - Parameters:
    ///   - jwt: JWT previously received from the anchor via SEP-10 authentication
    public init(jwt:String) {
        self.jwt = jwt
    }

    /// Converts the request parameters to a dictionary of data for multipart form submission.
    ///
    /// This method processes all KYC fields and organizes them according to SEP-9 requirements.
    /// Binary fields (such as photo_id_front) are collected separately and placed at the end
    /// of the parameters dictionary to comply with web server requirements for stream processing.
    ///
    /// - Returns: Dictionary mapping parameter names to their Data representations
    public func toParameters() -> [String:Data] {
        var parameters = [String:Data]()
        if let id = id {
            parameters["id"] = id.data(using: .utf8)
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
        if let type = type {
            parameters["type"] = type.data(using: .utf8)
        }
        if let transactionId = transactionId {
            parameters["transaction_id"] = transactionId.data(using: .utf8)
        }
        
        var collectedFiles:[String:Data] = [:]
        
        if let fields = fields {
            for field in fields {
                switch field {
                case .photoIdFront(_):
                    collectedFiles[field.parameter.0] = field.parameter.1
                case .photoIdBack(_):
                    collectedFiles[field.parameter.0] = field.parameter.1
                case .notaryApprovalOfPhotoId(_):
                    collectedFiles[field.parameter.0] = field.parameter.1
                case .ipAddress(_):
                    collectedFiles[field.parameter.0] = field.parameter.1
                case .photoProofResidence(_):
                    collectedFiles[field.parameter.0] = field.parameter.1
                case .proofOfIncome(_):
                    collectedFiles[field.parameter.0] = field.parameter.1
                case .proofOfLiveness(_):
                    collectedFiles[field.parameter.0] = field.parameter.1
                case .referralId(_):
                    collectedFiles[field.parameter.0] = field.parameter.1
                default:
                    parameters[field.parameter.0] = field.parameter.1
                }
            }
        }
        if let fields = organizationFields {
            for field in fields {
                switch field {
                case .photoIncorporationDoc(_):
                    collectedFiles[field.parameter.0] = field.parameter.1
                case .photoProofAddress(_):
                    collectedFiles[field.parameter.0] = field.parameter.1
                default:
                    parameters[field.parameter.0] = field.parameter.1
                }
            }
        }
        
        if let fields = financialAccountFields {
            for field in fields {
                parameters[field.parameter.0] = field.parameter.1
            }
        }
        
        if let fields = cardFields {
            for field in fields {
                parameters[field.parameter.0] = field.parameter.1
            }
        }
        
        if let fields = extraFields {
            for (key, value) in fields {
                parameters[key] = value.data(using: .utf8)
            }
        }

        /// Binary fields must be placed at the end for proper stream processing
        for (key, value) in collectedFiles {
            parameters[key] = value
        }
        
        if let files = extraFiles {
            for (key, value) in files {
                parameters[key] = value
            }
        }
    
        return parameters
    }
    
}
