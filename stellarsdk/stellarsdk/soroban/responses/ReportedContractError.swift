//
//  ReportedContractError.swift
//  stellarsdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation

/// A contract error code that a failed Soroban simulation reports.
///
/// The host error of a failed simulation either names the contract error directly
/// (`Error(Contract, #N)`) or masks it: a failing constructor surfaces as
/// `Error(Context, ...)` and a failing `__check_auth` as `Error(Auth, ...)`, and the code
/// then appears only in the diagnostic events of the response.
///
/// For a masked failure the earliest diagnostic event of a failed call whose topics are
/// the symbol `error` and a contract error is selected. This is a heuristic, not a proven
/// cause: an earlier error that a contract caught, several failing contracts, or an
/// unrelated error rolled back with the call can be selected instead of the error that
/// ended the simulation, and a code from a contract outside the OpenZeppelin smart-account
/// suite can collide with a code of `OZContractErrorCodes`. Diagnostic events are present
/// only when the RPC server returns them; without them a code is available only when the
/// host error names it directly.
public struct ReportedContractError: Equatable, Hashable, Sendable {

    /// Where a failed simulation reports the contract error code.
    public enum Provenance: Equatable, Hashable, Sendable {
        /// The host error names `Error(Contract, #N)`.
        case hostError
        /// The earliest diagnostic error event of a failed call names the code.
        case diagnosticEvents
    }

    /// The contract error code `N`.
    public let code: UInt32

    /// Where the failure reports the code.
    public let provenance: Provenance

    /// The contract that emitted the selected event, as a `C...` strkey; `nil` for
    /// ``Provenance/hostError`` and for an event without a contract ID.
    public let contractId: String?

    /// Creates a reported contract error.
    ///
    /// - Parameters:
    ///   - code: The contract error code.
    ///   - provenance: Where the failure reports the code.
    ///   - contractId: The emitting contract as a `C...` strkey, or `nil`.
    public init(code: UInt32, provenance: Provenance, contractId: String?) {
        self.code = code
        self.provenance = provenance
        self.contractId = contractId
    }

    /// The earliest entry of `events` that decodes as a diagnostic event of a failed call
    /// with exactly the two topics `error` (symbol) and a contract error; entries that do
    /// not decode are skipped.
    static func earliestFailedCallError(in events: [String]) -> ReportedContractError? {
        for entry in events {
            guard let diagnostic = try? DiagnosticEventXDR(fromBase64: entry),
                  !diagnostic.inSuccessfulContractCall,
                  diagnostic.event.type == ContractEventType.diagnostic.rawValue,
                  case .v0(let body) = diagnostic.event.body,
                  body.topics.count == 2,
                  case .symbol(let name) = body.topics[0], name == "error",
                  case .error(let scError) = body.topics[1],
                  case .contract(let code) = scError else {
                continue
            }
            let contractId = diagnostic.event.hash.flatMap { try? $0.wrapped.encodeContractId() }
            return ReportedContractError(code: code, provenance: .diagnosticEvents, contractId: contractId)
        }
        return nil
    }
}

extension SimulateTransactionResponse {

    /// The contract error code this failed simulation reports, or `nil`.
    ///
    /// Only the first line of ``error`` is read, the host error `Error(Type, Value)` with an
    /// optional `HostError:` prefix; a textual event log after it is never parsed.
    /// - `Error(Contract, #N)` gives `N` with ``ReportedContractError/Provenance/hostError``
    ///   and no contract ID, whatever the events hold.
    /// - `Error(Context, ...)` and `Error(Auth, ...)` give the earliest diagnostic event of a
    ///   failed call whose topics are the symbol `error` and a contract error, with
    ///   ``ReportedContractError/Provenance/diagnosticEvents`` and the emitting contract.
    ///   Entries of ``events`` that do not decode are skipped; an unknown code is returned
    ///   as found.
    /// - Every other header, a code outside the `UInt32` range, and a response without
    ///   ``error`` give `nil`.
    ///
    /// The selection is a heuristic; see ``ReportedContractError``.
    ///
    /// - Returns: The reported contract error, or `nil`. Never throws.
    public func reportedContractError() -> ReportedContractError? {
        guard let error = error, let header = HostErrorHeader.parse(firstLineOf: Substring(error)) else {
            return nil
        }
        switch header {
        case .contract(let code):
            return ReportedContractError(code: code, provenance: .hostError, contractId: nil)
        case .masked:
            return ReportedContractError.earliestFailedCallError(in: events ?? [])
        case .other:
            return nil
        }
    }
}

/// The host-error header on the first line of a simulation error text.
enum HostErrorHeader: Equatable {
    /// `Error(Contract, #N)` with `N` in the `UInt32` range.
    case contract(UInt32)
    /// `Error(Context, ...)` or `Error(Auth, ...)`, the categories that mask a contract error.
    case masked
    /// Any other well-formed header, including `Error(Contract, ...)` without a `UInt32` code.
    case other

    /// `Error(Type, Value)` with an optional `HostError:` prefix and nothing else on the line.
    /// The pattern is a compile-time constant, so initialization cannot fail.
    private static let headerRegex: NSRegularExpression? = try? NSRegularExpression(
        pattern: #"^\s*(?:HostError:\s*)?Error\(\s*([A-Za-z]+)\s*,\s*([^()]*?)\s*\)\s*$"#,
        options: []
    )

    /// Parses the text of `text` up to its first line break; `nil` when it is not a header.
    static func parse(firstLineOf text: Substring) -> HostErrorHeader? {
        let line = String(text.prefix { !$0.isNewline })
        guard let regex = headerRegex else {
            return nil
        }
        let range = NSRange(line.startIndex..<line.endIndex, in: line)
        guard let match = regex.firstMatch(in: line, options: [], range: range),
              let typeRange = Range(match.range(at: 1), in: line),
              let valueRange = Range(match.range(at: 2), in: line) else {
            return nil
        }
        let value = line[valueRange]
        switch line[typeRange] {
        case "Contract":
            guard value.first == "#",
                  value.dropFirst().allSatisfy({ $0.isASCII && $0.isNumber }),
                  let code = UInt32(value.dropFirst()) else {
                return .other
            }
            return .contract(code)
        case "Context", "Auth":
            return .masked
        default:
            return .other
        }
    }
}

/// Writes and reads the contract error part of the simulation failure messages of
/// `AssembledTransaction`, so writer and reader share one format.
enum SimulationFailureMessage {

    /// The prefix of the message `AssembledTransaction.simulate` throws.
    static let simulatePrefix = "Simulation failed with error: "

    /// The prefix of the message `AssembledTransaction.getSimulationData` throws.
    static let simulationDataPrefix = "Transaction simulation failed. Error: "

    private static let suffixMarker = " (contract error in diagnostic events: Error(Contract, #"
    private static let contractPart = "), contract "

    /// The text appended to a simulation failure message: empty for `nil` and for
    /// ``ReportedContractError/Provenance/hostError``, otherwise
    /// ` (contract error in diagnostic events: Error(Contract, #N), contract C...)`, ending
    /// after `#N))` when the event has no contract ID.
    static func suffix(for reported: ReportedContractError?) -> String {
        guard let reported = reported, reported.provenance == .diagnosticEvents else {
            return ""
        }
        guard let contractId = reported.contractId else {
            return "\(suffixMarker)\(reported.code)))"
        }
        return "\(suffixMarker)\(reported.code)\(contractPart)\(contractId))"
    }

    /// `prefix`, the RPC's host error text, and the suffix for `reported`.
    static func compose(prefix: String, hostError: String, reported: ReportedContractError?) -> String {
        return prefix + hostError + suffix(for: reported)
    }

    /// Reads a message in the form ``compose(prefix:hostError:reported:)`` writes.
    ///
    /// The message must start with one of the two prefixes. A suffix counts only when it
    /// runs to the end of the message and reads back exactly as ``suffix(for:)`` writes it.
    /// The header is the first line after the prefix. A contract header gives the host
    /// error value; a masked header gives the suffix value, or `nil` without one. The text
    /// between the first line and the suffix is never read.
    static func reportedContractError(in message: String) -> ReportedContractError? {
        let rest: Substring
        if message.hasPrefix(simulatePrefix) {
            rest = message.dropFirst(simulatePrefix.count)
        } else if message.hasPrefix(simulationDataPrefix) {
            rest = message.dropFirst(simulationDataPrefix.count)
        } else {
            return nil
        }
        var body = rest
        var suffixValue: ReportedContractError?
        if let markerRange = rest.range(of: suffixMarker, options: [.backwards, .literal]) {
            let tail = rest[markerRange.lowerBound...]
            if let parsed = parseSuffix(tail[markerRange.upperBound...]), suffix(for: parsed) == tail {
                suffixValue = parsed
                body = rest[..<markerRange.lowerBound]
            }
        }
        switch HostErrorHeader.parse(firstLineOf: body) {
        case .contract(let code):
            return ReportedContractError(code: code, provenance: .hostError, contractId: nil)
        case .masked:
            return suffixValue
        case .other, nil:
            return nil
        }
    }

    /// Parses `N))` or `N), contract C...)` after the suffix marker; the caller compares the
    /// re-written suffix with the original text, which rejects every non-canonical form.
    private static func parseSuffix(_ text: Substring) -> ReportedContractError? {
        let digits = text.prefix { $0.isASCII && $0.isNumber }
        guard let code = UInt32(digits) else {
            return nil
        }
        let remainder = text[digits.endIndex...]
        if remainder == "))" {
            return ReportedContractError(code: code, provenance: .diagnosticEvents, contractId: nil)
        }
        guard remainder.hasPrefix(contractPart), remainder.hasSuffix(")") else {
            return nil
        }
        let contractId = String(remainder.dropFirst(contractPart.count).dropLast())
        guard contractId.isValidContractId() else {
            return nil
        }
        return ReportedContractError(code: code, provenance: .diagnosticEvents, contractId: contractId)
    }
}
