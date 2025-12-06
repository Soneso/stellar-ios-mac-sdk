//
//  QuoteService.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 20.02.24.
//  Copyright © 2024 Soneso. All rights reserved.
//

import Foundation

/// Result enum for SEP-38 info endpoint requests.
public enum Sep38InfoResponseEnum {
    /// Successfully retrieved supported assets and delivery methods.
    case success(response: Sep38InfoResponse)
    /// Request failed with quote service error.
    case failure(error: QuoteServiceError)
}

/// Result enum for SEP-38 prices endpoint requests.
public enum Sep38PricesResponseEnum {
    /// Successfully retrieved indicative prices for multiple assets.
    case success(response: Sep38PricesResponse)
    /// Request failed with quote service error.
    case failure(error: QuoteServiceError)
}

/// Result enum for SEP-38 price endpoint requests.
public enum Sep38PriceResponseEnum {
    /// Successfully retrieved indicative price for asset exchange.
    case success(response: Sep38PriceResponse)
    /// Request failed with quote service error.
    case failure(error: QuoteServiceError)
}

/// Result enum for SEP-38 quote requests (create and retrieve).
public enum Sep38QuoteResponseEnum {
    /// Successfully created or retrieved firm quote.
    case success(response: Sep38QuoteResponse)
    /// Request failed with quote service error.
    case failure(error: QuoteServiceError)
}

/// Implements SEP-0038 - Anchor RFQ (Request for Quote) API.
///
/// This class provides price discovery and firm quotes for asset exchanges. Anchors use this
/// to offer indicative and firm exchange rates for converting between on-chain and off-chain assets.
/// Essential for cross-asset deposit/withdrawal operations.
///
/// ## Typical Usage
///
/// ```swift
/// let service = QuoteService(serviceAddress: "https://anchor.example.com")
///
/// // Get indicative price
/// let priceResult = await service.price(
///     context: "sep6",
///     sellAsset: "iso4217:USD",
///     buyAsset: "stellar:USDC:G...",
///     sellAmount: "100",
///     jwt: jwtToken
/// )
///
/// // Request firm quote
/// let quoteRequest = Sep38PostQuoteRequest(
///     context: "sep6",
///     sellAsset: "iso4217:USD",
///     buyAsset: "stellar:USDC:G...",
///     sellAmount: "100"
/// )
/// let quoteResult = await service.postQuote(request: quoteRequest, jwt: jwtToken)
///
/// // Use quote in SEP-6 deposit-exchange
/// if case .success(let quote) = quoteResult {
///     let depositRequest = DepositExchangeRequest(
///         destinationAsset: quote.buyAsset,
///         sourceAsset: quote.sellAsset,
///         amount: quote.sellAmount,
///         quoteId: quote.id,
///         account: accountId,
///         jwt: jwtToken
///     )
///     // Submit to TransferServerService
/// }
/// ```
///
/// See also:
/// - [SEP-0038 Specification](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0038.md)
/// - [TransferServerService] for SEP-6 integration
/// - [InteractiveService] for SEP-24 integration
public class QuoteService: NSObject {

    /// The base URL of the SEP-38 quote service endpoint for price discovery and firm quotes.
    public var serviceAddress: String
    private let serviceHelper: ServiceHelper
    private let jsonDecoder = JSONDecoder()

    /// Creates a QuoteService instance with a direct service endpoint URL.
    ///
    /// - Parameter serviceAddress: The URL of the SEP-38 quote server (e.g., "https://anchor.example.com/sep38")
    public init(serviceAddress:String) {
        self.serviceAddress = serviceAddress
        serviceHelper = ServiceHelper(baseURL: serviceAddress)
        jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
    }
    
    /// Returns the supported Stellar assets and off-chain assets available for trading.
    ///
    /// - Parameter jwt: Optional JWT token obtained from SEP-10 authentication
    /// - Returns: Sep38InfoResponseEnum with supported assets and delivery methods, or an error
    ///
    /// See: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0038.md#get-info
    public func info(jwt:String? = nil) async -> Sep38InfoResponseEnum {
        
        let result = await serviceHelper.GETRequestWithPath(path: "/info", jwtToken: jwt)
        switch result {
        case .success(let data):
            do {
                let response = try self.jsonDecoder.decode(Sep38InfoResponse.self, from: data)
                return .success(response:response)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
        case .failure(let error):
            return .failure(error: self.errorFor(horizonError: error))
        }
    }
    
    /// Fetches indicative prices of available off-chain assets in exchange for a Stellar asset and vice versa.
    ///
    /// - Parameter sellAsset: The asset you want to sell, using the Asset Identification Format (e.g., "stellar:USDC:G...", "iso4217:USD")
    /// - Parameter sellAmount: The amount of sell_asset the client would exchange for each of the buy_assets
    /// - Parameter sellDeliveryMethod: Optional, one of the name values specified by the sell_delivery_methods array for the associated asset returned from GET /info. Can be provided if the user is delivering an off-chain asset to the anchor but is not strictly required.
    /// - Parameter buyDeliveryMethod: Optional, one of the name values specified by the buy_delivery_methods array for the associated asset returned from GET /info. Can be provided if the user intends to receive an off-chain asset from the anchor but is not strictly required.
    /// - Parameter countryCode: Optional, the ISO 3166-2 or ISO-3166-1 alpha-2 code of the user's current address. Should be provided if there are two or more country codes available for the desired asset in GET /info.
    /// - Parameter jwt: Optional JWT token obtained from SEP-10 authentication
    /// - Returns: Sep38PricesResponseEnum with indicative prices for available assets, or an error
    ///
    /// See: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0038.md#get-prices
    public func prices(sellAsset:String,
                       sellAmount:String,
                       sellDeliveryMethod:String? = nil,
                       buyDeliveryMethod:String? = nil,
                       countryCode:String? = nil,
                       jwt:String? = nil) async -> Sep38PricesResponseEnum {
        
        var requestPath = "/prices?sell_asset=\(sellAsset)&sell_amount=\(sellAmount)"
        if let value = sellDeliveryMethod {
            requestPath += "&sell_delivery_method=\(value)"
        }
        if let value = buyDeliveryMethod {
            requestPath += "&buy_delivery_method=\(value)"
        }
        if let value = countryCode {
            requestPath += "&country_code=\(value)"
        }
        
        let result = await serviceHelper.GETRequestWithPath(path: requestPath, jwtToken: jwt)
        switch result {
        case .success(let data):
            do {
                let response = try self.jsonDecoder.decode(Sep38PricesResponse.self, from: data)
                return .success(response:response)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
        case .failure(let error):
            return .failure(error: self.errorFor(horizonError: error))
        }
    }
    
    /// Fetches the indicative price for a given asset pair.
    ///
    /// The caller must provide either sellAmount or buyAmount, but not both.
    ///
    /// - Parameter context: The context for what this quote will be used for. Must be one of "sep6" or "sep31".
    /// - Parameter sellAsset: The asset the client would like to sell (e.g., "stellar:USDC:G...", "iso4217:ARS")
    /// - Parameter buyAsset: The asset the client would like to exchange for sellAsset
    /// - Parameter sellAmount: Optional, the amount of sellAsset the client would like to exchange for buyAsset
    /// - Parameter buyAmount: Optional, the amount of buyAsset the client would like to exchange for sellAsset
    /// - Parameter sellDeliveryMethod: Optional, one of the name values specified by the sell_delivery_methods array for the associated asset returned from GET /info. Can be provided if the user is delivering an off-chain asset to the anchor but is not strictly required.
    /// - Parameter buyDeliveryMethod: Optional, one of the name values specified by the buy_delivery_methods array for the associated asset returned from GET /info. Can be provided if the user intends to receive an off-chain asset from the anchor but is not strictly required.
    /// - Parameter countryCode: Optional, the ISO 3166-2 or ISO-3166-1 alpha-2 code of the user's current address. Should be provided if there are two or more country codes available for the desired asset in GET /info.
    /// - Parameter jwt: Optional JWT token obtained from SEP-10 authentication
    /// - Returns: Sep38PriceResponseEnum with indicative exchange rate, or an error
    ///
    /// See: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0038.md#get-price
    public func price(context:String,
                      sellAsset:String,
                      buyAsset:String,
                      sellAmount:String? = nil,
                      buyAmount:String? = nil, 
                      sellDeliveryMethod:String? = nil,
                      buyDeliveryMethod:String? = nil,
                      countryCode:String? = nil,
                      jwt:String? = nil) async -> Sep38PriceResponseEnum {
        
        // The caller must provide either sellAmount or buyAmount, but not both.
        if ((sellAmount != nil && buyAmount != nil) || (sellAmount == nil && buyAmount == nil)) {
            return .failure(error: .invalidArgument(message: "The caller must provide either sellAmount or buyAmount, but not both"))
        }
        
        var requestPath = "/price?sell_asset=\(sellAsset)&buy_asset=\(buyAsset)&context=\(context)"
        if let value = sellAmount {
            requestPath += "&sell_amount=\(value)"
        }
        if let value = buyAmount {
            requestPath += "&buy_amount=\(value)"
        }
        if let value = sellDeliveryMethod {
            requestPath += "&sell_delivery_method=\(value)"
        }
        if let value = buyDeliveryMethod {
            requestPath += "&buy_delivery_method=\(value)"
        }
        if let value = countryCode {
            requestPath += "&country_code=\(value)"
        }
        
        let result = await serviceHelper.GETRequestWithPath(path: requestPath, jwtToken: jwt)
        switch result {
        case .success(let data):
            do {
                let response = try self.jsonDecoder.decode(Sep38PriceResponse.self, from: data)
                return .success(response:response)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
        case .failure(let error):
            return .failure(error: self.errorFor(horizonError: error))
        }
    }
    
    /// Requests a firm quote for a Stellar asset and off-chain asset pair.
    ///
    /// Unlike indicative prices, firm quotes are guaranteed by the anchor for a limited time.
    /// The returned quote ID can be used in SEP-6 or SEP-31 transactions.
    ///
    /// - Parameter request: Sep38PostQuoteRequest containing asset pair and amount details
    /// - Parameter jwt: JWT token obtained from SEP-10 authentication (required)
    /// - Returns: Sep38QuoteResponseEnum with firm quote details including expiration, or an error
    ///
    /// See: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0038.md#post-quote
    public func postQuote(request: Sep38PostQuoteRequest, jwt:String) async -> Sep38QuoteResponseEnum {
        
        // The caller must provide either sellAmount or buyAmount, but not both.
        if ((request.sellAmount != nil && request.buyAmount != nil) ||
            (request.sellAmount == nil && request.buyAmount == nil)) {
            return .failure(error: .invalidArgument(message: "The caller must provide either sellAmount or buyAmount, but not both"))
        }
        
        let requestData = try! JSONSerialization.data(withJSONObject: request.toJson())
        let result = await serviceHelper.POSTRequestWithPath(path: "/quote", jwtToken: jwt, body: requestData, contentType: "application/json")
        switch result {
        case .success(let data):
            do {
                let response = try self.jsonDecoder.decode(Sep38QuoteResponse.self, from: data)
                return .success(response:response)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
        case .failure(let error):
            return .failure(error: self.errorFor(horizonError: error))
        }
    }
    
    /// Fetches a previously-provided firm quote by ID.
    ///
    /// Use this to retrieve quote details or check if a quote is still valid before using it.
    ///
    /// - Parameter id: The quote ID returned from postQuote
    /// - Parameter jwt: Optional JWT token obtained from SEP-10 authentication
    /// - Returns: Sep38QuoteResponseEnum with quote details, or an error
    ///
    /// See: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0038.md#get-quote
    public func getQuote(id:String, jwt:String? = nil) async -> Sep38QuoteResponseEnum {
        
        let requestPath = "/quote/\(id)"
        
        let result = await serviceHelper.GETRequestWithPath(path: requestPath, jwtToken: jwt)
        switch result {
        case .success(let data):
            do {
                let response = try self.jsonDecoder.decode(Sep38QuoteResponse.self, from: data)
                return .success(response:response)
            } catch {
                return .failure(error: .parsingResponseFailed(message: error.localizedDescription))
            }
        case .failure(let error):
            return .failure(error: self.errorFor(horizonError: error))
        }
    }
    
    private func errorFor(horizonError:HorizonRequestError) -> QuoteServiceError {
        switch horizonError {
        case .badRequest(let message, _):
            return .badRequest(message: extractErrorMessage(message: message))
        case .forbidden(let message, _):
            return .permissionDenied(message: extractErrorMessage(message: message))
        case .notFound(let message, _):
            return .notFound(message: extractErrorMessage(message: message))
        default:
            return .horizonError(error: horizonError)
        }
    }
    
    private func extractErrorMessage(message:String) -> String {
        if let data = message.data(using: .utf8) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any], let error = json["error"] as? String {
                    return error
                }
            } catch {
                return message
            }
        }
        return message
    }
}
