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
    /// See [Horizon API] (https://developers.stellar.org/api/horizon/reference/endpoints/accounts-single.html "Account Details")
    ///
    /// - Parameter accountId: A stellar account ID for an already created account. An stellar account is created when min. one lumen has been sent to a new public key / account ID.
    /// - Parameter response: The closure to be called upon response.
    ///
    @available(*, renamed: "getAccountDetails(accountId:)")
    open func getAccountDetails(accountId: String, response: @escaping AccountResponseClosure) {
        Task {
            let result = await getAccountDetails(accountId: accountId)
            response(result)
        }
    }
    
    /// Provides information and links relating to a single account.
    /// See [Horizon API] (https://developers.stellar.org/api/horizon/reference/endpoints/accounts-single.html "Account Details")
    ///
    /// - Parameter accountId: A stellar account ID for an already created account. An stellar account is created when min. one lumen has been sent to a new public key / account ID.
    /// - Parameter response: The closure to be called upon response.
    ///
    open func getAccountDetails(accountId: String) async -> AccountResponseEnum {
        var requestPath = "/accounts/\(accountId)"
        if accountId.hasPrefix("M"), let mux = try? accountId.decodeMuxedAccount() {
            requestPath = "/accounts/\(mux.ed25519AccountId)"
        }
        let result = await serviceHelper.GETRequestWithPath(path: requestPath)
        switch result {
        case .success(let data):
            do {
                let responseMessage = try self.jsonDecoder.decode(AccountResponse.self, from: data)
                return .success(details:responseMessage)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
            
        case .failure(let error):
            return .failure(error:error)
        }
    }

    /// Each account in the Stellar network can contain multiple key/value pairs associated with it. This fuction can be used to retrieve value of such a data key.
    /// See [Horizon API] (https://developers.stellar.org/api/horizon/reference/endpoints/data-for-account.html "Data for Account")
    ///
    /// - Parameter accountId: A stellar account ID for an already created account. An stellar account is created when it has a minimum balance of 1 lumen.
    /// - Parameter key: Key name of the requested data field.
    /// - Parameter response: The closure to be called upon response.
    ///
    @available(*, renamed: "getDataForAccount(accountId:key:)")
    open func getDataForAccount(accountId: String, key: String, response: @escaping DataForAccountResponseClosure) {
        Task {
            let result = await getDataForAccount(accountId: accountId, key: key)
            response(result)
        }
    }
    
    /// Each account in the Stellar network can contain multiple key/value pairs associated with it. This fuction can be used to retrieve value of such a data key.
    /// See [Horizon API] (https://developers.stellar.org/api/horizon/reference/endpoints/data-for-account.html "Data for Account")
    ///
    /// - Parameter accountId: A stellar account ID for an already created account. An stellar account is created when it has a minimum balance of 1 lumen.
    /// - Parameter key: Key name of the requested data field.
    /// - Parameter response: The closure to be called upon response.
    ///
    open func getDataForAccount(accountId: String, key: String) async -> DataForAccountResponseEnum {
        let requestPath = "/accounts/\(accountId)/data/\(key)"
        
        let result = await serviceHelper.GETRequestWithPath(path: requestPath)
        switch result {
        case .success(let data):
            do {
                let responseMessage = try self.jsonDecoder.decode(DataForAccountResponse.self, from: data)
                return .success(details:responseMessage)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
            
        case .failure(let error):
            return .failure(error:error)
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
    @available(*, renamed: "createTestAccount(accountId:)")
    open func createTestAccount(accountId:String, response: @escaping CreateTestAccountClosure) {
        Task {
            let result = await createTestAccount(accountId: accountId)
            response(result)
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
    open func createTestAccount(accountId:String) async -> CreateTestAccountResponseEnum {
        
        let url = URL(string: "https://horizon-testnet.stellar.org/friendbot")
        let components = NSURLComponents(url: url!, resolvingAgainstBaseURL: false)
        let item = URLQueryItem(name: "addr", value: accountId)
        components?.queryItems = [item]
        
        
        return await withCheckedContinuation { continuation in
            let task = URLSession.shared.dataTask(with: components!.url!) { data, httpResponse, error in
                guard error == nil else {
                    continuation.resume(returning: .failure(error: HorizonRequestError.requestFailed(message: error!.localizedDescription, horizonErrorResponse: nil)))
                    return
                }
                guard let data1 = data else {
                    continuation.resume(returning: .failure(error: HorizonRequestError.emptyResponse))
                    return
                }
                
                let json = try! JSONSerialization.jsonObject(with: data1, options: [])
                continuation.resume(returning: .success(details: json))
            }
            
            task.resume()
        }
    }
    
    /// Creates an account on futurenet
    ///
    /// - Parameter accountId: A Stellar account ID. This can be generated using the KeyPair class:
    ///
    ///                             let myKeyPair = try KeyPair.generateRandomKeyPair()
    ///                             let accountId = myKeyPair.accountId
    ///
    /// - Parameter response:  The closure to be called upon response.
    ///
    @available(*, renamed: "createFutureNetTestAccount(accountId:)")
    open func createFutureNetTestAccount(accountId:String, response: @escaping CreateTestAccountClosure) {
        Task {
            let result = await createFutureNetTestAccount(accountId: accountId)
            response(result)
        }
    }
    
    /// Creates an account on futurenet
    ///
    /// - Parameter accountId: A Stellar account ID. This can be generated using the KeyPair class:
    ///
    ///                             let myKeyPair = try KeyPair.generateRandomKeyPair()
    ///                             let accountId = myKeyPair.accountId
    ///
    /// - Parameter response:  The closure to be called upon response.
    ///
    open func createFutureNetTestAccount(accountId:String) async -> CreateTestAccountResponseEnum {
        
        let url = URL(string: "https://friendbot-futurenet.stellar.org")
        let components = NSURLComponents(url: url!, resolvingAgainstBaseURL: false)
        let item = URLQueryItem(name: "addr", value: accountId)
        components?.queryItems = [item]
        
        
        return await withCheckedContinuation { continuation in
            let task = URLSession.shared.dataTask(with: components!.url!) { data, httpResponse, error in
                guard error == nil else {
                    continuation.resume(returning: .failure(error: HorizonRequestError.requestFailed(message: error!.localizedDescription, horizonErrorResponse: nil)))
                    return
                }
                guard let data1 = data else {
                    continuation.resume(returning: .failure(error: HorizonRequestError.emptyResponse))
                    return
                }
                
                let json = try! JSONSerialization.jsonObject(with: data1, options: [])
                continuation.resume(returning: .success(details: json))
            }
            
            task.resume()
        }
    }
    
    /// This endpoint allows filtering accounts who have a given signer or have a trustline to an asset. The result is a list of accounts.
    ///
    /// To find all accounts who are trustees to an asset, pass the query parameter asset using the canonical representation for an issued assets which is Code:IssuerAccountID. Read more about canonical representation of assets in SEP-0011.
    ///
    /// See [Horizon API] (https://developers.stellar.org/api/horizon/reference/endpoints/accounts.html "Accounts")
    ///
    /// This fuction responds with a page of accounts. Pages represent a subset of a larger collection of objects. As an example, it would be unfeasible to provide the All Transactions endpoint without paging. Over time there will be millions of transactions in the Stellar network’s ledger and returning them all over a single request would be unfeasible.
    ///
    /// - Parameter signer: Optional. Account ID.
    /// - Parameter asset: Optional. An issued asset represented in coanolical form ("native" or "Code:IssuerAccountID").
    /// - Parameter sponsor: Optional. Account ID.
    /// - Parameter liquidityPoolId: Liquidity Pool ID
    /// - Parameter cursor: Optional. A paging token, specifying where to start returning records from.
    /// - Parameter order: Optional. The order in which to return rows, “asc” or “desc”, ordered by assetCode then by assetIssuer.
    /// - Parameter limit: Optional. Maximum number of records to return. Default: 10
    @available(*, renamed: "getAccounts(signer:asset:sponsor:liquidityPoolId:cursor:order:limit:)")
    open func getAccounts(signer:String? = nil, asset:String? = nil, sponsor:String? = nil, liquidityPoolId:String? = nil, cursor:String? = nil, order:Order? = nil, limit:Int? = nil, response:@escaping PageResponse<AccountResponse>.ResponseClosure) {
        Task {
            let result = await getAccounts(signer: signer, asset: asset, sponsor: sponsor, liquidityPoolId: liquidityPoolId, cursor: cursor, order: order, limit: limit)
            response(result)
        }
    }
    
    /// This endpoint allows filtering accounts who have a given signer or have a trustline to an asset. The result is a list of accounts.
    ///
    /// To find all accounts who are trustees to an asset, pass the query parameter asset using the canonical representation for an issued assets which is Code:IssuerAccountID. Read more about canonical representation of assets in SEP-0011.
    ///
    /// See [Horizon API] (https://developers.stellar.org/api/horizon/reference/endpoints/accounts.html "Accounts")
    ///
    /// This fuction responds with a page of accounts. Pages represent a subset of a larger collection of objects. As an example, it would be unfeasible to provide the All Transactions endpoint without paging. Over time there will be millions of transactions in the Stellar network’s ledger and returning them all over a single request would be unfeasible.
    ///
    /// - Parameter signer: Optional. Account ID.
    /// - Parameter asset: Optional. An issued asset represented in coanolical form ("native" or "Code:IssuerAccountID").
    /// - Parameter sponsor: Optional. Account ID.
    /// - Parameter liquidityPoolId: Liquidity Pool ID
    /// - Parameter cursor: Optional. A paging token, specifying where to start returning records from.
    /// - Parameter order: Optional. The order in which to return rows, “asc” or “desc”, ordered by assetCode then by assetIssuer.
    /// - Parameter limit: Optional. Maximum number of records to return. Default: 10
    open func getAccounts(signer:String? = nil, asset:String? = nil, sponsor:String? = nil, liquidityPoolId:String? = nil, cursor:String? = nil, order:Order? = nil, limit:Int? = nil) async -> PageResponse<AccountResponse>.ResponseEnum {
        var requestPath = "/accounts"
        
        var params = Dictionary<String,String>()
        params["signer"] = signer
        params["asset"] = asset
        params["sponsor"] = sponsor
        var lidHex = liquidityPoolId
        if liquidityPoolId != nil && liquidityPoolId!.hasPrefix("L"),
            let id = try? liquidityPoolId!.decodeLiquidityPoolIdToHex() {
            lidHex = id
        }
        params["liquidity_pool"] = lidHex
        params["cursor"] = cursor
        params["order"] = order?.rawValue
        if let limit = limit { params["limit"] = String(limit) }
        
        if let pathParams = params.stringFromHttpParameters(),
           pathParams.count > 0 {
            requestPath += "?\(pathParams)"
        }
        
        return await getAccountsFromUrl(url: serviceHelper.requestUrlWithPath(path: requestPath))
    }
    
    /// Loads accounts for a given url if valid. E.g. for a "next" link from a PageResponse<AccountResponse> object.
    ///
    /// - Parameter url: The url to be used to load the accounts.
    ///
    @available(*, renamed: "getAccountsFromUrl(url:)")
    open func getAccountsFromUrl(url:String, response:@escaping PageResponse<AccountResponse>.ResponseClosure) {
        Task {
            let result = await getAccountsFromUrl(url: url)
            response(result)
        }
    }
    
    /// Loads accounts for a given url if valid. E.g. for a "next" link from a PageResponse<AccountResponse> object.
    ///
    /// - Parameter url: The url to be used to load the accounts.
    ///
    open func getAccountsFromUrl(url:String) async -> PageResponse<AccountResponse>.ResponseEnum {
        let result = await serviceHelper.GETRequestFromUrl(url: url)
        switch result {
        case .success(let data):
            do {
                let accounts = try self.jsonDecoder.decode(PageResponse<AccountResponse>.self, from: data)
                return .success(page: accounts)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
        case .failure(let error):
            return .failure(error:error)
        }
    }
}
