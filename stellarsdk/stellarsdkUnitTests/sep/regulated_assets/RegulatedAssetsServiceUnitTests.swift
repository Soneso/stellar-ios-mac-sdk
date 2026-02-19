//
//  RegulatedAssetsServiceUnitTests.swift
//  stellarsdk
//
//  Created by Soneso on 2026-02-04.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

final class RegulatedAssetsServiceUnitTests: XCTestCase {

    let sep08Server = "127.0.0.1"
    let horizonServer = "horizon-testnet.stellar.org"

    // Test issuer account with AUTH_REQUIRED and AUTH_REVOCABLE flags
    let regulatedIssuerAccountId = "GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP"
    // Test issuer account without authorization flags
    let nonRegulatedIssuerAccountId = "GDIODQRBHD32QZWTGOHO2MRZQY2TRG5KTI2NNTFYH2JDYZGMU3NJVAUI"

    var sep08PostTransactionSuccessMock: Sep08PostTransactionSuccessMock!
    var sep08PostTransactionRevisedMock: Sep08PostTransactionRevisedMock!
    var sep08PostTransactionPendingMock: Sep08PostTransactionPendingMock!
    var sep08PostTransactionPendingMinimalMock: Sep08PostTransactionPendingMinimalMock!
    var sep08PostTransactionActionRequiredMock: Sep08PostTransactionActionRequiredMock!
    var sep08PostTransactionActionRequiredMinimalMock: Sep08PostTransactionActionRequiredMinimalMock!
    var sep08PostTransactionRejectedMock: Sep08PostTransactionRejectedMock!
    var sep08PostTransactionBadRequestRejectedMock: Sep08PostTransactionBadRequestRejectedMock!
    var sep08PostTransactionUnknownStatusMock: Sep08PostTransactionUnknownStatusMock!
    var sep08PostTransactionServerErrorMock: Sep08PostTransactionServerErrorMock!
    var sep08PostActionDoneMock: Sep08PostActionDoneMock!
    var sep08PostActionNextUrlMock: Sep08PostActionNextUrlMock!
    var sep08PostActionUnknownMock: Sep08PostActionUnknownMock!
    var sep08PostActionErrorMock: Sep08PostActionErrorMock!

    override func setUp() {
        super.setUp()

        URLProtocol.registerClass(ServerMock.self)

        sep08PostTransactionSuccessMock = Sep08PostTransactionSuccessMock(address: sep08Server)
        sep08PostTransactionRevisedMock = Sep08PostTransactionRevisedMock(address: sep08Server)
        sep08PostTransactionPendingMock = Sep08PostTransactionPendingMock(address: sep08Server)
        sep08PostTransactionPendingMinimalMock = Sep08PostTransactionPendingMinimalMock(address: sep08Server)
        sep08PostTransactionActionRequiredMock = Sep08PostTransactionActionRequiredMock(address: sep08Server)
        sep08PostTransactionActionRequiredMinimalMock = Sep08PostTransactionActionRequiredMinimalMock(address: sep08Server)
        sep08PostTransactionRejectedMock = Sep08PostTransactionRejectedMock(address: sep08Server)
        sep08PostTransactionBadRequestRejectedMock = Sep08PostTransactionBadRequestRejectedMock(address: sep08Server)
        sep08PostTransactionUnknownStatusMock = Sep08PostTransactionUnknownStatusMock(address: sep08Server)
        sep08PostTransactionServerErrorMock = Sep08PostTransactionServerErrorMock(address: sep08Server)
        sep08PostActionDoneMock = Sep08PostActionDoneMock(address: sep08Server)
        sep08PostActionNextUrlMock = Sep08PostActionNextUrlMock(address: sep08Server)
        sep08PostActionUnknownMock = Sep08PostActionUnknownMock(address: sep08Server)
        sep08PostActionErrorMock = Sep08PostActionErrorMock(address: sep08Server)
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: - Service Initialization Tests

    func testInitWithTomlDataAndNetwork() throws {
        let tomlString = """
        NETWORK_PASSPHRASE = "Test SDF Network ; September 2015"
        HORIZON_URL = "https://horizon-testnet.stellar.org"

        [DOCUMENTATION]
        ORG_NAME = "Test Regulated Assets Issuer"

        [[CURRENCIES]]
        code = "REG"
        issuer = "\(regulatedIssuerAccountId)"
        regulated = true
        approval_server = "https://approval.example.com"
        approval_criteria = "Must pass KYC verification"
        """

        let toml = try StellarToml(fromString: tomlString)
        let service = try RegulatedAssetsService(tomlData: toml, network: .testnet)

        XCTAssertEqual(service.network.passphrase, Network.testnet.passphrase, "Should use testnet passphrase")
        XCTAssertEqual(service.regulatedAssets.count, 1, "Should have one regulated asset")
        XCTAssertEqual(service.regulatedAssets[0].assetCode, "REG")
        XCTAssertEqual(service.regulatedAssets[0].issuerId, regulatedIssuerAccountId)
        XCTAssertEqual(service.regulatedAssets[0].approvalServer, "https://approval.example.com")
        XCTAssertEqual(service.regulatedAssets[0].approvalCriteria, "Must pass KYC verification")
    }

    func testInitWithTomlDataDeriveNetworkFromPassphrase() throws {
        let tomlString = """
        NETWORK_PASSPHRASE = "Test SDF Network ; September 2015"
        HORIZON_URL = "https://horizon-testnet.stellar.org"

        [DOCUMENTATION]
        ORG_NAME = "Test Issuer"

        [[CURRENCIES]]
        code = "TST"
        issuer = "\(regulatedIssuerAccountId)"
        regulated = true
        approval_server = "https://approval.example.com"
        """

        let toml = try StellarToml(fromString: tomlString)
        let service = try RegulatedAssetsService(tomlData: toml)

        XCTAssertEqual(service.network.passphrase, "Test SDF Network ; September 2015", "Should derive network from TOML passphrase")
        XCTAssertEqual(service.regulatedAssets.count, 1)
        XCTAssertEqual(service.regulatedAssets[0].assetCode, "TST")
    }

    func testInitWithCustomHorizonUrl() throws {
        let tomlString = """
        NETWORK_PASSPHRASE = "Test SDF Network ; September 2015"
        HORIZON_URL = "https://horizon-testnet.stellar.org"

        [DOCUMENTATION]
        ORG_NAME = "Test Issuer"

        [[CURRENCIES]]
        code = "TST"
        issuer = "\(regulatedIssuerAccountId)"
        regulated = true
        approval_server = "https://approval.example.com"
        """

        let toml = try StellarToml(fromString: tomlString)
        let customHorizon = "https://custom-horizon.example.com"
        let service = try RegulatedAssetsService(tomlData: toml, horizonUrl: customHorizon)

        XCTAssertEqual(service.sdk.horizonURL, customHorizon, "Service should use custom Horizon URL")
        XCTAssertEqual(service.network.passphrase, "Test SDF Network ; September 2015")
    }

    func testInitWithMissingNetworkThrows() throws {
        let tomlString = """
        [DOCUMENTATION]
        ORG_NAME = "Test Issuer"
        """

        let toml = try StellarToml(fromString: tomlString)

        XCTAssertThrowsError(try RegulatedAssetsService(tomlData: toml)) { error in
            if case RegulatedAssetsServiceError.invalidToml = error {
                // Expected error
            } else {
                XCTFail("Should throw invalidToml error")
            }
        }
    }

    func testInitWithPublicNetwork() throws {
        let tomlString = """
        NETWORK_PASSPHRASE = "Public Global Stellar Network ; September 2015"

        [DOCUMENTATION]
        ORG_NAME = "Test Issuer"

        [[CURRENCIES]]
        code = "USD"
        issuer = "\(regulatedIssuerAccountId)"
        regulated = true
        approval_server = "https://approval.example.com"
        """

        let toml = try StellarToml(fromString: tomlString)
        let service = try RegulatedAssetsService(tomlData: toml)

        XCTAssertEqual(service.network.passphrase, Network.public.passphrase, "Service should use public network passphrase")
        XCTAssertEqual(service.sdk.horizonURL, "https://horizon.stellar.org", "Should use default public Horizon URL")
    }

    func testInitWithTestnetFromPassphrase() throws {
        let tomlString = """
        NETWORK_PASSPHRASE = "Test SDF Network ; September 2015"

        [DOCUMENTATION]
        ORG_NAME = "Test Issuer"

        [[CURRENCIES]]
        code = "TST"
        issuer = "\(regulatedIssuerAccountId)"
        regulated = true
        approval_server = "https://approval.example.com"
        """

        let toml = try StellarToml(fromString: tomlString)
        let service = try RegulatedAssetsService(tomlData: toml)

        XCTAssertEqual(service.network.passphrase, Network.testnet.passphrase, "Service should use testnet passphrase")
        XCTAssertEqual(service.sdk.horizonURL, "https://horizon-testnet.stellar.org", "Should use default testnet Horizon URL")
    }

    func testInitWithFuturenetFromPassphrase() throws {
        let tomlString = """
        NETWORK_PASSPHRASE = "Test SDF Future Network ; October 2022"

        [DOCUMENTATION]
        ORG_NAME = "Test Issuer"

        [[CURRENCIES]]
        code = "TST"
        issuer = "\(regulatedIssuerAccountId)"
        regulated = true
        approval_server = "https://approval.example.com"
        """

        let toml = try StellarToml(fromString: tomlString)
        let service = try RegulatedAssetsService(tomlData: toml)

        XCTAssertEqual(service.network.passphrase, Network.futurenet.passphrase, "Service should use futurenet passphrase")
        XCTAssertEqual(service.sdk.horizonURL, "https://horizon-futurenet.stellar.org", "Should use default futurenet Horizon URL")
    }

    func testInitWithCustomNetworkAndNoHorizonUrlThrows() throws {
        let tomlString = """
        NETWORK_PASSPHRASE = "Custom Test Network"

        [DOCUMENTATION]
        ORG_NAME = "Test Issuer"
        """

        let toml = try StellarToml(fromString: tomlString)

        XCTAssertThrowsError(try RegulatedAssetsService(tomlData: toml)) { error in
            if case RegulatedAssetsServiceError.invalidToml = error {
                // Expected error
            } else {
                XCTFail("Should throw invalidToml error for custom network without Horizon URL")
            }
        }
    }

    // MARK: - forDomain() Static Method Tests

    func testForDomainSuccess() async throws {
        let domainServer = "example.com"
        let tomlMock = Sep08TomlSuccessMock(address: domainServer)

        let result = await RegulatedAssetsService.forDomain(
            domain: "http://\(domainServer)",
            network: .testnet
        )

        _ = tomlMock // Keep mock alive

        switch result {
        case .success(let service):
            XCTAssertEqual(service.network.passphrase, Network.testnet.passphrase, "Should use testnet passphrase from TOML")
            XCTAssertEqual(service.regulatedAssets.count, 1, "Should have one regulated asset")
            XCTAssertEqual(service.regulatedAssets[0].assetCode, "USD")
            XCTAssertEqual(service.regulatedAssets[0].approvalServer, "https://approval.example.com")
        case .failure(let error):
            XCTFail("Should succeed, got error: \(error)")
        }
    }

    func testForDomainInvalidUrl() async throws {
        let result = await RegulatedAssetsService.forDomain(
            domain: "not a valid url with spaces",
            network: .testnet
        )

        switch result {
        case .success(_):
            XCTFail("Should fail with invalid domain URL")
        case .failure(let error):
            // SDK may return either invalidDomain or invalidToml depending on URL parsing behavior
            if case RegulatedAssetsServiceError.invalidDomain = error {
                // Expected error
            } else if case RegulatedAssetsServiceError.invalidToml = error {
                // Also acceptable - URL parsing may succeed but TOML fetch fails
            } else {
                XCTFail("Should return invalidDomain or invalidToml error, got: \(error)")
            }
        }
    }

    func testForDomainInvalidToml() async throws {
        let domainServer = "invalid-toml.com"
        let tomlMock = Sep08TomlInvalidMock(address: domainServer)

        let result = await RegulatedAssetsService.forDomain(
            domain: "http://\(domainServer)",
            network: .testnet
        )

        _ = tomlMock // Keep mock alive

        switch result {
        case .success(_):
            XCTFail("Should fail when TOML is invalid")
        case .failure(let error):
            if case RegulatedAssetsServiceError.invalidToml = error {
                // Expected error
            } else {
                XCTFail("Should return invalidToml error, got: \(error)")
            }
        }
    }

    func testForDomainMissingToml() async throws {
        let domainServer = "missing-toml.com"
        let tomlMock = Sep08TomlMissingMock(address: domainServer)

        let result = await RegulatedAssetsService.forDomain(
            domain: "http://\(domainServer)",
            network: .testnet
        )

        _ = tomlMock // Keep mock alive

        switch result {
        case .success(_):
            XCTFail("Should fail when TOML is missing")
        case .failure(let error):
            if case RegulatedAssetsServiceError.invalidToml = error {
                // Expected error - SDK returns invalidToml for fetch failures
            } else {
                XCTFail("Should return invalidToml error, got: \(error)")
            }
        }
    }

    func testForDomainNetworkFailure() async throws {
        // Test with a domain that will fail to fetch (non-existent local address)
        let result = await RegulatedAssetsService.forDomain(
            domain: "http://localhost:9999999",
            network: .testnet
        )

        switch result {
        case .success(_):
            XCTFail("Should fail when TOML cannot be fetched")
        case .failure(let error):
            if case RegulatedAssetsServiceError.invalidToml = error {
                // Expected error - SDK returns invalidToml for all fetch/parse failures
            } else {
                XCTFail("Should return invalidToml error, got: \(error)")
            }
        }
    }

    // MARK: - Regulated Assets Parsing Tests

    func testParseMultipleRegulatedAssets() throws {
        let tomlString = """
        NETWORK_PASSPHRASE = "Test SDF Network ; September 2015"
        HORIZON_URL = "https://horizon-testnet.stellar.org"

        [DOCUMENTATION]
        ORG_NAME = "Test Issuer"

        [[CURRENCIES]]
        code = "REG1"
        issuer = "\(regulatedIssuerAccountId)"
        regulated = true
        approval_server = "https://approval1.example.com"
        approval_criteria = "Criteria 1"

        [[CURRENCIES]]
        code = "REG2"
        issuer = "\(regulatedIssuerAccountId)"
        regulated = true
        approval_server = "https://approval2.example.com"

        [[CURRENCIES]]
        code = "UNREG"
        issuer = "\(nonRegulatedIssuerAccountId)"
        regulated = false
        """

        let toml = try StellarToml(fromString: tomlString)
        let service = try RegulatedAssetsService(tomlData: toml, network: .testnet)

        // Should only include regulated assets
        XCTAssertEqual(service.regulatedAssets.count, 2, "Should have two regulated assets")

        // Verify first regulated asset
        let reg1 = service.regulatedAssets.first { $0.assetCode == "REG1" }
        XCTAssertNotNil(reg1, "Should find REG1 asset")
        XCTAssertEqual(reg1?.approvalServer, "https://approval1.example.com")
        XCTAssertEqual(reg1?.approvalCriteria, "Criteria 1")
        XCTAssertEqual(reg1?.issuerId, regulatedIssuerAccountId)

        // Verify second regulated asset
        let reg2 = service.regulatedAssets.first { $0.assetCode == "REG2" }
        XCTAssertNotNil(reg2, "Should find REG2 asset")
        XCTAssertEqual(reg2?.approvalServer, "https://approval2.example.com")
        XCTAssertNil(reg2?.approvalCriteria)
        XCTAssertEqual(reg2?.issuerId, regulatedIssuerAccountId)
    }

    func testParseCurrencyWithoutApprovalServerIgnored() throws {
        let tomlString = """
        NETWORK_PASSPHRASE = "Test SDF Network ; September 2015"
        HORIZON_URL = "https://horizon-testnet.stellar.org"

        [DOCUMENTATION]
        ORG_NAME = "Test Issuer"

        [[CURRENCIES]]
        code = "REG"
        issuer = "\(regulatedIssuerAccountId)"
        regulated = true
        """

        let toml = try StellarToml(fromString: tomlString)
        let service = try RegulatedAssetsService(tomlData: toml, network: .testnet)

        XCTAssertEqual(service.regulatedAssets.count, 0, "Asset without approval_server should be ignored")
    }

    func testParseShortAssetCodeAsAlphanum4() throws {
        let tomlString = """
        NETWORK_PASSPHRASE = "Test SDF Network ; September 2015"
        HORIZON_URL = "https://horizon-testnet.stellar.org"

        [DOCUMENTATION]
        ORG_NAME = "Test Issuer"

        [[CURRENCIES]]
        code = "USD"
        issuer = "\(regulatedIssuerAccountId)"
        regulated = true
        approval_server = "https://approval.example.com"
        """

        let toml = try StellarToml(fromString: tomlString)
        let service = try RegulatedAssetsService(tomlData: toml, network: .testnet)

        XCTAssertEqual(service.regulatedAssets.count, 1)
        XCTAssertEqual(service.regulatedAssets[0].type, AssetType.ASSET_TYPE_CREDIT_ALPHANUM4)
    }

    func testParseLongAssetCodeAsAlphanum12() throws {
        let tomlString = """
        NETWORK_PASSPHRASE = "Test SDF Network ; September 2015"
        HORIZON_URL = "https://horizon-testnet.stellar.org"

        [DOCUMENTATION]
        ORG_NAME = "Test Issuer"

        [[CURRENCIES]]
        code = "REGULATED"
        issuer = "\(regulatedIssuerAccountId)"
        regulated = true
        approval_server = "https://approval.example.com"
        """

        let toml = try StellarToml(fromString: tomlString)
        let service = try RegulatedAssetsService(tomlData: toml, network: .testnet)

        XCTAssertEqual(service.regulatedAssets.count, 1)
        XCTAssertEqual(service.regulatedAssets[0].type, AssetType.ASSET_TYPE_CREDIT_ALPHANUM12)
    }

    func testParseNoCurrenciesSection() throws {
        let tomlString = """
        NETWORK_PASSPHRASE = "Test SDF Network ; September 2015"
        HORIZON_URL = "https://horizon-testnet.stellar.org"

        [DOCUMENTATION]
        ORG_NAME = "Test Issuer"
        """

        let toml = try StellarToml(fromString: tomlString)
        let service = try RegulatedAssetsService(tomlData: toml, network: .testnet)

        XCTAssertEqual(service.regulatedAssets.count, 0, "Should have no regulated assets")
    }

    // MARK: - Post Transaction Tests

    func testPostTransactionSuccess() async throws {
        let tomlString = """
        NETWORK_PASSPHRASE = "Test SDF Network ; September 2015"
        HORIZON_URL = "https://horizon-testnet.stellar.org"

        [DOCUMENTATION]
        ORG_NAME = "Test Issuer"

        [[CURRENCIES]]
        code = "REG"
        issuer = "\(regulatedIssuerAccountId)"
        regulated = true
        approval_server = "http://\(sep08Server)/success"
        """

        let toml = try StellarToml(fromString: tomlString)
        let service = try RegulatedAssetsService(tomlData: toml, network: .testnet)

        let txXdr = "AAAAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGVtcHR5X3R4X2Jhc2U2NA=="
        let result = await service.postTransaction(txB64Xdr: txXdr, apporvalServer: "http://\(sep08Server)/success")

        switch result {
        case .success(let response):
            XCTAssertEqual(response.tx, "signed_tx_xdr_base64")
            XCTAssertEqual(response.message, "Transaction approved")
        case .revised(_):
            XCTFail("Should return success, not revised")
        case .pending(_):
            XCTFail("Should return success, not pending")
        case .actionRequired(_):
            XCTFail("Should return success, not actionRequired")
        case .rejected(_):
            XCTFail("Should return success, not rejected")
        case .failure(let error):
            XCTFail("Should not fail: \(error)")
        }
    }

    func testPostTransactionRevised() async throws {
        let tomlString = """
        NETWORK_PASSPHRASE = "Test SDF Network ; September 2015"
        HORIZON_URL = "https://horizon-testnet.stellar.org"

        [DOCUMENTATION]
        ORG_NAME = "Test Issuer"

        [[CURRENCIES]]
        code = "REG"
        issuer = "\(regulatedIssuerAccountId)"
        regulated = true
        approval_server = "http://\(sep08Server)/revised"
        """

        let toml = try StellarToml(fromString: tomlString)
        let service = try RegulatedAssetsService(tomlData: toml, network: .testnet)

        let txXdr = "AAAAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGVtcHR5X3R4X2Jhc2U2NA=="
        let result = await service.postTransaction(txB64Xdr: txXdr, apporvalServer: "http://\(sep08Server)/revised")

        switch result {
        case .success(_):
            XCTFail("Should return revised, not success")
        case .revised(let response):
            XCTAssertEqual(response.tx, "revised_tx_xdr_base64")
            XCTAssertEqual(response.message, "Transaction revised to add compliance fee")
        case .pending(_):
            XCTFail("Should return revised, not pending")
        case .actionRequired(_):
            XCTFail("Should return revised, not actionRequired")
        case .rejected(_):
            XCTFail("Should return revised, not rejected")
        case .failure(let error):
            XCTFail("Should not fail: \(error)")
        }
    }

    func testPostTransactionPending() async throws {
        let tomlString = """
        NETWORK_PASSPHRASE = "Test SDF Network ; September 2015"
        HORIZON_URL = "https://horizon-testnet.stellar.org"

        [DOCUMENTATION]
        ORG_NAME = "Test Issuer"

        [[CURRENCIES]]
        code = "REG"
        issuer = "\(regulatedIssuerAccountId)"
        regulated = true
        approval_server = "http://\(sep08Server)/pending"
        """

        let toml = try StellarToml(fromString: tomlString)
        let service = try RegulatedAssetsService(tomlData: toml, network: .testnet)

        let txXdr = "AAAAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGVtcHR5X3R4X2Jhc2U2NA=="
        let result = await service.postTransaction(txB64Xdr: txXdr, apporvalServer: "http://\(sep08Server)/pending")

        switch result {
        case .success(_):
            XCTFail("Should return pending, not success")
        case .revised(_):
            XCTFail("Should return pending, not revised")
        case .pending(let response):
            XCTAssertEqual(response.timeout, 3600)
            XCTAssertEqual(response.message, "Approval pending, please wait")
        case .actionRequired(_):
            XCTFail("Should return pending, not actionRequired")
        case .rejected(_):
            XCTFail("Should return pending, not rejected")
        case .failure(let error):
            XCTFail("Should not fail: \(error)")
        }
    }

    func testPostTransactionPendingWithoutOptionalFields() async throws {
        let tomlString = """
        NETWORK_PASSPHRASE = "Test SDF Network ; September 2015"
        HORIZON_URL = "https://horizon-testnet.stellar.org"

        [DOCUMENTATION]
        ORG_NAME = "Test Issuer"

        [[CURRENCIES]]
        code = "REG"
        issuer = "\(regulatedIssuerAccountId)"
        regulated = true
        approval_server = "http://\(sep08Server)/pending_minimal"
        """

        let toml = try StellarToml(fromString: tomlString)
        let service = try RegulatedAssetsService(tomlData: toml, network: .testnet)

        let txXdr = "AAAAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGVtcHR5X3R4X2Jhc2U2NA=="
        let result = await service.postTransaction(txB64Xdr: txXdr, apporvalServer: "http://\(sep08Server)/pending_minimal")

        switch result {
        case .pending(let response):
            XCTAssertEqual(response.timeout, 0, "Timeout should default to 0 when not provided")
            XCTAssertNil(response.message, "Message should be nil when not provided")
        default:
            XCTFail("Should return pending")
        }
    }

    func testPostTransactionActionRequired() async throws {
        let tomlString = """
        NETWORK_PASSPHRASE = "Test SDF Network ; September 2015"
        HORIZON_URL = "https://horizon-testnet.stellar.org"

        [DOCUMENTATION]
        ORG_NAME = "Test Issuer"

        [[CURRENCIES]]
        code = "REG"
        issuer = "\(regulatedIssuerAccountId)"
        regulated = true
        approval_server = "http://\(sep08Server)/action_required"
        """

        let toml = try StellarToml(fromString: tomlString)
        let service = try RegulatedAssetsService(tomlData: toml, network: .testnet)

        let txXdr = "AAAAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGVtcHR5X3R4X2Jhc2U2NA=="
        let result = await service.postTransaction(txB64Xdr: txXdr, apporvalServer: "http://\(sep08Server)/action_required")

        switch result {
        case .success(_):
            XCTFail("Should return actionRequired, not success")
        case .revised(_):
            XCTFail("Should return actionRequired, not revised")
        case .pending(_):
            XCTFail("Should return actionRequired, not pending")
        case .actionRequired(let response):
            XCTAssertEqual(response.message, "Please complete KYC verification")
            XCTAssertEqual(response.actionUrl, "https://kyc.example.com/verify")
            XCTAssertEqual(response.actionMethod, "POST")
            XCTAssertNotNil(response.actionFields)
            XCTAssertEqual(response.actionFields?.count, 2)
            XCTAssertTrue(response.actionFields?.contains("email") ?? false)
            XCTAssertTrue(response.actionFields?.contains("kyc_id") ?? false)
        case .rejected(_):
            XCTFail("Should return actionRequired, not rejected")
        case .failure(let error):
            XCTFail("Should not fail: \(error)")
        }
    }

    func testPostTransactionActionRequiredDefaultMethod() async throws {
        let tomlString = """
        NETWORK_PASSPHRASE = "Test SDF Network ; September 2015"
        HORIZON_URL = "https://horizon-testnet.stellar.org"

        [DOCUMENTATION]
        ORG_NAME = "Test Issuer"

        [[CURRENCIES]]
        code = "REG"
        issuer = "\(regulatedIssuerAccountId)"
        regulated = true
        approval_server = "http://\(sep08Server)/action_required_minimal"
        """

        let toml = try StellarToml(fromString: tomlString)
        let service = try RegulatedAssetsService(tomlData: toml, network: .testnet)

        let txXdr = "AAAAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGVtcHR5X3R4X2Jhc2U2NA=="
        let result = await service.postTransaction(txB64Xdr: txXdr, apporvalServer: "http://\(sep08Server)/action_required_minimal")

        switch result {
        case .actionRequired(let response):
            XCTAssertEqual(response.actionMethod, "GET", "Default action method should be GET")
            XCTAssertNil(response.actionFields, "Action fields should be nil when not provided")
        default:
            XCTFail("Should return actionRequired")
        }
    }

    func testPostTransactionRejected() async throws {
        let tomlString = """
        NETWORK_PASSPHRASE = "Test SDF Network ; September 2015"
        HORIZON_URL = "https://horizon-testnet.stellar.org"

        [DOCUMENTATION]
        ORG_NAME = "Test Issuer"

        [[CURRENCIES]]
        code = "REG"
        issuer = "\(regulatedIssuerAccountId)"
        regulated = true
        approval_server = "http://\(sep08Server)/rejected"
        """

        let toml = try StellarToml(fromString: tomlString)
        let service = try RegulatedAssetsService(tomlData: toml, network: .testnet)

        let txXdr = "AAAAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGVtcHR5X3R4X2Jhc2U2NA=="
        let result = await service.postTransaction(txB64Xdr: txXdr, apporvalServer: "http://\(sep08Server)/rejected")

        switch result {
        case .success(_):
            XCTFail("Should return rejected, not success")
        case .revised(_):
            XCTFail("Should return rejected, not revised")
        case .pending(_):
            XCTFail("Should return rejected, not pending")
        case .actionRequired(_):
            XCTFail("Should return rejected, not actionRequired")
        case .rejected(let response):
            XCTAssertEqual(response.error, "Transaction violates compliance requirements")
        case .failure(let error):
            XCTFail("Should not fail: \(error)")
        }
    }

    func testPostTransactionRejectedWithBadRequest() async throws {
        let tomlString = """
        NETWORK_PASSPHRASE = "Test SDF Network ; September 2015"
        HORIZON_URL = "https://horizon-testnet.stellar.org"

        [DOCUMENTATION]
        ORG_NAME = "Test Issuer"

        [[CURRENCIES]]
        code = "REG"
        issuer = "\(regulatedIssuerAccountId)"
        regulated = true
        approval_server = "http://\(sep08Server)/bad_request_rejected"
        """

        let toml = try StellarToml(fromString: tomlString)
        let service = try RegulatedAssetsService(tomlData: toml, network: .testnet)

        let txXdr = "AAAAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGVtcHR5X3R4X2Jhc2U2NA=="
        let result = await service.postTransaction(txB64Xdr: txXdr, apporvalServer: "http://\(sep08Server)/bad_request_rejected")

        switch result {
        case .rejected(let response):
            XCTAssertEqual(response.error, "Transaction rejected due to compliance violation")
        default:
            XCTFail("Should return rejected even with 400 status code")
        }
    }

    func testPostTransactionUnknownStatus() async throws {
        let tomlString = """
        NETWORK_PASSPHRASE = "Test SDF Network ; September 2015"
        HORIZON_URL = "https://horizon-testnet.stellar.org"

        [DOCUMENTATION]
        ORG_NAME = "Test Issuer"

        [[CURRENCIES]]
        code = "REG"
        issuer = "\(regulatedIssuerAccountId)"
        regulated = true
        approval_server = "http://\(sep08Server)/unknown_status"
        """

        let toml = try StellarToml(fromString: tomlString)
        let service = try RegulatedAssetsService(tomlData: toml, network: .testnet)

        let txXdr = "AAAAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGVtcHR5X3R4X2Jhc2U2NA=="
        let result = await service.postTransaction(txB64Xdr: txXdr, apporvalServer: "http://\(sep08Server)/unknown_status")

        switch result {
        case .failure(let error):
            switch error {
            case .parsingResponseFailed(let message):
                XCTAssertTrue(message.contains("unknown sep08 post transaction response"))
            default:
                XCTFail("Should return parsingResponseFailed error")
            }
        default:
            XCTFail("Should fail with unknown status")
        }
    }

    func testPostTransactionServerError() async throws {
        let tomlString = """
        NETWORK_PASSPHRASE = "Test SDF Network ; September 2015"
        HORIZON_URL = "https://horizon-testnet.stellar.org"

        [DOCUMENTATION]
        ORG_NAME = "Test Issuer"

        [[CURRENCIES]]
        code = "REG"
        issuer = "\(regulatedIssuerAccountId)"
        regulated = true
        approval_server = "http://\(sep08Server)/server_error"
        """

        let toml = try StellarToml(fromString: tomlString)
        let service = try RegulatedAssetsService(tomlData: toml, network: .testnet)

        let txXdr = "AAAAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGVtcHR5X3R4X2Jhc2U2NA=="
        let result = await service.postTransaction(txB64Xdr: txXdr, apporvalServer: "http://\(sep08Server)/server_error")

        switch result {
        case .failure(_):
            // Expected
            break
        default:
            XCTFail("Should fail with server error")
        }
    }

    // MARK: - Post Action Tests

    func testPostActionDone() async throws {
        let tomlString = """
        NETWORK_PASSPHRASE = "Test SDF Network ; September 2015"
        HORIZON_URL = "https://horizon-testnet.stellar.org"

        [DOCUMENTATION]
        ORG_NAME = "Test Issuer"

        [[CURRENCIES]]
        code = "REG"
        issuer = "\(regulatedIssuerAccountId)"
        regulated = true
        approval_server = "https://approval.example.com"
        """

        let toml = try StellarToml(fromString: tomlString)
        let service = try RegulatedAssetsService(tomlData: toml, network: .testnet)

        let actionFields = ["email": "user@example.com", "kyc_id": "12345"]
        let result = await service.postAction(url: "http://\(sep08Server)/action_done", actionFields: actionFields)

        switch result {
        case .done:
            // Expected
            break
        case .nextUrl(_):
            XCTFail("Should return done, not nextUrl")
        case .failure(let error):
            XCTFail("Should not fail: \(error)")
        }
    }

    func testPostActionNextUrl() async throws {
        let tomlString = """
        NETWORK_PASSPHRASE = "Test SDF Network ; September 2015"
        HORIZON_URL = "https://horizon-testnet.stellar.org"

        [DOCUMENTATION]
        ORG_NAME = "Test Issuer"

        [[CURRENCIES]]
        code = "REG"
        issuer = "\(regulatedIssuerAccountId)"
        regulated = true
        approval_server = "https://approval.example.com"
        """

        let toml = try StellarToml(fromString: tomlString)
        let service = try RegulatedAssetsService(tomlData: toml, network: .testnet)

        let actionFields = ["email": "user@example.com"]
        let result = await service.postAction(url: "http://\(sep08Server)/action_next", actionFields: actionFields)

        switch result {
        case .done:
            XCTFail("Should return nextUrl, not done")
        case .nextUrl(let response):
            XCTAssertEqual(response.nextUrl, "https://kyc.example.com/step2")
            XCTAssertEqual(response.message, "Please complete step 2")
        case .failure(let error):
            XCTFail("Should not fail: \(error)")
        }
    }

    func testPostActionUnknownResult() async throws {
        let tomlString = """
        NETWORK_PASSPHRASE = "Test SDF Network ; September 2015"
        HORIZON_URL = "https://horizon-testnet.stellar.org"

        [DOCUMENTATION]
        ORG_NAME = "Test Issuer"

        [[CURRENCIES]]
        code = "REG"
        issuer = "\(regulatedIssuerAccountId)"
        regulated = true
        approval_server = "https://approval.example.com"
        """

        let toml = try StellarToml(fromString: tomlString)
        let service = try RegulatedAssetsService(tomlData: toml, network: .testnet)

        let actionFields = ["email": "user@example.com"]
        let result = await service.postAction(url: "http://\(sep08Server)/action_unknown", actionFields: actionFields)

        switch result {
        case .failure(let error):
            switch error {
            case .parsingResponseFailed(let message):
                XCTAssertTrue(message.contains("unknown sep08 post action response"))
            default:
                XCTFail("Should return parsingResponseFailed error")
            }
        default:
            XCTFail("Should fail with unknown result")
        }
    }

    func testPostActionServerError() async throws {
        let tomlString = """
        NETWORK_PASSPHRASE = "Test SDF Network ; September 2015"
        HORIZON_URL = "https://horizon-testnet.stellar.org"

        [DOCUMENTATION]
        ORG_NAME = "Test Issuer"

        [[CURRENCIES]]
        code = "REG"
        issuer = "\(regulatedIssuerAccountId)"
        regulated = true
        approval_server = "https://approval.example.com"
        """

        let toml = try StellarToml(fromString: tomlString)
        let service = try RegulatedAssetsService(tomlData: toml, network: .testnet)

        let actionFields = ["email": "user@example.com"]
        let result = await service.postAction(url: "http://\(sep08Server)/action_error", actionFields: actionFields)

        switch result {
        case .failure(_):
            // Expected
            break
        default:
            XCTFail("Should fail with server error")
        }
    }

    // MARK: - authorizationRequired() Method Tests

    func testAuthorizationRequiredWithBothFlags() async throws {
        let horizonHost = horizonServer
        let accountId = regulatedIssuerAccountId

        let tomlString = """
        NETWORK_PASSPHRASE = "Test SDF Network ; September 2015"
        HORIZON_URL = "http://\(horizonHost)"

        [DOCUMENTATION]
        ORG_NAME = "Test Issuer"

        [[CURRENCIES]]
        code = "REG"
        issuer = "\(accountId)"
        regulated = true
        approval_server = "https://approval.example.com"
        """

        let toml = try StellarToml(fromString: tomlString)
        let service = try RegulatedAssetsService(tomlData: toml, network: .testnet)
        let asset = service.regulatedAssets[0]

        // Create mock for account details request
        let handler: MockHandler = { mock, request in
            mock.statusCode = 200
            return """
            {
                "_links": {
                    "self": {"href": "https://horizon.stellar.org/accounts/\(accountId)"},
                    "transactions": {"href": "https://horizon.stellar.org/accounts/\(accountId)/transactions"},
                    "operations": {"href": "https://horizon.stellar.org/accounts/\(accountId)/operations"},
                    "payments": {"href": "https://horizon.stellar.org/accounts/\(accountId)/payments"},
                    "effects": {"href": "https://horizon.stellar.org/accounts/\(accountId)/effects"},
                    "offers": {"href": "https://horizon.stellar.org/accounts/\(accountId)/offers"},
                    "trades": {"href": "https://horizon.stellar.org/accounts/\(accountId)/trades"},
                    "data": {"href": "https://horizon.stellar.org/accounts/\(accountId)/data/{key}","templated": true}
                },
                "id": "\(accountId)",
                "account_id": "\(accountId)",
                "sequence": "1",
                "paging_token": "\(accountId)",
                "subentry_count": 0,
                "last_modified_ledger": 1,
                "num_sponsoring": 0,
                "num_sponsored": 0,
                "thresholds": {
                    "low_threshold": 0,
                    "med_threshold": 0,
                    "high_threshold": 0
                },
                "flags": {
                    "auth_required": true,
                    "auth_revocable": true,
                    "auth_immutable": false,
                    "auth_clawback_enabled": false
                },
                "balances": [],
                "signers": [],
                "data": {}
            }
            """
        }

        let requestMock = RequestMock(host: horizonHost,
                                      path: "/accounts/\(accountId)",
                                      httpMethod: "GET",
                                      mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let result = await service.authorizationRequired(asset: asset)

        ServerMock.remove(mock: requestMock)

        switch result {
        case .success(let required):
            XCTAssertTrue(required, "Should require authorization when both flags are set")
        case .failure(let error):
            XCTFail("Should succeed, got error: \(error)")
        }
    }

    func testAuthorizationRequiredWithoutFlags() async throws {
        let horizonHost = horizonServer
        let accountId = nonRegulatedIssuerAccountId

        let tomlString = """
        NETWORK_PASSPHRASE = "Test SDF Network ; September 2015"
        HORIZON_URL = "http://\(horizonHost)"

        [DOCUMENTATION]
        ORG_NAME = "Test Issuer"

        [[CURRENCIES]]
        code = "REG"
        issuer = "\(accountId)"
        regulated = true
        approval_server = "https://approval.example.com"
        """

        let toml = try StellarToml(fromString: tomlString)
        let service = try RegulatedAssetsService(tomlData: toml, network: .testnet)
        let asset = service.regulatedAssets[0]

        // Create mock for account details request
        let handler: MockHandler = { mock, request in
            mock.statusCode = 200
            return """
            {
                "_links": {
                    "self": {"href": "https://horizon.stellar.org/accounts/\(accountId)"},
                    "transactions": {"href": "https://horizon.stellar.org/accounts/\(accountId)/transactions"},
                    "operations": {"href": "https://horizon.stellar.org/accounts/\(accountId)/operations"},
                    "payments": {"href": "https://horizon.stellar.org/accounts/\(accountId)/payments"},
                    "effects": {"href": "https://horizon.stellar.org/accounts/\(accountId)/effects"},
                    "offers": {"href": "https://horizon.stellar.org/accounts/\(accountId)/offers"},
                    "trades": {"href": "https://horizon.stellar.org/accounts/\(accountId)/trades"},
                    "data": {"href": "https://horizon.stellar.org/accounts/\(accountId)/data/{key}","templated": true}
                },
                "id": "\(accountId)",
                "account_id": "\(accountId)",
                "sequence": "1",
                "paging_token": "\(accountId)",
                "subentry_count": 0,
                "last_modified_ledger": 1,
                "num_sponsoring": 0,
                "num_sponsored": 0,
                "thresholds": {
                    "low_threshold": 0,
                    "med_threshold": 0,
                    "high_threshold": 0
                },
                "flags": {
                    "auth_required": false,
                    "auth_revocable": false,
                    "auth_immutable": false,
                    "auth_clawback_enabled": false
                },
                "balances": [],
                "signers": [],
                "data": {}
            }
            """
        }

        let requestMock = RequestMock(host: horizonHost,
                                      path: "/accounts/\(accountId)",
                                      httpMethod: "GET",
                                      mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let result = await service.authorizationRequired(asset: asset)

        ServerMock.remove(mock: requestMock)

        switch result {
        case .success(let required):
            XCTAssertFalse(required, "Should not require authorization when flags are not set")
        case .failure(let error):
            XCTFail("Should succeed, got error: \(error)")
        }
    }

    func testAuthorizationRequiredOnlyAuthRequired() async throws {
        let horizonHost = horizonServer
        let accountId = regulatedIssuerAccountId

        let tomlString = """
        NETWORK_PASSPHRASE = "Test SDF Network ; September 2015"
        HORIZON_URL = "http://\(horizonHost)"

        [DOCUMENTATION]
        ORG_NAME = "Test Issuer"

        [[CURRENCIES]]
        code = "REG"
        issuer = "\(accountId)"
        regulated = true
        approval_server = "https://approval.example.com"
        """

        let toml = try StellarToml(fromString: tomlString)
        let service = try RegulatedAssetsService(tomlData: toml, network: .testnet)
        let asset = service.regulatedAssets[0]

        // Create mock for account details request
        let handler: MockHandler = { mock, request in
            mock.statusCode = 200
            return """
            {
                "_links": {
                    "self": {"href": "https://horizon.stellar.org/accounts/\(accountId)"},
                    "transactions": {"href": "https://horizon.stellar.org/accounts/\(accountId)/transactions"},
                    "operations": {"href": "https://horizon.stellar.org/accounts/\(accountId)/operations"},
                    "payments": {"href": "https://horizon.stellar.org/accounts/\(accountId)/payments"},
                    "effects": {"href": "https://horizon.stellar.org/accounts/\(accountId)/effects"},
                    "offers": {"href": "https://horizon.stellar.org/accounts/\(accountId)/offers"},
                    "trades": {"href": "https://horizon.stellar.org/accounts/\(accountId)/trades"},
                    "data": {"href": "https://horizon.stellar.org/accounts/\(accountId)/data/{key}","templated": true}
                },
                "id": "\(accountId)",
                "account_id": "\(accountId)",
                "sequence": "1",
                "paging_token": "\(accountId)",
                "subentry_count": 0,
                "last_modified_ledger": 1,
                "num_sponsoring": 0,
                "num_sponsored": 0,
                "thresholds": {
                    "low_threshold": 0,
                    "med_threshold": 0,
                    "high_threshold": 0
                },
                "flags": {
                    "auth_required": true,
                    "auth_revocable": false,
                    "auth_immutable": false,
                    "auth_clawback_enabled": false
                },
                "balances": [],
                "signers": [],
                "data": {}
            }
            """
        }

        let requestMock = RequestMock(host: horizonHost,
                                      path: "/accounts/\(accountId)",
                                      httpMethod: "GET",
                                      mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let result = await service.authorizationRequired(asset: asset)

        ServerMock.remove(mock: requestMock)

        switch result {
        case .success(let required):
            XCTAssertFalse(required, "Should not require authorization when only AUTH_REQUIRED is set")
        case .failure(let error):
            XCTFail("Should succeed, got error: \(error)")
        }
    }

    func testAuthorizationRequiredAccountNotFound() async throws{
        // Use a valid format account ID that doesn't exist
        let notFoundAccountId = "GDIODQRBHD32QZWTGOHO2MRZQY2TRG5KTI2NNTFYH2JDYZGMU3NJVXXX"
        let tomlString = """
        NETWORK_PASSPHRASE = "Test SDF Network ; September 2015"
        HORIZON_URL = "http://\(horizonServer)"

        [DOCUMENTATION]
        ORG_NAME = "Test Issuer"

        [[CURRENCIES]]
        code = "REG"
        issuer = "\(notFoundAccountId)"
        regulated = true
        approval_server = "https://approval.example.com"
        """

        let toml = try StellarToml(fromString: tomlString)
        let service = try RegulatedAssetsService(tomlData: toml, network: .testnet)
        let asset = service.regulatedAssets[0]

        // Create mock for account not found
        let handler: MockHandler = { mock, request in
            mock.statusCode = 404
            return """
            {
                "type": "https://stellar.org/horizon-errors/not_found",
                "title": "Resource Missing",
                "status": 404,
                "detail": "The resource at the url requested was not found."
            }
            """
        }

        let requestMock = RequestMock(host: horizonServer,
                                      path: "/accounts/\(notFoundAccountId)",
                                      httpMethod: "GET",
                                      mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let result = await service.authorizationRequired(asset: asset)

        ServerMock.remove(mock: requestMock)

        switch result {
        case .success(_):
            XCTFail("Should fail when account is not found")
        case .failure(let error):
            // Expected error
            XCTAssertNotNil(error, "Should return an error")
        }
    }

    // MARK: - RegulatedAsset Tests

    func testRegulatedAssetInitialization() throws {
        let asset = try RegulatedAsset(
            type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4,
            assetCode: "USD",
            issuerId: regulatedIssuerAccountId,
            approvalServer: "https://approval.example.com",
            approvalCriteria: "Must complete KYC"
        )

        XCTAssertNotNil(asset, "Asset should be created successfully")
        XCTAssertEqual(asset?.assetCode, "USD")
        XCTAssertEqual(asset?.issuerId, regulatedIssuerAccountId)
        XCTAssertEqual(asset?.approvalServer, "https://approval.example.com")
        XCTAssertEqual(asset?.approvalCriteria, "Must complete KYC")
        XCTAssertEqual(asset?.type, AssetType.ASSET_TYPE_CREDIT_ALPHANUM4)
        XCTAssertNotNil(asset?.issuer, "Asset issuer keypair should be initialized")
    }

    func testRegulatedAssetWithoutCriteria() throws {
        let asset = try RegulatedAsset(
            type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM12,
            assetCode: "REGULATED",
            issuerId: regulatedIssuerAccountId,
            approvalServer: "https://approval.example.com"
        )

        XCTAssertNotNil(asset, "Asset should be created without criteria")
        XCTAssertEqual(asset?.assetCode, "REGULATED")
        XCTAssertEqual(asset?.type, AssetType.ASSET_TYPE_CREDIT_ALPHANUM12)
        XCTAssertNil(asset?.approvalCriteria)
        XCTAssertEqual(asset?.approvalServer, "https://approval.example.com")
    }

    // MARK: - Response Struct Tests

    func testSep08PostTransactionSuccessDecoding() throws {
        let json = """
        {
            "tx": "signed_tx_xdr",
            "message": "Transaction approved successfully"
        }
        """

        let decoder = JSONDecoder()
        let response = try decoder.decode(Sep08PostTransactionSuccess.self, from: json.data(using: .utf8)!)

        XCTAssertEqual(response.tx, "signed_tx_xdr")
        XCTAssertEqual(response.message, "Transaction approved successfully")
    }

    func testSep08PostTransactionSuccessWithoutMessage() throws {
        let json = """
        {
            "tx": "signed_tx_xdr"
        }
        """

        let decoder = JSONDecoder()
        let response = try decoder.decode(Sep08PostTransactionSuccess.self, from: json.data(using: .utf8)!)

        XCTAssertEqual(response.tx, "signed_tx_xdr")
        XCTAssertNil(response.message)
    }

    func testSep08PostTransactionRevisedDecoding() throws {
        let json = """
        {
            "tx": "revised_tx_xdr",
            "message": "Added compliance fee"
        }
        """

        let decoder = JSONDecoder()
        let response = try decoder.decode(Sep08PostTransactionRevised.self, from: json.data(using: .utf8)!)

        XCTAssertEqual(response.tx, "revised_tx_xdr")
        XCTAssertEqual(response.message, "Added compliance fee")
    }

    func testSep08PostTransactionPendingDecoding() throws {
        let json = """
        {
            "timeout": 300,
            "message": "Approval pending review"
        }
        """

        let decoder = JSONDecoder()
        let response = try decoder.decode(Sep08PostTransactionPending.self, from: json.data(using: .utf8)!)

        XCTAssertEqual(response.timeout, 300)
        XCTAssertEqual(response.message, "Approval pending review")
    }

    func testSep08PostTransactionPendingMinimal() throws {
        let json = """
        {
        }
        """

        let decoder = JSONDecoder()
        let response = try decoder.decode(Sep08PostTransactionPending.self, from: json.data(using: .utf8)!)

        XCTAssertEqual(response.timeout, 0)
        XCTAssertNil(response.message)
    }

    func testSep08PostTransactionActionRequiredDecoding() throws {
        let json = """
        {
            "message": "KYC required",
            "action_url": "https://kyc.example.com",
            "action_method": "POST",
            "action_fields": ["name", "email", "document"]
        }
        """

        let decoder = JSONDecoder()
        let response = try decoder.decode(Sep08PostTransactionActionRequired.self, from: json.data(using: .utf8)!)

        XCTAssertEqual(response.message, "KYC required")
        XCTAssertEqual(response.actionUrl, "https://kyc.example.com")
        XCTAssertEqual(response.actionMethod, "POST")
        XCTAssertEqual(response.actionFields?.count, 3)
        XCTAssertTrue(response.actionFields?.contains("name") ?? false)
    }

    func testSep08PostTransactionActionRequiredMinimal() throws {
        let json = """
        {
            "message": "Action needed",
            "action_url": "https://action.example.com"
        }
        """

        let decoder = JSONDecoder()
        let response = try decoder.decode(Sep08PostTransactionActionRequired.self, from: json.data(using: .utf8)!)

        XCTAssertEqual(response.actionMethod, "GET", "Default action method should be GET")
        XCTAssertNil(response.actionFields)
    }

    func testSep08PostTransactionRejectedDecoding() throws {
        let json = """
        {
            "error": "Transaction violates sanctions"
        }
        """

        let decoder = JSONDecoder()
        let response = try decoder.decode(Sep08PostTransactionRejected.self, from: json.data(using: .utf8)!)

        XCTAssertEqual(response.error, "Transaction violates sanctions")
    }

    func testSep08PostTransactionStatusResponseDecoding() throws {
        let json = """
        {
            "status": "success"
        }
        """

        let decoder = JSONDecoder()
        let response = try decoder.decode(Sep08PostTransactionStatusResponse.self, from: json.data(using: .utf8)!)

        XCTAssertEqual(response.status, "success")
    }

    func testSep08PostTransactionStatusResponseMissingStatus() throws {
        let json = """
        {
            "other_field": "value"
        }
        """

        let decoder = JSONDecoder()
        let response = try decoder.decode(Sep08PostTransactionStatusResponse.self, from: json.data(using: .utf8)!)

        XCTAssertNil(response.status)
    }

    func testSep08PostActionResultResponseDecoding() throws {
        let json = """
        {
            "result": "no_further_action_required"
        }
        """

        let decoder = JSONDecoder()
        let response = try decoder.decode(Sep08PostActionResultResponse.self, from: json.data(using: .utf8)!)

        XCTAssertEqual(response.result, "no_further_action_required")
    }

    func testSep08PostActionNextUrlDecoding() throws {
        let json = """
        {
            "next_url": "https://next.example.com/step2",
            "message": "Continue to next step"
        }
        """

        let decoder = JSONDecoder()
        let response = try decoder.decode(Sep08PostActionNextUrl.self, from: json.data(using: .utf8)!)

        XCTAssertEqual(response.nextUrl, "https://next.example.com/step2")
        XCTAssertEqual(response.message, "Continue to next step")
    }

    func testSep08PostActionNextUrlWithoutMessage() throws {
        let json = """
        {
            "next_url": "https://next.example.com"
        }
        """

        let decoder = JSONDecoder()
        let response = try decoder.decode(Sep08PostActionNextUrl.self, from: json.data(using: .utf8)!)

        XCTAssertEqual(response.nextUrl, "https://next.example.com")
        XCTAssertNil(response.message)
    }

    // MARK: - Edge Case Tests

    func testRegulatedAssetWithEmptyAssetCode() throws {
        let tomlString = """
        NETWORK_PASSPHRASE = "Test SDF Network ; September 2015"
        HORIZON_URL = "https://horizon-testnet.stellar.org"

        [DOCUMENTATION]
        ORG_NAME = "Test Issuer"

        [[CURRENCIES]]
        code = ""
        issuer = "\(regulatedIssuerAccountId)"
        regulated = true
        approval_server = "https://approval.example.com"
        """

        let toml = try StellarToml(fromString: tomlString)
        let service = try RegulatedAssetsService(tomlData: toml, network: .testnet)

        XCTAssertEqual(service.regulatedAssets.count, 0, "Empty asset code should be ignored")
    }

    func testRegulatedAssetWithInvalidIssuerId() throws {
        let tomlString = """
        NETWORK_PASSPHRASE = "Test SDF Network ; September 2015"
        HORIZON_URL = "https://horizon-testnet.stellar.org"

        [DOCUMENTATION]
        ORG_NAME = "Test Issuer"

        [[CURRENCIES]]
        code = "USD"
        issuer = "INVALID_ISSUER_ID"
        regulated = true
        approval_server = "https://approval.example.com"
        """

        let toml = try StellarToml(fromString: tomlString)
        let service = try RegulatedAssetsService(tomlData: toml, network: .testnet)

        XCTAssertEqual(service.regulatedAssets.count, 0, "Invalid issuer ID should be ignored")
    }

    func testRegulatedAssetWithTooLongAssetCode() throws {
        let tomlString = """
        NETWORK_PASSPHRASE = "Test SDF Network ; September 2015"
        HORIZON_URL = "https://horizon-testnet.stellar.org"

        [DOCUMENTATION]
        ORG_NAME = "Test Issuer"

        [[CURRENCIES]]
        code = "THISISAVERYLONGASSETCODE"
        issuer = "\(regulatedIssuerAccountId)"
        regulated = true
        approval_server = "https://approval.example.com"
        """

        let toml = try StellarToml(fromString: tomlString)
        let service = try RegulatedAssetsService(tomlData: toml, network: .testnet)

        XCTAssertEqual(service.regulatedAssets.count, 0, "Asset code longer than 12 chars should be ignored")
    }

    func testMalformedTomlString() throws {
        let tomlString = """
        This is not valid TOML syntax {{{
        random garbage
        """

        XCTAssertThrowsError(try StellarToml(fromString: tomlString)) { error in
            // Expected to throw during TOML parsing
        }
    }

    // MARK: - Network Error Tests

    func testPostTransactionNetworkError() async throws {
        let tomlString = """
        NETWORK_PASSPHRASE = "Test SDF Network ; September 2015"
        HORIZON_URL = "https://horizon-testnet.stellar.org"

        [DOCUMENTATION]
        ORG_NAME = "Test Issuer"

        [[CURRENCIES]]
        code = "REG"
        issuer = "\(regulatedIssuerAccountId)"
        regulated = true
        approval_server = "http://\(sep08Server)/network_error"
        """

        let toml = try StellarToml(fromString: tomlString)
        let service = try RegulatedAssetsService(tomlData: toml, network: .testnet)

        let networkErrorMock: Sep08PostTransactionNetworkErrorMock? = Sep08PostTransactionNetworkErrorMock(address: sep08Server)

        let txXdr = "AAAAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGVtcHR5X3R4X2Jhc2U2NA=="
        let result = await service.postTransaction(txB64Xdr: txXdr, apporvalServer: "http://\(sep08Server)/network_error")

        _ = networkErrorMock // Keep mock alive

        switch result {
        case .failure(let error):
            // SDK returns staleHistory for 503 status code (this is acceptable for network errors)
            switch error {
            case .requestFailed(_, _), .parsingResponseFailed(_), .staleHistory(_, _):
                // Expected network error types
                break
            default:
                XCTFail("Expected network-related error, got: \(error)")
            }
        default:
            XCTFail("Should fail with network error")
        }
    }

    func testPostActionNetworkError() async throws {
        let tomlString = """
        NETWORK_PASSPHRASE = "Test SDF Network ; September 2015"
        HORIZON_URL = "https://horizon-testnet.stellar.org"

        [DOCUMENTATION]
        ORG_NAME = "Test Issuer"

        [[CURRENCIES]]
        code = "REG"
        issuer = "\(regulatedIssuerAccountId)"
        regulated = true
        approval_server = "https://approval.example.com"
        """

        let toml = try StellarToml(fromString: tomlString)
        let service = try RegulatedAssetsService(tomlData: toml, network: .testnet)

        let networkErrorMock: Sep08PostActionNetworkErrorMock? = Sep08PostActionNetworkErrorMock(address: sep08Server)

        let actionFields = ["email": "user@example.com"]
        let result = await service.postAction(url: "http://\(sep08Server)/action_network_error", actionFields: actionFields)

        _ = networkErrorMock // Keep mock alive

        switch result {
        case .failure(let error):
            // SDK returns staleHistory for 503 status code (this is acceptable for network errors)
            switch error {
            case .requestFailed(_, _), .parsingResponseFailed(_), .staleHistory(_, _):
                // Expected network error types
                break
            default:
                XCTFail("Expected network-related error, got: \(error)")
            }
        default:
            XCTFail("Should fail with network error")
        }
    }

}

// MARK: - Mock Classes

class Sep08PostTransactionSuccessMock: ResponsesMock {
    var address: String

    init(address: String) {
        self.address = address
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 200
            return """
            {
                "status": "success",
                "tx": "signed_tx_xdr_base64",
                "message": "Transaction approved"
            }
            """
        }

        return RequestMock(host: address,
                           path: "/success",
                           httpMethod: "POST",
                           mockHandler: handler)
    }
}

class Sep08PostTransactionRevisedMock: ResponsesMock {
    var address: String

    init(address: String) {
        self.address = address
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 200
            return """
            {
                "status": "revised",
                "tx": "revised_tx_xdr_base64",
                "message": "Transaction revised to add compliance fee"
            }
            """
        }

        return RequestMock(host: address,
                           path: "/revised",
                           httpMethod: "POST",
                           mockHandler: handler)
    }
}

class Sep08PostTransactionPendingMock: ResponsesMock {
    var address: String

    init(address: String) {
        self.address = address
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 200
            return """
            {
                "status": "pending",
                "timeout": 3600,
                "message": "Approval pending, please wait"
            }
            """
        }

        return RequestMock(host: address,
                           path: "/pending",
                           httpMethod: "POST",
                           mockHandler: handler)
    }
}

class Sep08PostTransactionPendingMinimalMock: ResponsesMock {
    var address: String

    init(address: String) {
        self.address = address
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 200
            return """
            {
                "status": "pending"
            }
            """
        }

        return RequestMock(host: address,
                           path: "/pending_minimal",
                           httpMethod: "POST",
                           mockHandler: handler)
    }
}

class Sep08PostTransactionActionRequiredMock: ResponsesMock {
    var address: String

    init(address: String) {
        self.address = address
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 200
            return """
            {
                "status": "action_required",
                "message": "Please complete KYC verification",
                "action_url": "https://kyc.example.com/verify",
                "action_method": "POST",
                "action_fields": ["email", "kyc_id"]
            }
            """
        }

        return RequestMock(host: address,
                           path: "/action_required",
                           httpMethod: "POST",
                           mockHandler: handler)
    }
}

class Sep08PostTransactionActionRequiredMinimalMock: ResponsesMock {
    var address: String

    init(address: String) {
        self.address = address
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 200
            return """
            {
                "status": "action_required",
                "message": "Action needed",
                "action_url": "https://kyc.example.com/verify"
            }
            """
        }

        return RequestMock(host: address,
                           path: "/action_required_minimal",
                           httpMethod: "POST",
                           mockHandler: handler)
    }
}

class Sep08PostTransactionRejectedMock: ResponsesMock {
    var address: String

    init(address: String) {
        self.address = address
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 200
            return """
            {
                "status": "rejected",
                "error": "Transaction violates compliance requirements"
            }
            """
        }

        return RequestMock(host: address,
                           path: "/rejected",
                           httpMethod: "POST",
                           mockHandler: handler)
    }
}

class Sep08PostTransactionBadRequestRejectedMock: ResponsesMock {
    var address: String

    init(address: String) {
        self.address = address
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 400
            return """
            {
                "status": "rejected",
                "error": "Transaction rejected due to compliance violation"
            }
            """
        }

        return RequestMock(host: address,
                           path: "/bad_request_rejected",
                           httpMethod: "POST",
                           mockHandler: handler)
    }
}

class Sep08PostTransactionUnknownStatusMock: ResponsesMock {
    var address: String

    init(address: String) {
        self.address = address
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 200
            return """
            {
                "status": "unknown_status_value"
            }
            """
        }

        return RequestMock(host: address,
                           path: "/unknown_status",
                           httpMethod: "POST",
                           mockHandler: handler)
    }
}

class Sep08PostTransactionServerErrorMock: ResponsesMock {
    var address: String

    init(address: String) {
        self.address = address
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 500
            return """
            {
                "error": "Internal server error"
            }
            """
        }

        return RequestMock(host: address,
                           path: "/server_error",
                           httpMethod: "POST",
                           mockHandler: handler)
    }
}

class Sep08PostActionDoneMock: ResponsesMock {
    var address: String

    init(address: String) {
        self.address = address
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 200
            return """
            {
                "result": "no_further_action_required"
            }
            """
        }

        return RequestMock(host: address,
                           path: "/action_done",
                           httpMethod: "POST",
                           mockHandler: handler)
    }
}

class Sep08PostActionNextUrlMock: ResponsesMock {
    var address: String

    init(address: String) {
        self.address = address
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 200
            return """
            {
                "result": "follow_next_url",
                "next_url": "https://kyc.example.com/step2",
                "message": "Please complete step 2"
            }
            """
        }

        return RequestMock(host: address,
                           path: "/action_next",
                           httpMethod: "POST",
                           mockHandler: handler)
    }
}

class Sep08PostActionUnknownMock: ResponsesMock {
    var address: String

    init(address: String) {
        self.address = address
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 200
            return """
            {
                "result": "unknown_result_value"
            }
            """
        }

        return RequestMock(host: address,
                           path: "/action_unknown",
                           httpMethod: "POST",
                           mockHandler: handler)
    }
}

class Sep08PostActionErrorMock: ResponsesMock {
    var address: String

    init(address: String) {
        self.address = address
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 500
            return """
            {
                "error": "Internal server error"
            }
            """
        }

        return RequestMock(host: address,
                           path: "/action_error",
                           httpMethod: "POST",
                           mockHandler: handler)
    }
}

// MARK: - TOML Mock Classes

class Sep08TomlSuccessMock: ResponsesMock {
    var address: String

    init(address: String) {
        self.address = address
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 200
            mock.contentType = "text/plain"
            return """
            NETWORK_PASSPHRASE = "Test SDF Network ; September 2015"
            HORIZON_URL = "https://horizon-testnet.stellar.org"

            [DOCUMENTATION]
            ORG_NAME = "Test Issuer"

            [[CURRENCIES]]
            code = "USD"
            issuer = "GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP"
            regulated = true
            approval_server = "https://approval.example.com"
            """
        }

        return RequestMock(host: address,
                           path: "/.well-known/stellar.toml",
                           httpMethod: "GET",
                           mockHandler: handler)
    }
}

class Sep08TomlInvalidMock: ResponsesMock {
    var address: String

    init(address: String) {
        self.address = address
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 200
            mock.contentType = "text/plain"
            return """
            This is not valid TOML {{{}}}
            """
        }

        return RequestMock(host: address,
                           path: "/.well-known/stellar.toml",
                           httpMethod: "GET",
                           mockHandler: handler)
    }
}

class Sep08TomlMissingMock: ResponsesMock {
    var address: String

    init(address: String) {
        self.address = address
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 404
            return """
            {
                "error": "Not found"
            }
            """
        }

        return RequestMock(host: address,
                           path: "/.well-known/stellar.toml",
                           httpMethod: "GET",
                           mockHandler: handler)
    }
}

// MARK: - Network Error Mock Classes

class Sep08PostTransactionNetworkErrorMock: ResponsesMock {
    var address: String

    init(address: String) {
        self.address = address
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 503
            return """
            Service Unavailable
            """
        }

        return RequestMock(host: address,
                           path: "/network_error",
                           httpMethod: "POST",
                           mockHandler: handler)
    }
}

class Sep08PostActionNetworkErrorMock: ResponsesMock {
    var address: String

    init(address: String) {
        self.address = address
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 503
            return """
            Service Unavailable
            """
        }

        return RequestMock(host: address,
                           path: "/action_network_error",
                           httpMethod: "POST",
                           mockHandler: handler)
    }
}
