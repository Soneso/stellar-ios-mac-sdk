//
//  PageOfEffectsResponse.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 02/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  Represents a page of effetcs response.
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/endpoints/effects-all.html "All Effects")
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/page.html "Page")
public class PageOfEffectsResponse: NSObject {
    
    /// An array of effect response objects received from the API
    public var effects:[EffectResponse]
    
    /// A list of links related to this all effects response
    public var links: PagingLinksResponse
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter effects: The effects received from the Horizon API
        - Parameter links: The links received from the Horizon API
     */
    public init(effects: [EffectResponse], links:PagingLinksResponse) {
        self.effects = effects
        self.links = links
    }
}
