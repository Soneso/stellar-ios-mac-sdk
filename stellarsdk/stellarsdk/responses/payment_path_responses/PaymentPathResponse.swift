//
//  PaymentPathResponse.swift
//  stellarsdk
//
//  Created by Istvan Elekes on 2/14/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  Represents a Payment Path response.
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/path.html "Payment Path")
public class PaymentPathResponse: NSObject, Decodable {
    
    /// An array of assets that represents the intermediary assets this path hops through
    public var path:[OfferAssetResponse]
    
    /// An estimated cost for making a payment of destination_amount on this path. Suitable for use in a path payments sendMax field
    public var sourceAmount:String
    
    /// The destination amount specified in the search that found this path
    public var destinationAmount:String
    
    /// The type for the destination asset specified in the search that found this path
    public var destinationAssetType:String
    
    /// The code for the destination asset specified in the search that found this path
    public var destinationAssetCode:String?
    
    /// The issuer for the destination asset specified in the search that found this path
    public var destinationAssetIssuer:String?
    
    /// The type for the source asset specified in the search that found this path
    public var sourceAssetType:String
    
    /// The code for the source asset specified in the search that found this path
    public var sourceAssetCode:String?
    
    /// The issuer for the source asset specified in the search that found this path
    public var sourceAssetIssuer:String?
    
    private enum CodingKeys: String, CodingKey {
        
        case path
        case sourceAmount = "source_amount"
        case destinationAmount = "destination_amount"
        case destinationAssetType = "destination_asset_type"
        case destinationAssetCode = "destination_asset_code"
        case destinationAssetIssuer = "destination_asset_issuer"
        case sourceAssetType = "source_asset_type"
        case sourceAssetCode = "source_asset_code"
        case sourceAssetIssuer = "source_asset_issuer"
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        path = try values.decode(Array.self, forKey: .path)
        sourceAmount = try values.decode(String.self, forKey: .sourceAmount)
        destinationAmount = try values.decode(String.self, forKey: .destinationAmount)
        destinationAssetType = try values.decode(String.self, forKey: .destinationAssetType)
        destinationAssetCode = try values.decodeIfPresent(String.self, forKey: .destinationAssetCode)
        destinationAssetIssuer = try values.decodeIfPresent(String.self, forKey: .destinationAssetIssuer)
        sourceAssetType = try values.decode(String.self, forKey: .sourceAssetType)
        sourceAssetCode = try values.decodeIfPresent(String.self, forKey: .sourceAssetCode)
        sourceAssetIssuer = try values.decodeIfPresent(String.self, forKey: .sourceAssetIssuer)
    }
}
