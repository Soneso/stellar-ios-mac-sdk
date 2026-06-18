import Foundation

extension SorobanCredentialsXDR {

    /// The inner `SorobanAddressCredentialsXDR` when the credential arm is `.address`
    /// (the legacy protocol 24 arm).
    ///
    /// Existing call sites depend on nil being returned for all other arms including the
    /// protocol-27 `.addressV2` and `.addressWithDelegates` arms. Use `addressCredentials`
    /// when arm-agnostic access is required.
    public var address: SorobanAddressCredentialsXDR? {
        switch self {
        case .address(let addr):
            return addr
        default:
            return nil
        }
    }

    /// The inner `SorobanAddressCredentialsXDR` for any address-type arm.
    ///
    /// Returns the credentials from `.address`, `.addressV2`, or `.addressWithDelegates`
    /// (protocol 27). Returns `nil` for `.sourceAccount`.
    public var addressCredentials: SorobanAddressCredentialsXDR? {
        switch self {
        case .address(let creds):
            return creds
        case .addressV2(let creds):
            return creds
        case .addressWithDelegates(let withDelegates):
            return withDelegates.addressCredentials
        case .sourceAccount:
            return nil
        }
    }

    /// Returns a new `SorobanCredentialsXDR` carrying `c` in the same arm as `self`.
    ///
    /// For `.addressWithDelegates` the delegates array is preserved; only
    /// `addressCredentials` is replaced. Calling this on `.sourceAccount` throws because
    /// source-account credentials have no inner address credentials to replace.
    ///
    /// - Parameter c: Replacement address credentials.
    /// - Returns: A new credential value with the same arm carrying the updated credentials.
    /// - Throws: `StellarSDKError.invalidArgument` for `.sourceAccount`.
    public func withAddressCredentials(_ c: SorobanAddressCredentialsXDR) throws -> SorobanCredentialsXDR {
        switch self {
        case .address:
            return .address(c)
        case .addressV2:
            return .addressV2(c)
        case .addressWithDelegates(let withDelegates):
            let updated = SorobanAddressCredentialsWithDelegatesXDR(
                addressCredentials: c,
                delegates: withDelegates.delegates
            )
            return .addressWithDelegates(updated)
        case .sourceAccount:
            throw StellarSDKError.invalidArgument(
                message: "withAddressCredentials: source-account credentials carry no inner address credentials"
            )
        }
    }
}
