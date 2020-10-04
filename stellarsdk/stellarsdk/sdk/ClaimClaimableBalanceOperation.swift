//
//  ClaimClaimableBalanceOperation.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 02.10.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

/// Represents a claim claimable balance operation. Claimable Balances can be used to “split up” a payment into two parts, which allows the sending to only depend on the sending account, and the receipt to only depend on the receiving account.
/// See [Stellar Guides](https://developers.stellar.org/docs/glossary/claimable-balance "Claimable Balances").
public class ClaimClaimableBalanceOperation:Operation {
    
    public let balanceId:String
    
    /// Creates a new ClaimClaimableBalanceOperation object.
    ///
    /// - Parameter balanceId: The claimable balance id to be claimed.
    /// - Parameter sourceAccountId: The source account of the operation. Optional. Defaults to the transaction's source account.
    public init(balanceId:String, sourceAccountId:String? = nil) {
        self.balanceId = balanceId
        super.init(sourceAccountId:sourceAccountId)
    }
    
    /// Creates a new ClaimClaimableBalanceOperation object from the given ClaimClaimableBalanceOpXDR object.
    ///
    /// - Parameter fromXDR: the ClaimClaimableBalanceOpXDR object to be used to create a new ClaimClaimableBalanceOperation object.
    /// - Parameter sourceAccountId: (optional) source account Id, must be valid, otherwise it will be ignored.
    public init(fromXDR:ClaimClaimableBalanceOpXDR, sourceAccountId:String?) throws {
        switch fromXDR.balanceID {
        case .claimableBalanceIDTypeV0(let hash):
            self.balanceId = hash.wrapped.hexEncodedString()
        }
        super.init(sourceAccountId: sourceAccountId)
    }
    
    override func getOperationBodyXDR() throws -> OperationBodyXDR {
        
        let cIDXDR = ClaimableBalanceIDXDR.claimableBalanceIDTypeV0(ClaimClaimableBalanceOperation.wrappedDataFrom(balanceIdHexString:balanceId))
        let cbXDR = ClaimClaimableBalanceOpXDR(balanceID: cIDXDR)
        return OperationBodyXDR.claimClaimableBalance(cbXDR)
    }
    
    static func wrappedDataFrom(balanceIdHexString: String) -> WrappedData32 {
        var hex = balanceIdHexString
        // remove leading zeros
        while hex.hasPrefix("00") {
            hex = String(hex.dropFirst(2))
        }
        var data = Data()
        while(hex.count > 0) {
            let subIndex = hex.index(hex.startIndex, offsetBy: 2)
            let c = String(hex[..<subIndex])
            hex = String(hex[subIndex...])
            var ch: UInt32 = 0
            Scanner(string: c).scanHexInt32(&ch)
            var char = UInt8(ch)
            data.append(&char, count: 1)
        }
        return WrappedData32(data)
    }
}
