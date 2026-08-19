//
//  ContractIdUtils.swift
//  stellarsdk
//
//  Created by Soneso on 19.08.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

/// Contract id derivation.
public enum ContractIdUtils {

    /// Derives the contract id a deployment by the given deployer with the
    /// given salt creates on the given network.
    ///
    /// The id depends only on the deployer address, the salt and the network;
    /// the executable the contract is created with (wasm hash, CAP-85 external
    /// reference or Stellar asset) does not enter the derivation. Use it to
    /// know a contract's address before deploying, for example when the
    /// address is needed in constructor arguments of another contract.
    ///
    /// - Parameter deployer: the address the deployment is issued from (account or contract)
    /// - Parameter salt: the 32 byte salt the deployment uses
    /// - Parameter network: the network the contract is deployed to
    /// - Returns: the derived contract id ("C...")
    /// - Throws: StellarSDKError.invalidArgument if the salt is not exactly 32 bytes
    public static func deriveContractId(deployer: SCAddressXDR, salt: Data, network: Network) throws -> String {
        guard salt.count == 32 else {
            throw StellarSDKError.invalidArgument(message: "salt must be exactly 32 bytes, got \(salt.count)")
        }
        let fromAddress = ContractIDPreimageFromAddressXDR(address: deployer, salt: Uint256XDR(salt))
        let contractIdPreimage = ContractIDPreimageXDR.fromAddress(fromAddress)
        let hashIdPreimageContractId = HashIDPreimageContractIDXDR(
            networkID: HashXDR(network.networkId),
            contractIDPreimage: contractIdPreimage)
        let preimage = HashIDPreimageXDR.contractID(hashIdPreimageContractId)
        let encodedPreimage = Data(try XDREncoder.encode(preimage))
        return try encodedPreimage.sha256Hash.encodeContractId()
    }
}
