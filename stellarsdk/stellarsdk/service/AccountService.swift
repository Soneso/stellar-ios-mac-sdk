//
//  AccountService.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 29/01/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// An enum used to diferentiate between successful and failed account details responses
public enum AccountResponseEnum {
    case success(details: AccountResponse)
    case failure(error: HorizonRequestError)
}

/// An enum used to diferentiate between successful and failed data for account responses
public enum DataForAccountResponseEnum {
    case success(details: DataForAccountResponse)
    case failure(error: HorizonRequestError)
}

/// An enum used to diferentiate between successful and failed create account responses
public enum CreateAccountResponseEnum {
    case success(details: Any)
    case failure(error: Error)
}

/// A closure to be called with the response from a create account request
public typealias CreateAccountClosure = (_ response:CreateAccountResponseEnum) -> (Void)
/// A closure to be called with the response from a account details request
public typealias AccountResponseClosure = (_ response:AccountResponseEnum) -> (Void)
/// A closure to be called with the response from a data for account requrst
public typealias DataForAccountResponseClosure = (_ response:DataForAccountResponseEnum) -> (Void)

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
    
    /**
        Provides information and links relating to a single account.
        See [Horizon API] (https://www.stellar.org/developers/horizon/reference/endpoints/accounts-single.html "Account Details")
 
        - Parameter accountId:  A stellar accountId (public key) for an already created account. An stellar account is created when min. one lumen has been sent to a new public key.
        - Parameter response:   The closure to be called upon response.
     
        - Throws:
            - 'HorizonRequestError.notFound' if there is no account whose ID matches the 'accountId' parameter.
            - other 'HorizonRequestError' errors depending on the error case.
     
     */
    open func getAccountDetails(accountId: String, response: @escaping AccountResponseClosure) {
        let requestPath = "/accounts/\(accountId)"
        
        serviceHelper.GETRequestWithPath(path: requestPath) { (result) -> (Void) in
            switch result {
            case .success(let data):
                do {
                    let responseMessage = try self.jsonDecoder.decode(AccountResponse.self, from: data)
                    response(.success(details:responseMessage))
                } catch {
                    response(.failure(error: .parsingResponseFailed(message: error.localizedDescription)))
                }
                
            case .failure(let error):
                response(.failure(error:error))
            }
        }
    }

    /**
        Each account in the Stellar network can contain multiple key/value pairs associated with it. This fuction can be used to retrieve value of such a data key.
        See [Horizon API] (https://www.stellar.org/developers/horizon/reference/endpoints/data-for-account.html "Data for Account")
     
        - Parameter accountId:  A stellar accountId (public key) for an already created account. An stellar account is created when min. one lumen has been sent to a new public key.
        - Parameter key:        Key name of the requested data field.
        - Parameter response:   The closure to be called upon response.
     
        - Throws:
            - A 'HorizonRequestError.notFound' error if there is no account whose ID matches the 'accountId' parameter or there is no data field with a given key.
            - other 'HorizonRequestError' errors depending on the error case.
     
     */
    open func getDataForAccount(accountId: String, key: String, response: @escaping DataForAccountResponseClosure) {
        let requestPath = "/accounts/\(accountId)/data/\(key)"
        
        serviceHelper.GETRequestWithPath(path: requestPath) { (result) -> (Void) in
            switch result {
            case .success(let data):
                do {
                    let responseMessage = try self.jsonDecoder.decode(DataForAccountResponse.self, from: data)
                    response(.success(details:responseMessage))
                } catch {
                    response(.failure(error: .parsingResponseFailed(message: error.localizedDescription)))
                }
                
            case .failure(let error):
                response(.failure(error:error))
            }
        }
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
}
