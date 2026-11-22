//
//  AssetContractIdUnitTests.swift
//  stellarsdkUnitTests
//
//  Created by Soneso on 22.11.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

/// Tests `Asset.contractId(network:)`, the id of an asset's Stellar Asset Contract.
final class AssetContractIdUnitTests: XCTestCase {

    private let xlmTestnetId = "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC"
    private let xlmPublicId = "CAS3J7GYLGXMF6TDJBBYYSE3HQ6BBSMLNUQ34T6TZMYMW2EVH34XOWMA"
    private let usdcPublicId = "CCW67TSZV3SSS2HXMBQ5JFGCKJNXKZM7UQUWUZPUTHXSTZLEO7SJMI75"
    private let testAssetTestnetId = "CBEFNXB7GMEO2PKBCOSKRUQBDWAH4PVA2RIREKPV335KM7MBK2HRLRGB"

    private func xlm() throws -> Asset {
        return try XCTUnwrap(Asset(type: AssetType.ASSET_TYPE_NATIVE))
    }

    private func usdc() throws -> Asset {
        return try XCTUnwrap(Asset(canonicalForm: "USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN"))
    }

    /// The id hashed from the contract id preimage of the operation that deploys the asset's
    /// contract.
    private func idOfDeployPreimage(_ asset: Asset, network: Network) throws -> String {
        let operation = try InvokeHostFunctionOperation.forDeploySACWithAsset(asset: asset)
        guard case .createContract(let arguments) = operation.hostFunction else {
            throw SACTestError("the deploy operation does not create a contract")
        }
        let preimage = HashIDPreimageXDR.contractID(HashIDPreimageContractIDXDR(
            networkID: HashXDR(network.passphrase.sha256Hash),
            contractIDPreimage: arguments.contractIDPreimage))
        return try Data(try XDREncoder.encode(preimage)).sha256Hash.encodeContractId()
    }

    func testNativeAssetOnTestnet() throws {
        let id = try xlm().contractId(network: Network.testnet)

        XCTAssertEqual(id, xlmTestnetId)
        XCTAssertEqual(try id.decodeContractIdToHex(), "d7928b72c2703ccfeaf7eb9ff4ef4d504a55a8b979fc9b450ea2c842b4d1ce61")
    }

    func testNativeAssetOnPublic() throws {
        XCTAssertEqual(try xlm().contractId(network: Network.public), xlmPublicId)
    }

    func testIssuedAssetOnPublic() throws {
        XCTAssertEqual(try usdc().contractId(network: Network.public), usdcPublicId)
    }

    /// An alphanumeric 12 asset, through the `ChangeTrustAsset` subclass.
    func testIssuedAssetOnTestnet() throws {
        let asset = try XCTUnwrap(ChangeTrustAsset(canonicalForm: "TESTASSET:GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX"))

        XCTAssertEqual(try asset.contractId(network: Network.testnet), testAssetTestnetId)
    }

    func testOneAssetHasDifferentIdsOnTestnetAndPublic() throws {
        let asset = try usdc()
        let testnetId = try asset.contractId(network: Network.testnet)
        let publicId = try asset.contractId(network: Network.public)

        XCTAssertEqual(publicId, usdcPublicId)
        XCTAssertTrue(testnetId.isValidContractId())
        XCTAssertNotEqual(testnetId, publicId)
    }

    func testIdEqualsTheHashOfTheDeployPreimage() throws {
        XCTAssertEqual(try idOfDeployPreimage(try xlm(), network: Network.testnet), xlmTestnetId)
        XCTAssertEqual(try idOfDeployPreimage(try xlm(), network: Network.testnet), try xlm().contractId(network: Network.testnet))

        XCTAssertEqual(try idOfDeployPreimage(try usdc(), network: Network.public), usdcPublicId)
        XCTAssertEqual(try idOfDeployPreimage(try usdc(), network: Network.public), try usdc().contractId(network: Network.public))
    }

    func testPoolShareThrows() throws {
        let poolShare = try XCTUnwrap(try ChangeTrustAsset(assetA: try xlm(), assetB: try usdc()))

        XCTAssertThrowsError(try poolShare.contractId(network: Network.testnet)) { error in
            guard case StellarSDKError.xdrEncodingError(let message) = error else {
                XCTFail("expected StellarSDKError.xdrEncodingError, got \(error)")
                return
            }
            XCTAssertEqual(message, "A liquidity pool share has no Stellar Asset Contract; contractId(network:) takes the native asset or an issued asset")
        }
    }
}
