//
//  TradeResponse.swift
//  stellarsdk
//
//  Created by Istvan Elekes on 2/8/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  Represents a trade response.
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/trade.html "Trade")
public class TradeResponse: NSObject, Decodable {
    
    /// A list of links related to this trade.
    public var links:TradeLinksResponse
    
    /// Unique identifier for this trade.
    public var id:String
    
    /// Paging token suitable for use as a cursor parameter.
    public var pagingToken:String
    
    /// An ISO 8601 formatted string of when the ledger with this trade was closed.
    public var ledgerCloseTime:Date
    
    /// base party of this trade
    public var baseAccount:String
    
    /// amount of base asset that was moved from base_account to counter_account
    public var baseAmount:String
    
    /// type of base asset
    public var baseAssetType:String
    
    /// code of base asset
    public var baseAssetCode:String?
    
    /// issuer of base asset
    public var baseAssetIssuer:String?
    
    /// counter party of this trade
    public var counterAccount:String
    
    /// amount of counter asset that was moved from counter_account to base_account
    public var counterAmount:String
    
    /// type of counter asset
    public var counterAssetType:String
    
    /// code of counter asset
    public var counterAssetCode:String?
    
    /// issuer of counter asset
    public var counterAssetIssuer:String?
    
    /// indicates which party of the trade made the sell offer
    public var baseIsSeller:Bool
    
    private enum CodingKeys: String, CodingKey {
        
        case links = "_links"
        case id
        case pagingToken = "paging_token"
        case ledgerCloseTime = "ledger_close_time"
        case baseAccount = "base_account"
        case baseAmount = "base_amount"
        case baseAssetType = "base_asset_type"
        case baseAssetCode = "base_asset_code"
        case baseAssetIssuer = "base_asset_issuer"
        case counterAccount = "counter_account"
        case counterAmount = "counter_amount"
        case counterAssetType = "counter_asset_type"
        case counterAssetCode = "counter_asset_code"
        case counterAssetIssuer = "counter_asset_issuer"
        case baseIsSeller = "base_is_seller"
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        links = try values.decode(TradeLinksResponse.self, forKey: .links)
        id = try values.decode(String.self, forKey: .id)
        pagingToken = try values.decode(String.self, forKey: .pagingToken)
        ledgerCloseTime = try values.decode(Date.self, forKey: .ledgerCloseTime)
        baseAccount = try values.decode(String.self, forKey: .baseAccount)
        baseAmount = try values.decode(String.self, forKey: .baseAmount)
        baseAssetType = try values.decode(String.self, forKey: .baseAssetType)
        baseAssetCode = try values.decodeIfPresent(String.self, forKey: .baseAssetCode)
        baseAssetIssuer = try values.decodeIfPresent(String.self, forKey: .baseAssetIssuer)
        counterAccount = try values.decode(String.self, forKey: .counterAccount)
        counterAmount = try values.decode(String.self, forKey: .counterAmount)
        counterAssetType = try values.decode(String.self, forKey: .counterAssetType)
        counterAssetCode = try values.decodeIfPresent(String.self, forKey: .counterAssetCode)
        counterAssetIssuer = try values.decodeIfPresent(String.self, forKey: .counterAssetIssuer)
        baseIsSeller = try values.decode(Bool.self, forKey: .baseIsSeller)
    }
}
