//
//  ServiceHelper.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 30/01/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// An enum for HTTP methods
enum HTTPMethod {
    case get
    case post
    case put
    case delete
    case patch
}

/// An enum to diferentiate between succesful and failed responses
enum Result {
    case success(data: Data)
    case failure(error: HorizonRequestError)
}

/// A closure to be called when a HTTP response is received
typealias ResponseClosure = (_ response:Result) -> (Void)

/// End class responsible with the HTTP connection to the Horizon server
class ServiceHelper: NSObject {
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
    
    private override init() {
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
    /// Performs a get request to the specified path.
    ///
    /// - parameter path:  A path relative to the baseURL. If URL parameters have to be sent they can be encoded in this parameter as you would do it with regular URLs.
    /// - parameter jwtToken: token to be set in the header as Authorization: Bearer  token
    /// - parameter response:   The closure to be called upon response.
    @available(*, renamed: "GETRequestWithPath(path:jwtToken:)")
    open func GETRequestWithPath(path: String, jwtToken:String? = nil, completion: @escaping ResponseClosure) {
        Task {
            let result = await GETRequestWithPath(path: path, jwtToken: jwtToken)
            completion(result)
        }
    }
    
    /// Performs a get request to the specified path.
    ///
    /// - parameter path:  A path relative to the baseURL. If URL parameters have to be sent they can be encoded in this parameter as you would do it with regular URLs.
    /// - parameter jwtToken: token to be set in the header as Authorization: Bearer  token
    /// - returns Result
    @available(*, renamed: "GETRequestWithPath(path:jwtToken:)")
    open func GETRequestWithPath(path: String, jwtToken:String? = nil) async -> Result {
        let requestUrl = requestUrlWithPath(path: path)
        return await requestFromUrl(url: requestUrl, method: .get, jwtToken: jwtToken)
    }

    /// Performs a get request to the specified path.
    ///
    /// - parameter path:  A URL for the request. If URL parameters have to be sent they can be encoded in this parameter as you would do it with regular URLs.
    /// - parameter jwtToken: token to be set in the header as Authorization: Bearer  token
    /// - parameter response:   The closure to be called upon response.
    @available(*, renamed: "GETRequestFromUrl(url:jwtToken:)")
    open func GETRequestFromUrl(url: String, jwtToken:String? = nil, completion: @escaping ResponseClosure) {
        Task {
            let result = await GETRequestFromUrl(url: url, jwtToken: jwtToken)
            completion(result)
        }
    }
    
    /// Performs a get request to the specified path.
    ///
    /// - parameter path:  A URL for the request. If URL parameters have to be sent they can be encoded in this parameter as you would do it with regular URLs.
    /// - parameter jwtToken: token to be set in the header as Authorization: Bearer  token
    /// - returns Result
    open func GETRequestFromUrl(url: String, jwtToken:String? = nil) async -> Result {
        return await requestFromUrl(url: url, method: .get, jwtToken: jwtToken)
    }
    
    /// Performs a post request to the specified path.
    ///
    /// - parameter path:  A path relative to the baseURL. If URL parameters have to be sent they can be encoded in this parameter as you would do it with regular URLs.
    /// - parameter jwtToken: token to be set in the header as Authorization: Bearer  token
    /// - parameter body:  An optional parameter with the data that should be contained in the request body
    /// - parameter contentType:  An optional parameter with the content type to set
    /// - parameter response:   The closure to be called upon response.
    @available(*, renamed: "POSTRequestWithPath(path:jwtToken:body:contentType:)")
    open func POSTRequestWithPath(path: String, jwtToken:String? = nil, body:Data? = nil, contentType:String? = nil, completion: @escaping ResponseClosure) {
        Task {
            let result = await POSTRequestWithPath(path: path, jwtToken: jwtToken, body: body, contentType: contentType)
            completion(result)
        }
    }
    
    /// Performs a post request to the specified path.
    ///
    /// - parameter path:  A path relative to the baseURL. If URL parameters have to be sent they can be encoded in this parameter as you would do it with regular URLs.
    /// - parameter jwtToken: token to be set in the header as Authorization: Bearer  token
    /// - parameter body:  An optional parameter with the data that should be contained in the request body
    /// - parameter contentType:  An optional parameter with the content type to set
    /// - returns Result
    open func POSTRequestWithPath(path: String, jwtToken:String? = nil, body:Data? = nil, contentType:String? = nil) async -> Result {
        let requestUrl = requestUrlWithPath(path: path)
        return await requestFromUrl(url: requestUrl, method: .post, contentType: contentType, jwtToken: jwtToken, body: body)
    }
    
    /// Performs a put request to the specified path.
    ///
    /// - parameter path:  A path relative to the baseURL. If URL parameters have to be sent they can be encoded in this parameter as you would do it with regular URLs.
    /// - parameter jwtToken: token to be set in the header as Authorization: Bearer  token
    /// - parameter body:  An optional parameter with the data that should be contained in the request body
    /// - parameter contentType:  An optional parameter with the content type to set
    /// - parameter response:   The closure to be called upon response.
    @available(*, renamed: "PUTRequestWithPath(path:jwtToken:body:contentType:)")
    open func PUTRequestWithPath(path: String, jwtToken:String? = nil, body:Data? = nil, contentType:String? = nil, completion: @escaping ResponseClosure) {
        Task {
            let result = await PUTRequestWithPath(path: path, jwtToken: jwtToken, body: body, contentType: contentType)
            completion(result)
        }
    }
    
    /// Performs a put request to the specified path.
    ///
    /// - parameter path:  A path relative to the baseURL. If URL parameters have to be sent they can be encoded in this parameter as you would do it with regular URLs.
    /// - parameter jwtToken: token to be set in the header as Authorization: Bearer  token
    /// - parameter body:  An optional parameter with the data that should be contained in the request body
    /// - parameter contentType:  An optional parameter with the content type to set
    /// - returns Result
    open func PUTRequestWithPath(path: String, jwtToken:String? = nil, body:Data? = nil, contentType:String? = nil) async -> Result {
        let requestUrl = requestUrlWithPath(path: path)
        return await requestFromUrl(url: requestUrl, method: .put, contentType: contentType, jwtToken: jwtToken, body: body)
    }
    
    /// Performs a patch request to the specified path.
    ///
    /// - parameter path:  A path relative to the baseURL. If URL parameters have to be sent they can be encoded in this parameter as you would do it with regular URLs.
    /// - parameter jwtToken: token to be set in the header as Authorization: Bearer  token
    /// - parameter contentType:  An optional parameter representing the content type of the request
    /// - parameter body:  An optional parameter with the data that should be contained in the request body
    /// - parameter response:   The closure to be called upon response.
    @available(*, renamed: "PATCHRequestWithPath(path:jwtToken:contentType:body:)")
    open func PATCHRequestWithPath(path: String, jwtToken:String? = nil, contentType:String? = nil, body:Data? = nil, completion: @escaping ResponseClosure) {
        Task {
            let result = await PATCHRequestWithPath(path: path, jwtToken: jwtToken, contentType: contentType, body: body)
            completion(result)
        }
    }
    
    /// Performs a patch request to the specified path.
    ///
    /// - parameter path:  A path relative to the baseURL. If URL parameters have to be sent they can be encoded in this parameter as you would do it with regular URLs.
    /// - parameter jwtToken: token to be set in the header as Authorization: Bearer  token
    /// - parameter contentType:  An optional parameter representing the content type of the request
    /// - parameter body:  An optional parameter with the data that should be contained in the request body
    /// - returns Result
    open func PATCHRequestWithPath(path: String, jwtToken:String? = nil, contentType:String? = nil, body:Data? = nil) async -> Result {
        let requestUrl = requestUrlWithPath(path: path)
        return await requestFromUrl(url: requestUrl, method: .patch, jwtToken: jwtToken, body: body)
    }
    
    /// Performs a post request to the specified path.
    ///
    /// - parameter path:  A path relative to the baseURL. If URL parameters have to be sent they can be encoded in this parameter as you would do it with regular URLs.
    /// - parameter parameters:  An optional parameter with the data that should be contained in the request body
    /// - parameter jwtToken: token to be set in the header as Authorization: Bearer  token
    /// - parameter response:   The closure to be called upon response.
    @available(*, renamed: "POSTMultipartRequestWithPath(path:parameters:jwtToken:)")
    open func POSTMultipartRequestWithPath(path: String, parameters:[String:Data]? = nil, jwtToken:String? = nil, completion: @escaping ResponseClosure) {
        Task {
            let result = await POSTMultipartRequestWithPath(path: path, parameters: parameters, jwtToken: jwtToken)
            completion(result)
        }
    }
    
    /// Performs a post request to the specified path.
    ///
    /// - parameter path:  A path relative to the baseURL. If URL parameters have to be sent they can be encoded in this parameter as you would do it with regular URLs.
    /// - parameter parameters:  An optional parameter with the data that should be contained in the request body
    /// - parameter jwtToken: token to be set in the header as Authorization: Bearer  token
    /// - returns Resut
    open func POSTMultipartRequestWithPath(path: String, parameters:[String:Data]? = nil, jwtToken:String? = nil) async -> Result {
        return await multipartRequestWithPath(path: path, parameters: parameters, method: .post, jwtToken: jwtToken)
    }
    
    /// Performs a put request to the specified path.
    ///
    /// - parameter path:  A path relative to the baseURL. If URL parameters have to be sent they can be encoded in this parameter as you would do it with regular URLs.
    /// - parameter parameters:  An optional parameter with the data that should be contained in the request body
    /// - parameter jwtToken: token to be set in the header as Authorization: Bearer  token
    /// - parameter response:   The closure to be called upon response.
    @available(*, renamed: "PUTMultipartRequestWithPath(path:parameters:jwtToken:)")
    open func PUTMultipartRequestWithPath(path: String, parameters:[String:Data]? = nil, jwtToken:String? = nil, completion: @escaping ResponseClosure) {
        Task {
            let result = await PUTMultipartRequestWithPath(path: path, parameters: parameters, jwtToken: jwtToken)
            completion(result)
        }
    }
    
    
    /// Performs a put request to the specified path.
    ///
    /// - parameter path:  A path relative to the baseURL. If URL parameters have to be sent they can be encoded in this parameter as you would do it with regular URLs.
    /// - parameter parameters:  An optional parameter with the data that should be contained in the request body
    /// - parameter jwtToken: token to be set in the header as Authorization: Bearer  token
    /// - returns Resut
    open func PUTMultipartRequestWithPath(path: String, parameters:[String:Data]? = nil, jwtToken:String? = nil) async -> Result {
        return await multipartRequestWithPath(path: path, parameters: parameters, method: .put, jwtToken: jwtToken)
    }
    
    /// Performs a multipart request to the specified path using the passed http method
    ///
    /// - parameter path:  A path relative to the baseURL. If URL parameters have to be sent they can be encoded in this parameter as you would do it with regular URLs.
    /// - parameter parameters:  An optional parameter with the data that should be contained in the request body
    /// - parameter method:  the http method to be used, e.g. .put, .post
    /// - parameter jwtToken: token to be set in the header as Authorization: Bearer  token
    /// - parameter response:   The closure to be called upon response.
    @available(*, renamed: "multipartRequestWithPath(path:parameters:method:jwtToken:)")
    open func multipartRequestWithPath(path: String, parameters:[String:Data]? = nil, method: HTTPMethod, jwtToken:String? = nil, completion: @escaping ResponseClosure) {
        Task {
            let result = await multipartRequestWithPath(path: path, parameters: parameters, method: method, jwtToken: jwtToken)
            completion(result)
        }
    }
    
    /// Performs a multipart request to the specified path using the passed http method
    ///
    /// - parameter path:  A path relative to the baseURL. If URL parameters have to be sent they can be encoded in this parameter as you would do it with regular URLs.
    /// - parameter parameters:  An optional parameter with the data that should be contained in the request body
    /// - parameter method:  the http method to be used, e.g. .put, .post
    /// - parameter jwtToken: token to be set in the header as Authorization: Bearer  token
    /// - returns Resut
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
    
    /// Performs a delete request to the specified path.
    ///
    /// - parameter path:  A path relative to the baseURL. If URL parameters have to be sent they can be encoded in this parameter as you would do it with regular URLs.
    /// - parameter jwtToken: token to be set in the header as Authorization: Bearer  token
    /// - parameter response:   The closure to be called upon response.
    @available(*, renamed: "DELETERequestWithPath(path:jwtToken:)")
    open func DELETERequestWithPath(path: String, jwtToken:String? = nil, completion: @escaping ResponseClosure) {
        Task {
            let result = await DELETERequestWithPath(path: path, jwtToken: jwtToken)
            completion(result)
        }
    }
    
    /// Performs a delete request to the specified path.
    ///
    /// - parameter path:  A path relative to the baseURL. If URL parameters have to be sent they can be encoded in this parameter as you would do it with regular URLs.
    /// - parameter jwtToken: token to be set in the header as Authorization: Bearer  token
    /// - returns Resut
    open func DELETERequestWithPath(path: String, jwtToken:String? = nil) async -> Result {
        let requestUrl = requestUrlWithPath(path: path)
        return await requestFromUrl(url: requestUrl, method: .delete, jwtToken: jwtToken)
    }
        
    @available(*, renamed: "requestFromUrl(url:method:contentType:jwtToken:body:)")
    open func requestFromUrl(url: String, method: HTTPMethod, contentType:String? = nil, jwtToken:String? = nil, body:Data? = nil, completion: @escaping ResponseClosure) {
        Task {
            let result = await requestFromUrl(url: url, method: method, contentType: contentType, jwtToken: jwtToken, body: body)
            completion(result)
        }
    }
    
    
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
