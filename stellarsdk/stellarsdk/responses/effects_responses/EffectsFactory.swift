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
    func effectsFromResponseData(data: Data) throws -> AllEffectsResponse {
        var effectsList = [EffectResponse]()
        var links: AllEffectsLinksResponse
        
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String:AnyObject]
            
            for record in json["_embedded"]!["records"] as! [[String:AnyObject]] {
                let jsonRecord = try JSONSerialization.data(withJSONObject: record, options: .prettyPrinted)
                
                // The class to be used depends on the effect type coded in its json reresentation.
                if let type = EffectType(rawValue: record["type_i"] as! Int) {
                    switch type {
                    case .accountCreated:
                        let effect = try jsonDecoder.decode(AccountCreatedEffectResponse.self, from: jsonRecord)
                        effectsList.append(effect)
                    case .accountRemoved:
                        let effect = try jsonDecoder.decode(AccountRemovedEffectResponse.self, from: jsonRecord)
                        effectsList.append(effect)
                    case .accountCredited:
                        let effect = try jsonDecoder.decode(AccountCreditedEffectResponse.self, from: jsonRecord)
                        effectsList.append(effect)
                    case .accountDebited:
                        let effect = try jsonDecoder.decode(AccountDebitedEffectResponse.self, from: jsonRecord)
                        effectsList.append(effect)
                    case .accountThresholdsUpdated:
                        let effect = try jsonDecoder.decode(AccountThresholdsUpdatedEffectResponse.self, from: jsonRecord)
                        effectsList.append(effect)
                    case .accountHomeDomainUpdated:
                        let effect = try jsonDecoder.decode(AccountHomeDomainUpdatedEffectResponse.self, from: jsonRecord)
                        effectsList.append(effect)
                    case .accountFlagsUpdated:
                        let effect = try jsonDecoder.decode(AccountFlagsUpdatedEffectResponse.self, from: jsonRecord)
                        effectsList.append(effect)
                    case .signerCreated:
                        let effect = try jsonDecoder.decode(SignerCreatedEffectResponse.self, from: jsonRecord)
                        effectsList.append(effect)
                    case .signerRemoved:
                        let effect = try jsonDecoder.decode(SignerRemovedEffectResponse.self, from: jsonRecord)
                        effectsList.append(effect)
                    case .signerUpdated:
                        let effect = try jsonDecoder.decode(SignerUpdatedEffectResponse.self, from: jsonRecord)
                        effectsList.append(effect)
                    case .trustlineCreated:
                        let effect = try jsonDecoder.decode(TrustlineCreatedEffectResponse.self, from: jsonRecord)
                        effectsList.append(effect)
                    case .trustlineRemoved:
                        let effect = try jsonDecoder.decode(TrustlineRemovedEffectResponse.self, from: jsonRecord)
                        effectsList.append(effect)
                    case .trustlineUpdated:
                        let effect = try jsonDecoder.decode(TrustlineUpdatedEffectResponse.self, from: jsonRecord)
                        effectsList.append(effect)
                    case .trustlineAuthorized:
                        let effect = try jsonDecoder.decode(TrustlineAuthorizedEffectResponse.self, from: jsonRecord)
                        effectsList.append(effect)
                    case .trustlineDeauthorized:
                        let effect = try jsonDecoder.decode(TrustlineDeauthorizedEffectResponse.self, from: jsonRecord)
                        effectsList.append(effect)
                    case .offerCreated:
                        let effect = try jsonDecoder.decode(OfferCreatedEffectResponse.self, from: jsonRecord)
                        effectsList.append(effect)
                    case .offerRemoved:
                        let effect = try jsonDecoder.decode(OfferRemovedEffectResponse.self, from: jsonRecord)
                        effectsList.append(effect)
                    case .offerUpdated:
                        let effect = try jsonDecoder.decode(OfferUpdatedEffectResponse.self, from: jsonRecord)
                        effectsList.append(effect)
                    case .tradeEffect:
                        let effect = try jsonDecoder.decode(TradeEffectResponse.self, from: jsonRecord)
                        effectsList.append(effect)
                    }
                }
            }
            
            let linksJson = try JSONSerialization.data(withJSONObject: json["_links"]!, options: .prettyPrinted)
            links = try jsonDecoder.decode(AllEffectsLinksResponse.self, from: linksJson)
            
        } catch {
            throw EffectsError.parsingFailed(response: error.localizedDescription)
        }
        
        return AllEffectsResponse(effects: effectsList, links:links)
    }
}
