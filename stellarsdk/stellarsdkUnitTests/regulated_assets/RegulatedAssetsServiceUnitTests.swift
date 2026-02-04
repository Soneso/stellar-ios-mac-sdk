//
//  RegulatedAssetsServiceUnitTests.swift
//  stellarsdk
//
//  Created by Claude on 2026-02-04.
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

        XCTAssertNotNil(service, "Service should be created successfully")
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

        XCTAssertNotNil(service, "Service should derive network from passphrase")
        XCTAssertEqual(service.regulatedAssets.count, 1)
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

        XCTAssertNotNil(service, "Service should use custom Horizon URL")
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

        XCTAssertNotNil(service, "Service should use default public network Horizon")
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

        XCTAssertNotNil(service, "Service should use testnet Horizon")
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

        XCTAssertNotNil(service, "Service should use futurenet Horizon")
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
        XCTAssertNotNil(reg1)
        XCTAssertEqual(reg1?.approvalServer, "https://approval1.example.com")
        XCTAssertEqual(reg1?.approvalCriteria, "Criteria 1")

        // Verify second regulated asset
        let reg2 = service.regulatedAssets.first { $0.assetCode == "REG2" }
        XCTAssertNotNil(reg2)
        XCTAssertEqual(reg2?.approvalServer, "https://approval2.example.com")
        XCTAssertNil(reg2?.approvalCriteria)
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

    // MARK: - RegulatedAsset Tests

    func testRegulatedAssetInitialization() throws {
        let asset = try RegulatedAsset(
            type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4,
            assetCode: "USD",
            issuerId: regulatedIssuerAccountId,
            approvalServer: "https://approval.example.com",
            approvalCriteria: "Must complete KYC"
        )

        XCTAssertNotNil(asset)
        XCTAssertEqual(asset?.assetCode, "USD")
        XCTAssertEqual(asset?.issuerId, regulatedIssuerAccountId)
        XCTAssertEqual(asset?.approvalServer, "https://approval.example.com")
        XCTAssertEqual(asset?.approvalCriteria, "Must complete KYC")
        XCTAssertEqual(asset?.type, AssetType.ASSET_TYPE_CREDIT_ALPHANUM4)
    }

    func testRegulatedAssetWithoutCriteria() throws {
        let asset = try RegulatedAsset(
            type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM12,
            assetCode: "REGULATED",
            issuerId: regulatedIssuerAccountId,
            approvalServer: "https://approval.example.com"
        )

        XCTAssertNotNil(asset)
        XCTAssertEqual(asset?.assetCode, "REGULATED")
        XCTAssertNil(asset?.approvalCriteria)
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
