//
//  EffectsFactory.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 02/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  This class creates the different types of effect response classes depending on the effect type value from json.
class EffectsFactory: NSObject {
    
    /// The json decoder used to parse the received json response from the Horizon API.
    let jsonDecoder = JSONDecoder()
    
    /**
        Returns an AllEffectResponse object conatining all effect responses parsed from the json data.
     
        - Parameter data: The json data received from the Horizon API. See
     */
    func effectsFromResponseData(data: Data) throws -> PageResponse<EffectResponse> {
        var effectsList = [EffectResponse]()
        var links: PagingLinksResponse
        
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String:AnyObject]
            
            for record in json["_embedded"]!["records"] as! [[String:AnyObject]] {
                let jsonRecord = try JSONSerialization.data(withJSONObject: record, options: .prettyPrinted)
                let effect = try effectFromData(data: jsonRecord)
                effectsList.append(effect)
            }
            
            let linksJson = try JSONSerialization.data(withJSONObject: json["_links"]!, options: .prettyPrinted)
            links = try jsonDecoder.decode(PagingLinksResponse.self, from: linksJson)
            
        } catch {
            throw HorizonRequestError.parsingResponseFailed(message: error.localizedDescription)
        }
        
        return PageResponse<EffectResponse>(records: effectsList, links: links)
    }
    
    func effectFromData(data: Data) throws -> EffectResponse {
        let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String:AnyObject]
        // The class to be used depends on the effect type coded in its json reresentation.
        
        if let type = EffectType(rawValue: json["type_i"] as! Int) {
            switch type {
            case .accountCreated:
                let effect = try jsonDecoder.decode(AccountCreatedEffectResponse.self, from: data)
                return effect
            case .accountRemoved:
                let effect = try jsonDecoder.decode(AccountRemovedEffectResponse.self, from: data)
                return effect
            case .accountCredited:
                let effect = try jsonDecoder.decode(AccountCreditedEffectResponse.self, from: data)
                return effect
            case .accountDebited:
                let effect = try jsonDecoder.decode(AccountDebitedEffectResponse.self, from: data)
                return effect
            case .accountThresholdsUpdated:
                let effect = try jsonDecoder.decode(AccountThresholdsUpdatedEffectResponse.self, from: data)
                return effect
            case .accountHomeDomainUpdated:
                let effect = try jsonDecoder.decode(AccountHomeDomainUpdatedEffectResponse.self, from: data)
                return effect
            case .accountFlagsUpdated:
                let effect = try jsonDecoder.decode(AccountFlagsUpdatedEffectResponse.self, from: data)
                return effect
            case .accountInflationDestinationUpdated:
                let effect = try jsonDecoder.decode(AccountInflationDestinationUpdatedEffectResponse.self, from: data)
                return effect
            case .signerCreated:
                let effect = try jsonDecoder.decode(SignerCreatedEffectResponse.self, from: data)
                return effect
            case .signerRemoved:
                let effect = try jsonDecoder.decode(SignerRemovedEffectResponse.self, from: data)
                return effect
            case .signerUpdated:
                let effect = try jsonDecoder.decode(SignerUpdatedEffectResponse.self, from: data)
                return effect
            case .trustlineCreated:
                let effect = try jsonDecoder.decode(TrustlineCreatedEffectResponse.self, from: data)
                return effect
            case .trustlineRemoved:
                let effect = try jsonDecoder.decode(TrustlineRemovedEffectResponse.self, from: data)
                return effect
            case .trustlineUpdated:
                let effect = try jsonDecoder.decode(TrustlineUpdatedEffectResponse.self, from: data)
                return effect
            case .trustlineAuthorized:
                let effect = try jsonDecoder.decode(TrustlineAuthorizedEffectResponse.self, from: data)
                return effect
            case .trustlineDeauthorized:
                let effect = try jsonDecoder.decode(TrustlineDeauthorizedEffectResponse.self, from: data)
                return effect
            case .offerCreated:
                let effect = try jsonDecoder.decode(OfferCreatedEffectResponse.self, from: data)
                return effect
            case .offerRemoved:
                let effect = try jsonDecoder.decode(OfferRemovedEffectResponse.self, from: data)
                return effect
            case .offerUpdated:
                let effect = try jsonDecoder.decode(OfferUpdatedEffectResponse.self, from: data)
                return effect
            case .tradeEffect:
                let effect = try jsonDecoder.decode(TradeEffectResponse.self, from: data)
                return effect
            }
        } else {
            throw HorizonRequestError.parsingResponseFailed(message: "Unknown effect type")
        }
    }
    
}
