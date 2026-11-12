//
//  SecretSeedRedaction.swift
//  stellarsdk
//
//  Created by Soneso on 12.11.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

/// Keeps a secret seed given by mistake out of error texts.
///
/// A key position is an input whose every valid value is a strkey or an id that cannot start
/// with "S" or "s", the first letter of a secret seed: an address, an account, contract or
/// muxed id, a pool or claimable balance id. An error text shows such an input by its kind
/// through `keyPositionText(_:)` and never the input itself; this covers a seed with a
/// changed, a missing or an extra character and a lowercase seed. Any other position, such as
/// a number string or a union case name, and a text that wraps a caller's input go through
/// `redactingSecretSeeds(in:)`.
internal enum SecretSeedRedaction {

    /// The text naming a valid secret seed.
    static let secretSeed = "a secret seed (S...)"

    /// The text naming any other value that starts with "S" or "s" in a key position.
    static let valueStartingWithS = "a value starting with S (not shown, it may be a secret seed)"

    /// The kind of `value` given in a key position: `secretSeed` when `value` is a valid secret
    /// seed once trimmed of whitespace, `valueStartingWithS` for any other value whose trimmed
    /// form starts with "S" or "s", and nil for every other value.
    static func seedKind(of value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("S") || trimmed.hasPrefix("s") else {
            return nil
        }
        return trimmed.isValidEd25519SecretSeed() ? secretSeed : valueStartingWithS
    }

    /// `value` as an error text shows it in a key position: the kind `seedKind(of:)` names,
    /// otherwise `value` unchanged.
    static func keyPositionText(_ value: String) -> String {
        return seedKind(of: value) ?? value
    }

    /// The length of a secret seed.
    private static let seedLength = 56

    /// `text` with every maximal run of ASCII letters and digits that starts with "S" or "s"
    /// and is at least 40 characters long replaced by `secretSeed`, and then every valid
    /// secret seed in any letter case that is left inside the text replaced as well.
    ///
    /// A secret seed is such a run of 56 characters, and a seed with a changed, a missing or
    /// an extra character still is one. Shorter runs, such as words, asset codes and numbers,
    /// stay. A run of that length that is no seed, for example a fragment of base64 text
    /// that starts with "S", is replaced as well. A valid seed glued to a preceding letter or
    /// digit opens no run of its own and is found by its checksum.
    static func redactingSecretSeeds(in text: String) -> String {
        let runsReplaced = text.replacingOccurrences(of: "(?<![A-Za-z0-9])[Ss][A-Za-z0-9]{39,}",
                                                     with: secretSeed,
                                                     options: .regularExpression)
        return replacingValidSecretSeeds(in: runsReplaced)
    }

    /// `text` with every 56 character substring that is a valid secret seed once uppercased
    /// replaced by `secretSeed`, scanning from the start.
    private static func replacingValidSecretSeeds(in text: String) -> String {
        let scalars = Array(text.unicodeScalars)
        guard scalars.count >= seedLength else {
            return text
        }
        var result = String.UnicodeScalarView()
        var index = 0
        while index < scalars.count {
            let end = index + seedLength
            if end <= scalars.count, scalars[index] == "S" || scalars[index] == "s",
               scalars[index..<end].allSatisfy(isBase32Letter) {
                var candidate = String.UnicodeScalarView()
                candidate.append(contentsOf: scalars[index..<end])
                if String(candidate).uppercased().isValidEd25519SecretSeed() {
                    result.append(contentsOf: secretSeed.unicodeScalars)
                    index = end
                    continue
                }
            }
            result.append(scalars[index])
            index += 1
        }
        return String(result)
    }

    /// Whether `scalar` is a letter of the base32 alphabet in either case.
    private static func isBase32Letter(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar {
        case "A"..."Z", "a"..."z", "2"..."7":
            return true
        default:
            return false
        }
    }
}
