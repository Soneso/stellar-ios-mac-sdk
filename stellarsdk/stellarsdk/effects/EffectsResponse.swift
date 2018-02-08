//
//  EffectsResponse.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 02/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

public class EffectsResponse: NSObject {
    public var effects:[Effect]
    public var links: AllEffectsLinks
    
    public init(effects: [Effect], links:AllEffectsLinks) {
        self.effects = effects
        self.links = links
    }
}
