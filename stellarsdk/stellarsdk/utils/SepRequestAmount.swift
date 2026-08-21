//
//  SepRequestAmount.swift
//  stellarsdk
//
//  Copyright © Soneso. All rights reserved.
//

import Foundation

/// Renders an asset amount for a SEP request field.
///
/// Scoped to the classic seven decimal places, and to request fields the SDK types as a `Double`.
/// Not for Soroban token amounts, whose scale the token defines and which routinely carry far more
/// than seven decimals, and not for transaction amounts, which reach operation XDR through
/// `Operation.toXDRAmount`.
internal enum SepRequestAmount {

    /// Renders an amount as a plain decimal string suitable for a request parameter.
    ///
    /// The rendering starts from the shortest decimal representation that reads back to the same
    /// `Double` — the digits `String(Double)` shows — and rounds it to at most seven decimal
    /// places, trimming trailing fractional zeroes and suppressing the decimal point for whole
    /// amounts. It never uses scientific notation, which `String(Double)` switches to outside
    /// roughly 1e-4..1e16 and which anchors do not accept, and it never renders the binary
    /// expansion behind the shortest representation. A fraction that ends exactly halfway
    /// rounds away from zero.
    ///
    /// The rendering is locale independent: every step is decimal string arithmetic on
    /// `String(Double)`, whose digits are ASCII with a period separator whatever the device's
    /// regional settings are.
    ///
    /// Two limits are worth knowing. An amount below half a stroop rounds to `0` and the sign is
    /// dropped, and a non-finite amount renders as the empty string; neither names an amount the
    /// caller can transact, and both leave the anchor to answer.
    static func format(_ amount: Double) -> String {
        guard amount.isFinite else {
            return ""
        }

        var shortest = String(amount)
        var sign = ""
        if shortest.hasPrefix("-") {
            sign = "-"
            shortest.removeFirst()
        }

        // Split the representation into its digit string and the position of the decimal
        // point within it, folding a scientific exponent into that position.
        var exponent = 0
        if let eIndex = shortest.firstIndex(where: { $0 == "e" || $0 == "E" }) {
            exponent = Int(shortest[shortest.index(after: eIndex)...]) ?? 0
            shortest = String(shortest[..<eIndex])
        }
        var pointPosition: Int
        if let dotIndex = shortest.firstIndex(of: ".") {
            pointPosition = shortest.distance(from: shortest.startIndex, to: dotIndex)
            shortest.remove(at: dotIndex)
        } else {
            pointPosition = shortest.count
        }
        let digits = shortest
        pointPosition += exponent

        var integerDigits: String
        var fractionDigits: String
        if pointPosition <= 0 {
            integerDigits = "0"
            fractionDigits = String(repeating: "0", count: -pointPosition) + digits
        } else if pointPosition >= digits.count {
            integerDigits = digits + String(repeating: "0", count: pointPosition - digits.count)
            fractionDigits = ""
        } else {
            let splitIndex = digits.index(digits.startIndex, offsetBy: pointPosition)
            integerDigits = String(digits[..<splitIndex])
            fractionDigits = String(digits[splitIndex...])
        }

        // Round the fraction to seven places on the decimal digits, carrying into the
        // integer part when the fraction overflows.
        if fractionDigits.count > 7 {
            let cutIndex = fractionDigits.index(fractionDigits.startIndex, offsetBy: 7)
            let roundsUp = fractionDigits[cutIndex] >= "5"
            fractionDigits = String(fractionDigits[..<cutIndex])
            if roundsUp {
                var combined = Array(integerDigits + fractionDigits)
                var index = combined.count - 1
                var carry = true
                while carry && index >= 0 {
                    if combined[index] == "9" {
                        combined[index] = "0"
                    } else {
                        combined[index] = Character(String(combined[index].wholeNumberValue! + 1))
                        carry = false
                    }
                    index -= 1
                }
                if carry {
                    combined.insert("1", at: 0)
                }
                fractionDigits = String(combined.suffix(7))
                integerDigits = String(combined.prefix(combined.count - 7))
            }
        }

        while fractionDigits.hasSuffix("0") {
            fractionDigits.removeLast()
        }
        let body = fractionDigits.isEmpty ? integerDigits : integerDigits + "." + fractionDigits

        // A zero result carries no sign.
        if body.allSatisfy({ $0 == "0" || $0 == "." }) {
            return "0"
        }
        return sign + body
    }
}
