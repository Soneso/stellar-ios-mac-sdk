//
//  LinkResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 02.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents a hypermedia link in Horizon API responses.
///
/// Horizon uses HAL (Hypertext Application Language) for responses, which includes links
/// to related resources. Links provide navigation between related resources without requiring
/// clients to construct URLs manually.
///
/// Links may be templated (contain placeholders like {cursor}, {limit}) that clients can
/// fill in with values, or they may be direct URLs ready to use.
///
/// Example usage:
/// ```swift
/// let account: AccountResponse = // ... get account
///
/// // Direct link (not templated)
/// if let transactionsURL = account.links.transactions?.href {
///     // Use URL directly to fetch transactions
/// }
///
/// // Templated link - requires parameter substitution
/// if let templated = account.links.transactions?.templated, templated {
///     // Link contains placeholders like {cursor}, {limit}, {order}
///     // Need to substitute values before using
/// }
/// ```
///
/// See also:
/// - [HAL Specification](https://en.wikipedia.org/wiki/Hypertext_Application_Language)
/// - PagingLinksResponse for pagination links
public class LinkResponse: NSObject, Decodable {

    /// URL of the linked resource. May contain URI template placeholders if templated is true.
    public var href:String

    /// If true, href contains URI template variables that must be substituted with values.
    /// Common variables: {cursor}, {limit}, {order}. If false or nil, href is a direct URL.
    public var templated:Bool?
    
    // Properties to encode and decode
    enum CodingKeys: String, CodingKey {
        case href
        case templated
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        href = try values.decode(String.self, forKey: .href)
        templated = try values.decodeIfPresent(Bool.self, forKey: .templated)
    }
}
