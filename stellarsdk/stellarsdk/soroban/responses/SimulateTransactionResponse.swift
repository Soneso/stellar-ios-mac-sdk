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
    
    /// If error is present then results will not be in the response
    public var results:[SimulateTransactionResult]?
    
    /// Information about the fees expected, instructions used, etc.
    public var cost:SimulateTransactionCost
    
    /// Stringified-number of the current latest ledger observed by the node when this response was generated.
    public var latestLedger:String
    
    /// The recommended Soroban Transaction Data to use when submitting the simulated transaction. This data contains the refundable fee and resource usage information such as the ledger footprint and IO access data.
    public var transactionData:SorobanTransactionDataXDR?
    
    /// Recommended minimum resource fee to add when submitting the transaction. This fee is to be added on top of the Stellar network fee.
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
    
    private enum CodingKeys: String, CodingKey {
        case results
        case cost
        case latestLedger
        case transactionData
        case minResourceFee
        case events
        case error
        case restorePreamble
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        latestLedger = try values.decode(String.self, forKey: .latestLedger)
        cost = try values.decode(SimulateTransactionCost.self, forKey: .cost)
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
    }
    
    public var footprint:Footprint? {
        if let fxdr = transactionData?.resources.footprint {
            return Footprint(xdrFootprint: fxdr)
        }
        return nil;
    }
    
    public var sorobanAuth:[SorobanAuthorizationEntryXDR]? {
        if(results != nil && results!.count > 0) {
            if let auth = results![0].auth {
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
        }
        return nil;
    }
}

/// It can only present on successful simulation (i.e. no error) of InvokeHostFunction operations. If present, it indicates
/// the simulation detected expired ledger entries which requires restoring with the submission of a RestoreFootprint
/// operation before submitting the InvokeHostFunction operation. The restorePreamble.minResourceFee and restorePreamble.transactionData fields should
/// be used to construct the transaction containing the RestoreFootprint
public class RestorePreamble: NSObject, Decodable {
    
    /// The recommended Soroban Transaction Data to use when submitting the RestoreFootprint operation.
    public var transactionData:SorobanTransactionDataXDR?
    
    ///  Recommended minimum resource fee to add when submitting the RestoreFootprint operation. This fee is to be added on top of the Stellar network fee.
    public var minResourceFee:UInt32?

    private enum CodingKeys: String, CodingKey {
        case transactionData
        case minResourceFee
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let transactionDataXdrString = try values.decode(String.self, forKey: .transactionData)
        transactionData = try SorobanTransactionDataXDR(fromBase64: transactionDataXdrString)
        let resStr = try values.decode(String.self, forKey: .minResourceFee)
        minResourceFee = UInt32(resStr)
    }
}

