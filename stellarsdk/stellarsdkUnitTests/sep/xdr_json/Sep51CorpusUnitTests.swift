//
//  Sep51CorpusUnitTests.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 06.08.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

/// Drives `corpus.json`, the SEP-0051 (XDR-JSON) conformance corpus.
///
/// Every entry pins one XDR value in both forms: the base64 the binary codec produces and the
/// exact JSON text this SDK must emit for it. Both directions are asserted for every entry, so
/// the suite states conformance to an external record rather than self-consistency.
///
/// An entry's `json` is authoritative whatever its `oracle` class says. `reference` marks the
/// SDK and the reference agreeing; `incomparable` and `spec` mark the places where SEP-0051 and
/// the reference disagree and the SDK follows the spec. The reference's own output is recorded
/// in `oracle_json` for the maintainer's benefit and is deliberately not decoded here: asserting
/// it would pin the divergence the SDK does not follow.
final class Sep51CorpusUnitTests: XCTestCase {

    // MARK: - Emission

    func testEveryEntryRendersTheJsonTheCorpusPins() {
        guard let entries = loadEntries() else { return }

        for (index, entry) in entries.enumerated() {
            do {
                let produced = try GeneratedXdrJsonCorpusDispatch.json(forType: entry.iosType,
                                                                       xdrBase64: entry.xdr)
                XCTAssertEqual(produced, entry.json, Self.describe(entry, at: index))
            } catch {
                XCTFail("\(Self.describe(entry, at: index)): emitting XDR-JSON failed with \(error)")
            }
        }
    }

    // MARK: - Acceptance

    func testEveryEntryReadsBackToTheSameXdr() {
        guard let entries = loadEntries() else { return }

        for (index, entry) in entries.enumerated() {
            do {
                let produced = try GeneratedXdrJsonCorpusDispatch.xdrBase64(forType: entry.iosType,
                                                                            json: entry.json)
                XCTAssertEqual(produced, entry.xdr, Self.describe(entry, at: index))
            } catch {
                XCTFail("\(Self.describe(entry, at: index)): reading XDR-JSON failed with \(error)")
            }
        }
    }

    /// An input variant is an alternative spelling the SDK must accept for the same value. It is
    /// asserted on the reading direction only, because the SDK emits the entry's canonical `json`
    /// rather than the variant.
    func testEveryInputVariantReadsToTheSameXdr() {
        guard let entries = loadEntries() else { return }

        for (index, entry) in entries.enumerated() {
            for (position, variant) in (entry.inputVariants ?? []).enumerated() {
                let label = "\(Self.describe(entry, at: index)) [input variant \(position)]"
                do {
                    let produced = try GeneratedXdrJsonCorpusDispatch.xdrBase64(forType: entry.iosType,
                                                                                json: variant)
                    XCTAssertEqual(produced, entry.xdr, label)
                } catch {
                    XCTFail("\(label): reading XDR-JSON failed with \(error)")
                }
            }
        }
    }

    // MARK: - Dispatch completeness

    func testEveryCorpusTypeIsDispatched() {
        guard let entries = loadEntries() else { return }

        let named = Set(entries.map { $0.iosType })
        let undispatched = named.subtracting(GeneratedXdrJsonCorpusDispatch.dispatchedTypes).sorted()
        XCTAssertTrue(undispatched.isEmpty,
                      "corpus.json names \(undispatched.count) type(s) the generated dispatch does "
                      + "not carry, so those entries are untested: \(undispatched.joined(separator: ", "))")
    }

    // MARK: - Resource integrity

    func testCorpusCarriesEveryEntryItDeclares() {
        guard let corpus = loadCorpus() else { return }

        XCTAssertEqual(corpus.entries.count, corpus.metadata.entryCount,
                       "\(Self.resourceName).json declares \(corpus.metadata.entryCount) entries but "
                       + "carries \(corpus.entries.count). \(Self.regenerationHint)")
        XCTAssertGreaterThanOrEqual(corpus.entries.count, Self.minimumEntryCount,
                                    "\(Self.resourceName).json carries \(corpus.entries.count) entries. "
                                    + "The shipped corpus carries far more; a resource this small is a "
                                    + "gutted or partial copy. \(Self.regenerationHint)")
    }

    // MARK: - Corpus model

    private struct Corpus: Decodable {
        let metadata: Metadata
        let entries: [Entry]
    }

    private struct Metadata: Decodable {
        let entryCount: Int
    }

    private struct Entry: Decodable {
        let type: String
        let iosType: String
        let xdr: String
        let json: String
        let oracle: String
        let note: String
        let inputVariants: [String]?
    }

    // MARK: - Loading

    private static let resourceName = "corpus"
    private static let regenerationHint =
        "Regenerate it with python3 tools/sep-51-corpus/generate_corpus.py."

    /// A floor rather than the exact count, so adding seeds never breaks this assertion while a
    /// resource that is present but emptied still fails here instead of passing vacuously.
    private static let minimumEntryCount = 350

    private enum CorpusUnavailable: Error, CustomStringConvertible {
        case resourceMissing

        var description: String {
            switch self {
            case .resourceMissing:
                return "the test bundle carries no \(Sep51CorpusUnitTests.resourceName).json resource"
            }
        }
    }

    private static func readCorpus() throws -> Corpus {
        guard let url = Bundle.module.url(forResource: resourceName, withExtension: "json") else {
            throw CorpusUnavailable.resourceMissing
        }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(Corpus.self, from: data)
    }

    private func loadCorpus() -> Corpus? {
        do {
            return try Self.readCorpus()
        } catch {
            XCTFail("\(Self.resourceName).json could not be read from the test bundle: \(error). "
                    + "It must be declared as a resource of the stellarsdkUnitTests target in "
                    + "Package.swift. \(Self.regenerationHint)")
            return nil
        }
    }

    private func loadEntries() -> [Entry]? {
        loadCorpus()?.entries
    }

    private static func describe(_ entry: Entry, at index: Int) -> String {
        "corpus entry \(index): \(entry.type) as \(entry.iosType), oracle \(entry.oracle) — \(entry.note)"
    }
}
