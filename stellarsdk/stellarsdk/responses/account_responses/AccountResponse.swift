//
//  AccountResponse.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 30/01/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents a Stellar account with all its properties and balances.
///
/// Contains complete account information including balances, signers, thresholds, flags,
/// sequence number, and sponsorship data. This is the main data structure returned when
/// querying account details from Horizon.
///
/// Example usage:
/// ```swift
/// let sdk = StellarSDK()
///
/// let response = await sdk.accounts.getAccountDetails(accountId: "GACCOUNT...")
/// switch response {
/// case .success(let account):
///     // Access account properties
///     print("Account ID: \(account.accountId)")
///     print("Sequence: \(account.sequenceNumber)")
///
///     // Check balances
///     for balance in account.balances {
///         if balance.assetType == AssetTypeAsString.NATIVE {
///             print("XLM Balance: \(balance.balance)")
///         } else {
///             print("\(balance.assetCode ?? ""): \(balance.balance)")
///         }
///     }
///
///     // Check signers
///     for signer in account.signers {
///         print("Signer: \(signer.key) weight: \(signer.weight)")
///     }
///
///     // Use for transaction building
///     let transaction = try Transaction(
///         sourceAccount: account,
///         operations: [/* ... */],
///         memo: Memo.none,
///         timeBounds: nil
///     )
/// case .failure(let error):
///     print("Error: \(error)")
/// }
/// ```
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
/// - AccountService for querying accounts
public class AccountResponse: NSObject, Decodable, TransactionAccount {

    /// Navigation links related to this account including transactions, operations, and payments.
    public var links:AccountLinksResponse

    /// The account ID (public key), always starts with 'G'.
    public var accountId:String

    /// KeyPair instance for this account containing the public key.
    public var keyPair: KeyPair

    /// Current sequence number. Must be incremented for each transaction from this account.
    public private(set) var sequenceNumber: Int64

    /// Number of subentries (trustlines, offers, data entries, etc.) owned by this account.
    /// Affects the minimum balance requirement.
    public var subentryCount:UInt

    /// Paging token for cursor-based pagination.
    public var pagingToken:String

    /// Account designated to receive inflation (deprecated feature).
    public var inflationDestination:String?

    /// Home domain for this account. Used for federation and stellar.toml lookup.
    public var homeDomain:String?

    /// Signature thresholds for low, medium, and high security operations.
    public var thresholds:AccountThresholdsResponse

    /// Account flags (auth required, auth revocable, auth immutable, auth clawback enabled).
    public var flags:AccountFlagsResponse

    /// Array of all asset balances including native XLM and issued assets.
    public var balances:[AccountBalanceResponse]

    /// Array of account signers with their public keys and signing weights.
    public var signers:[AccountSignerResponse]

    /// Key-value data entries attached to this account. Values are base64 encoded.
    public var data:[String:String]

    /// Account ID of the sponsor for this account's base reserve (if sponsored).
    public var sponsor:String?

    /// Number of reserves this account is currently sponsoring for other accounts.
    public var numSponsoring:Int

    /// Number of reserves being sponsored for this account by others.
    public var numSponsored:Int

    /// Ledger sequence number when the sequence number was last updated.
    public var sequenceLedger:Int?

    /// Timestamp when the sequence number was last updated (ISO 8601).
    public var sequenceTime:String?

    /// Ledger sequence number when this account was last modified.
    public var lastModifiedLedger:Int

    /// Timestamp when this account was last modified (ISO 8601).
    public var lastModifiedTime:String?
    
    // Properties to encode and decode
    enum CodingKeys: String, CodingKey {
        case links = "_links"
        case accountId = "account_id"
        case sequenceNumber = "sequence"
        case pagingToken = "paging_token"
        case subentryCount = "subentry_count"
        case inflationDestination = "inflation_destination"
        case homeDomain = "home_domain"
        case thresholds
        case flags
        case balances
        case signers
        case data
        case sponsor
        case numSponsoring = "num_sponsoring"
        case numSponsored = "num_sponsored"
        case sequenceLedger = "sequence_ledger"
        case sequenceTime = "sequence_time"
        case lastModifiedLedger = "last_modified_ledger"
        case lastModifiedTime = "last_modified_time"
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
    */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        links = try values.decode(AccountLinksResponse.self, forKey: .links)
        accountId = try values.decode(String.self, forKey: .accountId)
        self.keyPair = try KeyPair(accountId: accountId)
        let sequenceNumberString = try values.decode(String.self, forKey: .sequenceNumber)
        sequenceNumber = Int64(sequenceNumberString)!
        pagingToken = try values.decode(String.self, forKey: .pagingToken)
        subentryCount = try values.decode(UInt.self, forKey: .subentryCount)
        thresholds = try values.decode(AccountThresholdsResponse.self, forKey: .thresholds)
        flags = try values.decode(AccountFlagsResponse.self, forKey: .flags)
        balances = try values.decode(Array.self, forKey: .balances)
        signers = try values.decode(Array.self, forKey: .signers)
        data = try values.decode([String:String].self, forKey: .data)
        homeDomain = try values.decodeIfPresent(String.self, forKey: .homeDomain)
        inflationDestination = try values.decodeIfPresent(String.self, forKey: .inflationDestination)
        sponsor = try values.decodeIfPresent(String.self, forKey: .sponsor)
        if let ns = try values.decodeIfPresent(Int.self, forKey: .numSponsoring) {
            numSponsoring = ns
        } else {
            numSponsoring = 0
        }
        if let ns = try values.decodeIfPresent(Int.self, forKey: .numSponsored) {
            numSponsored = ns
        } else {
            numSponsored = 0
        }
        sequenceLedger = try values.decodeIfPresent(Int.self, forKey: .sequenceLedger)
        sequenceTime = try values.decodeIfPresent(String.self, forKey: .sequenceTime)
        lastModifiedLedger = try values.decode(Int.self, forKey: .lastModifiedLedger)
        lastModifiedTime = try values.decodeIfPresent(String.self, forKey: .lastModifiedTime)
            
    }
    
    ///  Returns sequence number incremented by one, but does not increment internal counter.
    public func incrementedSequenceNumber() -> Int64 {
        return sequenceNumber + 1
    }
    
    /// Increments sequence number in this object by one.
    public func incrementSequenceNumber() {
        sequenceNumber += 1
    }
    
    public func decrementSequenceNumber() {
        sequenceNumber -= 1
    }
}
