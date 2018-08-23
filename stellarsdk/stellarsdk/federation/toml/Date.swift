/*
 * Copyright 2016-2018 JD Fergason
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation

private func buildDateFormatter(format: String) -> DateFormatter {
    let formatter = DateFormatter()
    formatter.dateFormat = format
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.calendar = Calendar(identifier: .iso8601)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    return formatter
}

private var rfc3339fractionalformatter =
    buildDateFormatter(format: "yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSSSSSZZZZZ")

private var rfc3339formatter: DateFormatter =
    buildDateFormatter(format: "yyyy'-'MM'-'dd'T'HH':'mm':'ssZZZZZ")

private func localTimeOffset() -> String {
    let totalSeconds: Int = TimeZone.current.secondsFromGMT()
    let minutes: Int = (totalSeconds / 60) % 60
    let hours: Int = totalSeconds / 3600
    return String(format: "%02d%02d", hours, minutes)
 }

extension Date {
    
    // rfc3339 w fractional seconds w/ time offset
    init?(rfc3339String: String, fractionalSeconds: Bool = true, localTime: Bool = false) {
        var dateStr = rfc3339String
        var dateFormatter: DateFormatter

        if localTime {
            dateStr += localTimeOffset()
        }
        
        dateFormatter = fractionalSeconds ? rfc3339fractionalformatter : rfc3339formatter

        if let d = dateFormatter.date(from: dateStr) {
            self.init(timeInterval: 0, since: d)
        } else {
            return nil
        }
    }

    func rfc3339String() -> String {
        return rfc3339fractionalformatter.string(from: self)
    }
    
}
