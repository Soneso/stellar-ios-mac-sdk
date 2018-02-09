//
//  AllEffectsResponse.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 02/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

///  Represents an all effetcs response, containing effetcs response objects and links from the all effects request
///  Horizon API Request GET /effects{?cursor,limit,order}
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/endpoints/effects-all.html "All Effects")
public class AllEffectsResponse: NSObject {
    
    /// An array of effect response objects received from the API
    public var effects:[EffectResponse]
    
    /// A list of links related to this all effects response
    public var links: AllEffectsLinksResponse
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter effects: The effects received from the Horizon API
        - Parameter links: The links received from the Horizon API
     */
    public init(effects: [EffectResponse], links:AllEffectsLinksResponse) {
        self.effects = effects
        self.links = links
    }
}
