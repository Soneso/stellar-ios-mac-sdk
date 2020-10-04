//
//  RevokeSponsorshipOperation.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 04.10.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

/// The logic of this operation depends on the state of the source account.
/// If the source account is not sponsored or is sponsored by the owner of the specified entry or sub-entry, then attempt to revoke the sponsorship. If the source account is sponsored, the next step depends on whether the entry is sponsored or not. If it is sponsored, attempt to transfer the sponsorship to the sponsor of the source account. If the entry is not sponsored, then establish the sponsorship.
/// See [Stellar Guides](https://developers.stellar.org/docs/start/list-of-operations/#revoke-sponsorship "Revoke Sponsorship").
public class RevokeSponsorshipOperation:Operation {
    
    public let ledgerKey:LedgerKeyXDR?
    public let signerAccountId:String?
    public let signerKey:SignerKeyXDR?
    
    /// Creates a new RevokeSponsorshipOperation object.
    ///
    /// - Parameter ledgerKey: Ledger key that holds information to identify a specific ledgerEntry that may have it’s sponsorship modified.
    public init(ledgerKey:LedgerKeyXDR, sourceAccountId:String? = nil) {
        self.ledgerKey = ledgerKey
        self.signerAccountId = nil
        self.signerKey = nil
        super.init(sourceAccountId:sourceAccountId)
    }
    
    /// - Parameter signerAccountId: account id of Signer that may have it’s sponsorship modified.
    /// - Parameter signerKey: signerKey of Signer that may have it’s sponsorship modified.
    public init(signerAccountId:String, signerKey:SignerKeyXDR, sourceAccountId:String? = nil) {
        self.signerAccountId = signerAccountId
        self.signerKey = signerKey
        self.ledgerKey = nil
        super.init(sourceAccountId:sourceAccountId)
    }
    
    public static func revokeAccountSponsorshipLedgerKey(accountId:String) throws -> LedgerKeyXDR {
        let pk = try PublicKey(accountId: accountId)
        let value = LedgerKeyAccountXDR(accountID: pk)
        return LedgerKeyXDR.account(value)
    }
    
    public static func revokeDataSponsorshipLedgerKey(accountId:String, dataName:String) throws -> LedgerKeyXDR {
        let pk = try PublicKey(accountId: accountId)
        let value = LedgerKeyDataXDR(accountId: pk, dataName: dataName)
        return LedgerKeyXDR.data(value)
    }
    
    public static func revokeTrustlineSponsorshipLedgerKey(accountId:String, asset:Asset) throws -> LedgerKeyXDR {
        let pk = try PublicKey(accountId: accountId)
        let value = LedgerKeyTrustLineXDR(accountID: pk, asset: try asset.toXDR())
        return LedgerKeyXDR.trustline(value)
    }
    
    public static func revokeClaimableBalanceSponsorshipLedgerKey(balanceId:String) throws -> LedgerKeyXDR {
        let balanceIdData = ClaimClaimableBalanceOperation.wrappedDataFrom(balanceIdHexString:balanceId)
        let value = ClaimableBalanceIDXDR.claimableBalanceIDTypeV0(balanceIdData)
        return LedgerKeyXDR.claimableBalance(value)
    }
    
    public static func revokeOfferSponsorshipLedgerKey(sellerAccountId:String, offerId:UInt64) throws -> LedgerKeyXDR {
        let pk = try PublicKey(accountId: sellerAccountId)
        let value = LedgerKeyOfferXDR(sellerId: pk, offerId: offerId)
        return LedgerKeyXDR.offer(value)
    }
    
    /// Creates a new RevokeSponsorshipOperation object from the given RevokeSponsorshipOperationOpXDR object.
    ///
    /// - Parameter fromXDR: the RevokeSponsorshipOpXDR object to be used to create a new RevokeSponsorshipOperation object.
    /// - Parameter sourceAccountId: (optional) source account Id, must be valid, otherwise it will be ignored.
    public init(fromXDR:RevokeSponsorshipOpXDR, sourceAccountId:String?) throws {
        
        switch fromXDR {
        case .revokeSponsorshipLedgerEntry(let ledgerKey):
            self.ledgerKey = ledgerKey
            self.signerAccountId = nil
            self.signerKey = nil
        case .revokeSponsorshipSignerEntry(let signer):
            signerAccountId = signer.accountID.accountId
            signerKey = signer.signerKey
            self.ledgerKey = nil
        }
        super.init(sourceAccountId: sourceAccountId)
    }
    
    override func getOperationBodyXDR() throws -> OperationBodyXDR {
        
        if let lk = ledgerKey {
            let operation = RevokeSponsorshipOpXDR.revokeSponsorshipLedgerEntry(lk)
            return OperationBodyXDR.revokeSponsorship(operation)
        } else if let sid = signerAccountId, let sk = signerKey{
            let pk = try PublicKey(accountId: sid)
            let rsxdr = RevokeSponsorshipSignerXDR(accountID: pk, signerKey: sk)
            let operation = RevokeSponsorshipOpXDR.revokeSponsorshipSignerEntry(rsxdr)
            return OperationBodyXDR.revokeSponsorship(operation)
        } else {
            throw StellarSDKError.encodingError(message: "error xdr encoding revoke sponsorship operation, incomplete data")
        }
    }
}
