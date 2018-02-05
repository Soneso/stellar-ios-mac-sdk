//
//  EffectsFactory.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 02/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

class EffectsFactory: NSObject {
    let jsonDecoder = JSONDecoder()
    
    func effectsFromResponseData(data: Data) throws -> EffectsResponse {
        var effectsList = [Effect]()
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String:AnyObject]
            
            for record in json["_embedded"]!["records"] as! [[String:AnyObject]] {
                let jsonRecord = try JSONSerialization.data(withJSONObject: record, options: .prettyPrinted)
                if let type = EffectType(rawValue: record["type_i"] as! Int) {
                    switch type {
                    case .accountCreated:
                        let effect = try jsonDecoder.decode(AccountCreatedEffect.self, from: jsonRecord)
                        effectsList.append(effect)
                    case .accountRemoved:
                        let effect = try jsonDecoder.decode(AccountRemovedEffect.self, from: jsonRecord)
                        effectsList.append(effect)
                    case .accountCredited:
                        let effect = try jsonDecoder.decode(AccountCreditedEffect.self, from: jsonRecord)
                        effectsList.append(effect)
                    case .accountDebited:
                        let effect = try jsonDecoder.decode(AccountDebitedEffect.self, from: jsonRecord)
                        effectsList.append(effect)
                    case .accountThresholdsUpdated:
                        let effect = try jsonDecoder.decode(AccountThresholdsUpdatedEffect.self, from: jsonRecord)
                        effectsList.append(effect)
                    case .accountHomeDomainUpdated:
                        let effect = try jsonDecoder.decode(AccountHomeDomainUpdatedEffect.self, from: jsonRecord)
                        effectsList.append(effect)
                    case .accountFlagsUpdated:
                        let effect = try jsonDecoder.decode(AccountFlagsUpdatedEffect.self, from: jsonRecord)
                        effectsList.append(effect)
                    case .signerCreated:
                        let effect = try jsonDecoder.decode(SignerCreatedEffect.self, from: jsonRecord)
                        effectsList.append(effect)
                    case .signerRemoved:
                        let effect = try jsonDecoder.decode(SignerRemovedEffect.self, from: jsonRecord)
                        effectsList.append(effect)
                    case .signerUpdated:
                        let effect = try jsonDecoder.decode(SignerUpdatedEffect.self, from: jsonRecord)
                        effectsList.append(effect)
                    case .trustlineCreated:
                        let effect = try jsonDecoder.decode(TrustlineCreatedEffect.self, from: jsonRecord)
                        effectsList.append(effect)
                    case .trustlineRemoved:
                        let effect = try jsonDecoder.decode(TrustlineRemovedEffect.self, from: jsonRecord)
                        effectsList.append(effect)
                    case .trustlineUpdated:
                        let effect = try jsonDecoder.decode(TrustlineUpdatedEffect.self, from: jsonRecord)
                        effectsList.append(effect)
                    case .trustlineAuthorized:
                        let effect = try jsonDecoder.decode(TrustlineAuthorizedEffect.self, from: jsonRecord)
                        effectsList.append(effect)
                    case .trustlineDeauthorized:
                        let effect = try jsonDecoder.decode(TrustlineDeauthorizedEffect.self, from: jsonRecord)
                        effectsList.append(effect)
                    case .offerCreated:
                        let effect = try jsonDecoder.decode(OfferCreatedEffect.self, from: jsonRecord)
                        effectsList.append(effect)
                    case .offerRemoved:
                        let effect = try jsonDecoder.decode(OfferRemovedEffect.self, from: jsonRecord)
                        effectsList.append(effect)
                    case .offerUpdated:
                        let effect = try jsonDecoder.decode(OfferUpdatedEffect.self, from: jsonRecord)
                        effectsList.append(effect)
                    case .tradeEffect:
                        let effect = try jsonDecoder.decode(TradeEffect.self, from: jsonRecord)
                        effectsList.append(effect)
                    }
                }
            }
            
        } catch {
            throw EffectsError.parsingFailed(response: error.localizedDescription)
        }
        
        return EffectsResponse(effects: effectsList)
    }
    
}
