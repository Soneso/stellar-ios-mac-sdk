//
//  URISchemeValidator.swift
//  stellarsdk
//
//  Created by Soneso on 11/09/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// An enum used to differentiate between successful and failed URL signing operations.
public enum SignURLEnum {
    /// URL signing succeeded with the signed URL.
    case success(signedURL: String)
    /// URL signing failed with the specified error.
    case failure(URISchemeErrors)
}

/// An enum used to differentiate between successful and failed URIScheme validity checks.
public enum URISchemeIsValidEnum {
    /// URI scheme validation succeeded.
    case success
    /// URI scheme validation failed with the specified error.
    case failure(URISchemeErrors)
}

/// Validates and signs SEP-0007 compliant Stellar URIs.
///
/// This class provides functionality for signing URI scheme requests and verifying their
/// authenticity by validating signatures against the origin domain's stellar.toml file.
/// It ensures URI requests come from legitimate sources by checking cryptographic signatures.
///
/// See: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0007.md
public class URISchemeValidator: NSObject {
    /// The predefined URIScheme prefix
    private let URISchemePrefix = "stellar.sep.7 - URI Scheme"

    /// Signs a SEP-0007 compliant URL with the signer's key pair.
    ///
    /// Generates a signature for the URI and appends it as the `signature` parameter.
    ///
    /// - Parameter url: The SEP-0007 compliant URI to be signed
    /// - Parameter signerKeyPair: The key pair used to generate the signature
    /// - Returns: SignURLEnum with the signed URL on success, or an error on failure
    public func signURI(url: String, signerKeyPair: KeyPair) -> SignURLEnum {
        if let signature = sign(url: url, signerKeyPair: signerKeyPair){
            if verify(forURL: url, urlEncodedBase64Signature: signature, signerPublicKey: signerKeyPair.publicKey) {
                var returnURL = url
                returnURL.append("&\(SignTransactionParams.signature)=\(signature)")
                return .success(signedURL: returnURL)
            }
        }
        
        return .failure(.invalidSignature)
    }
    
    /// Validates a SEP-0007 URI by verifying its signature against the origin domain's stellar.toml.
    ///
    /// Checks that:
    /// 1. The `origin_domain` parameter is present and is a valid fully qualified domain name
    /// 2. The domain's stellar.toml contains a `URI_REQUEST_SIGNING_KEY`
    /// 3. The `signature` parameter is present and valid for the signing key
    ///
    /// - Parameter url: The SEP-0007 compliant URI to validate
    /// - Returns: URISchemeIsValidEnum indicating success or the specific validation error
    public func checkURISchemeIsValid(url: String) async -> URISchemeIsValidEnum {
        guard let originDomain = getOriginDomain(forURL: url) else {
            return .failure(.missingOriginDomain)
        }
        
        guard originDomain.isFullyQualifiedDomainName else {
            return .failure(.invalidOriginDomain)
        }
        
        /// Get stellarToml from the origin_domain: https://<origin_domain>/.well-known/stellar.toml
        let result = await StellarToml.from(domain: originDomain)
        switch result {
        case .success(response: let stellarToml):
            /// extract URI_REQUEST_SIGNING_KEY field from tomlFile
            guard let uriRequestSigningKey = stellarToml.accountInformation.uriRequestSigningKey else {
                return .failure(.tomlSignatureMissing)
            }
            
            guard let signerPublicKey = try? PublicKey(accountId: uriRequestSigningKey) else {
                return .failure(.missingSignature)
            }
            
            /// check if the signature is valid for the url
            guard let signature = self.getSignatureField(forURL: url) else {
                return .failure(.missingSignature)
            }
            
            if self.verify(forURL: url, urlEncodedBase64Signature: signature, signerPublicKey: signerPublicKey) {
                return .success
            } else {
                return .failure(.invalidSignature)
            }
            
        case .failure(error: let stellarTomlError):
            switch stellarTomlError {
            case .invalidDomain:
                return .failure(.invalidTomlDomain)
            case .invalidToml:
                return .failure(.invalidToml)
            }
        }
    }
    
    /// Extracts the signature parameter value from a SEP-0007 URI.
    ///
    /// - Parameter url: The SEP-0007 URI to parse
    /// - Returns: The signature value if found, nil otherwise
    private func getSignatureField(forURL url: String) -> String? {
        let fields = url.split(separator: "&")
        for field in fields {
            if field.hasPrefix("\(SignTransactionParams.signature)") {
                return field.replacingOccurrences(of: "\(SignTransactionParams.signature)=", with: "")
            }
        }
        
        return nil
    }
    
    /// Extracts the origin_domain parameter value from a SEP-0007 URI.
    ///
    /// - Parameter url: The SEP-0007 URI to parse
    /// - Returns: The origin domain if found, nil otherwise
    private func getOriginDomain(forURL url: String) -> String? {
        let fields = url.split(separator: "&")
        for field in fields {
            if field.hasPrefix("\(SignTransactionParams.origin_domain)") {
                return field.replacingOccurrences(of: "\(SignTransactionParams.origin_domain)=", with: "")
            }
        }
        
        return nil
    }
    
    /// Verifies the signature of a SEP-0007 URI against the signer's public key.
    ///
    /// - Parameter url: The SEP-0007 URI to verify
    /// - Parameter urlEncodedBase64Signature: The URL-encoded base64 signature to verify
    /// - Parameter signerPublicKey: The public key to verify the signature against
    /// - Returns: True if the signature is valid, false otherwise
    private func verify(forURL url: String, urlEncodedBase64Signature: String, signerPublicKey: PublicKey) -> Bool {
        let urlSignatureLess = url.replacingOccurrences(of: "&\(SignTransactionParams.signature)=\(urlEncodedBase64Signature)", with: "")
        let payloadBytes = getPayload(forUriScheme: urlSignatureLess)
        let base64Signature = urlEncodedBase64Signature.urlDecoded
        if let base64Signature = base64Signature {
            let signatureBytes = [UInt8].init(base64: base64Signature)
            
            if let isValid = try? signerPublicKey.verify(signature: signatureBytes, message: payloadBytes) {
                return isValid
            }
        }
        
        return false
    }
    
    /// Constructs the payload bytes for signature verification per SEP-0007.
    ///
    /// The payload consists of a 36-byte prefix selector followed by the URI scheme prefix and the URI itself.
    ///
    /// - Parameter uri: The SEP-0007 URI (without signature parameter)
    /// - Returns: The payload bytes to be signed or verified
    private func getPayload(forUriScheme uri: String) -> [UInt8] {
        var prefixSelectorBytes = [UInt8](repeating: 0, count: 36)
        prefixSelectorBytes[35] = 4

        let prefix = URISchemePrefix
        let prefixData = prefix.data(using: .utf8) ?? Data()
        let uriData = uri.data(using: .utf8) ?? Data()
        let uriWithPrefixBytes: [UInt8] = Array(prefixData) + Array(uriData)

        return prefixSelectorBytes + uriWithPrefixBytes
    }
    
    /// Signs the URI and returns a URL-encoded base64 signature.
    ///
    /// - Parameter url: The SEP-0007 URI to sign
    /// - Parameter signerKeyPair: The key pair to sign with
    /// - Returns: The URL-encoded base64 signature, or nil if signing fails
    private func sign(url: String, signerKeyPair: KeyPair) -> String? {
        let payloadBytes = getPayload(forUriScheme: url)
        let signatureBytes = signerKeyPair.sign(payloadBytes)
        let base64Signature = Data(signatureBytes).base64EncodedString()
        let urlEncodedBase64Signature = base64Signature.urlEncoded

        return urlEncodedBase64Signature
    }
}
