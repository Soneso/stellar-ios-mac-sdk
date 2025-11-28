//
//  LinksResponse.swift
//  stellarsdk
//
//  Created by Istvan Elekes on 2/10/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Navigation links for paginated result sets from Horizon.
///
/// Horizon uses cursor-based pagination for large result sets. This response provides
/// links to navigate between pages: the current page (self), next page, and previous page.
///
/// Pagination links preserve all query parameters from the original request (filters,
/// ordering, etc.) and include cursor parameters to fetch the adjacent pages.
///
/// Example usage:
/// ```swift
/// let page: PageResponse<TransactionResponse> = // ... get page
///
/// // Check if there are more pages
/// if let nextURL = page.links.next?.href {
///     // Fetch next page using the URL
/// }
///
/// if let prevURL = page.links.prev?.href {
///     // Fetch previous page using the URL
/// }
///
/// // Self link to current page
/// let currentPageURL = page.links.selflink.href
/// ```
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
/// - PageResponse for paginated results
/// - LinkResponse for individual link details
public struct PagingLinksResponse: Decodable, Sendable {

    /// Link to the current page with all original query parameters.
    public let selflink:LinkResponse

    /// Link to the next page of results. Nil if this is the last page.
    public let next:LinkResponse?

    /// Link to the previous page of results. Nil if this is the first page.
    public let prev:LinkResponse?
    
    
    // Properties to encode and decode.
    enum CodingKeys: String, CodingKey {
        case selflink = "self"
        case next
        case prev
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        selflink = try values.decode(LinkResponse.self, forKey: .selflink)
        next = try values.decodeIfPresent(LinkResponse.self, forKey: .next)
        prev = try values.decodeIfPresent(LinkResponse.self, forKey: .prev)
    }
}
