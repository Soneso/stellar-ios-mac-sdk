//
//  StellarTomlTestCase.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 2026-02-03.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

final class StellarTomlTestCase: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: - Basic Stellar TOML Parsing Tests

    func testParseStellarToml() throws {
        let tomlString = """
        VERSION = "2.7.0"
        NETWORK_PASSPHRASE = "Test SDF Network ; September 2015"

        [DOCUMENTATION]
        ORG_NAME = "Test Organization"
        ORG_URL = "https://example.com"
        """

        let stellarToml = try StellarToml(fromString: tomlString)

        XCTAssertNotNil(stellarToml, "Should parse stellar.toml")
        XCTAssertEqual(stellarToml.accountInformation.version, "2.7.0", "Should parse version")
        XCTAssertEqual(stellarToml.accountInformation.networkPassphrase, "Test SDF Network ; September 2015", "Should parse network passphrase")
        XCTAssertEqual(stellarToml.issuerDocumentation.orgName, "Test Organization", "Should parse org name")
        XCTAssertEqual(stellarToml.issuerDocumentation.orgURL, "https://example.com", "Should parse org URL")
    }

    func testParseWithAllFields() throws {
        let tomlString = """
        VERSION = "2.7.0"
        NETWORK_PASSPHRASE = "Public Global Stellar Network ; September 2015"
        FEDERATION_SERVER = "https://federation.example.com"
        AUTH_SERVER = "https://auth.example.com"
        TRANSFER_SERVER = "https://transfer.example.com"
        TRANSFER_SERVER_SEP0024 = "https://transfer24.example.com"
        KYC_SERVER = "https://kyc.example.com"
        WEB_AUTH_ENDPOINT = "https://webauth.example.com"
        WEB_AUTH_FOR_CONTRACTS_ENDPOINT = "https://webauth-contracts.example.com"
        WEB_AUTH_CONTRACT_ID = "CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
        SIGNING_KEY = "GBBM6BKZPEHWYO3E3YKREDPQXMS4VK35YLNU7NFBRI26RAN7GI5POFBB"
        HORIZON_URL = "https://horizon.example.com"
        ACCOUNTS = ["GABC123", "GDEF456"]
        URI_REQUEST_SIGNING_KEY = "GXYZ789"
        DIRECT_PAYMENT_SERVER = "https://directpay.example.com"
        ANCHOR_QUOTE_SERVER = "https://quote.example.com"

        [DOCUMENTATION]
        ORG_NAME = "Example Organization"
        ORG_DBA = "ExampleOrg"
        ORG_URL = "https://example.com"
        ORG_LOGO = "https://example.com/logo.png"
        ORG_DESCRIPTION = "A test organization for Stellar"
        ORG_PHYSICAL_ADDRESS = "123 Main St, City, Country"
        ORG_PHYSICAL_ADDRESS_ATTESTATION = "https://example.com/address-proof.pdf"
        ORG_PHONE_NUMBER = "+1234567890"
        ORG_PHONE_NUMBER_ATTESTATION = "https://example.com/phone-proof.pdf"
        ORG_KEYBASE = "exampleorg"
        ORG_TWITTER = "exampleorg"
        ORG_GITHUB = "exampleorg"
        ORG_OFFICIAL_EMAIL = "official@example.com"
        ORG_SUPPORT_EMAIL = "support@example.com"
        ORG_LICENSING_AUTHORITY = "Financial Authority"
        ORG_LICENSE_TYPE = "Money Transmitter"
        ORG_LICENSE_NUMBER = "MT-12345"
        """

        let stellarToml = try StellarToml(fromString: tomlString)

        // Verify account information
        XCTAssertEqual(stellarToml.accountInformation.version, "2.7.0")
        XCTAssertEqual(stellarToml.accountInformation.networkPassphrase, "Public Global Stellar Network ; September 2015")
        XCTAssertEqual(stellarToml.accountInformation.federationServer, "https://federation.example.com")
        XCTAssertEqual(stellarToml.accountInformation.authServer, "https://auth.example.com")
        XCTAssertEqual(stellarToml.accountInformation.transferServer, "https://transfer.example.com")
        XCTAssertEqual(stellarToml.accountInformation.transferServerSep24, "https://transfer24.example.com")
        XCTAssertEqual(stellarToml.accountInformation.kycServer, "https://kyc.example.com")
        XCTAssertEqual(stellarToml.accountInformation.webAuthEndpoint, "https://webauth.example.com")
        XCTAssertEqual(stellarToml.accountInformation.webAuthForContractsEndpoint, "https://webauth-contracts.example.com")
        XCTAssertEqual(stellarToml.accountInformation.webAuthContractId, "CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC")
        XCTAssertEqual(stellarToml.accountInformation.signingKey, "GBBM6BKZPEHWYO3E3YKREDPQXMS4VK35YLNU7NFBRI26RAN7GI5POFBB")
        XCTAssertEqual(stellarToml.accountInformation.horizonUrl, "https://horizon.example.com")
        XCTAssertEqual(stellarToml.accountInformation.accounts.count, 2)
        XCTAssertEqual(stellarToml.accountInformation.accounts[0], "GABC123")
        XCTAssertEqual(stellarToml.accountInformation.uriRequestSigningKey, "GXYZ789")
        XCTAssertEqual(stellarToml.accountInformation.directPaymentServer, "https://directpay.example.com")
        XCTAssertEqual(stellarToml.accountInformation.anchorQuoteServer, "https://quote.example.com")

        // Verify issuer documentation
        XCTAssertEqual(stellarToml.issuerDocumentation.orgName, "Example Organization")
        XCTAssertEqual(stellarToml.issuerDocumentation.orgDBA, "ExampleOrg")
        XCTAssertEqual(stellarToml.issuerDocumentation.orgURL, "https://example.com")
        XCTAssertEqual(stellarToml.issuerDocumentation.orgLogo, "https://example.com/logo.png")
        XCTAssertEqual(stellarToml.issuerDocumentation.orgDescription, "A test organization for Stellar")
        XCTAssertEqual(stellarToml.issuerDocumentation.orgPhysicalAddress, "123 Main St, City, Country")
        XCTAssertEqual(stellarToml.issuerDocumentation.orgPhysicalAddressAttestation, "https://example.com/address-proof.pdf")
        XCTAssertEqual(stellarToml.issuerDocumentation.orgPhoneNumber, "+1234567890")
        XCTAssertEqual(stellarToml.issuerDocumentation.orgPhoneNumberAttestation, "https://example.com/phone-proof.pdf")
        XCTAssertEqual(stellarToml.issuerDocumentation.orgKeybase, "exampleorg")
        XCTAssertEqual(stellarToml.issuerDocumentation.orgTwitter, "exampleorg")
        XCTAssertEqual(stellarToml.issuerDocumentation.orgGithub, "exampleorg")
        XCTAssertEqual(stellarToml.issuerDocumentation.orgOfficialEmail, "official@example.com")
        XCTAssertEqual(stellarToml.issuerDocumentation.orgSupportEmail, "support@example.com")
        XCTAssertEqual(stellarToml.issuerDocumentation.orgLicensingAuthority, "Financial Authority")
        XCTAssertEqual(stellarToml.issuerDocumentation.orgLicenseType, "Money Transmitter")
        XCTAssertEqual(stellarToml.issuerDocumentation.orgLicenseNumber, "MT-12345")
    }

    func testParseMinimalToml() throws {
        let minimalToml = """
        [DOCUMENTATION]
        ORG_NAME = "Minimal Org"
        """

        let stellarToml = try StellarToml(fromString: minimalToml)

        XCTAssertNotNil(stellarToml, "Should parse minimal stellar.toml")
        XCTAssertEqual(stellarToml.issuerDocumentation.orgName, "Minimal Org")
        XCTAssertNil(stellarToml.accountInformation.version)
        XCTAssertNil(stellarToml.accountInformation.federationServer)
        XCTAssertTrue(stellarToml.currenciesDocumentation.isEmpty)
        XCTAssertTrue(stellarToml.validatorsInformation.isEmpty)
        XCTAssertTrue(stellarToml.pointsOfContact.isEmpty)
    }

    // MARK: - Service Endpoints Tests

    func testParseFederationServer() throws {
        let tomlString = """
        FEDERATION_SERVER = "https://federation.stellar.org"

        [DOCUMENTATION]
        ORG_NAME = "Stellar Foundation"
        """

        let stellarToml = try StellarToml(fromString: tomlString)

        XCTAssertEqual(stellarToml.accountInformation.federationServer, "https://federation.stellar.org")
    }

    func testParseAuthServer() throws {
        let tomlString = """
        AUTH_SERVER = "https://auth.stellar.org"

        [DOCUMENTATION]
        ORG_NAME = "Stellar Foundation"
        """

        let stellarToml = try StellarToml(fromString: tomlString)

        XCTAssertEqual(stellarToml.accountInformation.authServer, "https://auth.stellar.org")
    }

    func testParseTransferServer() throws {
        let tomlString = """
        TRANSFER_SERVER = "https://transfer.stellar.org"
        TRANSFER_SERVER_SEP0024 = "https://transfer24.stellar.org"

        [DOCUMENTATION]
        ORG_NAME = "Stellar Foundation"
        """

        let stellarToml = try StellarToml(fromString: tomlString)

        XCTAssertEqual(stellarToml.accountInformation.transferServer, "https://transfer.stellar.org")
        XCTAssertEqual(stellarToml.accountInformation.transferServerSep24, "https://transfer24.stellar.org")
    }

    func testParseKycServer() throws {
        let tomlString = """
        KYC_SERVER = "https://kyc.stellar.org"

        [DOCUMENTATION]
        ORG_NAME = "Stellar Foundation"
        """

        let stellarToml = try StellarToml(fromString: tomlString)

        XCTAssertEqual(stellarToml.accountInformation.kycServer, "https://kyc.stellar.org")
    }

    func testParseWebAuthEndpoint() throws {
        let tomlString = """
        WEB_AUTH_ENDPOINT = "https://webauth.stellar.org"
        WEB_AUTH_FOR_CONTRACTS_ENDPOINT = "https://webauth-contracts.stellar.org"
        WEB_AUTH_CONTRACT_ID = "CABC123"

        [DOCUMENTATION]
        ORG_NAME = "Stellar Foundation"
        """

        let stellarToml = try StellarToml(fromString: tomlString)

        XCTAssertEqual(stellarToml.accountInformation.webAuthEndpoint, "https://webauth.stellar.org")
        XCTAssertEqual(stellarToml.accountInformation.webAuthForContractsEndpoint, "https://webauth-contracts.stellar.org")
        XCTAssertEqual(stellarToml.accountInformation.webAuthContractId, "CABC123")
    }

    func testParseSigningKey() throws {
        let tomlString = """
        SIGNING_KEY = "GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP"

        [DOCUMENTATION]
        ORG_NAME = "Stellar Foundation"
        """

        let stellarToml = try StellarToml(fromString: tomlString)

        XCTAssertEqual(stellarToml.accountInformation.signingKey, "GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP")
    }

    // MARK: - Currencies Tests

    func testParseCurrencies() throws {
        let tomlString = """
        [DOCUMENTATION]
        ORG_NAME = "Test Org"

        [[CURRENCIES]]
        code = "USD"
        issuer = "GBBM6BKZPEHWYO3E3YKREDPQXMS4VK35YLNU7NFBRI26RAN7GI5POFBB"
        status = "live"
        display_decimals = 2
        name = "US Dollar"
        desc = "United States Dollar"
        image = "https://example.com/usd.png"
        is_asset_anchored = true
        anchor_asset_type = "fiat"
        anchor_asset = "USD"

        [[CURRENCIES]]
        code = "BTC"
        issuer = "GB7KKHHVYLDIZEKYJPAJUOTBE5E3NJAXPSDZK7O6O44WR3EBRO5HRPVT"
        status = "live"
        display_decimals = 7
        name = "Bitcoin"
        desc = "Bitcoin token"
        is_asset_anchored = true
        anchor_asset_type = "crypto"
        anchor_asset = "BTC"
        """

        let stellarToml = try StellarToml(fromString: tomlString)

        XCTAssertEqual(stellarToml.currenciesDocumentation.count, 2, "Should parse two currencies")

        let usd = stellarToml.currenciesDocumentation[0]
        XCTAssertEqual(usd.code, "USD")
        XCTAssertEqual(usd.issuer, "GBBM6BKZPEHWYO3E3YKREDPQXMS4VK35YLNU7NFBRI26RAN7GI5POFBB")
        XCTAssertEqual(usd.status, "live")
        XCTAssertEqual(usd.displayDecimals, 2)
        XCTAssertEqual(usd.name, "US Dollar")
        XCTAssertEqual(usd.desc, "United States Dollar")
        XCTAssertEqual(usd.image, "https://example.com/usd.png")
        XCTAssertEqual(usd.isAssetAnchored, true)
        XCTAssertEqual(usd.anchorAssetType, "fiat")
        XCTAssertEqual(usd.anchorAsset, "USD")

        let btc = stellarToml.currenciesDocumentation[1]
        XCTAssertEqual(btc.code, "BTC")
        XCTAssertEqual(btc.issuer, "GB7KKHHVYLDIZEKYJPAJUOTBE5E3NJAXPSDZK7O6O44WR3EBRO5HRPVT")
        XCTAssertEqual(btc.displayDecimals, 7)
        XCTAssertEqual(btc.anchorAssetType, "crypto")
    }

    func testParseCurrencyWithContract() throws {
        let tomlString = """
        [DOCUMENTATION]
        ORG_NAME = "Test Org"

        [[CURRENCIES]]
        code = "USDC"
        contract = "CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE"
        name = "USD Coin"
        desc = "Soroban USDC token"
        """

        let stellarToml = try StellarToml(fromString: tomlString)

        XCTAssertEqual(stellarToml.currenciesDocumentation.count, 1)

        let usdc = stellarToml.currenciesDocumentation[0]
        XCTAssertEqual(usdc.code, "USDC")
        XCTAssertEqual(usdc.contract, "CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE")
        XCTAssertEqual(usdc.name, "USD Coin")
    }

    func testParseCurrencyWithSupplyInfo() throws {
        let tomlString = """
        [DOCUMENTATION]
        ORG_NAME = "Test Org"

        [[CURRENCIES]]
        code = "TOKEN"
        issuer = "GBBM6BKZPEHWYO3E3YKREDPQXMS4VK35YLNU7NFBRI26RAN7GI5POFBB"
        fixed_number = 1000000
        """

        let stellarToml = try StellarToml(fromString: tomlString)

        let token = stellarToml.currenciesDocumentation[0]
        XCTAssertEqual(token.fixedNumber, 1000000)
    }

    func testParseCurrencyWithRegulation() throws {
        let tomlString = """
        [DOCUMENTATION]
        ORG_NAME = "Test Org"

        [[CURRENCIES]]
        code = "REG"
        issuer = "GBBM6BKZPEHWYO3E3YKREDPQXMS4VK35YLNU7NFBRI26RAN7GI5POFBB"
        regulated = true
        approval_server = "https://approval.example.com"
        approval_criteria = "Must pass KYC"
        """

        let stellarToml = try StellarToml(fromString: tomlString)

        let reg = stellarToml.currenciesDocumentation[0]
        XCTAssertEqual(reg.regulated, true)
        XCTAssertEqual(reg.approvalServer, "https://approval.example.com")
        XCTAssertEqual(reg.approvalCriteria, "Must pass KYC")
    }

    func testParseCurrencyWithCollateral() throws {
        let tomlString = """
        [DOCUMENTATION]
        ORG_NAME = "Test Org"

        [[CURRENCIES]]
        code = "BTC"
        issuer = "GBBM6BKZPEHWYO3E3YKREDPQXMS4VK35YLNU7NFBRI26RAN7GI5POFBB"
        is_asset_anchored = true
        anchor_asset_type = "crypto"
        anchor_asset = "BTC"
        collateral_addresses = ["1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa", "3J98t1WpEZ73CNmYviecrnyiWrnqRhWNLy"]
        collateral_address_messages = ["msg1", "msg2"]
        collateral_address_signatures = ["sig1", "sig2"]
        """

        let stellarToml = try StellarToml(fromString: tomlString)

        let btc = stellarToml.currenciesDocumentation[0]
        XCTAssertEqual(btc.collateralAddresses.count, 2)
        XCTAssertEqual(btc.collateralAddresses[0], "1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa")
        XCTAssertEqual(btc.collateralAddressMessages.count, 2)
        XCTAssertEqual(btc.collateralAddressSignatures.count, 2)
    }

    // MARK: - Validators Tests

    func testParseValidators() throws {
        let tomlString = """
        [DOCUMENTATION]
        ORG_NAME = "Test Org"

        [[VALIDATORS]]
        ALIAS = "validator1"
        DISPLAY_NAME = "Validator One"
        PUBLIC_KEY = "GBBM6BKZPEHWYO3E3YKREDPQXMS4VK35YLNU7NFBRI26RAN7GI5POFBB"
        HOST = "validator1.example.com:11625"
        HISTORY = "https://history.example.com/validator1"

        [[VALIDATORS]]
        ALIAS = "validator2"
        DISPLAY_NAME = "Validator Two"
        PUBLIC_KEY = "GB7KKHHVYLDIZEKYJPAJUOTBE5E3NJAXPSDZK7O6O44WR3EBRO5HRPVT"
        HOST = "validator2.example.com:11625"
        HISTORY = "https://history.example.com/validator2"
        """

        let stellarToml = try StellarToml(fromString: tomlString)

        XCTAssertEqual(stellarToml.validatorsInformation.count, 2, "Should parse two validators")

        let validator1 = stellarToml.validatorsInformation[0]
        XCTAssertEqual(validator1.alias, "validator1")
        XCTAssertEqual(validator1.displayName, "Validator One")
        XCTAssertEqual(validator1.publicKey, "GBBM6BKZPEHWYO3E3YKREDPQXMS4VK35YLNU7NFBRI26RAN7GI5POFBB")
        XCTAssertEqual(validator1.host, "validator1.example.com:11625")
        XCTAssertEqual(validator1.history, "https://history.example.com/validator1")

        let validator2 = stellarToml.validatorsInformation[1]
        XCTAssertEqual(validator2.alias, "validator2")
        XCTAssertEqual(validator2.displayName, "Validator Two")
    }

    // MARK: - Documentation Tests

    func testParseDocumentation() throws {
        let tomlString = """
        [DOCUMENTATION]
        ORG_NAME = "Stellar Development Foundation"
        ORG_DBA = "SDF"
        ORG_URL = "https://stellar.org"
        ORG_LOGO = "https://stellar.org/logo.png"
        ORG_DESCRIPTION = "Building the future of finance"
        ORG_PHYSICAL_ADDRESS = "123 Mission St, San Francisco, CA"
        ORG_PHYSICAL_ADDRESS_ATTESTATION = "https://stellar.org/address-proof.pdf"
        ORG_PHONE_NUMBER = "+14155551234"
        ORG_PHONE_NUMBER_ATTESTATION = "https://stellar.org/phone-proof.pdf"
        ORG_KEYBASE = "stellarorg"
        ORG_TWITTER = "stellarorg"
        ORG_GITHUB = "stellar"
        ORG_OFFICIAL_EMAIL = "contact@stellar.org"
        ORG_SUPPORT_EMAIL = "support@stellar.org"
        ORG_LICENSING_AUTHORITY = "FinCEN"
        ORG_LICENSE_TYPE = "Money Services Business"
        ORG_LICENSE_NUMBER = "MSB-12345"
        """

        let stellarToml = try StellarToml(fromString: tomlString)

        let doc = stellarToml.issuerDocumentation
        XCTAssertEqual(doc.orgName, "Stellar Development Foundation")
        XCTAssertEqual(doc.orgDBA, "SDF")
        XCTAssertEqual(doc.orgURL, "https://stellar.org")
        XCTAssertEqual(doc.orgLogo, "https://stellar.org/logo.png")
        XCTAssertEqual(doc.orgDescription, "Building the future of finance")
        XCTAssertEqual(doc.orgPhysicalAddress, "123 Mission St, San Francisco, CA")
        XCTAssertEqual(doc.orgPhysicalAddressAttestation, "https://stellar.org/address-proof.pdf")
        XCTAssertEqual(doc.orgPhoneNumber, "+14155551234")
        XCTAssertEqual(doc.orgPhoneNumberAttestation, "https://stellar.org/phone-proof.pdf")
        XCTAssertEqual(doc.orgKeybase, "stellarorg")
        XCTAssertEqual(doc.orgTwitter, "stellarorg")
        XCTAssertEqual(doc.orgGithub, "stellar")
        XCTAssertEqual(doc.orgOfficialEmail, "contact@stellar.org")
        XCTAssertEqual(doc.orgSupportEmail, "support@stellar.org")
        XCTAssertEqual(doc.orgLicensingAuthority, "FinCEN")
        XCTAssertEqual(doc.orgLicenseType, "Money Services Business")
        XCTAssertEqual(doc.orgLicenseNumber, "MSB-12345")
    }

    // MARK: - Principals Tests

    func testParsePrincipals() throws {
        let tomlString = """
        [DOCUMENTATION]
        ORG_NAME = "Test Org"

        [[PRINCIPALS]]
        name = "Jane Doe"
        email = "jane@example.com"
        keybase = "janedoe"
        telegram = "janedoe"
        twitter = "janedoe"
        github = "janedoe"
        id_photo_hash = "be688838ca8686e5c90689bf2ab585cef1137c999b48c70b92f67a5c34dc15697b5d11c982ed6d71be1e1e7f7b4e0733884aa97c3f7a339a8ed03577cf74be09"
        verification_photo_hash = "016ba8c4cfde65af99cb5fa8b8a37e2eb73f481b3ae34991666df2e04feb6c038666ebd1ec2b6f623967756033c702dde5f423f7d47ab6ed1827ff53783731f7"

        [[PRINCIPALS]]
        name = "John Smith"
        email = "john@example.com"
        """

        let stellarToml = try StellarToml(fromString: tomlString)

        XCTAssertEqual(stellarToml.pointsOfContact.count, 2, "Should parse two principals")

        let principal1 = stellarToml.pointsOfContact[0]
        XCTAssertEqual(principal1.name, "Jane Doe")
        XCTAssertEqual(principal1.email, "jane@example.com")
        XCTAssertEqual(principal1.keybase, "janedoe")
        XCTAssertEqual(principal1.telegram, "janedoe")
        XCTAssertEqual(principal1.twitter, "janedoe")
        XCTAssertEqual(principal1.github, "janedoe")
        XCTAssertNotNil(principal1.idPhotoHash)
        XCTAssertNotNil(principal1.verificationPhotoHash)

        let principal2 = stellarToml.pointsOfContact[1]
        XCTAssertEqual(principal2.name, "John Smith")
        XCTAssertEqual(principal2.email, "john@example.com")
        XCTAssertNil(principal2.keybase)
    }

    // MARK: - Error Handling Tests

    func testInvalidTomlThrowsError() {
        let invalidToml = """
        [DOCUMENTATION
        ORG_NAME = "Test"
        """

        XCTAssertThrowsError(try StellarToml(fromString: invalidToml), "Invalid TOML should throw error") { error in
            XCTAssertTrue(error is TomlFileError, "Should throw TomlFileError")
            if let tomlError = error as? TomlFileError {
                XCTAssertEqual(tomlError, TomlFileError.invalidToml, "Should be invalidToml error")
            }
        }
    }

    func testEmptyDocumentationSection() throws {
        // The parser appears to handle missing DOCUMENTATION gracefully
        // by creating an empty documentation object
        let tomlWithoutDoc = """
        [DOCUMENTATION]
        """

        let stellarToml = try StellarToml(fromString: tomlWithoutDoc)

        XCTAssertNotNil(stellarToml.issuerDocumentation, "Should have issuer documentation object")
        XCTAssertNil(stellarToml.issuerDocumentation.orgName, "Org name should be nil when not provided")
    }

    // MARK: - Real-World Example Tests

    func testParseRealWorldExample() throws {
        let realWorldToml = """
        VERSION = "2.7.0"
        NETWORK_PASSPHRASE = "Public Global Stellar Network ; September 2015"
        FEDERATION_SERVER = "https://api.testanchor.stellar.org/federation"
        AUTH_SERVER = "https://api.testanchor.stellar.org/auth"
        TRANSFER_SERVER = "https://api.testanchor.stellar.org"
        TRANSFER_SERVER_SEP0024 = "https://api.testanchor.stellar.org/sep24"
        KYC_SERVER = "https://api.testanchor.stellar.org/kyc"
        WEB_AUTH_ENDPOINT = "https://api.testanchor.stellar.org/auth"
        SIGNING_KEY = "GCKFBEIYV2U22IO2BJ4KVJOIP7XPWQGQFKKWXR6DOSJBV7STMAQSMTGG"
        HORIZON_URL = "https://horizon-testnet.stellar.org"
        ACCOUNTS = ["GCKFBEIYV2U22IO2BJ4KVJOIP7XPWQGQFKKWXR6DOSJBV7STMAQSMTGG"]
        DIRECT_PAYMENT_SERVER = "https://api.testanchor.stellar.org/sep31"

        [DOCUMENTATION]
        ORG_NAME = "Test Anchor"
        ORG_DBA = "Test Anchor"
        ORG_URL = "https://testanchor.stellar.org"
        ORG_LOGO = "https://testanchor.stellar.org/logo.png"
        ORG_DESCRIPTION = "Test anchor for Stellar integration testing"
        ORG_OFFICIAL_EMAIL = "support@testanchor.stellar.org"

        [[CURRENCIES]]
        code = "USD"
        issuer = "GCKFBEIYV2U22IO2BJ4KVJOIP7XPWQGQFKKWXR6DOSJBV7STMAQSMTGG"
        status = "test"
        display_decimals = 2
        name = "US Dollar"
        desc = "Test USD token"
        is_asset_anchored = true
        anchor_asset_type = "fiat"
        anchor_asset = "USD"

        [[CURRENCIES]]
        code = "ETH"
        issuer = "GCKFBEIYV2U22IO2BJ4KVJOIP7XPWQGQFKKWXR6DOSJBV7STMAQSMTGG"
        status = "test"
        display_decimals = 7
        name = "Ethereum"
        desc = "Test ETH token"
        is_asset_anchored = true
        anchor_asset_type = "crypto"
        anchor_asset = "ETH"
        """

        let stellarToml = try StellarToml(fromString: realWorldToml)

        // Verify basic structure
        XCTAssertNotNil(stellarToml)
        XCTAssertEqual(stellarToml.accountInformation.version, "2.7.0")
        XCTAssertEqual(stellarToml.issuerDocumentation.orgName, "Test Anchor")
        XCTAssertEqual(stellarToml.currenciesDocumentation.count, 2)
        XCTAssertTrue(stellarToml.validatorsInformation.isEmpty)
        XCTAssertTrue(stellarToml.pointsOfContact.isEmpty)

        // Verify service endpoints
        XCTAssertNotNil(stellarToml.accountInformation.federationServer)
        XCTAssertNotNil(stellarToml.accountInformation.authServer)
        XCTAssertNotNil(stellarToml.accountInformation.transferServer)
        XCTAssertNotNil(stellarToml.accountInformation.kycServer)
        XCTAssertNotNil(stellarToml.accountInformation.webAuthEndpoint)

        // Verify currencies
        let usd = stellarToml.currenciesDocumentation.first { $0.code == "USD" }
        XCTAssertNotNil(usd)
        XCTAssertEqual(usd?.status, "test")
        XCTAssertEqual(usd?.isAssetAnchored, true)

        let eth = stellarToml.currenciesDocumentation.first { $0.code == "ETH" }
        XCTAssertNotNil(eth)
        XCTAssertEqual(eth?.anchorAssetType, "crypto")
    }

    func testParseCompleteExample() throws {
        let completeToml = """
        VERSION = "2.7.0"
        NETWORK_PASSPHRASE = "Public Global Stellar Network ; September 2015"
        FEDERATION_SERVER = "https://api.example.com/federation"
        TRANSFER_SERVER = "https://api.example.com"
        WEB_AUTH_ENDPOINT = "https://api.example.com/auth"
        SIGNING_KEY = "GBBM6BKZPEHWYO3E3YKREDPQXMS4VK35YLNU7NFBRI26RAN7GI5POFBB"
        ACCOUNTS = ["GBBM6BKZPEHWYO3E3YKREDPQXMS4VK35YLNU7NFBRI26RAN7GI5POFBB"]

        [DOCUMENTATION]
        ORG_NAME = "Example Organization"
        ORG_URL = "https://example.com"
        ORG_LOGO = "https://example.com/logo.png"
        ORG_DESCRIPTION = "Example organization description"
        ORG_OFFICIAL_EMAIL = "contact@example.com"

        [[CURRENCIES]]
        code = "USD"
        issuer = "GBBM6BKZPEHWYO3E3YKREDPQXMS4VK35YLNU7NFBRI26RAN7GI5POFBB"
        status = "live"
        name = "US Dollar"

        [[PRINCIPALS]]
        name = "CEO Name"
        email = "ceo@example.com"

        [[VALIDATORS]]
        ALIAS = "main-validator"
        DISPLAY_NAME = "Main Validator"
        PUBLIC_KEY = "GBBM6BKZPEHWYO3E3YKREDPQXMS4VK35YLNU7NFBRI26RAN7GI5POFBB"
        """

        let stellarToml = try StellarToml(fromString: completeToml)

        // Verify all sections are present
        XCTAssertNotNil(stellarToml.accountInformation)
        XCTAssertNotNil(stellarToml.issuerDocumentation)
        XCTAssertEqual(stellarToml.currenciesDocumentation.count, 1)
        XCTAssertEqual(stellarToml.pointsOfContact.count, 1)
        XCTAssertEqual(stellarToml.validatorsInformation.count, 1)

        // Spot check values from each section
        XCTAssertEqual(stellarToml.accountInformation.signingKey, "GBBM6BKZPEHWYO3E3YKREDPQXMS4VK35YLNU7NFBRI26RAN7GI5POFBB")
        XCTAssertEqual(stellarToml.issuerDocumentation.orgName, "Example Organization")
        XCTAssertEqual(stellarToml.currenciesDocumentation[0].code, "USD")
        XCTAssertEqual(stellarToml.pointsOfContact[0].name, "CEO Name")
        XCTAssertEqual(stellarToml.validatorsInformation[0].alias, "main-validator")
    }

    // MARK: - Edge Cases Tests

    func testParseEmptyCurrenciesSection() throws {
        let tomlString = """
        [DOCUMENTATION]
        ORG_NAME = "Test Org"

        [CURRENCIES]
        """

        let stellarToml = try StellarToml(fromString: tomlString)

        XCTAssertTrue(stellarToml.currenciesDocumentation.isEmpty, "Empty CURRENCIES section should result in empty array")
    }

    func testParseEmptyPrincipalsSection() throws {
        let tomlString = """
        [DOCUMENTATION]
        ORG_NAME = "Test Org"

        [PRINCIPALS]
        """

        let stellarToml = try StellarToml(fromString: tomlString)

        XCTAssertTrue(stellarToml.pointsOfContact.isEmpty, "Empty PRINCIPALS section should result in empty array")
    }

    func testParseEmptyValidatorsSection() throws {
        let tomlString = """
        [DOCUMENTATION]
        ORG_NAME = "Test Org"

        [VALIDATORS]
        """

        let stellarToml = try StellarToml(fromString: tomlString)

        XCTAssertTrue(stellarToml.validatorsInformation.isEmpty, "Empty VALIDATORS section should result in empty array")
    }

    func testParseWithCommentsAndWhitespace() throws {
        let tomlString = """
        # Stellar TOML configuration
        VERSION = "2.7.0"

        # Service endpoints
        FEDERATION_SERVER = "https://federation.example.com"

        [DOCUMENTATION]
        # Organization information
        ORG_NAME = "Test Org"
        ORG_URL = "https://example.com"  # Main website
        """

        let stellarToml = try StellarToml(fromString: tomlString)

        XCTAssertEqual(stellarToml.accountInformation.version, "2.7.0")
        XCTAssertEqual(stellarToml.accountInformation.federationServer, "https://federation.example.com")
        XCTAssertEqual(stellarToml.issuerDocumentation.orgURL, "https://example.com")
    }

    func testParseAccountsArray() throws {
        let tomlString = """
        ACCOUNTS = [
            "GBBM6BKZPEHWYO3E3YKREDPQXMS4VK35YLNU7NFBRI26RAN7GI5POFBB",
            "GB7KKHHVYLDIZEKYJPAJUOTBE5E3NJAXPSDZK7O6O44WR3EBRO5HRPVT",
            "GD6WVYRVID442Y4JVWFWKWCZKB45UGHJAABBJRS22TUSTWGJYXIUR7N2"
        ]

        [DOCUMENTATION]
        ORG_NAME = "Test Org"
        """

        let stellarToml = try StellarToml(fromString: tomlString)

        XCTAssertEqual(stellarToml.accountInformation.accounts.count, 3)
        XCTAssertEqual(stellarToml.accountInformation.accounts[0], "GBBM6BKZPEHWYO3E3YKREDPQXMS4VK35YLNU7NFBRI26RAN7GI5POFBB")
        XCTAssertEqual(stellarToml.accountInformation.accounts[2], "GD6WVYRVID442Y4JVWFWKWCZKB45UGHJAABBJRS22TUSTWGJYXIUR7N2")
    }
}
