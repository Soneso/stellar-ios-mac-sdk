//
//  ISO8601DateFormatter+Full.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 14.01.25.
//  Copyright © 2025 Soneso. All rights reserved.
//

import Foundation

extension ISO8601DateFormatter {
    public static let full: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withFullTime, .withTimeZone, .withFractionalSeconds]
        return formatter
    }()
}
