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
    
    /**
     Checks if there is a previous page available.
     
     - Returns: true if a previous page is avialable
     */
    open func hasPreviousPage()->Bool {
        return links.prev != nil
    }
    
    /**
     Checks if there is a next page available.
     
     - Returns: true if a next page is avialable
     */
    open func hasNextPage()->Bool {
        return links.next != nil
    }
    
    /**
        Provides the next page if available. Before calling this, make sure there is a next page available by calling 'hasNextPage'.  If there is no next page available this fuction will respond with a 'HorizonRequestError.notFound" error.
     
        - Parameter response:   The closure to be called upon response.
     */
    open func getNextPage(response:@escaping PageOfEffectsResponseClosure) {
        let effetcsService = EffectsService(baseURL:"")
        if let url = links.next?.href {
            effetcsService.getEffetcsFromUrl(url:url, response:response)
        } else {
            response(.failure(error: .notFound(message: "next page not found", horizonErrorResponse: nil)))
        }
    }
    
    /**
        Provides the previous page if available. Before calling this, make sure there is a prevoius page available by calling 'hasPreviousPage'. If there is no prevoius page available this fuction will respond with a 'HorizonRequestError.notFound" error.
     
        - Parameter response:   The closure to be called upon response.
     */
    open func getPreviousPage(response:@escaping PageOfEffectsResponseClosure) {
        let effetcsService = EffectsService(baseURL:"")
        if let url = links.prev?.href {
            effetcsService.getEffetcsFromUrl(url:url, response:response)
        } else {
            response(.failure(error: .notFound(message: "previous page not found", horizonErrorResponse: nil)))
        }
    }
}
