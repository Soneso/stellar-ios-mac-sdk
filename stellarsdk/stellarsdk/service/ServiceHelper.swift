//
//  ServiceHelper.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 30/01/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// HTTP methods supported for Horizon API requests.
enum HTTPMethod {
    case get
    case post
    case put
    case delete
    case patch
}

/// Result type to differentiate between successful and failed HTTP responses.
enum Result {
    case success(data: Data)
    case failure(error: HorizonRequestError)
}

/// Internal helper class responsible for HTTP connections to the Horizon server.
///
/// Handles all HTTP communication including GET, POST, PUT, PATCH, DELETE requests,
/// multipart form data, JWT authentication, and Horizon-specific error handling.
class ServiceHelper: @unchecked Sendable {
    static let HorizonClientVersionHeader = "X-Client-Version"
    static let HorizonClientNameHeader = "X-Client-Name"
    static let HorizonClientApplicationNameHeader = "X-App-Name"
    static let HorizonClientApplicationVersionHeader = "X-App-Version"

    lazy var horizonRequestHeaders: [String: String] = {
        var headers: [String: String] = [:]

        let mainBundle = Bundle.main
        let frameworkBundle = Bundle(for: ServiceHelper.self)
        
        if let bundleIdentifier = frameworkBundle.infoDictionary?["CFBundleIdentifier"] as? String {
            headers[ServiceHelper.HorizonClientNameHeader] = bundleIdentifier
        }
        if let bundleVersion = frameworkBundle.infoDictionary?["CFBundleShortVersionString"] as? String {
            headers[ServiceHelper.HorizonClientVersionHeader] = bundleVersion
        }
        if let applicationBundleID = mainBundle.infoDictionary?["CFBundleIdentifier"] as? String {
            headers[ServiceHelper.HorizonClientApplicationNameHeader] = applicationBundleID
        }
        if let applicationBundleVersion = mainBundle.infoDictionary?["CFBundleShortVersionString"] as? String {
            headers[ServiceHelper.HorizonClientApplicationVersionHeader] = applicationBundleVersion
        }

        return headers
    }()

    /// The url of the Horizon server to connect to
    private let baseURL: String
    private let baseUrlQueryItems: [URLQueryItem]?
    let jsonDecoder = JSONDecoder()
    
    private init() {
        baseURL = ""
        baseUrlQueryItems = nil
    }
    
    init(baseURL: String) {
        if let url = URL(string: baseURL), let components = URLComponents(url: url, resolvingAgainstBaseURL: false), let queryItems = components.queryItems {
            self.baseUrlQueryItems = queryItems.count > 0 ? queryItems : nil
            var bComponents = components
            bComponents.query = nil
            if let bUrl = bComponents.url {
                self.baseURL = bUrl.absoluteString.hasSuffix("/") ? String(bUrl.absoluteString.dropLast()) : bUrl.absoluteString
            } else {
                self.baseURL = ""
            }
        } else {
            self.baseURL = baseURL
            self.baseUrlQueryItems = nil
        }
    }
    
    /// Constructs a complete request URL by combining the base URL with the given path.
    ///
    /// Merges any query items from the base URL with those in the path.
    ///
    /// - Parameter path: The API endpoint path to append to the base URL
    /// - Returns: The complete URL string for the request
    open func requestUrlWithPath(path: String) -> String {
        
        if let url = URL(string: self.baseURL + path), let components = URLComponents(url: url, resolvingAgainstBaseURL: false), let bQueryItems = self.baseUrlQueryItems {
            var rComponents = components
            if let rQueryItems = rComponents.queryItems {
                var tQueryItems = rQueryItems
                tQueryItems.append(contentsOf: bQueryItems)
                rComponents.queryItems = tQueryItems
            } else {
                rComponents.queryItems = bQueryItems
            }
            if let bUrl = rComponents.url {
                return bUrl.absoluteString
            }
        }
        return baseURL + path
    }
    
    /// Performs a GET request to the specified path.
    ///
    /// - Parameter path: A path relative to the baseURL. URL parameters can be encoded in this parameter as you would do with regular URLs.
    /// - Parameter jwtToken: Optional token to be set in the header as "Authorization: Bearer {token}"
    /// - Returns: Result with response data on success or HorizonRequestError on failure
    open func GETRequestWithPath(path: String, jwtToken:String? = nil) async -> Result {
        let requestUrl = requestUrlWithPath(path: path)
        return await requestFromUrl(url: requestUrl, method: .get, jwtToken: jwtToken)
    }

    /// Performs a GET request to the specified URL.
    ///
    /// - Parameter url: A complete URL for the request. URL parameters can be encoded in this parameter as you would do with regular URLs.
    /// - Parameter jwtToken: Optional token to be set in the header as "Authorization: Bearer {token}"
    /// - Returns: Result with response data on success or HorizonRequestError on failure
    open func GETRequestFromUrl(url: String, jwtToken:String? = nil) async -> Result {
        return await requestFromUrl(url: url, method: .get, jwtToken: jwtToken)
    }
    
    /// Performs a POST request to the specified path.
    ///
    /// - Parameter path: A path relative to the baseURL. URL parameters can be encoded in this parameter as you would do with regular URLs.
    /// - Parameter jwtToken: Optional token to be set in the header as "Authorization: Bearer {token}"
    /// - Parameter body: Optional data to be contained in the request body
    /// - Parameter contentType: Optional content type to set in the request header
    /// - Returns: Result with response data on success or HorizonRequestError on failure
    open func POSTRequestWithPath(path: String, jwtToken:String? = nil, body:Data? = nil, contentType:String? = nil) async -> Result {
        let requestUrl = requestUrlWithPath(path: path)
        return await requestFromUrl(url: requestUrl, method: .post, contentType: contentType, jwtToken: jwtToken, body: body)
    }
    
    /// Performs a PUT request to the specified path.
    ///
    /// - Parameter path: A path relative to the baseURL. URL parameters can be encoded in this parameter as you would do with regular URLs.
    /// - Parameter jwtToken: Optional token to be set in the header as "Authorization: Bearer {token}"
    /// - Parameter body: Optional data to be contained in the request body
    /// - Parameter contentType: Optional content type to set in the request header
    /// - Returns: Result with response data on success or HorizonRequestError on failure
    open func PUTRequestWithPath(path: String, jwtToken:String? = nil, body:Data? = nil, contentType:String? = nil) async -> Result {
        let requestUrl = requestUrlWithPath(path: path)
        return await requestFromUrl(url: requestUrl, method: .put, contentType: contentType, jwtToken: jwtToken, body: body)
    }
    
    /// Performs a PATCH request to the specified path.
    ///
    /// - Parameter path: A path relative to the baseURL. URL parameters can be encoded in this parameter as you would do with regular URLs.
    /// - Parameter jwtToken: Optional token to be set in the header as "Authorization: Bearer {token}"
    /// - Parameter contentType: Optional content type to set in the request header
    /// - Parameter body: Optional data to be contained in the request body
    /// - Returns: Result with response data on success or HorizonRequestError on failure
    open func PATCHRequestWithPath(path: String, jwtToken:String? = nil, contentType:String? = nil, body:Data? = nil) async -> Result {
        let requestUrl = requestUrlWithPath(path: path)
        return await requestFromUrl(url: requestUrl, method: .patch, jwtToken: jwtToken, body: body)
    }
    
    /// Performs a multipart POST request to the specified path.
    ///
    /// - Parameter path: A path relative to the baseURL. URL parameters can be encoded in this parameter as you would do with regular URLs.
    /// - Parameter parameters: Optional dictionary of form field names to data values for the multipart body
    /// - Parameter jwtToken: Optional token to be set in the header as "Authorization: Bearer {token}"
    /// - Returns: Result with response data on success or HorizonRequestError on failure
    open func POSTMultipartRequestWithPath(path: String, parameters:[String:Data]? = nil, jwtToken:String? = nil) async -> Result {
        return await multipartRequestWithPath(path: path, parameters: parameters, method: .post, jwtToken: jwtToken)
    }
    
    /// Performs a multipart PUT request to the specified path.
    ///
    /// - Parameter path: A path relative to the baseURL. URL parameters can be encoded in this parameter as you would do with regular URLs.
    /// - Parameter parameters: Optional dictionary of form field names to data values for the multipart body
    /// - Parameter jwtToken: Optional token to be set in the header as "Authorization: Bearer {token}"
    /// - Returns: Result with response data on success or HorizonRequestError on failure
    open func PUTMultipartRequestWithPath(path: String, parameters:[String:Data]? = nil, jwtToken:String? = nil) async -> Result {
        return await multipartRequestWithPath(path: path, parameters: parameters, method: .put, jwtToken: jwtToken)
    }
    
    /// Performs a multipart request to the specified path using the given HTTP method.
    ///
    /// Constructs a multipart/form-data request body with proper boundaries and encoding.
    ///
    /// - Parameter path: A path relative to the baseURL. URL parameters can be encoded in this parameter as you would do with regular URLs.
    /// - Parameter parameters: Optional dictionary of form field names to data values for the multipart body
    /// - Parameter method: The HTTP method to use (e.g., .put, .post)
    /// - Parameter jwtToken: Optional token to be set in the header as "Authorization: Bearer {token}"
    /// - Returns: Result with response data on success or HorizonRequestError on failure
    open func multipartRequestWithPath(path: String, parameters:[String:Data]? = nil, method: HTTPMethod, jwtToken:String? = nil) async -> Result {
        let boundary = String(format: "------------------------%08X%08X", arc4random(), arc4random())
        let contentType: String = {
            guard let charset = CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(String.Encoding.utf8.rawValue)) else {
                return ""
            }
            return "multipart/form-data; charset=\(charset); boundary=\(boundary)"
        }()
        let httpBody: Data = {
            var body = Data()

            if let parameters = parameters {
                for (rawName, rawValue) in parameters {
                    if !body.isEmpty {
                        if let newlineData = "\r\n".data(using: .utf8) {
                            body.append(newlineData)
                        }
                    }

                    if let boundaryData = "--\(boundary)\r\n".data(using: .utf8) {
                        body.append(boundaryData)
                    }

                    guard rawName.canBeConverted(to: .utf8), let disposition = "Content-Disposition: form-data; name=\"\(rawName)\"\r\n".data(using: .utf8) else {
                        continue
                    }
                    body.append(disposition)
                    if let newlineData = "\r\n".data(using: .utf8) {
                        body.append(newlineData)
                    }
                    body.append(rawValue)
                }
            }

            if let closingBoundaryData = "\r\n--\(boundary)--\r\n".data(using: .utf8) {
                body.append(closingBoundaryData)
            }

            return body
        }()
        let requestUrl = requestUrlWithPath(path: path)
        return await requestFromUrl(url: requestUrl, method: method, contentType: contentType, jwtToken: jwtToken, body: httpBody)
    }
    
    /// Performs a DELETE request to the specified path.
    ///
    /// - Parameter path: A path relative to the baseURL. URL parameters can be encoded in this parameter as you would do with regular URLs.
    /// - Parameter jwtToken: Optional token to be set in the header as "Authorization: Bearer {token}"
    /// - Returns: Result with response data on success or HorizonRequestError on failure
    open func DELETERequestWithPath(path: String, jwtToken:String? = nil) async -> Result {
        let requestUrl = requestUrlWithPath(path: path)
        return await requestFromUrl(url: requestUrl, method: .delete, jwtToken: jwtToken)
    }
        
    /// Performs an HTTP request to the specified URL.
    ///
    /// This is the core request method that handles all HTTP communication with Horizon.
    /// It sets appropriate headers, handles authentication, and maps HTTP status codes
    /// to specific HorizonRequestError types.
    ///
    /// - Parameter url: The complete URL for the request
    /// - Parameter method: The HTTP method to use
    /// - Parameter contentType: Optional content type to set in the request header
    /// - Parameter jwtToken: Optional token to be set in the header as "Authorization: Bearer {token}"
    /// - Parameter body: Optional data to be contained in the request body
    /// - Returns: Result with response data on success or HorizonRequestError on failure
    open func requestFromUrl(url: String, method: HTTPMethod, contentType:String? = nil, jwtToken:String? = nil, body:Data? = nil) async -> Result {
        guard let url1 = URL(string: url) else {
            return .failure(error: .requestFailed(message: "Invalid URL: \(url)", horizonErrorResponse: nil))
        }
        var urlRequest = URLRequest(url: url1)

        horizonRequestHeaders.forEach {
            urlRequest.addValue($0.value, forHTTPHeaderField: $0.key)
        }

        if let contentType = contentType {
            urlRequest.addValue(contentType, forHTTPHeaderField: "Content-Type")
        }

        if let token = jwtToken {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        switch method {
        case .get:
            break
        case .post:
            urlRequest.httpMethod = "POST"
            urlRequest.httpBody = body
        case .put:
            urlRequest.httpMethod = "PUT"
            urlRequest.httpBody = body
        case .delete:
            urlRequest.httpMethod = "DELETE"
        case .patch:
            urlRequest.httpMethod = "PATCH"
            urlRequest.httpBody = body
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(error: .emptyResponse)
            }

            var message: String!
            message = String(data: data, encoding: String.Encoding.utf8)
            if message == nil {
                message = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            }

            switch httpResponse.statusCode {
            case 200, 201, 202:
                return .success(data: data)
            case 400:
                if let badRequestErrorResponse = try? self.jsonDecoder.decode(BadRequestErrorResponse.self, from: data) {
                    return .failure(error: .badRequest(message: message, horizonErrorResponse: badRequestErrorResponse))
                }
                return .failure(error: .badRequest(message: message, horizonErrorResponse: nil))
            case 401:
                return .failure(error: .unauthorized(message: message))
            case 403:
                if let forbiddenErrorResponse = try? self.jsonDecoder.decode(ForbiddenErrorResponse.self, from: data) {
                    return .failure(error: .forbidden(message: message, horizonErrorResponse: forbiddenErrorResponse))
                }
                return .failure(error: .forbidden(message: message, horizonErrorResponse: nil))
            case 404:
                if let notFoundErrorResponse = try? self.jsonDecoder.decode(NotFoundErrorResponse.self, from: data) {
                    return .failure(error: .notFound(message: message, horizonErrorResponse: notFoundErrorResponse))
                }
                return .failure(error: .notFound(message: message, horizonErrorResponse: nil))
            case 406:
                if let notAcceptableErrorResponse = try? self.jsonDecoder.decode(NotAcceptableErrorResponse.self, from: data) {
                    return .failure(error: .notAcceptable(message: message, horizonErrorResponse: notAcceptableErrorResponse))
                }
                return .failure(error: .notAcceptable(message: message, horizonErrorResponse: nil))
            case 409:
                if let duplicateErrorResponse = try? self.jsonDecoder.decode(DuplicateErrorResponse.self, from: data) {
                    return .failure(error: .duplicate(message: message, horizonErrorResponse: duplicateErrorResponse))
                }
                return .failure(error: .duplicate(message: message, horizonErrorResponse: nil))
            case 410:
                if let beforeHistoryErrorResponse = try? self.jsonDecoder.decode(BeforeHistoryErrorResponse.self, from: data) {
                    return .failure(error: .beforeHistory(message: message, horizonErrorResponse: beforeHistoryErrorResponse))
                }
                return .failure(error: .beforeHistory(message: message, horizonErrorResponse: nil))
            case 413:
                if let errorResponse = try? self.jsonDecoder.decode(PayloadTooLargeErrorResponse.self, from: data) {
                    return .failure(error: .payloadTooLarge(message: message, horizonErrorResponse: errorResponse))
                }
                return .failure(error: .payloadTooLarge(message: message, horizonErrorResponse: nil))
            case 429:
                if let rateLimitExceededErrorResponse = try? self.jsonDecoder.decode(RateLimitExceededErrorResponse.self, from: data) {
                    return .failure(error: .rateLimitExceeded(message: message, horizonErrorResponse: rateLimitExceededErrorResponse))
                }
                return .failure(error: .rateLimitExceeded(message: message, horizonErrorResponse: nil))
            case 500:
                if let internalServerErrorResponse = try? self.jsonDecoder.decode(InternalServerErrorResponse.self, from: data) {
                    return .failure(error: .internalServerError(message: message, horizonErrorResponse: internalServerErrorResponse))
                }
                return .failure(error: .internalServerError(message: message, horizonErrorResponse: nil))
            case 501:
                if let notImplementedErrorResponse = try? self.jsonDecoder.decode(NotImplementedErrorResponse.self, from: data) {
                    return .failure(error: .notImplemented(message: message, horizonErrorResponse: notImplementedErrorResponse))
                }
                return .failure(error: .notImplemented(message: message, horizonErrorResponse: nil))
            case 503:
                if let staleHistoryErrorResponse = try? self.jsonDecoder.decode(StaleHistoryErrorResponse.self, from: data) {
                    return .failure(error: .staleHistory(message: message, horizonErrorResponse: staleHistoryErrorResponse))
                }
                return .failure(error: .staleHistory(message: message, horizonErrorResponse: nil))
            case 504:
                if let timeoutErrorResponse = try? self.jsonDecoder.decode(TimeoutErrorResponse.self, from: data) {
                    return .failure(error: .timeout(message: message, horizonErrorResponse: timeoutErrorResponse))
                }
                return .failure(error: .timeout(message: message, horizonErrorResponse: nil))
            default:
                if let errorResponse = try? self.jsonDecoder.decode(ErrorResponse.self, from: data) {
                    return .failure(error: .requestFailed(message: message, horizonErrorResponse: errorResponse))
                }
                return .failure(error: .requestFailed(message: message, horizonErrorResponse: nil))
            }
        } catch {
            return .failure(error: .requestFailed(message: error.localizedDescription, horizonErrorResponse: nil))
        }
    }
}
