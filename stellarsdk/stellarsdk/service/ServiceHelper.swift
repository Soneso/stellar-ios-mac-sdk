//
//  ServiceHelper.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 30/01/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// An enum to diferentiate between succesful and failed responses
enum Result {
    case success(data: Data)
    case failure(error: NetworkError)
}

/// A closure to be called when a HTTP response is received
typealias ResponseClosure = (_ response:Result) -> (Void)

/// End class responsible with the HTTP connection to the Horizon server
class ServiceHelper: NSObject {
    /// The url of the Horizon server to connect to
    let baseURL: String
    
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
    open func GETRequest(path: String, completion: @escaping ResponseClosure) {
        let url = URL(string: baseURL + path)!
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
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
                case 404:
                    completion(.failure(error:.resourceNotFound(message:message)))
                    return
                case 500:
                    completion(.failure(error:.internalError(message:message)))
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
