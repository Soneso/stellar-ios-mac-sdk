//
//  SegmentFilter.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 27.02.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

/// Filter for matching individual segments within contract event topics.
///
/// SegmentFilter is used as part of TopicFilter to match specific positions
/// in event topic arrays. Each segment can be matched either by:
/// - Wildcard string (e.g., "*" to match any value)
/// - Specific SCVal values (exact matches)
///
/// Event topics in Soroban are arrays of SCVal values. A SegmentFilter allows
/// you to specify matching criteria for a single position in that array.
///
/// Matching rules:
/// - If wildcard is set, any value at this position will match
/// - If scval array is provided, the position must match one of the specified values
/// - Only one matching mode (wildcard or scval) should be used per segment
///
/// Example:
/// ```swift
/// // Match any value at this position
/// let anySegment = SegmentFilter(wildcard: "*")
///
/// // Match specific account address
/// let address = try SCAddressXDR(accountId: "GADDR...")
/// let addressVal = SCValXDR.address(address)
/// let specificSegment = SegmentFilter(scval: [addressVal])
///
/// // Use in topic filter
/// let topicFilter = TopicFilter(segmentMatchers: [
///     SegmentFilter(wildcard: "*"),           // Any event name
///     SegmentFilter(scval: [addressVal])      // Specific address
/// ])
/// ```
///
/// See also:
/// - [TopicFilter] for combining segment filters
/// - [EventFilter] for filtering contract events
/// - [SCValXDR] for Soroban value types
public final class SegmentFilter: Sendable {

    /// Wildcard pattern for matching any value at this segment position.
    ///
    /// When set to "*", this segment will match any value. Typically used
    /// when you want to ignore certain positions in the topic array.
    public let wildcard:String?

    /// Array of specific SCVal values to match at this segment position.
    ///
    /// The segment will match if the actual value equals any of the values
    /// in this array. Values are compared after XDR encoding.
    public let scval: [SCValXDR]?

    /// Creates a segment filter with optional wildcard or specific value matching.
    ///
    /// - Parameters:
    ///   - wildcard: Wildcard string (typically "*") to match any value
    ///   - scval: Array of specific SCVal values to match exactly
    ///
    /// Note: Typically only one parameter should be provided. If both are set,
    /// the RPC server behavior is implementation-dependent.
    public init(wildcard:String? = nil, scval: [SCValXDR]? = nil) {
        self.wildcard = wildcard
        self.scval = scval
    }

    /// Builds request parameters for Soroban RPC queries.
    ///
    /// Converts the filter into a dictionary suitable for JSON-RPC requests.
    /// SCVal values are XDR-encoded as base64 strings.
    ///
    /// - Returns: Dictionary containing wildcard and/or scval parameters
    public func buildRequestParams() -> [String : Any] {
        var result: [String : Any] = [:]
        if let wildcard = wildcard {
            result["wildcard"] = wildcard
        }
        // scval
        if let scval = scval, !scval.isEmpty {
            var arr:[String] = []
            for val in scval {
                if let encoded = val.xdrEncoded {
                    arr.append(encoded)
                }
            }
            if !arr.isEmpty {
                result["scval"] = arr
            }
        }
        return result;
    }
}
