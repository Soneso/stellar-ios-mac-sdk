//
//  SeedVariants.swift
//  stellarsdkUnitTests
//
//  Created by Soneso on 12.11.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation
import stellarsdk

/// The secret seed of a key pair generated at run time and the near misses derived from it,
/// the inputs an error text must never show.
struct SeedVariants {
    /// A valid secret seed.
    let seed: String
    /// The seed with one character changed, which breaks its checksum.
    let changed: String
    /// The seed in lowercase.
    let lowercase: String
    /// The seed with one character missing.
    let missing: String
    /// The seed with one character added.
    let extra: String

    init() throws {
        guard let seed = try KeyPair.generateRandomKeyPair().secretSeed else {
            throw StellarSDKError.invalidArgument(message: "the generated key pair has no secret seed")
        }
        var characters = Array(seed)
        self.seed = seed
        characters[10] = characters[10] == "A" ? "B" : "A"
        changed = String(characters)
        lowercase = seed.lowercased()
        var shortened = Array(seed)
        shortened.remove(at: 20)
        missing = String(shortened)
        var lengthened = Array(seed)
        lengthened.insert("A", at: 30)
        extra = String(lengthened)
    }

    /// Every variant that is a value starting with "S" or "s" but no valid secret seed.
    var nearMisses: [String] { [changed, lowercase, missing, extra] }

    /// The seed followed by its near misses.
    var all: [String] { [seed] + nearMisses }
}
