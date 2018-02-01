//
//  AccountService.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 29/01/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

/// A enum used to diferentiate between successful and failed account details responses
public enum AccountDetailsResponseEnum {
    case success(details: AccountDetailsResponse)
    case failure(error: AccountError)
}

/// A enum used to diferentiate between successful and failed create account responses
public enum CreateAccountResponseEnum {
    case success(details: Any)
    case failure(error: AccountError)
}

/// A closure to be called with the response from a create account request
public typealias CreateAccountClosure = (_ response:CreateAccountResponseEnum) -> (Void)
/// A closure to be called with the response from a account details request
public typealias AccountDetailsClosure = (_ response:AccountDetailsResponseEnum) -> (Void)

/// Class that handles account related calls
open class AccountService: NSObject {
    let serviceHelper: ServiceHelper
    let jsonDecoder = JSONDecoder()
    
    private override init() {
        serviceHelper = ServiceHelper(baseURL: "")
    }
    
    init(baseURL: String) {
        serviceHelper = ServiceHelper(baseURL: baseURL)
    }
    
    /// Create an account on the test network.
    ///
    /// - parameter key:        A stellar accountid key. This can be generated using the KeyPair class.
    /// - parameter response:   The closure to be called upon response.
    open func createTestAccount(key: String, response: @escaping CreateAccountClosure) {
        
        let url = URL(string: "https://horizon-testnet.stellar.org/friendbot")
        let components = NSURLComponents(url: url!, resolvingAgainstBaseURL: false)
        let item = URLQueryItem(name: "addr", value: key)
        components?.queryItems = [item]
        
        
        let task = URLSession.shared.dataTask(with: components!.url!) { data, httpResponse, error in
            guard error == nil else {
                return
            }
            guard let data = data else {
                return
            }
            
            let json = try! JSONSerialization.jsonObject(with: data, options: [])
            response(.success(details: json))
        }
        
        task.resume()
    }
    
    /// Get the details for an account.
    ///
    /// - parameter accountId:  A stellar accountid for an already created account. An stellar account is created when some assets are sent to a new key.
    /// - parameter response:   The closure to be called upon response.
    open func getAccountDetails(accountId: String, response: @escaping AccountDetailsClosure) {
        let requestPath = "/accounts/\(accountId)"
        
        serviceHelper.GETRequest(path: requestPath) { (result) -> (Void) in
            switch result {
            case .success(let data):
                do {
                    let responseMessage = try self.jsonDecoder.decode(AccountDetailsResponse.self, from: data)
                    response(.success(details:responseMessage))
                } catch {
                    response(.failure(error: .parsingFailed(response: error.localizedDescription)))
                }
                
            case .failure(let error):
                switch error {
                case .resourceNotFound(let message):
                    response(.failure(error: .accountNotFound(response: message)))
                case .requestFailed(let message):
                    response(.failure(error: .requestFailed(response: message)))
                case .internalError(let message):
                    response(.failure(error: .requestFailed(response: message)))
                case .emptyResponse:
                    response(.failure(error: .requestFailed(response: "The response came back empty")))
                }
            }
        }
    }
    
}
