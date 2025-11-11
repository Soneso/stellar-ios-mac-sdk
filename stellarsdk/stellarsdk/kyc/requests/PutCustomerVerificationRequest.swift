import Foundation

/// Request parameters for submitting customer verification data via SEP-0012.
///
/// This struct encapsulates the parameters needed to verify previously provided customer fields
/// that require verification, such as mobile_number or email_address. Fields that are in the
/// VERIFICATION_REQUIRED status require a request to this endpoint with verification codes or
/// confirmation values.
///
/// Note: This endpoint has been deprecated in favor of using the PUT /customer endpoint for
/// verification. However, it is still supported for backwards compatibility.
///
/// Example usage:
/// ```
/// let request = PutCustomerVerificationRequest(
///     id: "391fb415-c223-4608-b2f5-dd1e91e3a986",
///     fields: ["mobile_number_verification": "123456"],
///     jwt: authToken
/// )
/// ```
///
/// See also:
/// - [SEP-0012](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0012.md)
public struct PutCustomerVerificationRequest {

    /// The ID of the customer as returned in the response of a previous PUT request.
    public var id:String

    /// JWT previously received from the anchor via the SEP-10 authentication flow.
    public var jwt:String

    /// One or more SEP-9 fields appended with _verification.
    /// For example, if mobile_number requires verification, this would contain
    /// "mobile_number_verification" as a key with the verification code as the value.
    public var fields:[String:String]

    /// Creates a new customer verification request.
    ///
    /// - Parameters:
    ///   - id: The customer ID from a previous PUT /customer response
    ///   - fields: Dictionary of verification fields with their verification codes
    ///   - jwt: JWT previously received from the anchor via SEP-10 authentication
    public init(id:String, fields:[String:String], jwt:String) {
        self.id = id
        self.fields = fields
        self.jwt = jwt
    }

    /// Converts the request parameters to a dictionary of data for form submission.
    ///
    /// - Returns: Dictionary mapping parameter names to their Data representations
    public func toParameters() -> [String:Data] {
        var parameters = [String:Data]()
        parameters["id"] = id.data(using: .utf8)
        for field in fields {
            parameters[field.key] = field.value.data(using: .utf8)
        }
        return parameters
    }

}
