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
    /// Never uses scientific notation, which `String(Double)` switches to outside roughly
    /// 1e-4..1e16 and which anchors do not accept. Stellar assets carry at most seven decimal
    /// places, so the fraction is rounded to seven digits, trailing zeroes in the fractional
    /// part are trimmed and the decimal point is suppressed for whole amounts.
    ///
    /// The rendering is locale independent: digits are ASCII and the separator is always a
    /// period, whatever the device's regional settings are.
    ///
    /// Three limits are worth knowing. An amount below half a stroop rounds to `0` and the sign
    /// is dropped, and a non-finite amount renders as the empty string; neither names an amount
    /// the caller can transact, and both leave the anchor to answer. From 2^29 (536870912) upward
    /// a `Double` no longer carries seven meaningful fractional digits, because that is where one
    /// unit in the last place first exceeds a stroop, so the last digits describe the stored value
    /// rather than the amount that was written.
    static func format(_ amount: Double) -> String {
        guard amount.isFinite else {
            return ""
        }
        // A nil locale keeps the conversion ASCII with a period separator.
        var formatted = String(format: "%.7f", locale: nil, amount)
        while formatted.hasSuffix("0") {
            formatted.removeLast()
        }
        if formatted.hasSuffix(".") {
            formatted.removeLast()
        }
        return formatted == "-0" ? "0" : formatted
    }
}
