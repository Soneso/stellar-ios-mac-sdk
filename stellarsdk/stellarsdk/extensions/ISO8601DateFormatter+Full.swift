//
//  ISO8601DateFormatter+Full.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 14.01.25.
//  Copyright © 2025 Soneso. All rights reserved.
//

import Foundation

/// Extension providing a full ISO 8601 date formatter with fractional seconds.
extension ISO8601DateFormatter {
    /// Shared ISO 8601 date formatter with full date, time, timezone, and fractional seconds.
    ///
    /// Configured to parse and format dates with maximum precision including microseconds.
    /// This format is used by some Horizon API endpoints that require high-precision timestamps.
    ///
    /// Example:
    /// ```swift
    /// let dateString = "2024-01-15T10:30:45.123456Z"
    /// if let date = ISO8601DateFormatter.full.date(from: dateString) {
    ///     // Use parsed date with microsecond precision
    /// }
    /// ```
    public nonisolated(unsafe) static let full: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withFullTime, .withTimeZone, .withFractionalSeconds]
        return formatter
    }()
}
