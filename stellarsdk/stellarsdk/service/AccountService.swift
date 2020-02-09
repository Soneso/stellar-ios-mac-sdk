//
//  AccountService.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 29/01/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// An enum used to diferentiate between successful and failed account details responses.
public enum AccountResponseEnum {
    case success(details: AccountResponse)
    case failure(error: HorizonRequestError)
}

/// An enum used to diferentiate between successful and failed data for account responses.
public enum DataForAccountResponseEnum {
    case success(details: DataForAccountResponse)
    case failure(error: HorizonRequestError)
}

/// An enum used to diferentiate between successful and failed create test account responses.
public enum CreateTestAccountResponseEnum {
    case success(details: Any)
    case failure(error: HorizonRequestError)
}

/// A closure to be called with the response from a create test account request.
public typealias CreateTestAccountClosure = (_ response:CreateTestAccountResponseEnum) -> (Void)
/// A closure to be called with the response from a account details request.
public typealias AccountResponseClosure = (_ response:AccountResponseEnum) -> (Void)
/// A closure to be called with the response from a data for account requrst.
public typealias DataForAccountResponseClosure = (_ response:DataForAccountResponseEnum) -> (Void)

/// Class that handles account related calls.
open class AccountService: NSObject {
    let serviceHelper: ServiceHelper
    let jsonDecoder = JSONDecoder()
    
    private override init() {
        serviceHelper = ServiceHelper(baseURL: "")
    }
    
    init(baseURL: String) {
        serviceHelper = ServiceHelper(baseURL: baseURL)
    }
    
    /// Provides information and links relating to a single account.
    /// See [Horizon API] (https://www.stellar.org/developers/horizon/reference/endpoints/accounts-single.html "Account Details")
    ///
    /// - Parameter accountId: A stellar account ID for an already created account. An stellar account is created when min. one lumen has been sent to a new public key / account ID.
    /// - Parameter response: The closure to be called upon response.
    ///
    /// - Throws:
    ///     - 'HorizonRequestError.notFound' if there is no account whose ID matches the 'accountId' parameter.
    ///     - other 'HorizonRequestError' errors depending on the error case.
    ///
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

    /// Each account in the Stellar network can contain multiple key/value pairs associated with it. This fuction can be used to retrieve value of such a data key.
    /// See [Horizon API] (https://www.stellar.org/developers/horizon/reference/endpoints/data-for-account.html "Data for Account")
    ///
    /// - Parameter accountId: A stellar account ID for an already created account. An stellar account is created when it has a minimum balance of 1 lumen.
    /// - Parameter key: Key name of the requested data field.
    /// - Parameter response: The closure to be called upon response.
    ///
    /// - Throws:
    ///     - A 'HorizonRequestError.notFound' error if there is no account whose ID matches the 'accountId' parameter or there is no data field with a given key.
    ///     - other 'HorizonRequestError' errors depending on the error case.
    ///
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
    
    /// On Stellar’s test network, you can ask Friendbot, the Stellar friendly robot with a very fat wallet, to create an account for you.
    /// To create such a test account, this fuction will send Friendbot the public key you created. Friendbot will create and fund a new account using that public key as the account ID.
    ///
    ///
    /// - Parameter accountId: A Stellar account ID. This can be generated using the KeyPair class:
    ///
    ///                             let myKeyPair = try KeyPair.generateRandomKeyPair()
    ///                             let accountId = myKeyPair.accountId
    ///
    /// - Parameter response:  The closure to be called upon response.
    ///
    open func createTestAccount(accountId:String, response: @escaping CreateTestAccountClosure) {
        
        let url = URL(string: "https://horizon-testnet.stellar.org/friendbot")
        let components = NSURLComponents(url: url!, resolvingAgainstBaseURL: false)
        let item = URLQueryItem(name: "addr", value: accountId)
        components?.queryItems = [item]
        
        
        let task = URLSession.shared.dataTask(with: components!.url!) { data, httpResponse, error in
            guard error == nil else {
                response(.failure(error: HorizonRequestError.requestFailed(message: error!.localizedDescription)))
                return
            }
            guard let data = data else {
                response(.failure(error: HorizonRequestError.emptyResponse))
                return
            }
            
            let json = try! JSONSerialization.jsonObject(with: data, options: [])
            response(.success(details: json))
        }
        
        task.resume()
    }
    
    /// This endpoint allows filtering accounts who have a given signer or have a trustline to an asset. The result is a list of accounts.
    
    /// To find all accounts who are trustees to an asset, pass the query parameter asset using the canonical representation for an issued assets which is Code:IssuerAccountID. Read more about canonical representation of assets in SEP-0011.
    
    /// See [Horizon API] (https://www.stellar.org/developers/horizon/reference/endpoints/accounts.html "Accounts")
    
    /// This fuction responds with a page of accounts. Pages represent a subset of a larger collection of objects. As an example, it would be unfeasible to provide the All Transactions endpoint without paging. Over time there will be millions of transactions in the Stellar network’s ledger and returning them all over a single request would be unfeasible.
    ///
    /// - Parameter signer: Optional. Account ID.
    /// - Parameter asset: Optional. An issued asset represented as "Code:IssuerAccountID".
    /// - Parameter cursor: Optional. A paging token, specifying where to start returning records from.
    /// - Parameter order: Optional. The order in which to return rows, “asc” or “desc”, ordered by assetCode then by assetIssuer.
    /// - Parameter limit: Optional. Maximum number of records to return. Default: 10
    ///
    open func getAccounts(signer:String? = nil, asset:String? = nil, cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<AccountResponse>.ResponseClosure) {
        var requestPath = "/accounts"
        
        var params = Dictionary<String,String>()
        params["signer"] = signer
        params["asset"] = asset
        params["cursor"] = cursor
        params["order"] = order?.rawValue
        if let limit = limit { params["limit"] = String(limit) }
        
        if let pathParams = params.stringFromHttpParameters(),
            pathParams.count > 0 {
            requestPath += "?\(pathParams)"
        }
        
        getAccountsFromUrl(url:serviceHelper.baseURL + requestPath, response:response)
    }
    
    /// Loads accounts for a given url if valid. E.g. for a "next" link from a PageResponse<AccountResponse> object.
    ///
    /// - Parameter url: The url to be used to load the accounts.
    ///
    open func getAccountsFromUrl(url:String, response:@escaping PageResponse<AccountResponse>.ResponseClosure) {
        serviceHelper.GETRequestFromUrl(url: url) { (result) -> (Void) in
            switch result {
            case .success(let data):
                do {
                    let accounts = try self.jsonDecoder.decode(PageResponse<AccountResponse>.self, from: data)
                    response(.success(details: accounts))
                } catch {
                    response(.failure(error: .parsingResponseFailed(message: error.localizedDescription)))
                }
            case .failure(let error):
                response(.failure(error:error))
            }
        }
    }
}
