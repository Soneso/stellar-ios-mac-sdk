//
//  SimulateTransactionResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

/// Response from simulating a Soroban contract invocation.
///
/// Contains all information needed to understand what will happen when a transaction executes:
/// - Return values from contract function calls
/// - Resource requirements (CPU instructions, memory, I/O)
/// - Ledger footprint (which ledger entries will be read/written)
/// - Authorization requirements for multi-party transactions
/// - Events emitted during simulation
/// - Required fees and resource costs
///
/// Use this response to:
/// - Get results from read-only contract calls without submitting a transaction
/// - Determine resource limits before submitting a write transaction
/// - Check if ledger entries need restoration before invocation
/// - Validate that a transaction will succeed before submission
///
/// Before submitting a write transaction, you must:
/// 1. Simulate the transaction
/// 2. Use transactionData and minResourceFee from the simulation
/// 3. Add these to your transaction
/// 4. Sign and submit
///
/// Example:
/// ```swift
/// let simResponse = await server.simulateTransaction(simulateTxRequest: request)
/// switch simResponse {
/// case .success(let simulation):
///     // Check for errors
///     if let error = simulation.error {
///         print("Simulation failed: \(error)")
///         return
///     }
///
///     // Check if restoration is needed
///     if let restore = simulation.restorePreamble {
///         print("Must restore footprint first")
///         // Submit RestoreFootprint operation
///     }
///
///     // Get return value for read calls
///     if let result = simulation.results?.first?.returnValue {
///         print("Contract returned: \(result)")
///     }
///
///     // For write calls, use simulation data
///     transaction.setSorobanTransactionData(simulation.transactionData!)
///     transaction.addResourceFee(simulation.minResourceFee!)
/// case .failure(let error):
///     print("RPC error: \(error)")
/// }
/// ```
///
/// See also:
/// - [SorobanServer.simulateTransaction] for invoking simulation
/// - [Stellar developer docs](https://developers.stellar.org)
public class SimulateTransactionResponse: NSObject, Decodable {

    /// Simulation results including resource costs, return values, and auth requirements.
    public var results:[SimulateTransactionResult]?
    
    /// The sequence number of the latest ledger known to Soroban RPC at the time it handled the request.
    public var latestLedger:Int
    
    /// The recommended Soroban Transaction Data to use when submitting the simulated transaction. This data contains the refundable fee and resource usage information such as the ledger footprint and IO access data.  Not present in case of error.
    public var transactionData:SorobanTransactionDataXDR?
    
    /// Recommended minimum resource fee to add when submitting the transaction. This fee is to be added on top of the Stellar network fee. Not present in case of error.
    public var minResourceFee:UInt32?
    
    /// Array of the events emitted during the contract invocation(s). The events are ordered by their emission time. (an array of serialized base64 strings - DiagnosticEventXdr)
    public var events:[String]? // DiagnosticEventXdr

    ///  (optional) only present if the transaction failed. This field will include more details from stellar-core about why the invoke host function call failed.
    public var error:String?
    
    /// It can only present on successful simulation (i.e. no error) of InvokeHostFunction operations. If present, it indicates
    /// the simulation detected expired ledger entries which requires restoring with the submission of a RestoreFootprint
    /// operation before submitting the InvokeHostFunction operation. The restorePreamble.minResourceFee and restorePreamble.transactionData fields should
    /// be used to construct the transaction containing the RestoreFootprint
    public var restorePreamble:RestorePreamble?
    
    /// If present, it indicates how the state (ledger entries) will change as a result of the transaction execution.
    public var stateChanges:[LedgerEntryChange]? // only available from protocol 21 on
    
    private enum CodingKeys: String, CodingKey {
        case results
        case latestLedger
        case transactionData
        case minResourceFee
        case events
        case error
        case restorePreamble
        case stateChanges
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        latestLedger = try values.decode(Int.self, forKey: .latestLedger)
        if let transactionDataXdrString = try values.decodeIfPresent(String.self, forKey: .transactionData) {
            transactionData = try SorobanTransactionDataXDR(fromBase64: transactionDataXdrString)
        }
        if let resStr = try values.decodeIfPresent(String.self, forKey: .minResourceFee) {
            minResourceFee = UInt32(resStr)
        }
        events = try values.decodeIfPresent([String].self, forKey: .events)
        error = try values.decodeIfPresent(String.self, forKey: .error)
        if error == nil {
            results = try values.decodeIfPresent([SimulateTransactionResult].self, forKey: .results)
        }
        restorePreamble = try values.decodeIfPresent(RestorePreamble.self, forKey: .restorePreamble)
        stateChanges = try values.decodeIfPresent([LedgerEntryChange].self, forKey: .stateChanges)
    }

    /// The ledger footprint indicating which ledger entries will be read or written during transaction execution.
    public var footprint:Footprint? {
        if let fxdr = transactionData?.resources.footprint {
            return Footprint(xdrFootprint: fxdr)
        }
        return nil;
    }
    
    /// The soroban authorization entries if available.
    public var sorobanAuth:[SorobanAuthorizationEntryXDR]? {
        guard let results = results, let firstResult = results.first else {
            return nil
        }
        let auth = firstResult.auth
        do {
            var res:[SorobanAuthorizationEntryXDR] = []
            for base64Xdr in auth {
                res.append(try SorobanAuthorizationEntryXDR(fromBase64: base64Xdr))
            }
            return res
        } catch {
            return nil
        }
    }
    
    /// true if the simulation detected expired ledger entries which requires restoring with the submission of a RestoreFootprint
    /// operation before submitting the InvokeHostFunction operation. The restorePreamble.minResourceFee and restorePreamble.transactionData fields should
    /// be used to construct the transaction containing the RestoreFootprint
    private var needsRestoreFootprint:Bool {
        return restorePreamble != nil
    }
}

/// It can only present on successful simulation (i.e. no error) of InvokeHostFunction operations. If present, it indicates
/// the simulation detected expired ledger entries which requires restoring with the submission of a RestoreFootprint
/// operation before submitting the InvokeHostFunction operation. The restorePreamble.minResourceFee and restorePreamble.transactionData fields should
/// be used to construct the transaction containing the RestoreFootprint
public class RestorePreamble: NSObject, Decodable {
    
    /// The recommended Soroban Transaction Data to use when submitting the RestoreFootprint operation.
    public var transactionData:SorobanTransactionDataXDR
    
    ///  Recommended minimum resource fee to add when submitting the RestoreFootprint operation. This fee is to be added on top of the Stellar network fee.
    public var minResourceFee:UInt32

    private enum CodingKeys: String, CodingKey {
        case transactionData
        case minResourceFee
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let transactionDataXdrString = try values.decode(String.self, forKey: .transactionData)
        transactionData = try SorobanTransactionDataXDR(fromBase64: transactionDataXdrString)
        let resStr = try values.decode(String.self, forKey: .minResourceFee)
        if let mrf = UInt32(resStr) {
            minResourceFee = mrf
        } else {
            throw StellarSDKError.decodingError(message: "min ressource fee must be a positive integer")
        }
    }
}

/// Represents a change to a ledger entry as a result of transaction simulation.
public class LedgerEntryChange: NSObject, Decodable {

    /// Type of ledger entry change.
    public var type:String
    /// Ledger entry key identifier.
    public var key:LedgerKeyXDR
    /// Ledger entry state before change.
    public var before:LedgerEntryXDR?
    /// Ledger entry state after change.
    public var after:LedgerEntryXDR?

    private enum CodingKeys: String, CodingKey {
        case type
        case key
        case before
        case after
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        type = try values.decode(String.self, forKey: .type)
        
        let keyXdrString = try values.decode(String.self, forKey: .key)
        key = try LedgerKeyXDR(fromBase64: keyXdrString)
        
        if let beforeXdrString = try values.decodeIfPresent(String.self, forKey: .before) {
            before = try LedgerEntryXDR(fromBase64: beforeXdrString)
        }
        
        if let afterXdrString = try values.decodeIfPresent(String.self, forKey: .after) {
            after = try LedgerEntryXDR(fromBase64: afterXdrString)
        }
    }
}

