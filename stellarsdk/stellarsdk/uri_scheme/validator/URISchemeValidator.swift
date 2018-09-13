//
//  URISchemeValidator.swift
//  stellarsdk
//
//  Created by Soneso on 11/09/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// An enum used to diferentiate between successful and failed url singing operation.
public enum SignURLEnum {
    case success(signedURL: String)
    case failure(URISchemeErrors)
}

/// An enum used to diferentiate between successful and failed URIScheme validity.
public enum URISchemeIsValidEnum {
    case success()
    case failure(URISchemeErrors)
}

public class URISchemeValidator: NSObject {
    /// The predefined URIScheme prefix
    private let URISchemePrefix = "stellar.sep.7 - URI Scheme"
    
    /// Signs the URIScheme compliant URL with the signer's key pair.
    public func signURI(url: String, signerKeyPair: KeyPair) -> SignURLEnum {
        if let signature = sign(url: url, signerKeyPair: signerKeyPair){
            if verify(forURL: url, urlEncodedBase64Signature: signature, signerKeyPair: signerKeyPair) {
                var returnURL = url
                returnURL.append("&\(SignTransactionParams.signature)=\(signature)")
                return .success(signedURL: returnURL)
            }
        }
        
        return .failure(.invalidSignature)
    }
    
    /// Checks if the URL is valid; signature and domain must be present and correct for the signer's keypair.
    public func checkURISchemeIsValid(url: String, signerKeyPair: KeyPair) -> URISchemeIsValidEnum{
        if let signature = getSignatureField(forURL: url) {
            if verify(forURL: url, urlEncodedBase64Signature: signature, signerKeyPair: signerKeyPair) {
                if let originDomain = getOriginDomain(forURL: url) {
                    if originDomain.isFullyQualifiedDomainName {
                        return .success()
                    } else {
                        return .failure(.invalidOriginDomain)
                    }
                } else {
                    return .failure(.missingOriginDomain)
                }
            } else {
                return .failure(.invalidSignature)
            }
        } else {
            return .failure(.missingSignature)
        }
    }
    
    /// Returns the signature value from the url.
    private func getSignatureField(forURL url: String) -> String? {
        let fields = url.split(separator: "&")
        for field in fields {
            if field.hasPrefix("\(SignTransactionParams.signature)") {
                return field.replacingOccurrences(of: "\(SignTransactionParams.signature)=", with: "")
            }
        }
        
        return nil
    }
    
    /// Returns the origin domain value from the url.
    private func getOriginDomain(forURL url: String) -> String? {
        let fields = url.split(separator: "&")
        for field in fields {
            if field.hasPrefix("\(SignTransactionParams.origin_domain)") {
                return field.replacingOccurrences(of: "\(SignTransactionParams.origin_domain)=", with: "")
            }
        }
        
        return nil
    }
    
    /// Verifies if the url is valid for the given signature to check if it's an authentic url.
    private func verify(forURL url: String, urlEncodedBase64Signature: String, signerKeyPair: KeyPair) -> Bool {
        let urlSignatureLess = url.replacingOccurrences(of: "&\(SignTransactionParams.signature)=\(urlEncodedBase64Signature)", with: "")
        let payloadBytes = getPayload(forUriScheme: urlSignatureLess)
        let base64Signature = urlEncodedBase64Signature.urlDecoded
        if let base64Signature = base64Signature {
            let signatureBytes = [UInt8].init(base64: base64Signature)
            
            if let isValid = try? signerKeyPair.verify(signature: signatureBytes, message: payloadBytes) {
                return isValid
            }
        }
        
        return false
    }
    
    /// Returns the payload of the url.
    private func getPayload(forUriScheme uri: String) -> [UInt8] {
        var prefixSelectorBytes = [UInt8](repeating: 0, count: 36)
        prefixSelectorBytes[35] = 4
        
        let prefix = URISchemePrefix
        let uriWithPrefixBytes: [UInt8] = prefix.bytes + uri.bytes
        
        return prefixSelectorBytes + uriWithPrefixBytes
    }
    
    /// Signs the url and returns a url encoded base64 signature for the url.
    private func sign(url: String, signerKeyPair: KeyPair) -> String? {
        let payloadBytes = getPayload(forUriScheme: url)
        let signatureBytes = signerKeyPair.sign(payloadBytes)
        let base64Signature = signatureBytes.toBase64()
        let urlEncodedBase64Signature = base64Signature?.urlEncoded
        
        return urlEncodedBase64Signature
    }
}
