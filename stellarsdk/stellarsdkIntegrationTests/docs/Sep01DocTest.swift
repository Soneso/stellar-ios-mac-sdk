//
//  Sep01DocTest.swift
//  stellarsdkIntegrationTests
//
//  Tests for SEP-01 documentation code examples.
//  Uses StellarToml(fromString:) with inline TOML content to avoid network calls.
//

import XCTest
import stellarsdk

class Sep01DocTest: XCTestCase {

    // A comprehensive TOML string covering all sections documented in sep-01.md.
    let sampleToml = """
    VERSION="2.0.0"
    NETWORK_PASSPHRASE="Test SDF Network ; September 2015"
    FEDERATION_SERVER="https://example.com/federation"
    TRANSFER_SERVER="https://example.com/transfer"
    TRANSFER_SERVER_SEP0024="https://example.com/sep24"
    KYC_SERVER="https://example.com/kyc"
    WEB_AUTH_ENDPOINT="https://example.com/auth"
    WEB_AUTH_FOR_CONTRACTS_ENDPOINT="https://example.com/web_auth_contracts"
    WEB_AUTH_CONTRACT_ID="CBGTG7ZOL3XW2YQJVUX6V2OVDVQPVXVKKYKQ4PWZCZ3QXJIHXGZ6R2KJ"
    SIGNING_KEY="GBBHQ7H4V6RRORKYLHTCAWP6MOHNORRFJSDPXDFYDGJB2LPZUFPXUEW3"
    URI_REQUEST_SIGNING_KEY="GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV"
    HORIZON_URL="https://horizon.example.com"
    AUTH_SERVER="https://example.com/compliance"
    DIRECT_PAYMENT_SERVER="https://example.com/direct"
    ANCHOR_QUOTE_SERVER="https://example.com/quotes"
    ACCOUNTS=[
    "GD5DJQDDBKGAYNEAXU562HYGOOSYAEOO6AS53PZXBOZGCP5M2OPGMZV3",
    "GAENZLGHJGJRCMX5VCHOLHQXU3EMCU5XWDNU4BGGJFNLI2EL354IVBK7"
    ]

    [DOCUMENTATION]
    ORG_NAME="Example Anchor"
    ORG_DBA="Example DBA"
    ORG_URL="https://example.com"
    ORG_LOGO="https://example.com/logo.png"
    ORG_DESCRIPTION="An example anchor for testing"
    ORG_PHYSICAL_ADDRESS="123 Test Street, Testville"
    ORG_PHYSICAL_ADDRESS_ATTESTATION="https://example.com/address_proof.jpg"
    ORG_PHONE_NUMBER="+14155551234"
    ORG_PHONE_NUMBER_ATTESTATION="https://example.com/phone_proof.jpg"
    ORG_KEYBASE="examplekeybase"
    ORG_TWITTER="exampletwitter"
    ORG_GITHUB="examplegithub"
    ORG_OFFICIAL_EMAIL="official@example.com"
    ORG_SUPPORT_EMAIL="support@example.com"
    ORG_LICENSING_AUTHORITY="Test Authority"
    ORG_LICENSE_TYPE="Money Transmitter"
    ORG_LICENSE_NUMBER="MT-12345"

    [[PRINCIPALS]]
    name="Jane Doe"
    email="jane@example.com"
    keybase="jane_keybase"
    telegram="jane_telegram"
    twitter="jane_twitter"
    github="jane_github"
    id_photo_hash="abc123"
    verification_photo_hash="def456"

    [[CURRENCIES]]
    code="USD"
    issuer="GCZJM35NKGVK47BB4SPBDV25477PZYIYPVVG453LPYFNXLS3FGHDXOCM"
    display_decimals=2
    name="US Dollar"
    desc="A USD stablecoin"
    conditions="Redeemable 1:1 for USD"
    image="https://example.com/usd.png"
    status="live"
    is_asset_anchored=true
    anchor_asset_type="fiat"
    anchor_asset="USD"
    attestation_of_reserve="https://example.com/audit"
    redemption_instructions="Redeem via SEP-24"
    regulated=true
    approval_server="https://example.com/approve"
    approval_criteria="KYC required"

    [[CURRENCIES]]
    code="BTC"
    issuer="GAOO3LWBC4XF6VWRP5ESJ6IBHAISVJMSBTALHOQM2EZG7Q477UWA6L7U"
    display_decimals=7
    anchor_asset_type="crypto"
    anchor_asset="BTC"
    collateral_addresses=["2C1mCx3ukix1KfegAY5zgQJV7sanAciZpv"]
    collateral_address_signatures=["304502206e21798a42fae0e854281abd38bacd1aeed3ee3738d9e1446618c4571d10"]

    [[CURRENCIES]]
    code="USDC"
    contract="CBGTG7ZOL3XW2YQJVUX6V2OVDVQPVXVKKYKQ4PWZCZ3QXJIHXGZ6R2KJ"
    display_decimals=7

    [[CURRENCIES]]
    code="GOAT"
    issuer="GD5T6IPRNCKFOHQWT264YPKOZAWUMMZOLZBJ6BNQMUGPWGRLBK3U7ZNP"
    display_decimals=2
    name="goat share"
    desc="1 GOAT token entitles you to a share of revenue from Elkins Goat Farm."
    conditions="There will only ever be 10,000 GOAT tokens in existence."
    image="https://example.com/goat.png"
    fixed_number=10000

    [[VALIDATORS]]
    ALIAS="node-au"
    DISPLAY_NAME="Australia Node"
    HOST="core-au.example.com:11625"
    PUBLIC_KEY="GD5DJQDDBKGAYNEAXU562HYGOOSYAEOO6AS53PZXBOZGCP5M2OPGMZV3"
    HISTORY="http://history.example.com/core_live_001/"

    [[VALIDATORS]]
    ALIAS="node-us"
    DISPLAY_NAME="United States Node"
    HOST="core-us.example.com:11625"
    PUBLIC_KEY="GAENZLGHJGJRCMX5VCHOLHQXU3EMCU5XWDNU4BGGJFNLI2EL354IVBK7"
    HISTORY="http://history.example.com/core_live_002/"
    """

    // MARK: - Test: Quick example (from string, mirrors quick example snippet)

    func testQuickExample() {
        do {
            let stellarToml = try StellarToml(fromString: sampleToml)

            let info = stellarToml.accountInformation
            XCTAssertEqual("https://example.com/sep24", info.transferServerSep24)
            XCTAssertEqual("https://example.com/auth", info.webAuthEndpoint)
        } catch {
            XCTFail("Failed to parse TOML: \(error)")
        }
    }

    // MARK: - Test: Load from string (mirrors "From a string" snippet)

    func testFromString() {
        let tomlContent = """
        VERSION="2.0.0"
        NETWORK_PASSPHRASE="Test SDF Network ; September 2015"
        FEDERATION_SERVER="https://example.com/federation"
        TRANSFER_SERVER_SEP0024="https://example.com/sep24"
        WEB_AUTH_ENDPOINT="https://example.com/auth"
        SIGNING_KEY="GCKX7PGTILCAM6NKST6PWNCBSMLHZJKFWXFHQLE4SUVKBQY3HOOYUNK"

        [DOCUMENTATION]
        ORG_NAME="Example Anchor"
        ORG_URL="https://example.com"
        """

        do {
            let stellarToml = try StellarToml(fromString: tomlContent)
            let info = stellarToml.accountInformation
            XCTAssertEqual("2.0.0", info.version)
            XCTAssertEqual("https://example.com/federation", info.federationServer)
            XCTAssertEqual("https://example.com/sep24", info.transferServerSep24)
            XCTAssertEqual("https://example.com/auth", info.webAuthEndpoint)
            XCTAssertEqual("GCKX7PGTILCAM6NKST6PWNCBSMLHZJKFWXFHQLE4SUVKBQY3HOOYUNK", info.signingKey)
        } catch {
            XCTFail("Failed to parse TOML: \(error)")
        }
    }

    // MARK: - Test: General information / AccountInformation (mirrors "General information" snippet)

    func testGeneralInformation() {
        do {
            let stellarToml = try StellarToml(fromString: sampleToml)
            let info = stellarToml.accountInformation

            // Protocol version
            XCTAssertEqual("2.0.0", info.version)

            // Service endpoints
            XCTAssertEqual("https://example.com/federation", info.federationServer)
            XCTAssertEqual("https://example.com/transfer", info.transferServer)
            XCTAssertEqual("https://example.com/sep24", info.transferServerSep24)
            XCTAssertEqual("https://example.com/kyc", info.kycServer)
            XCTAssertEqual("https://example.com/auth", info.webAuthEndpoint)
            XCTAssertEqual("https://example.com/direct", info.directPaymentServer)
            XCTAssertEqual("https://example.com/quotes", info.anchorQuoteServer)

            // SEP-45
            XCTAssertEqual("https://example.com/web_auth_contracts", info.webAuthForContractsEndpoint)
            XCTAssertEqual("CBGTG7ZOL3XW2YQJVUX6V2OVDVQPVXVKKYKQ4PWZCZ3QXJIHXGZ6R2KJ", info.webAuthContractId)

            // Signing keys
            XCTAssertEqual("GBBHQ7H4V6RRORKYLHTCAWP6MOHNORRFJSDPXDFYDGJB2LPZUFPXUEW3", info.signingKey)
            XCTAssertEqual("GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV", info.uriRequestSigningKey)

            // Deprecated
            XCTAssertEqual("https://example.com/compliance", info.authServer)

            // Network info
            XCTAssertEqual("Test SDF Network ; September 2015", info.networkPassphrase)
            XCTAssertEqual("https://horizon.example.com", info.horizonUrl)

            // Accounts
            XCTAssertTrue(info.accounts.contains("GD5DJQDDBKGAYNEAXU562HYGOOSYAEOO6AS53PZXBOZGCP5M2OPGMZV3"))
            XCTAssertTrue(info.accounts.contains("GAENZLGHJGJRCMX5VCHOLHQXU3EMCU5XWDNU4BGGJFNLI2EL354IVBK7"))
            XCTAssertEqual(2, info.accounts.count)
        } catch {
            XCTFail("Failed to parse TOML: \(error)")
        }
    }

    // MARK: - Test: Organization documentation / IssuerDocumentation (mirrors "Organization documentation" snippet)

    func testOrganizationDocumentation() {
        do {
            let stellarToml = try StellarToml(fromString: sampleToml)
            let docs = stellarToml.issuerDocumentation

            XCTAssertEqual("Example Anchor", docs.orgName)
            XCTAssertEqual("Example DBA", docs.orgDBA)
            XCTAssertEqual("https://example.com", docs.orgURL)
            XCTAssertEqual("https://example.com/logo.png", docs.orgLogo)
            XCTAssertEqual("An example anchor for testing", docs.orgDescription)
            XCTAssertEqual("123 Test Street, Testville", docs.orgPhysicalAddress)
            XCTAssertEqual("https://example.com/address_proof.jpg", docs.orgPhysicalAddressAttestation)
            XCTAssertEqual("+14155551234", docs.orgPhoneNumber)
            XCTAssertEqual("https://example.com/phone_proof.jpg", docs.orgPhoneNumberAttestation)
            XCTAssertEqual("official@example.com", docs.orgOfficialEmail)
            XCTAssertEqual("support@example.com", docs.orgSupportEmail)
            XCTAssertEqual("examplekeybase", docs.orgKeybase)
            XCTAssertEqual("exampletwitter", docs.orgTwitter)
            XCTAssertEqual("examplegithub", docs.orgGithub)
            XCTAssertEqual("Test Authority", docs.orgLicensingAuthority)
            XCTAssertEqual("Money Transmitter", docs.orgLicenseType)
            XCTAssertEqual("MT-12345", docs.orgLicenseNumber)
        } catch {
            XCTFail("Failed to parse TOML: \(error)")
        }
    }

    // MARK: - Test: Principals / PointOfContactDocumentation (mirrors "Principals" snippet)

    func testPrincipals() {
        do {
            let stellarToml = try StellarToml(fromString: sampleToml)
            let principals = stellarToml.pointsOfContact

            XCTAssertEqual(1, principals.count)

            let principal = principals[0]
            XCTAssertEqual("Jane Doe", principal.name)
            XCTAssertEqual("jane@example.com", principal.email)
            XCTAssertEqual("jane_keybase", principal.keybase)
            XCTAssertEqual("jane_telegram", principal.telegram)
            XCTAssertEqual("jane_twitter", principal.twitter)
            XCTAssertEqual("jane_github", principal.github)
            XCTAssertEqual("abc123", principal.idPhotoHash)
            XCTAssertEqual("def456", principal.verificationPhotoHash)
        } catch {
            XCTFail("Failed to parse TOML: \(error)")
        }
    }

    // MARK: - Test: Currencies / CurrencyDocumentation (mirrors "Currencies" snippet)

    func testCurrencies() {
        do {
            let stellarToml = try StellarToml(fromString: sampleToml)
            let currencies = stellarToml.currenciesDocumentation

            XCTAssertEqual(4, currencies.count)

            // USD - classic asset with full metadata
            let usd = currencies[0]
            XCTAssertEqual("USD", usd.code)
            XCTAssertEqual("GCZJM35NKGVK47BB4SPBDV25477PZYIYPVVG453LPYFNXLS3FGHDXOCM", usd.issuer)
            XCTAssertEqual(2, usd.displayDecimals)
            XCTAssertEqual("US Dollar", usd.name)
            XCTAssertEqual("A USD stablecoin", usd.desc)
            XCTAssertEqual("Redeemable 1:1 for USD", usd.conditions)
            XCTAssertEqual("https://example.com/usd.png", usd.image)
            XCTAssertEqual("live", usd.status)
            XCTAssertEqual(true, usd.isAssetAnchored)
            XCTAssertEqual("fiat", usd.anchorAssetType)
            XCTAssertEqual("USD", usd.anchorAsset)
            XCTAssertEqual("https://example.com/audit", usd.attestationOfReserve)
            XCTAssertEqual("Redeem via SEP-24", usd.redemptionInstructions)
            XCTAssertEqual(true, usd.regulated)
            XCTAssertEqual("https://example.com/approve", usd.approvalServer)
            XCTAssertEqual("KYC required", usd.approvalCriteria)

            // BTC - crypto-backed with collateral
            let btc = currencies[1]
            XCTAssertEqual("BTC", btc.code)
            XCTAssertEqual("GAOO3LWBC4XF6VWRP5ESJ6IBHAISVJMSBTALHOQM2EZG7Q477UWA6L7U", btc.issuer)
            XCTAssertEqual(7, btc.displayDecimals)
            XCTAssertEqual("crypto", btc.anchorAssetType)
            XCTAssertEqual("BTC", btc.anchorAsset)
            XCTAssertTrue(btc.collateralAddresses.contains("2C1mCx3ukix1KfegAY5zgQJV7sanAciZpv"))
            XCTAssertTrue(btc.collateralAddressSignatures.contains(
                "304502206e21798a42fae0e854281abd38bacd1aeed3ee3738d9e1446618c4571d10"))

            // USDC - Soroban token contract
            let usdc = currencies[2]
            XCTAssertEqual("USDC", usdc.code)
            XCTAssertEqual("CBGTG7ZOL3XW2YQJVUX6V2OVDVQPVXVKKYKQ4PWZCZ3QXJIHXGZ6R2KJ", usdc.contract)
            XCTAssertNil(usdc.issuer)
            XCTAssertEqual(7, usdc.displayDecimals)

            // GOAT - asset with supply info
            let goat = currencies[3]
            XCTAssertEqual("GOAT", goat.code)
            XCTAssertEqual("GD5T6IPRNCKFOHQWT264YPKOZAWUMMZOLZBJ6BNQMUGPWGRLBK3U7ZNP", goat.issuer)
            XCTAssertEqual(2, goat.displayDecimals)
            XCTAssertEqual("goat share", goat.name)
            XCTAssertEqual("1 GOAT token entitles you to a share of revenue from Elkins Goat Farm.", goat.desc)
            XCTAssertEqual("There will only ever be 10,000 GOAT tokens in existence.", goat.conditions)
            XCTAssertEqual("https://example.com/goat.png", goat.image)
            XCTAssertEqual(10000, goat.fixedNumber)
        } catch {
            XCTFail("Failed to parse TOML: \(error)")
        }
    }

    // MARK: - Test: Validators / ValidatorInformation (mirrors "Validators" snippet)

    func testValidators() {
        do {
            let stellarToml = try StellarToml(fromString: sampleToml)
            let validators = stellarToml.validatorsInformation

            XCTAssertEqual(2, validators.count)

            XCTAssertEqual("node-au", validators[0].alias)
            XCTAssertEqual("Australia Node", validators[0].displayName)
            XCTAssertEqual("core-au.example.com:11625", validators[0].host)
            XCTAssertEqual("GD5DJQDDBKGAYNEAXU562HYGOOSYAEOO6AS53PZXBOZGCP5M2OPGMZV3", validators[0].publicKey)
            XCTAssertEqual("http://history.example.com/core_live_001/", validators[0].history)

            XCTAssertEqual("node-us", validators[1].alias)
            XCTAssertEqual("United States Node", validators[1].displayName)
            XCTAssertEqual("core-us.example.com:11625", validators[1].host)
            XCTAssertEqual("GAENZLGHJGJRCMX5VCHOLHQXU3EMCU5XWDNU4BGGJFNLI2EL354IVBK7", validators[1].publicKey)
            XCTAssertEqual("http://history.example.com/core_live_002/", validators[1].history)
        } catch {
            XCTFail("Failed to parse TOML: \(error)")
        }
    }

    // MARK: - Test: Error handling - invalid TOML (mirrors "Error handling" snippet)

    func testErrorHandlingInvalidToml() {
        let badToml = "this is not valid TOML [[["
        do {
            _ = try StellarToml(fromString: badToml)
            XCTFail("Expected parsing to throw")
        } catch {
            // Expected: TomlFileError.invalidToml
            XCTAssertTrue(error is TomlFileError)
        }
    }

    // MARK: - Test: Error handling - missing DOCUMENTATION section

    func testErrorHandlingMissingDocumentation() {
        // The SDK does not throw when [DOCUMENTATION] is absent.
        // Parsing succeeds and issuerDocumentation is returned with all nil properties.
        let tomlWithoutDocs = """
        VERSION="2.0.0"
        WEB_AUTH_ENDPOINT="https://example.com/auth"
        """
        do {
            let stellarToml = try StellarToml(fromString: tomlWithoutDocs)
            XCTAssertEqual("2.0.0", stellarToml.accountInformation.version)
            XCTAssertEqual("https://example.com/auth", stellarToml.accountInformation.webAuthEndpoint)
            // issuerDocumentation is non-nil but all its properties are nil
            XCTAssertNil(stellarToml.issuerDocumentation.orgName)
            XCTAssertNil(stellarToml.issuerDocumentation.orgURL)
        } catch {
            XCTFail("Parsing should succeed even without [DOCUMENTATION] section: \(error)")
        }
    }

    // MARK: - Test: Check for SEP support (mirrors "check for missing optional data" snippet)

    func testCheckSepSupport() {
        let minimalToml = """
        VERSION="2.0.0"

        [DOCUMENTATION]
        ORG_NAME="Minimal Anchor"
        """

        do {
            let stellarToml = try StellarToml(fromString: minimalToml)
            let info = stellarToml.accountInformation

            // This anchor has no endpoints configured
            XCTAssertNil(info.webAuthEndpoint)
            XCTAssertNil(info.transferServerSep24)
            XCTAssertNil(info.kycServer)
            XCTAssertNil(info.federationServer)
            XCTAssertNil(info.transferServer)
            XCTAssertNil(info.directPaymentServer)
            XCTAssertNil(info.anchorQuoteServer)
            XCTAssertNil(info.signingKey)

            // issuerDocumentation is always non-nil; check individual properties
            XCTAssertEqual("Minimal Anchor", stellarToml.issuerDocumentation.orgName)
            XCTAssertNil(stellarToml.issuerDocumentation.orgSupportEmail)

            // Arrays are non-nil but may be empty
            XCTAssertTrue(info.accounts.isEmpty)
            XCTAssertTrue(stellarToml.currenciesDocumentation.isEmpty)
            XCTAssertTrue(stellarToml.validatorsInformation.isEmpty)
            XCTAssertTrue(stellarToml.pointsOfContact.isEmpty)
        } catch {
            XCTFail("Failed to parse TOML: \(error)")
        }
    }
}
