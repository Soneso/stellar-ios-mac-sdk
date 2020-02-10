//
//  PathPaymentService.swift
//  stellarsdk
//
//  Created by Istvan Elekes on 2/14/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum PaymentPathsResponseEnum {
    case success(details: FindPaymentPathsResponse)
    case failure(error: HorizonRequestError)
}

/// A closure to be called with the response from a payment path request
public typealias FindPaymentPathsResponseClosure = (_ response:PaymentPathsResponseEnum) -> (Void)

public class PaymentPathsService: NSObject {
    let serviceHelper: ServiceHelper
    let jsonDecoder = JSONDecoder()
    
    private override init() {
        serviceHelper = ServiceHelper(baseURL: "")
    }
    
    init(baseURL: String) {
        serviceHelper = ServiceHelper(baseURL: baseURL)
    }
    
    open func findPaymentPaths(destinationAccount:String, destinationAssetType:String, destinationAssetCode:String? = nil, destinationAssetIssuer:String? = nil, destinationAmount:String, sourceAccount:String, response:@escaping FindPaymentPathsResponseClosure) {
        
        var requestPath = "/paths"
        var params = Dictionary<String,String>()
        params["destination_account"] = destinationAccount
        params["destination_asset_type"] = destinationAssetType
        params["destination_asset_code"] = destinationAssetCode
        params["destination_asset_issuer"] = destinationAssetIssuer
        params["destination_amount"] = destinationAmount
        params["source_account"] = sourceAccount
        
        if let pathParams = params.stringFromHttpParameters(),
            pathParams.count > 0 {
            requestPath += "?\(pathParams)"
        }
        
        findPaymentPathsFrom(url:serviceHelper.baseURL + requestPath, response:response)
    }
    
    /// The Stellar Network allows payments to be made across assets through path payments. A path payment specifies a series of assets to route a payment through, from source asset (the asset debited from the payer) to destination asset (the asset credited to the payee).
    /// See [Horizon API] (https://www.stellar.org/developers/horizon/reference/endpoints/path-finding-strict-receive.html "Strict receive payment path")
    ///
    /// A strict receive path search is specified using:
    /// - The source account id or source assets.
    /// - The asset and amount that the destination account should receive.
    ///
    /// As part of the search, horizon will load a list of assets available to the source account id and will find any payment paths from those source assets to the desired destination asset. The search’s amount parameter will be used to determine if a given path can satisfy a payment of the desired amount.
    /// 
    /// - Parameter sourceAccount: optional. The sender’s account id. Any returned path must use an asset that the sender has a trustline to.
    /// - Parameter sourceAssets: optional. A comma separated list of assets. Any returned path must use an asset included in this list. e.g. "USD:GAEDTJ4PPEFVW5XV2S7LUXBEHNQMX5Q2GM562RJGOQG7GVCE5H3HIB4V,native"
    /// - Parameter destinationAccount: optional. The destination account that any returned path should use.
    /// - Parameter destinationAssetType: optional The type of the destination asset e.g. "native", "credit_alphanum4" or "credit_alphanum12"
    /// - Parameter destinationAssetCode: required if destinationAssetType is not native. e.g. "USD"
    /// - Parameter destinationAssetIssuer: required if destination_asset_type is not native
    /// - Parameter destinationAmount: The amount, denominated in the destination asset, that any returned path should be able to satisfy
    ///
    /// The endpoint will not allow requests which provide both a source_account and a source_assets parameter. All requests must provide one or the other. The assets in source_assets are expected to be encoded using the following format:
    ///
    /// XLM should be represented as "native". Issued assets should be represented as "Code:IssuerAccountID". "Code" must consist of alphanumeric ASCII characters.
    /// This endpoint responds with a page of path resources
    open func strictReceive(sourceAccount:String? = nil, sourceAssets:String? = nil, destinationAccount:String? = nil, destinationAssetType:String? = nil, destinationAssetCode:String? = nil, destinationAssetIssuer:String? = nil, destinationAmount:String? = nil, response:@escaping FindPaymentPathsResponseClosure) {
        
        var requestPath = "/paths/strict-receive"
        var params = Dictionary<String,String>()
        params["source_account"] = sourceAccount
        params["source_assets"] = sourceAssets
        params["destination_account"] = destinationAccount
        params["destination_asset_type"] = destinationAssetType
        params["destination_asset_code"] = destinationAssetCode
        params["destination_asset_issuer"] = destinationAssetIssuer
        params["destination_amount"] = destinationAmount
        
        
        if let pathParams = params.stringFromHttpParameters(),
            pathParams.count > 0 {
            requestPath += "?\(pathParams)"
        }
        
        findPaymentPathsFrom(url:serviceHelper.baseURL + requestPath, response:response)
    }
    
    /// The Stellar Network allows payments to be made across assets through path payments. A path payment specifies a series of assets to route a payment through, from source asset (the asset debited from the payer) to destination asset (the asset credited to the payee).
    /// See [Horizon API] (https://www.stellar.org/developers/horizon/reference/endpoints/path-finding-strict-send.html "Strict send payment path")
    ///
    /// A Path Payment Strict Send allows a user to specify the amount of the asset to send. The amount received will vary based on offers in the order books.
    /// A path payment strict send search is specified using:
    /// - The destination account id or destination assets.
    /// - The source asset.
    /// - The source amount.
    ///
    /// As part of the search, horizon will load a list of assets available to the source account id or use the assets passed in the request and will find any payment paths from those source assets to the desired destination asset. The source’s amount parameter will be used to determine if a given path can satisfy a payment of the desired amount.
    ///
    /// - Parameter sourceAmount: optional. The amount, denominated in the source asset, that any returned path should be able to satisfy.
    /// - Parameter sourceAssetType: optional The type of the source asset e.g. "native", "credit_alphanum4" or "credit_alphanum12"
    /// - Parameter sourceAssetCode: required if sourceAssetType is not native. e.g. "USD"
    /// - Parameter sourceAssetIssuer: required if sourceAssetType is not native
    /// - Parameter destinationAccount: optional. The destination account that any returned path should use.
    /// - Parameter destinationAssests: optional. A comma separated list of assets. Any returned path must use an asset included in this list. e.g. "USD:GAEDTJ4PPEFVW5XV2S7LUXBEHNQMX5Q2GM562RJGOQG7GVCE5H3HIB4V,native"
    ///
    /// The endpoint will not allow requests which provide both a destination_account and destination_assets parameter. All requests must provide one or the other. The assets in destination_assets are expected to be encoded using the following format:
    
    /// XLM should be represented as "native". Issued assets should be represented as "Code:IssuerAccountID". "Code" must consist of alphanumeric ASCII characters.
    ///
    /// This endpoint responds with a page of path resources
    open func strictSend(sourceAmount:String? = nil, sourceAssetType:String? = nil, sourceAssetCode:String? = nil, sourceAssetIssuer:String? = nil, destinationAccount:String? = nil, destinationAssets:String? = nil, response:@escaping FindPaymentPathsResponseClosure) {
        
        var requestPath = "/paths/strict-send"
        var params = Dictionary<String,String>()
        params["source_amount"] = sourceAmount
        params["source_asset_type"] = sourceAssetType
        params["source_asset_code"] = sourceAssetCode
        params["source_asset_issuer"] = sourceAssetIssuer
        params["destination_account"] = destinationAccount
        params["destination_assets"] = destinationAssets
        
        
        if let pathParams = params.stringFromHttpParameters(),
            pathParams.count > 0 {
            requestPath += "?\(pathParams)"
        }
        
        findPaymentPathsFrom(url:serviceHelper.baseURL + requestPath, response:response)
    }
    
    func findPaymentPathsFrom(url:String, response:@escaping FindPaymentPathsResponseClosure) {
        serviceHelper.GETRequestFromUrl(url: url) { (result) -> (Void) in
            switch result {
            case .success(let data):
                do {
                    let findPaymentPaths = try self.jsonDecoder.decode(FindPaymentPathsResponse.self, from: data)
                    response(.success(details: findPaymentPaths))
                } catch {
                    response(.failure(error: .parsingResponseFailed(message: error.localizedDescription)))
                }
            case .failure(let error):
                response(.failure(error:error))
            }
        }
    }
}
