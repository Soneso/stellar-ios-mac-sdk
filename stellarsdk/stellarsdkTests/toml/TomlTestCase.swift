//
//  TomlTestCase.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 09/11/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class TomlTestCase: XCTestCase {

    func testStellarTomlFromStellar() {
        
        let expectation = XCTestExpectation(description: "Load and resolve stellar toml file from stellar.org")
        do {
            try StellarToml.from(domain: "stellar.org") { (result) -> (Void) in
                switch result {
                case .success(response: let stellarToml):
                    if "Stellar Development Foundation" != stellarToml.issuerDocumentation.orgName {
                        XCTAssert(false)
                    }
                    if "https://www.stellar.org" != stellarToml.issuerDocumentation.orgURL {
                        XCTAssert(false)
                    }
                    if "stellar" != stellarToml.issuerDocumentation.orgGithub {
                        XCTAssert(false)
                    }
                    if "StellarOrg" != stellarToml.issuerDocumentation.orgTwitter {
                        XCTAssert(false)
                    }
                    if stellarToml.validatorsInformation.count == 3 {
                        let validator1 = stellarToml.validatorsInformation[0]
                        let validator2 = stellarToml.validatorsInformation[1]
                        let validator3 = stellarToml.validatorsInformation[2]
                        if "sdf1" != validator1.alias {
                            XCTAssert(false)
                        }
                        if "SDF 1" != validator1.displayName {
                            XCTAssert(false)
                        }
                        if "core-live-a.stellar.org:11625" != validator1.host {
                            XCTAssert(false)
                        }
                        if "GCGB2S2KGYARPVIA37HYZXVRM2YZUEXA6S33ZU5BUDC6THSB62LZSTYH" != validator1.publicKey {
                            XCTAssert(false)
                        }
                        if "http://history.stellar.org/prd/core-live/core_live_001/" != validator1.history {
                            XCTAssert(false)
                        }
                        if "sdf2" != validator2.alias {
                            XCTAssert(false)
                        }
                        if "SDF 2" != validator2.displayName {
                            XCTAssert(false)
                        }
                        if "core-live-b.stellar.org:11625" != validator2.host {
                            XCTAssert(false)
                        }
                        if "GCM6QMP3DLRPTAZW2UZPCPX2LF3SXWXKPMP3GKFZBDSF3QZGV2G5QSTK" != validator2.publicKey {
                            XCTAssert(false)
                        }
                        if "http://history.stellar.org/prd/core-live/core_live_002/" != validator2.history {
                            XCTAssert(false)
                        }
                        if "sdf3" != validator3.alias {
                            XCTAssert(false)
                        }
                        if "SDF 3" != validator3.displayName {
                            XCTAssert(false)
                        }
                        if "core-live-c.stellar.org:11625" != validator3.host {
                            XCTAssert(false)
                        }
                        if "GABMKJM6I25XI4K7U6XWMULOUQIQ27BCTMLS6BYYSOWKTBUXVRJSXHYQ" != validator3.publicKey {
                            XCTAssert(false)
                        }
                        if "http://history.stellar.org/prd/core-live/core_live_003/" != validator3.history {
                            XCTAssert(false)
                        }
                    }
                    else {
                        XCTAssert(false)
                    }
                case .failure(_):
                    XCTAssert(false)
                }
                XCTAssert(true)
                expectation.fulfill()
            }
        } catch {
            XCTAssert(false)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testStellarTomlFromDomain() {
        
        let expectation = XCTestExpectation(description: "Load and resolve stellar toml file from domain")
        do {
            try StellarToml.from(domain: "lumenshine.com") { (result) -> (Void) in
                switch result {
                case .success(response: let stellarToml):
                    if "https://api.lumenshine.com/federation" == stellarToml.accountInformation.federationServer {
                        XCTAssert(true)
                    } else {
                        XCTAssert(false)
                    }
                case .failure(_):
                    XCTAssert(false)
                }
                expectation.fulfill()
            }
        } catch {
            XCTAssert(false)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testAccountInformationTomlV1() {
        do {
            let toml = try StellarToml(fromString: tomlSampleV1)
            XCTAssertTrue(toml.accountInformation.federationServer == "https://api.domain.com/federation")
            XCTAssertTrue(toml.accountInformation.authServer == "https://api.domain.com/auth")
            XCTAssertTrue(toml.accountInformation.transferServer == "https://api.domain.com")
            XCTAssertTrue(toml.accountInformation.signingKey == "GBBHQ7H4V6RRORKYLHTCAWP6MOHNORRFJSDPXDFYDGJB2LPZUFPXUEW3")
            XCTAssertTrue(toml.accountInformation.nodeNames.contains("GD5DJQDDBKGAYNEAXU562HYGOOSYAEOO6AS53PZXBOZGCP5M2OPGMZV3  lab1"))
            XCTAssertTrue(toml.accountInformation.nodeNames.contains("GB6REF5GOGGSEHZ3L2YK6K4T4KX3YDMWHDCPMV7MZJDLHBDNZXEPRBGM  donovan"))
            XCTAssertTrue(toml.accountInformation.nodeNames.contains("GBGR22MRCIVW2UZHFXMY5UIBJGPYABPQXQ5GGMNCSUM2KHE3N6CNH6G5  nelisky1"))
            XCTAssertTrue(toml.accountInformation.nodeNames.contains("GDXWQCSKVYAJSUGR2HBYVFVR7NA7YWYSYK3XYKKFO553OQGOHAUP2PX2  jianing"))
            XCTAssertTrue(toml.accountInformation.nodeNames.contains("GAOO3LWBC4XF6VWRP5ESJ6IBHAISVJMSBTALHOQM2EZG7Q477UWA6L7U  anchor"))
            XCTAssertTrue(toml.accountInformation.accounts.contains("$lab1"))
            XCTAssertTrue(toml.accountInformation.accounts.contains("GAENZLGHJGJRCMX5VCHOLHQXU3EMCU5XWDNU4BGGJFNLI2EL354IVBK7"))
            
            XCTAssertTrue(toml.accountInformation.ourValidators.contains("$nelisky1"))
            XCTAssertTrue(toml.accountInformation.ourValidators.contains("GCGB2S2KGYARPVIA37HYZXVRM2YZUEXA6S33ZU5BUDC6THSB62LZSTYH"))
            
            XCTAssertTrue(toml.accountInformation.desiredBaseFee == 100)
            XCTAssertTrue(toml.accountInformation.desiredMaxTxPerLedger == 400)
            
            XCTAssertTrue(toml.accountInformation.knownPeers.contains("192.168.0.1"))
            XCTAssertTrue(toml.accountInformation.knownPeers.contains("core-testnet1.stellar.org"))
            XCTAssertTrue(toml.accountInformation.knownPeers.contains("core-testnet2.stellar.org:11290"))
            XCTAssertTrue(toml.accountInformation.knownPeers.contains("2001:0db8:0100:f101:0210:a4ff:fee3:9566"))
            
            XCTAssertTrue(toml.accountInformation.history.contains("http://history.stellar.org/prd/core-live/core_live_001/"))
            XCTAssertTrue(toml.accountInformation.history.contains("http://history.stellar.org/prd/core-live/core_live_002/"))
            XCTAssertTrue(toml.accountInformation.history.contains("http://history.stellar.org/prd/core-live/core_live_003/"))
        } catch {
            XCTAssertTrue(false)
        }
    }
    
    func testAccountInformationTomlV2() {
        do {
            let toml = try StellarToml(fromString: tomlSampleV2)
            XCTAssertTrue(toml.accountInformation.federationServer == "https://api.domain.com/federation")
            XCTAssertTrue(toml.accountInformation.authServer == "https://api.domain.com/auth")
            XCTAssertTrue(toml.accountInformation.transferServer == "https://api.domain.com")
            XCTAssertTrue(toml.accountInformation.kycServer == "https://kyc.domain.com")
            XCTAssertTrue(toml.accountInformation.webAuthEndpoint == "https://webauth.domain.com")
            XCTAssertTrue(toml.accountInformation.version == "2.0")
            XCTAssertTrue(toml.accountInformation.signingKey == "GBBHQ7H4V6RRORKYLHTCAWP6MOHNORRFJSDPXDFYDGJB2LPZUFPXUEW3")
            XCTAssertTrue(toml.accountInformation.uriRequestSigningKey == "GBBHQ7H4V6RRORKYLHTCAWP6MOHNORRFJSDPXDFYDGJB2LPZUFPXUEW3")
            
            XCTAssertTrue(toml.accountInformation.accounts.contains("$lab1"))
            XCTAssertTrue(toml.accountInformation.accounts.contains("GAENZLGHJGJRCMX5VCHOLHQXU3EMCU5XWDNU4BGGJFNLI2EL354IVBK7"))
            
            
            
        } catch {
            XCTAssertTrue(false)
        }
    }
    
    func testIssuerDocumentationToml() {
        do {
            let toml = try StellarToml(fromString: tomlSampleV1)
            XCTAssertTrue(toml.issuerDocumentation.orgName == "Organization Name")
            XCTAssertTrue(toml.issuerDocumentation.orgDBA == "Organization DBA")
            XCTAssertTrue(toml.issuerDocumentation.orgURL == "https://www.domain.com")
            XCTAssertTrue(toml.issuerDocumentation.orgLogo == "https://www.domain.com/awesomelogo.jpg")
            XCTAssertTrue(toml.issuerDocumentation.orgDescription == "Description of issuer")
            XCTAssertTrue(toml.issuerDocumentation.orgPhysicalAddress == "123 Sesame St., New York, NY, 12345")
            XCTAssertTrue(toml.issuerDocumentation.orgPhysicalAddressAttestation == "https://www.domain.com/address_attestation.jpg")
            XCTAssertTrue(toml.issuerDocumentation.orgPhoneNumber == "1 (123)-456-7890")
            XCTAssertTrue(toml.issuerDocumentation.orgPhoneNumberAttestation == "https://www.domain.com/phone_attestation.jpg")
            XCTAssertTrue(toml.issuerDocumentation.orgKeybase == "accountname")
            XCTAssertTrue(toml.issuerDocumentation.orgTwitter == "orgtweet")
            XCTAssertTrue(toml.issuerDocumentation.orgGithub == "orgcode")
            XCTAssertTrue(toml.issuerDocumentation.orgOfficialEmail == "support@domain.com")
           
        } catch {
            XCTAssertTrue(false)
        }
    }
    
    func testPointOfContactToml() {
        do {
            let toml = try StellarToml(fromString: tomlSampleV1)
            let pointOfContact = toml.pointsOfContact.first!
            XCTAssertTrue(pointOfContact.name == "Jane Jedidiah Johnson")
            XCTAssertTrue(pointOfContact.email == "jane@domain.com")
            XCTAssertTrue(pointOfContact.keybase == "crypto_jane")
            XCTAssertTrue(pointOfContact.twitter == "crypto_jane")
            XCTAssertTrue(pointOfContact.github == "crypto_jane")
            XCTAssertTrue(pointOfContact.idPhotoHash == "be688838ca8686e5c90689bf2ab585cef1137c999b48c70b92f67a5c34dc15697b5d11c982ed6d71be1e1e7f7b4e0733884aa97c3f7a339a8ed03577cf74be09")
            XCTAssertTrue(pointOfContact.verificationPhotoHash == "016ba8c4cfde65af99cb5fa8b8a37e2eb73f481b3ae34991666df2e04feb6c038666ebd1ec2b6f623967756033c702dde5f423f7d47ab6ed1827ff53783731f7")
            
        } catch {
            XCTAssertTrue(false)
        }
    }
    
    func testCurrenciesToml() {
        do {
            let toml = try StellarToml(fromString: tomlSampleV1)
            let firstCurrency = toml.currenciesDocumentation.first!
            XCTAssertTrue(firstCurrency.code == "USD")
            XCTAssertTrue(firstCurrency.issuer == "GCZJM35NKGVK47BB4SPBDV25477PZYIYPVVG453LPYFNXLS3FGHDXOCM")
            XCTAssertTrue(firstCurrency.displayDecimals == 2)
            
            let secondCurrency = toml.currenciesDocumentation[1]
            XCTAssertTrue(secondCurrency.code == "BTC")
            XCTAssertTrue(secondCurrency.issuer == "GAOO3LWBC4XF6VWRP5ESJ6IBHAISVJMSBTALHOQM2EZG7Q477UWA6L7U")
            XCTAssertTrue(secondCurrency.displayDecimals == 7)
            XCTAssertTrue(secondCurrency.anchorAssetType == "crypto")
            XCTAssertTrue(secondCurrency.anchorAsset == "BTC")
            XCTAssertTrue(secondCurrency.redemptionInstructions == "Use SEP6 with our federation server")
            XCTAssertTrue(secondCurrency.collateralAddresses.contains("2C1mCx3ukix1KfegAY5zgQJV7sanAciZpv"))
            XCTAssertTrue(secondCurrency.collateralAddressSignatures.contains("304502206e21798a42fae0e854281abd38bacd1aeed3ee3738d9e1446618c4571d10"))
            
            let thirdCurrency = toml.currenciesDocumentation[2]
            XCTAssertTrue(thirdCurrency.code == "GOAT")
            XCTAssertTrue(thirdCurrency.issuer == "GD5T6IPRNCKFOHQWT264YPKOZAWUMMZOLZBJ6BNQMUGPWGRLBK3U7ZNP")
            XCTAssertTrue(thirdCurrency.displayDecimals == 2)
            XCTAssertTrue(thirdCurrency.name == "goat share")
            XCTAssertTrue(thirdCurrency.desc == "1 GOAT token entitles you to a share of revenue from Elkins Goat Farm.")
            XCTAssertTrue(thirdCurrency.conditions == "There will only ever be 10,000 GOAT tokens in existence. We will distribute the revenue share annually on Jan. 15th")
            XCTAssertTrue(thirdCurrency.image == "https://pbs.twimg.com/profile_images/666921221410439168/iriHah4f.jpg")
            XCTAssertTrue(thirdCurrency.fixedNumber == 10000)
            
            let linkedCurrencyDocumentation = toml.currenciesDocumentation[3]
            XCTAssertTrue(linkedCurrencyDocumentation.toml == "https://DOMAIN/.well-known/CURRENCY.toml")
            
        } catch {
            XCTAssertTrue(false)
        }
    }

    func testValidatorsTomlV1() {
        do {
            let toml = try StellarToml(fromString: tomlSampleV1)
            XCTAssertTrue(toml.validatorInformation.validators.contains("$self"))
            XCTAssertTrue(toml.validatorInformation.validators.contains("$lab1"))
            XCTAssertTrue(toml.validatorInformation.validators.contains("$nelisky1"))
            XCTAssertTrue(toml.validatorInformation.validators.contains("$jianing"))
            XCTAssertTrue(toml.validatorInformation.validators.contains("$eno"))
            XCTAssertTrue(toml.validatorInformation.validators.contains("$donovan"))
            
        } catch {
            XCTAssertTrue(false)
        }
    }
    
    var tomlSampleV1: String {
        get {
            return """
            # Sample stellar.toml
            
            FEDERATION_SERVER="https://api.domain.com/federation"
            AUTH_SERVER="https://api.domain.com/auth"
            TRANSFER_SERVER="https://api.domain.com"
            SIGNING_KEY="GBBHQ7H4V6RRORKYLHTCAWP6MOHNORRFJSDPXDFYDGJB2LPZUFPXUEW3"
            
            
            NODE_NAMES=[
            "GD5DJQDDBKGAYNEAXU562HYGOOSYAEOO6AS53PZXBOZGCP5M2OPGMZV3  lab1",
            "GB6REF5GOGGSEHZ3L2YK6K4T4KX3YDMWHDCPMV7MZJDLHBDNZXEPRBGM  donovan",
            "GBGR22MRCIVW2UZHFXMY5UIBJGPYABPQXQ5GGMNCSUM2KHE3N6CNH6G5  nelisky1",
            "GDXWQCSKVYAJSUGR2HBYVFVR7NA7YWYSYK3XYKKFO553OQGOHAUP2PX2  jianing",
            "GAOO3LWBC4XF6VWRP5ESJ6IBHAISVJMSBTALHOQM2EZG7Q477UWA6L7U  anchor"
            ]
            
            ACCOUNTS=[
            "$lab1",
            "GAENZLGHJGJRCMX5VCHOLHQXU3EMCU5XWDNU4BGGJFNLI2EL354IVBK7"
            ]
            
            OUR_VALIDATORS=[
            "$nelisky1",
            "GCGB2S2KGYARPVIA37HYZXVRM2YZUEXA6S33ZU5BUDC6THSB62LZSTYH"
            ]
            
            DESIRED_BASE_FEE=100
            DESIRED_MAX_TX_PER_LEDGER=400
            
            KNOWN_PEERS=[
            "192.168.0.1",
            "core-testnet1.stellar.org",
            "core-testnet2.stellar.org:11290",
            "2001:0db8:0100:f101:0210:a4ff:fee3:9566"
            ]
            
            HISTORY=[
            "http://history.stellar.org/prd/core-live/core_live_001/",
            "http://history.stellar.org/prd/core-live/core_live_002/",
            "http://history.stellar.org/prd/core-live/core_live_003/"
            ]
            
            [DOCUMENTATION]
            ORG_NAME="Organization Name"
            ORG_DBA="Organization DBA"
            ORG_URL="https://www.domain.com"
            ORG_LOGO="https://www.domain.com/awesomelogo.jpg"
            ORG_DESCRIPTION="Description of issuer"
            ORG_PHYSICAL_ADDRESS="123 Sesame St., New York, NY, 12345"
            ORG_PHYSICAL_ADDRESS_ATTESTATION="https://www.domain.com/address_attestation.jpg"
            ORG_PHONE_NUMBER="1 (123)-456-7890"
            ORG_PHONE_NUMBER_ATTESTATION="https://www.domain.com/phone_attestation.jpg"
            ORG_KEYBASE="accountname"
            ORG_TWITTER="orgtweet"
            ORG_GITHUB="orgcode"
            ORG_OFFICIAL_EMAIL="support@domain.com"
            
            [[PRINCIPALS]]
            name="Jane Jedidiah Johnson"
            email="jane@domain.com"
            keybase="crypto_jane"
            twitter="crypto_jane"
            github="crypto_jane"
            id_photo_hash="be688838ca8686e5c90689bf2ab585cef1137c999b48c70b92f67a5c34dc15697b5d11c982ed6d71be1e1e7f7b4e0733884aa97c3f7a339a8ed03577cf74be09"
            verification_photo_hash="016ba8c4cfde65af99cb5fa8b8a37e2eb73f481b3ae34991666df2e04feb6c038666ebd1ec2b6f623967756033c702dde5f423f7d47ab6ed1827ff53783731f7"
            
            [[CURRENCIES]]
            code="USD"
            issuer="GCZJM35NKGVK47BB4SPBDV25477PZYIYPVVG453LPYFNXLS3FGHDXOCM"
            display_decimals=2
            
            [[CURRENCIES]]
            code="BTC"
            issuer="GAOO3LWBC4XF6VWRP5ESJ6IBHAISVJMSBTALHOQM2EZG7Q477UWA6L7U"
            display_decimals=7
            anchor_asset_type="crypto"
            anchor_asset="BTC"
            redemption_instructions="Use SEP6 with our federation server"
            collateral_addresses=["2C1mCx3ukix1KfegAY5zgQJV7sanAciZpv"]
            collateral_address_signatures=["304502206e21798a42fae0e854281abd38bacd1aeed3ee3738d9e1446618c4571d10"]
            
            # asset with meta info
            [[CURRENCIES]]
            code="GOAT"
            issuer="GD5T6IPRNCKFOHQWT264YPKOZAWUMMZOLZBJ6BNQMUGPWGRLBK3U7ZNP"
            display_decimals=2
            name="goat share"
            desc="1 GOAT token entitles you to a share of revenue from Elkins Goat Farm."
            conditions="There will only ever be 10,000 GOAT tokens in existence. We will distribute the revenue share annually on Jan. 15th"
            image="https://pbs.twimg.com/profile_images/666921221410439168/iriHah4f.jpg"
            fixed_number=10000
            
            # linked currency documentation
            [[CURRENCIES]]
            toml="https://DOMAIN/.well-known/CURRENCY.toml"
            
            #   Potential quorum set of this domain's validators.
            [QUORUM_SET]
            VALIDATORS=[
            "$self", "$lab1", "$nelisky1","$jianing",
            "$eno","$donovan"
            ]
            
            # optional extra information for humans
            # Useful place for anchors to detail various policies and required info
            
            ###################################
            # Required compliance fields:
            #      name=<recipient name>
            #      addr=<recipient address>
            # Federation Format:
            #        <phone number>*anchor.com
            #        Forwarding supported by sending to: forward*anchor.com
            #           forward_type=bank_account
            #           swift=<swift code of receiving bank>
            #           acct=<recipient account number at receiving bank>
            # Minimum Amount Forward: $2 USD
            # Maximum Amount Forward: $10000 USD
            """
        }
    }

    var tomlSampleV2: String {
        get {
            return """
            # Sample stellar.toml
            
            FEDERATION_SERVER="https://api.domain.com/federation"
            AUTH_SERVER="https://api.domain.com/auth"
            TRANSFER_SERVER="https://api.domain.com"
            KYC_SERVER="https://kyc.domain.com"
            WEB_AUTH_ENDPOINT="https://webauth.domain.com"
            SIGNING_KEY="GBBHQ7H4V6RRORKYLHTCAWP6MOHNORRFJSDPXDFYDGJB2LPZUFPXUEW3"
            HORIZON_URL="https://horizon.domain.com"
            
            ACCOUNTS=[
            "$lab1",
            "GAENZLGHJGJRCMX5VCHOLHQXU3EMCU5XWDNU4BGGJFNLI2EL354IVBK7"
            ]
            
            VERSION="2.0"
            URI_REQUEST_SIGNING_KEY="GBBHQ7H4V6RRORKYLHTCAWP6MOHNORRFJSDPXDFYDGJB2LPZUFPXUEW3"
            
            [DOCUMENTATION]
            ORG_NAME="Organization Name"
            ORG_DBA="Organization DBA"
            ORG_URL="https://www.domain.com"
            ORG_LOGO="https://www.domain.com/awesomelogo.jpg"
            ORG_DESCRIPTION="Description of issuer"
            ORG_PHYSICAL_ADDRESS="123 Sesame St., New York, NY, 12345"
            ORG_PHYSICAL_ADDRESS_ATTESTATION="https://www.domain.com/address_attestation.jpg"
            ORG_PHONE_NUMBER="1 (123)-456-7890"
            ORG_PHONE_NUMBER_ATTESTATION="https://www.domain.com/phone_attestation.jpg"
            ORG_KEYBASE="accountname"
            ORG_TWITTER="orgtweet"
            ORG_GITHUB="orgcode"
            ORG_OFFICIAL_EMAIL="support@domain.com"
            
            [[PRINCIPALS]]
            name="Jane Jedidiah Johnson"
            email="jane@domain.com"
            keybase="crypto_jane"
            twitter="crypto_jane"
            github="crypto_jane"
            id_photo_hash="be688838ca8686e5c90689bf2ab585cef1137c999b48c70b92f67a5c34dc15697b5d11c982ed6d71be1e1e7f7b4e0733884aa97c3f7a339a8ed03577cf74be09"
            verification_photo_hash="016ba8c4cfde65af99cb5fa8b8a37e2eb73f481b3ae34991666df2e04feb6c038666ebd1ec2b6f623967756033c702dde5f423f7d47ab6ed1827ff53783731f7"
            
            [[CURRENCIES]]
            code="USD"
            issuer="GCZJM35NKGVK47BB4SPBDV25477PZYIYPVVG453LPYFNXLS3FGHDXOCM"
            display_decimals=2
            
            [[CURRENCIES]]
            code="BTC"
            issuer="GAOO3LWBC4XF6VWRP5ESJ6IBHAISVJMSBTALHOQM2EZG7Q477UWA6L7U"
            display_decimals=7
            anchor_asset_type="crypto"
            anchor_asset="BTC"
            redemption_instructions="Use SEP6 with our federation server"
            collateral_addresses=["2C1mCx3ukix1KfegAY5zgQJV7sanAciZpv"]
            collateral_address_signatures=["304502206e21798a42fae0e854281abd38bacd1aeed3ee3738d9e1446618c4571d10"]
            
            # asset with meta info
            [[CURRENCIES]]
            code="GOAT"
            issuer="GD5T6IPRNCKFOHQWT264YPKOZAWUMMZOLZBJ6BNQMUGPWGRLBK3U7ZNP"
            display_decimals=2
            name="goat share"
            desc="1 GOAT token entitles you to a share of revenue from Elkins Goat Farm."
            conditions="There will only ever be 10,000 GOAT tokens in existence. We will distribute the revenue share annually on Jan. 15th"
            image="https://pbs.twimg.com/profile_images/666921221410439168/iriHah4f.jpg"
            fixed_number=10000
            
            # linked currency documentation
            [[CURRENCIES]]
            toml="https://DOMAIN/.well-known/CURRENCY.toml"
            
            """
        }
    }
}
