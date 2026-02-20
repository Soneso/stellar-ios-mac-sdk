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
/// See [Stellar developer docs](https://developers.stellar.org).
public class RevokeSponsorshipOperation:Operation, @unchecked Sendable {

    /// The ledger key identifying the ledger entry whose sponsorship is being modified.
    public let ledgerKey:LedgerKeyXDR?
    /// The account ID of the signer whose sponsorship is being modified.
    public let signerAccountId:String?
    /// The signer key whose sponsorship is being modified.
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
    
    /// Creates a ledger key for revoking sponsorship of an account entry.
    /// - Parameter accountId: The account ID whose sponsorship will be revoked.
    /// - Returns: A ledger key identifying the account entry.
    public static func revokeAccountSponsorshipLedgerKey(accountId:String) throws -> LedgerKeyXDR {
        let pk = try PublicKey(accountId: accountId)
        let value = LedgerKeyAccountXDR(accountID: pk)
        return LedgerKeyXDR.account(value)
    }
    
    /// Creates a ledger key for revoking sponsorship of a data entry.
    /// - Parameters:
    ///   - accountId: The account ID that owns the data entry.
    ///   - dataName: The name of the data entry whose sponsorship will be revoked.
    /// - Returns: A ledger key identifying the data entry.
    public static func revokeDataSponsorshipLedgerKey(accountId:String, dataName:String) throws -> LedgerKeyXDR {
        let pk = try PublicKey(accountId: accountId)
        let value = LedgerKeyDataXDR(accountId: pk, dataName: dataName)
        return LedgerKeyXDR.data(value)
    }
    
    /// Creates a ledger key for revoking sponsorship of a trustline entry.
    /// - Parameters:
    ///   - accountId: The account ID that owns the trustline.
    ///   - asset: The asset of the trustline whose sponsorship will be revoked.
    /// - Returns: A ledger key identifying the trustline entry.
    public static func revokeTrustlineSponsorshipLedgerKey(accountId:String, asset:Asset) throws -> LedgerKeyXDR {
        let pk = try PublicKey(accountId: accountId)
        let value = LedgerKeyTrustLineXDR(accountID: pk, asset: try asset.toTrustlineAssetXDR())
        return LedgerKeyXDR.trustline(value)
    }
    
    /// Creates a ledger key for revoking sponsorship of a claimable balance entry.
    /// - Parameter balanceId: The claimable balance ID whose sponsorship will be revoked.
    /// - Returns: A ledger key identifying the claimable balance entry.
    public static func revokeClaimableBalanceSponsorshipLedgerKey(balanceId:String) throws -> LedgerKeyXDR {
        let value = try ClaimableBalanceIDXDR(claimableBalanceId: balanceId)
        return LedgerKeyXDR.claimableBalance(value)
    }
    
    /// Creates a ledger key for revoking sponsorship of an offer entry.
    /// - Parameters:
    ///   - sellerAccountId: The account ID of the seller who owns the offer.
    ///   - offerId: The offer ID whose sponsorship will be revoked.
    /// - Returns: A ledger key identifying the offer entry.
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
