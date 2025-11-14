//
//  AccountService.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 29/01/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Result enum for account details requests.
public enum AccountResponseEnum {
    /// Successfully retrieved account details from Horizon
    case success(details: AccountResponse)
    /// Failed to retrieve account details, contains error information
    case failure(error: HorizonRequestError)
}

/// Result enum for account data field requests.
public enum DataForAccountResponseEnum {
    /// Successfully retrieved account data field value
    case success(details: DataForAccountResponse)
    /// Failed to retrieve account data field, contains error information
    case failure(error: HorizonRequestError)
}

/// Result enum for test account creation requests.
public enum CreateTestAccountResponseEnum {
    /// Successfully created and funded test account via Friendbot
    case success(details: Any)
    /// Failed to create test account, contains error information
    case failure(error: HorizonRequestError)
}

/// A closure to be called with the response from a create test account request.
public typealias CreateTestAccountClosure = (_ response:CreateTestAccountResponseEnum) -> (Void)
/// A closure to be called with the response from an account details request.
public typealias AccountResponseClosure = (_ response:AccountResponseEnum) -> (Void)
/// A closure to be called with the response from a data for account request.
public typealias DataForAccountResponseClosure = (_ response:DataForAccountResponseEnum) -> (Void)

/// Service for querying account information from the Stellar Horizon API.
///
/// The AccountService provides methods to retrieve account details, query account data fields,
/// filter accounts by various criteria, and create test accounts on testnet and futurenet.
///
/// Example usage:
/// ```swift
/// let sdk = StellarSDK()
///
/// // Get account details
/// let accountResponse = await sdk.accounts.getAccountDetails(accountId: "GACCOUNT...")
/// switch accountResponse {
/// case .success(let account):
///     print("Sequence: \(account.sequenceNumber)")
///     print("Balances: \(account.balances)")
/// case .failure(let error):
///     print("Error: \(error)")
/// }
///
/// // Query accounts holding a specific asset
/// let assetAccounts = await sdk.accounts.getAccounts(
///     asset: "USD:GISSUER...",
///     limit: 20
/// )
/// ```
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
/// - AccountResponse for the account data structure
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
    /// See [Stellar developer docs](https://developers.stellar.org)
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
    
    /// Retrieves detailed information about a single Stellar account.
    ///
    /// Returns account data including balances, signers, thresholds, flags, sequence number,
    /// and other account properties. Supports both regular accounts (G-addresses) and
    /// muxed accounts (M-addresses).
    ///
    /// - Parameter accountId: The Stellar account ID (public key). Accepts G-addresses for regular
    ///                        accounts or M-addresses for muxed accounts. For muxed accounts, the
    ///                        underlying ed25519 account is queried automatically.
    ///
    /// - Returns: AccountResponseEnum with account details on success or error on failure
    ///
    /// Example:
    /// ```swift
    /// let response = await sdk.accounts.getAccountDetails(accountId: "GACCOUNT...")
    /// switch response {
    /// case .success(let account):
    ///     print("Sequence: \(account.sequenceNumber)")
    ///     for balance in account.balances {
    ///         print("\(balance.assetCode): \(balance.balance)")
    ///     }
    /// case .failure(let error):
    ///     print("Error: \(error)")
    /// }
    /// ```
    ///
    /// See also:
    /// - [Stellar developer docs](https://developers.stellar.org)
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
    /// See [Stellar developer docs](https://developers.stellar.org)
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
    
    /// Retrieves a specific data entry from an account's key-value store.
    ///
    /// Each Stellar account can store arbitrary key-value pairs using the ManageDataOperation.
    /// This method retrieves the base64-encoded value for a given key. Returns 404 if the
    /// account doesn't exist or the key is not found.
    ///
    /// - Parameters:
    ///   - accountId: The Stellar account ID containing the data entry
    ///   - key: The name of the data field to retrieve
    ///
    /// - Returns: DataForAccountResponseEnum with the base64-encoded value on success or error on failure
    ///
    /// Example:
    /// ```swift
    /// let response = await sdk.accounts.getDataForAccount(
    ///     accountId: "GACCOUNT...",
    ///     key: "user_email"
    /// )
    /// switch response {
    /// case .success(let data):
    ///     // Decode base64 value
    ///     if let decoded = Data(base64Encoded: data.value) {
    ///         print("Value: \(String(data: decoded, encoding: .utf8) ?? "")")
    ///     }
    /// case .failure(let error):
    ///     print("Error: \(error)")
    /// }
    /// ```
    ///
    /// See also:
    /// - [Stellar developer docs](https://developers.stellar.org)
    /// - ManageDataOperation for setting account data
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
    
    /// Creates and funds a test account on Stellar's testnet using Friendbot.
    ///
    /// Friendbot is a service that creates and funds new accounts on testnet with 10,000 XLM.
    /// This is useful for testing and development. Only works on testnet, not on the public network.
    ///
    /// - Parameter accountId: A Stellar account ID (public key starting with G). Generate using
    ///                        KeyPair.generateRandomKeyPair().accountId
    ///
    /// - Returns: CreateTestAccountResponseEnum with success or error
    ///
    /// Example:
    /// ```swift
    /// // Generate a new keypair
    /// let keyPair = try KeyPair.generateRandomKeyPair()
    /// let accountId = keyPair.accountId
    ///
    /// // Create and fund the account on testnet
    /// let response = await sdk.accounts.createTestAccount(accountId: accountId)
    /// switch response {
    /// case .success:
    ///     print("Test account created: \(accountId)")
    /// case .failure(let error):
    ///     print("Error: \(error)")
    /// }
    /// ```
    ///
    /// See also:
    /// - createFutureNetTestAccount for creating accounts on futurenet
    /// - [Stellar developer docs](https://developers.stellar.org)
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
    
    /// Creates and funds a test account on Stellar's futurenet using Friendbot.
    ///
    /// Futurenet is used for testing upcoming protocol features before they reach testnet.
    /// This method creates and funds new accounts on futurenet for early testing.
    ///
    /// - Parameter accountId: A Stellar account ID (public key starting with G). Generate using
    ///                        KeyPair.generateRandomKeyPair().accountId
    ///
    /// - Returns: CreateTestAccountResponseEnum with success or error
    ///
    /// Example:
    /// ```swift
    /// let keyPair = try KeyPair.generateRandomKeyPair()
    /// let response = await sdk.accounts.createFutureNetTestAccount(accountId: keyPair.accountId)
    /// switch response {
    /// case .success:
    ///     print("Futurenet account created")
    /// case .failure(let error):
    ///     print("Error: \(error)")
    /// }
    /// ```
    ///
    /// See also:
    /// - createTestAccount for creating accounts on testnet
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
    /// See [Stellar developer docs](https://developers.stellar.org)
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
    
    /// Queries accounts with optional filtering by signer, asset, sponsor, or liquidity pool.
    ///
    /// This endpoint allows you to search for accounts that match specific criteria. All filter
    /// parameters are optional - use them individually or in combination to narrow your search.
    /// Results are returned as a paginated list.
    ///
    /// - Parameters:
    ///   - signer: Filter accounts that have this account as a signer
    ///   - asset: Filter accounts with trustlines to this asset. Use canonical form "CODE:ISSUER"
    ///            (e.g., "USD:GISSUER...") or "native" for XLM. See SEP-0011 for asset representation.
    ///   - sponsor: Filter accounts sponsored by this account ID
    ///   - liquidityPoolId: Filter accounts participating in this liquidity pool (L-address or hex)
    ///   - cursor: Pagination cursor to start from. Use nil to start from the beginning.
    ///   - order: Sort order - .ascending or .descending. Default is ascending.
    ///   - limit: Maximum number of records per page. Default is 10, maximum is 200.
    ///
    /// - Returns: PageResponse containing matching accounts or error
    ///
    /// Example:
    /// ```swift
    /// // Find accounts holding a specific asset
    /// let response = await sdk.accounts.getAccounts(
    ///     asset: "USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN",
    ///     limit: 50
    /// )
    /// switch response {
    /// case .success(let page):
    ///     for account in page.records {
    ///         print("Account: \(account.accountId)")
    ///     }
    ///     // Load next page if available
    ///     if page.hasNextPage() {
    ///         let nextPage = await page.getNextPage()
    ///     }
    /// case .failure(let error):
    ///     print("Error: \(error)")
    /// }
    ///
    /// // Find accounts with a specific signer
    /// let signerAccounts = await sdk.accounts.getAccounts(
    ///     signer: "GSIGNER...",
    ///     order: .descending
    /// )
    /// ```
    ///
    /// See also:
    /// - [Stellar developer docs](https://developers.stellar.org)
    /// - PageResponse for pagination methods
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
    
    /// Loads accounts from a specific URL.
    ///
    /// Used internally for pagination. Can be called directly with URLs from PageResponse
    /// links (e.g., next, prev) to navigate paginated results.
    ///
    /// - Parameter url: The complete URL to fetch accounts from. Typically obtained from
    ///                  PageResponse.links.next.href or PageResponse.links.prev.href
    ///
    /// - Returns: PageResponse containing accounts or error
    ///
    /// Example:
    /// ```swift
    /// // Manual pagination using URL
    /// if let nextUrl = accountsPage.links.next?.href {
    ///     let nextPage = await sdk.accounts.getAccountsFromUrl(url: nextUrl)
    /// }
    /// ```
    ///
    /// See also:
    /// - PageResponse.getNextPage for automatic pagination
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
