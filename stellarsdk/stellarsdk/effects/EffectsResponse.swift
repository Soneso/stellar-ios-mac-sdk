//
//  EffectsResponse.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 02/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

///  Represents an effetcs response, containing effetc response objetcs and links from the effects request
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/endpoints/effects-all.html "All Effetcs")
public class EffectsResponse: NSObject {
    
    /// An array of effetc objects received from the respones
    public var effects:[Effect]
    
    /// A list of links related to this effects response
    public var links: AllEffectsLinks
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter effects: The effetcs received from the Horizon API
        - Parameter links: The links received from the Horizon API
     */
    public init(effects: [Effect], links:AllEffectsLinks) {
        self.effects = effects
        self.links = links
    }
}
