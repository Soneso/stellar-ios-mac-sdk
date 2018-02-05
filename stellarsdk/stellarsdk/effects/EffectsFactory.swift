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
                        print("")
                    case .accountCredited:
                        print("")
                    case .accountDebited:
                        print("")
                    case .accountThresholdsUpdated:
                        print("")
                    case .accountHomeDomainUpdated:
                        print("")
                    case .accountFlagsUpdated:
                        print("")
                    case .signerCreated:
                        print("")
                    case .signerRemoved:
                        print("")
                    case .signerUpdated:
                        print("")
                    case .trustlineCreated:
                        print("")
                    case .trustlineRemoved:
                        print("")
                    case .trustlineUpdated:
                        print("")
                    case .trustlineAuthorized:
                        print("")
                    case .trustlineDeauthorized:
                        print("")
                    case .offerCreated:
                        print("")
                    case .offerRemoved:
                        print("")
                    case .offerUpdated:
                        print("")
                    case .tradeEffect:
                        print("")
                    }
                }
            }
            
        } catch {
            throw EffectsError.parsingFailed(response: error.localizedDescription)
        }
        
        return EffectsResponse(effects: effectsList)
    }
    
}
