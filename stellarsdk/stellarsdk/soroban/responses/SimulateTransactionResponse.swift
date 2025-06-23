//
//  SimulateTransactionResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

/// Response that will be received when submitting a trial contract invocation.
public class SimulateTransactionResponse: NSObject, Decodable {
    
    /// (optional) - This array will only have one element: the result for the Host Function invocation. Only present on successful simulation (i.e. no error) of InvokeHostFunction operations.
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
    
    public var footprint:Footprint? {
        if let fxdr = transactionData?.resources.footprint {
            return Footprint(xdrFootprint: fxdr)
        }
        return nil;
    }
    
    /// The soroban authorization entries if available.
    public var sorobanAuth:[SorobanAuthorizationEntryXDR]? {
        if(results != nil && results!.count > 0) {
            let auth = results![0].auth
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
        return nil;
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

public class LedgerEntryChange: NSObject, Decodable {
    
    public var type:String
    public var key:LedgerKeyXDR
    public var before:LedgerEntryXDR?
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

