//
//  DateFormatter+ISOParsing.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 06/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Extension providing ISO 8601 date formatting for DateFormatter.
extension DateFormatter {
    /// Shared ISO 8601 date formatter for parsing Horizon API timestamps.
    ///
    /// Configured to parse dates in the format "yyyy-MM-dd'T'HH:mm:ss'Z'" with UTC timezone.
    /// This is the standard format used by Stellar's Horizon API for timestamps.
    ///
    /// Example:
    /// ```swift
    /// let dateString = "2024-01-15T10:30:45Z"
    /// if let date = DateFormatter.iso8601.date(from: dateString) {
    ///     // Use parsed date
    /// }
    /// ```
    public static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}
