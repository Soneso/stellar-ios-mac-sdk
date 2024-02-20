//
//  QuoteService.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 20.02.24.
//  Copyright © 2024 Soneso. All rights reserved.
//

import Foundation

public enum Sep38InfoResponseEnum {
    case success(response: Sep38InfoResponse)
    case failure(error: QuoteServiceError)
}

public enum Sep38PricesResponseEnum {
    case success(response: Sep38PricesResponse)
    case failure(error: QuoteServiceError)
}

public enum Sep38PriceResponseEnum {
    case success(response: Sep38PriceResponse)
    case failure(error: QuoteServiceError)
}

public enum Sep38QuoteResponseEnum {
    case success(response: Sep38QuoteResponse)
    case failure(error: QuoteServiceError)
}

public typealias Sep38InfoResponseClosure = (_ response:Sep38InfoResponseEnum) -> (Void)
public typealias Sep38PricesResponseClosure = (_ response:Sep38PricesResponseEnum) -> (Void)
public typealias Sep38PriceResponseClosure = (_ response:Sep38PriceResponseEnum) -> (Void)
public typealias Sep38QuoteResponseClosure = (_ response:Sep38QuoteResponseEnum) -> (Void)


/**
 Implements SEP-0038 - Anchor RFQ API
 See <https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0038.md" target="_blank">Anchor RFQ API.</a>
 */
public class QuoteService: NSObject {

    public var serviceAddress: String
    private let serviceHelper: ServiceHelper
    private let jsonDecoder = JSONDecoder()
    
    public init(serviceAddress:String) {
        self.serviceAddress = serviceAddress
        serviceHelper = ServiceHelper(baseURL: serviceAddress)
        jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
    }
    
    /**
     This endpoint returns the supported Stellar assets and off-chain assets available for trading.
     See: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0038.md#get-info
     - Parameter jwt: optional jwt token obtained before with SEP-0010.
     */
    public func info(jwt:String? = nil, completion:@escaping Sep38InfoResponseClosure) {
        
        serviceHelper.GETRequestWithPath(path: "/info", jwtToken: jwt) { (result) -> (Void) in
            switch result {
            case .success(let data):
                do {
                    let response = try self.jsonDecoder.decode(Sep38InfoResponse.self, from: data)
                    completion(.success(response:response))
                } catch {
                    completion(.failure(error: .parsingResponseFailed(message: error.localizedDescription)))
                }
            case .failure(let error):
                completion(.failure(error: self.errorFor(horizonError: error)))
            }
        }
    }
    
    /**
     This endpoint can be used to fetch the indicative prices of available off-chain assets in exchange for a Stellar asset and vice versa.
     See <https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0038.md#get-prices" target="_blank">GET prices</a>
     
     - Parameter sellAsset: The asset you want to sell, using the Asset Identification Format.
     - Parameter sellAmount: The amount of sell_asset the client would exchange for each of the buy_assets.
     - Parameter sellDeliveryMethod: Optional, one of the name values specified by the sell_delivery_methods array for the associated asset returned from GET /info. Can be provided if the user is delivering an off-chain asset to the anchor but is not strictly required.
     - Parameter buyDeliveryMethod: Optional, one of the name values specified by the buy_delivery_methods array for the associated asset returned from GET /info. Can be provided if the user intends to receive an off-chain asset from the anchor but is not strictly required.
     - Parameter countryCode: Optional, The ISO 3166-2 or ISO-3166-1 alpha-2 code of the user's current address. Should be provided if there are two or more country codes available for the desired asset in GET /info.
     - Parameter jwt: optional jwt token obtained before with SEP-0010.
     */
    public func prices(sellAsset:String,
                       sellAmount:String,
                       sellDeliveryMethod:String? = nil,
                       buyDeliveryMethod:String? = nil,
                       countryCode:String? = nil,
                       jwt:String? = nil,
                       completion:@escaping Sep38PricesResponseClosure) {
        
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
        
        serviceHelper.GETRequestWithPath(path: requestPath, jwtToken: jwt) { (result) -> (Void) in
            switch result {
            case .success(let data):
                do {
                    let response = try self.jsonDecoder.decode(Sep38PricesResponse.self, from: data)
                    completion(.success(response:response))
                } catch {
                    completion(.failure(error: .parsingResponseFailed(message: error.localizedDescription)))
                }
            case .failure(let error):
                completion(.failure(error: self.errorFor(horizonError: error)))
            }
        }
    }
    
    /**
     This endpoint can be used to fetch the indicative price for a given asset pair.
     See <https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0038.md#get-price" target="_blank">GET price</a>
     
     - Parameter context: The context for what this quote will be used for. Must be one of 'sep6' or 'sep31'.
     - Parameter sellAsset: The asset the client would like to sell. Ex. stellar:USDC:G..., iso4217:ARS
     - Parameter buyAsset: The asset the client would like to exchange for sellAsset.
     - Parameter sellAmount: optional, the amount of sellAsset the client would like to exchange for buyAsset.
     - Parameter buyAmount: optional, the amount of buyAsset the client would like to exchange for sellAsset.
     - Parameter sellDeliveryMethod: optional, one of the name values specified by the sell_delivery_methods array for the associated asset returned from GET /info. Can be provided if the user is delivering an off-chain asset to the anchor but is not strictly required.
     - Parameter buyDeliveryMethod: optional, one of the name values specified by the buy_delivery_methods array for the associated asset returned from GET /info. Can be provided if the user intends to receive an off-chain asset from the anchor but is not strictly required.
     - Parameter countryCode: optional, The ISO 3166-2 or ISO-3166-1 alpha-2 code of the user's current address. Should be provided if there are two or more country codes available for the desired asset in GET /info.
     - Parameter jwt: optional jwt token obtained before with SEP-0010.
     */
    public func price(context:String, 
                      sellAsset:String,
                      buyAsset:String,
                      sellAmount:String? = nil,
                      buyAmount:String? = nil, 
                      sellDeliveryMethod:String? = nil,
                      buyDeliveryMethod:String? = nil,
                      countryCode:String? = nil,
                      jwt:String? = nil,
                      completion:@escaping Sep38PriceResponseClosure) {
        
        // The caller must provide either sellAmount or buyAmount, but not both.
        if ((sellAmount != nil && buyAmount != nil) || (sellAmount == nil && buyAmount == nil)) {
            completion(.failure(error: .invalidArgument(message: "The caller must provide either sellAmount or buyAmount, but not both")))
            return
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
        
        serviceHelper.GETRequestWithPath(path: requestPath, jwtToken: jwt) { (result) -> (Void) in
            switch result {
            case .success(let data):
                do {
                    let response = try self.jsonDecoder.decode(Sep38PriceResponse.self, from: data)
                    completion(.success(response:response))
                } catch {
                    completion(.failure(error: .parsingResponseFailed(message: error.localizedDescription)))
                }
            case .failure(let error):
                completion(.failure(error: self.errorFor(horizonError: error)))
            }
        }
    }
    
    /**
     This endpoint can be used to request a firm quote for a Stellar asset and off-chain asset pair.
     See <https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0038.md#post-quote" target="_blank">POST quote</a>
     
     - Parameter request: the request data.
     - Parameter jwt: jwt token obtained before with SEP-0010.
     */
    public func postQuote(request: Sep38PostQuoteRequest, jwt:String, completion:@escaping Sep38QuoteResponseClosure) {
        
        // The caller must provide either sellAmount or buyAmount, but not both.
        if ((request.sellAmount != nil && request.buyAmount != nil) ||
            (request.sellAmount == nil && request.buyAmount == nil)) {
            completion(.failure(error: .invalidArgument(message: "The caller must provide either sellAmount or buyAmount, but not both")))
            return
        }
        
        let requestData = try! JSONSerialization.data(withJSONObject: request.toJson())
        serviceHelper.POSTRequestWithPath(path: "/quote", jwtToken: jwt, body: requestData, contentType: "application/json") { (result) -> (Void) in
            switch result {
            case .success(let data):
                do {
                    let response = try self.jsonDecoder.decode(Sep38QuoteResponse.self, from: data)
                    completion(.success(response:response))
                } catch {
                    completion(.failure(error: .parsingResponseFailed(message: error.localizedDescription)))
                }
            case .failure(let error):
                completion(.failure(error: self.errorFor(horizonError: error)))
            }
        }
    }
    
    /**
     This endpoint can be used to fetch a previously-provided firm quote by id.
     See <https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0038.md#get-quote" target="_blank">GET quote</a>
     
     - Parameter id: the id of the quote.
     - Parameter jwt: jwt token obtained before with SEP-0010.
     */
    public func getQuote(id:String, jwt:String? = nil, completion:@escaping Sep38QuoteResponseClosure) {
    
        let requestPath = "/quote/\(id)"
        
        serviceHelper.GETRequestWithPath(path: requestPath, jwtToken: jwt) { (result) -> (Void) in
            switch result {
            case .success(let data):
                do {
                    let response = try self.jsonDecoder.decode(Sep38QuoteResponse.self, from: data)
                    completion(.success(response:response))
                } catch {
                    completion(.failure(error: .parsingResponseFailed(message: error.localizedDescription)))
                }
            case .failure(let error):
                completion(.failure(error: self.errorFor(horizonError: error)))
            }
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
