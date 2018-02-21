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
    /// The url of the Horizon server to connect to
    internal let baseURL: String
    let jsonDecoder = JSONDecoder()
    
    private override init() {
        baseURL = ""
    }
    
    init(baseURL: String) {
        self.baseURL = baseURL
    }
    
    /// Performs a get request to the spcified path.
    ///
    /// - parameter path:  A path relative to the baseURL. If URL parameters have to be sent they can be encoded in this parameter as you would do it with regular URLs.
    /// - parameter response:   The closure to be called upon response.
    open func GETRequestWithPath(path: String, completion: @escaping ResponseClosure) {
        requestFromUrl(url: baseURL + path, method:.get, completion:completion)
    }

    /// Performs a get request to the spcified path.
    ///
    /// - parameter path:  A URL for the request. If URL parameters have to be sent they can be encoded in this parameter as you would do it with regular URLs.
    /// - parameter response:   The closure to be called upon response.
    open func GETRequestFromUrl(url: String, completion: @escaping ResponseClosure) {
        requestFromUrl(url: url, method:.get, completion:completion)
    }
    
    /// Performs a post request to the spcified path.
    ///
    /// - parameter path:  A path relative to the baseURL. If URL parameters have to be sent they can be encoded in this parameter as you would do it with regular URLs.
    /// - parameter body:  An optional parameter with the data that should be contained in the request body
    /// - parameter response:   The closure to be called upon response.
    open func POSTRequestWithPath(path: String, body:Data? = nil, completion: @escaping ResponseClosure) {
        requestFromUrl(url: baseURL + path, method:.post, body:body, completion:completion)
    }
        
    open func requestFromUrl(url: String, method: HTTPMethod, body:Data? = nil, completion: @escaping ResponseClosure) {
        let url = URL(string: url)!
        var urlRequest = URLRequest(url: url)
        
        switch method {
        case .get:
            break
        case .post:
            urlRequest.httpMethod = "POST"
            urlRequest.httpBody = body
        }
        
        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                completion(.failure(error:.requestFailed(message:error.localizedDescription)))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                var message:String!
                if let data = data {
                    message = String(data: data, encoding: String.Encoding.utf8)
                    if message == nil {
                        message = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
                    }
                } else {
                    message = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
                }
                
                switch httpResponse.statusCode {
                case 200:
                    break
                case 400: // Bad request
                    if let data = data {
                        do {
                            let badRequestErrorResponse = try self.jsonDecoder.decode(BadRequestErrorResponse.self, from: data)
                            completion(.failure(error:.badRequest(message:message, horizonErrorResponse:badRequestErrorResponse)))
                            return
                        } catch {}
                    }
                    completion(.failure(error:.badRequest(message:message, horizonErrorResponse:nil)))
                    return
                case 403: // Forbidden
                    if let data = data {
                        do {
                            let forbiddenErrorResponse = try self.jsonDecoder.decode(ForbiddenErrorResponse.self, from: data)
                            completion(.failure(error:.forbidden(message:message, horizonErrorResponse:forbiddenErrorResponse)))
                            return
                        } catch {}
                    }
                    completion(.failure(error:.forbidden(message:message, horizonErrorResponse:nil)))
                    return
                case 404: // Not found
                    if let data = data {
                        do {
                            let notFoundErrorResponse = try self.jsonDecoder.decode(NotFoundErrorResponse.self, from: data)
                            completion(.failure(error:.notFound(message:message, horizonErrorResponse:notFoundErrorResponse)))
                            return
                        } catch {}
                    }
                    completion(.failure(error:.notFound(message:message, horizonErrorResponse:nil)))
                    return
                case 406: // Not acceptable
                    if let data = data {
                        do {
                            let notAcceptableErrorResponse = try self.jsonDecoder.decode(NotAcceptableErrorResponse.self, from: data)
                            completion(.failure(error:.notAcceptable(message:message, horizonErrorResponse:notAcceptableErrorResponse)))
                            return
                        } catch {}
                    }
                    completion(.failure(error:.notAcceptable(message:message, horizonErrorResponse:nil)))
                    return
                case 410: // Gone
                    if let data = data {
                        do {
                            let beforeHistoryErrorResponse = try self.jsonDecoder.decode(BeforeHistoryErrorResponse.self, from: data)
                            completion(.failure(error:.beforeHistory(message:message, horizonErrorResponse:beforeHistoryErrorResponse)))
                            return
                        } catch {}
                    }
                    completion(.failure(error:.beforeHistory(message:message, horizonErrorResponse:nil)))
                    return
                case 429: // Too many requests
                    if let data = data {
                        do {
                            let rateLimitExceededErrorResponse = try self.jsonDecoder.decode(RateLimitExceededErrorResponse.self, from: data)
                            completion(.failure(error:.rateLimitExceeded(message:message, horizonErrorResponse:rateLimitExceededErrorResponse)))
                            return
                        } catch {}
                    }
                    completion(.failure(error:.rateLimitExceeded(message:message, horizonErrorResponse:nil)))
                    return
                case 500: // Internal server error
                    if let data = data {
                        do {
                            let internalServerErrorResponse = try self.jsonDecoder.decode(InternalServerErrorResponse.self, from: data)
                            completion(.failure(error:.internalServerError(message:message, horizonErrorResponse:internalServerErrorResponse)))
                            return
                        } catch {}
                    }
                    completion(.failure(error:.internalServerError(message:message, horizonErrorResponse:nil)))
                    return
                case 501: // Not implemented
                    if let data = data {
                        do {
                            let notImplementedErrorResponse = try self.jsonDecoder.decode(NotImplementedErrorResponse.self, from: data)
                            completion(.failure(error:.notImplemented(message:message, horizonErrorResponse:notImplementedErrorResponse)))
                            return
                        } catch {}
                    }
                    completion(.failure(error:.notImplemented(message:message, horizonErrorResponse:nil)))
                    return
                case 503: // Service unavailable
                    if let data = data {
                        do {
                            let staleHistoryErrorResponse = try self.jsonDecoder.decode(StaleHistoryErrorResponse.self, from: data)
                            completion(.failure(error:.staleHistory(message:message, horizonErrorResponse:staleHistoryErrorResponse)))
                            return
                        } catch {}
                    }
                    completion(.failure(error:.staleHistory(message:message, horizonErrorResponse:nil)))
                    return
                default:
                    completion(.failure(error:.requestFailed(message:message)))
                    return
                }
            }
            
            if let data = data {
                completion(.success(data: data))
            } else {
                completion(.failure(error:.emptyResponse))
            }
        }
        
        task.resume()
    }
}
