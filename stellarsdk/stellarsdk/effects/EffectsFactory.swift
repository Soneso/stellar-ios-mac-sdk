//
//  EffectsFactory.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 02/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

class EffectsFactory: NSObject {
    
    func effectsFromResponseData(data: Data) throws -> EffectsResponse {
        var effectsList = [Effect]()
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String:AnyObject]
            print(json)
            
            for record in json["_embedded"]!["records"] as! [[String:AnyObject]] {
                let type = EffectType(rawValue: record["type_i"] as! Int)
            }
            
        } catch {
            throw EffectsError.parsingFailed(response: error.localizedDescription)
        }
        
        return EffectsResponse(effects: effectsList)
    }
    
}
