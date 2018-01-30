//
//  AccountService.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 29/01/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

public enum AccountDetailsResponseEnum {
    case success(details: AccountDetailsResponse)
    case failure(error: AccountError)
}

public enum CreateAccountResponseEnum {
    case success(details: Any)
    case failure(error: AccountError)
}

public typealias CreateAccountClosure = (_ response:CreateAccountResponseEnum) -> (Void)
public typealias AccountDetailsClosure = (_ response:AccountDetailsResponseEnum) -> (Void)

open class AccountService: NSObject {
    let serviceHelper: ServiceHelper
    let jsonDecoder = JSONDecoder()
    
    private override init() {
        serviceHelper = ServiceHelper(baseURL: "")
    }
    
    init(baseURL: String) {
        serviceHelper = ServiceHelper(baseURL: baseURL)
    }
    
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
                response(.failure(error: .requestFailed(response: error.localizedDescription)))
            }
        }
    }
    
}
