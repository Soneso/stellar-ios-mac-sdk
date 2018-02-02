//
//  EffectsResponse.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 02/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

public class EffectsResponse: NSObject {
    var effects:[Effect]
    
    public init(effects: [Effect]) {
        self.effects = effects
    }
    
}
