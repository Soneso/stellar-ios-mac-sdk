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

    func testStellarTomlFromDomain() {
        
        let expectation = XCTestExpectation(description: "Load and resolve stellar toml file from domain")
        do {
            try StellarToml.from(domain: "soneso.com") { (result) -> (Void) in
                switch result {
                case .success(response: let stellarToml):
                    XCTAssertTrue(stellarToml.accountInformation.version == "2.0.0")
                    XCTAssertTrue(stellarToml.accountInformation.networkPassphrase == "Public Global Stellar Network ; September 2015")
                    XCTAssertTrue(stellarToml.accountInformation.federationServer
                        == "https://stellarid.io/federation/")
                    XCTAssertTrue(stellarToml.accountInformation.authServer
                    == "https://api.domain.com/auth")
                    XCTAssertTrue(stellarToml.accountInformation.transferServer
                    == "https://api.domain.com")
                    XCTAssertNil(stellarToml.accountInformation.transferServerSep24)
                    XCTAssertNil(stellarToml.accountInformation.kycServer)
                    XCTAssertNil(stellarToml.accountInformation.webAuthEndpoint)
                    XCTAssertTrue(stellarToml.accountInformation.signingKey
                    == "GBBHQ7H4V6RRORKYLHTCAWP6MOHNORRFJSDPXDFYDGJB2LPZUFPXUEW3")
                    XCTAssertTrue(stellarToml.accountInformation.horizonUrl
                    == "https://horizon.domain.com")
                    XCTAssertTrue(stellarToml.accountInformation.accounts.contains("GD5DJQDDBKGAYNEAXU562HYGOOSYAEOO6AS53PZXBOZGCP5M2OPGMZV3"))
                    XCTAssertTrue(stellarToml.accountInformation.accounts.contains("GAENZLGHJGJRCMX5VCHOLHQXU3EMCU5XWDNU4BGGJFNLI2EL354IVBK7"))
                    XCTAssertTrue(stellarToml.accountInformation.accounts.contains("GAOO3LWBC4XF6VWRP5ESJ6IBHAISVJMSBTALHOQM2EZG7Q477UWA6L7U"))
                    XCTAssertNil(stellarToml.accountInformation.uriRequestSigningKey)
                    
                    let documentation = stellarToml.issuerDocumentation
                    XCTAssertTrue(documentation.orgName == "Organization Name")
                    XCTAssertTrue(documentation.orgDBA == "Organization DBA")
                    XCTAssertTrue(documentation.orgURL == "https://www.domain.com")
                    XCTAssertTrue(documentation.orgLogo == "https://www.domain.com/awesomelogo.png")
                    XCTAssertTrue(documentation.orgDescription == "Description of issuer")
                    XCTAssertTrue(documentation.orgPhysicalAddress == "123 Sesame Street, New York, NY 12345, United States")
                    XCTAssertTrue(documentation.orgPhysicalAddressAttestation == "https://www.domain.com/address_attestation.jpg")
                    XCTAssertTrue(documentation.orgPhoneNumber == "1 (123)-456-7890")
                    XCTAssertTrue(documentation.orgPhoneNumberAttestation == "https://www.domain.com/phone_attestation.jpg")
                    XCTAssertTrue(documentation.orgKeybase == "accountname")
                    XCTAssertTrue(documentation.orgTwitter == "orgtweet")
                    XCTAssertTrue(documentation.orgGithub == "orgcode")
                    XCTAssertTrue(documentation.orgOfficialEmail == "support@domain.com")
                    XCTAssertNil(documentation.orgLicensingAuthority)
                    XCTAssertNil(documentation.orgLicenseType)
                    XCTAssertNil(documentation.orgLicenseNumber)
                    
                    if let pointOfContact = stellarToml.pointsOfContact.first {
                        XCTAssertTrue(pointOfContact.name == "Jane Jedidiah Johnson")
                        XCTAssertTrue(pointOfContact.email == "jane@domain.com")
                        XCTAssertTrue(pointOfContact.keybase == "crypto_jane")
                        XCTAssertNil(pointOfContact.telegram)
                        XCTAssertTrue(pointOfContact.twitter == "crypto_jane")
                        XCTAssertTrue(pointOfContact.github == "crypto_jane")
                        XCTAssertTrue(pointOfContact.idPhotoHash == "be688838ca8686e5c90689bf2ab585cef1137c999b48c70b92f67a5c34dc15697b5d11c982ed6d71be1e1e7f7b4e0733884aa97c3f7a339a8ed03577cf74be09")
                        XCTAssertTrue(pointOfContact.verificationPhotoHash == "016ba8c4cfde65af99cb5fa8b8a37e2eb73f481b3ae34991666df2e04feb6c038666ebd1ec2b6f623967756033c702dde5f423f7d47ab6ed1827ff53783731f7")
                    }
                    else {
                        XCTAssert(false)
                    }
                    
                    let currencies = stellarToml.currenciesDocumentation
                    XCTAssertTrue(currencies[0].code == "USD")
                    XCTAssertTrue(currencies[0].issuer ==
                        "GCZJM35NKGVK47BB4SPBDV25477PZYIYPVVG453LPYFNXLS3FGHDXOCM");
                    XCTAssertTrue(currencies[0].displayDecimals == 2);
                    XCTAssertTrue(currencies[1].code == "BTC");
                    XCTAssertTrue(currencies[1].issuer ==
                        "GAOO3LWBC4XF6VWRP5ESJ6IBHAISVJMSBTALHOQM2EZG7Q477UWA6L7U");
                    XCTAssertTrue(currencies[1].displayDecimals == 7);
                    XCTAssertTrue(currencies[1].anchorAssetType == "crypto");
                    XCTAssertTrue(currencies[1].anchorAsset == "BTC");
                    XCTAssertTrue(currencies[1].redemptionInstructions ==
                        "Use SEP6 with our federation server");
                    XCTAssertTrue(currencies[1]
                        .collateralAddresses
                        .contains("2C1mCx3ukix1KfegAY5zgQJV7sanAciZpv"));
                    XCTAssertTrue(currencies[1].collateralAddressSignatures.contains(
                        "304502206e21798a42fae0e854281abd38bacd1aeed3ee3738d9e1446618c4571d10"));
                    XCTAssertTrue(currencies[2].code == "GOAT");
                    XCTAssertTrue(currencies[2].issuer ==
                        "GD5T6IPRNCKFOHQWT264YPKOZAWUMMZOLZBJ6BNQMUGPWGRLBK3U7ZNP");
                    XCTAssertTrue(currencies[2].displayDecimals == 2);
                    XCTAssertTrue(currencies[2].name == "goat share");
                    XCTAssertTrue(currencies[2].desc ==
                        "1 GOAT token entitles you to a share of revenue from Elkins Goat Farm.");
                    XCTAssertTrue(currencies[2].conditions ==
                        "There will only ever be 10,000 GOAT tokens in existence. We will distribute the revenue share annually on Jan. 15th");
                    XCTAssertTrue(currencies[2].image ==
                        "https://static.thenounproject.com/png/2292360-200.png");
                    XCTAssertTrue(currencies[2].fixedNumber == 10000);
                    
                    let validators = stellarToml.validatorsInformation
                    
                    XCTAssertTrue(validators[0].alias == "domain-au");
                    XCTAssertTrue(validators[0].displayName == "Domain Australia");
                    XCTAssertTrue(validators[0].host == "core-au.domain.com:11625");
                    XCTAssertTrue(validators[0].publicKey ==
                        "GD5DJQDDBKGAYNEAXU562HYGOOSYAEOO6AS53PZXBOZGCP5M2OPGMZV3");
                    XCTAssertTrue(validators[0].history ==
                        "http://history.domain.com/prd/core-live/core_live_001/");
                    XCTAssertTrue(validators[1].alias == "domain-sg");
                    XCTAssertTrue(validators[1].displayName == "Domain Singapore");
                    XCTAssertTrue(validators[1].host == "core-sg.domain.com:11625");
                    XCTAssertTrue(validators[1].publicKey ==
                        "GAENZLGHJGJRCMX5VCHOLHQXU3EMCU5XWDNU4BGGJFNLI2EL354IVBK7");
                    XCTAssertTrue(validators[1].history ==
                        "http://history.domain.com/prd/core-live/core_live_002/");
                    XCTAssertTrue(validators[2].alias == "domain-us");
                    XCTAssertTrue(validators[2].displayName == "Domain United States");
                    XCTAssertTrue(validators[2].host == "core-us.domain.com:11625");
                    XCTAssertTrue(validators[2].publicKey ==
                        "GAOO3LWBC4XF6VWRP5ESJ6IBHAISVJMSBTALHOQM2EZG7Q477UWA6L7U");
                    XCTAssertTrue(validators[2].history ==
                        "http://history.domain.com/prd/core-live/core_live_003/");
                    
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
    
    func testCurrencyFromLink() {
        
        let expectation = XCTestExpectation(description: "Load and resolve linked currency")
        do {
            try StellarToml.from(domain: "soneso.com") { (result) -> (Void) in
                switch result {
                case .success(response: let stellarToml):
                    
                    let currencies = stellarToml.currenciesDocumentation
                    XCTAssertTrue(currencies[3].toml == "https://soneso.com/.well-known/TESTC.toml")
                    
                    try! StellarToml.currencyFrom(url:currencies[3].toml!) { (result) -> (Void) in
                        switch result {
                        case .success(response: let currency):
                            XCTAssertTrue(currency.code == "TESTC")
                            XCTAssertTrue(currency.issuer == "GCPWPTAX6QVJQIQARN2WESISHVLN65D4HAGQECHLCAV22UST3W2Q6QTA")
                        case .failure(_):
                            XCTAssert(false)
                        }
                        expectation.fulfill()
                    }
                    
                case .failure(_):
                    XCTAssert(false)
                }
            }
        } catch {
            XCTAssert(false)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testStellarTomlFromString(){
        do {
            let stellarToml = try StellarToml(fromString: tomlSampleV2)
            XCTAssertTrue(stellarToml.accountInformation.version == "2.0.0")
            XCTAssertTrue(stellarToml.accountInformation.networkPassphrase == "Public Global Stellar Network ; September 2015")
            XCTAssertTrue(stellarToml.accountInformation.federationServer
                == "https://stellarid.io/federation/")
            XCTAssertTrue(stellarToml.accountInformation.authServer
            == "https://api.domain.com/auth")
            XCTAssertTrue(stellarToml.accountInformation.transferServer
            == "https://api.domain.com")
            XCTAssertNil(stellarToml.accountInformation.transferServerSep24)
            XCTAssertNil(stellarToml.accountInformation.kycServer)
            XCTAssertNil(stellarToml.accountInformation.webAuthEndpoint)
            XCTAssertTrue(stellarToml.accountInformation.signingKey
            == "GBBHQ7H4V6RRORKYLHTCAWP6MOHNORRFJSDPXDFYDGJB2LPZUFPXUEW3")
            XCTAssertTrue(stellarToml.accountInformation.horizonUrl
            == "https://horizon.domain.com")
            XCTAssertTrue(stellarToml.accountInformation.accounts.contains("GD5DJQDDBKGAYNEAXU562HYGOOSYAEOO6AS53PZXBOZGCP5M2OPGMZV3"))
            XCTAssertTrue(stellarToml.accountInformation.accounts.contains("GAENZLGHJGJRCMX5VCHOLHQXU3EMCU5XWDNU4BGGJFNLI2EL354IVBK7"))
            XCTAssertTrue(stellarToml.accountInformation.accounts.contains("GAOO3LWBC4XF6VWRP5ESJ6IBHAISVJMSBTALHOQM2EZG7Q477UWA6L7U"))
            XCTAssertNil(stellarToml.accountInformation.uriRequestSigningKey)
            
            let documentation = stellarToml.issuerDocumentation
            XCTAssertTrue(documentation.orgName == "Organization Name")
            XCTAssertTrue(documentation.orgDBA == "Organization DBA")
            XCTAssertTrue(documentation.orgURL == "https://www.domain.com")
            XCTAssertTrue(documentation.orgLogo == "https://www.domain.com/awesomelogo.png")
            XCTAssertTrue(documentation.orgDescription == "Description of issuer")
            XCTAssertTrue(documentation.orgPhysicalAddress == "123 Sesame Street, New York, NY 12345, United States")
            XCTAssertTrue(documentation.orgPhysicalAddressAttestation == "https://www.domain.com/address_attestation.jpg")
            XCTAssertTrue(documentation.orgPhoneNumber == "1 (123)-456-7890")
            XCTAssertTrue(documentation.orgPhoneNumberAttestation == "https://www.domain.com/phone_attestation.jpg")
            XCTAssertTrue(documentation.orgKeybase == "accountname")
            XCTAssertTrue(documentation.orgTwitter == "orgtweet")
            XCTAssertTrue(documentation.orgGithub == "orgcode")
            XCTAssertTrue(documentation.orgOfficialEmail == "support@domain.com")
            XCTAssertNil(documentation.orgLicensingAuthority)
            XCTAssertNil(documentation.orgLicenseType)
            XCTAssertNil(documentation.orgLicenseNumber)
            
            if let pointOfContact = stellarToml.pointsOfContact.first {
                XCTAssertTrue(pointOfContact.name == "Jane Jedidiah Johnson")
                XCTAssertTrue(pointOfContact.email == "jane@domain.com")
                XCTAssertTrue(pointOfContact.keybase == "crypto_jane")
                XCTAssertNil(pointOfContact.telegram)
                XCTAssertTrue(pointOfContact.twitter == "crypto_jane")
                XCTAssertTrue(pointOfContact.github == "crypto_jane")
                XCTAssertTrue(pointOfContact.idPhotoHash == "be688838ca8686e5c90689bf2ab585cef1137c999b48c70b92f67a5c34dc15697b5d11c982ed6d71be1e1e7f7b4e0733884aa97c3f7a339a8ed03577cf74be09")
                XCTAssertTrue(pointOfContact.verificationPhotoHash == "016ba8c4cfde65af99cb5fa8b8a37e2eb73f481b3ae34991666df2e04feb6c038666ebd1ec2b6f623967756033c702dde5f423f7d47ab6ed1827ff53783731f7")
            }
            else {
                XCTAssert(false)
            }
            
            let currencies = stellarToml.currenciesDocumentation
            XCTAssertTrue(currencies[0].code == "USD")
            XCTAssertTrue(currencies[0].issuer ==
                "GCZJM35NKGVK47BB4SPBDV25477PZYIYPVVG453LPYFNXLS3FGHDXOCM");
            XCTAssertTrue(currencies[0].displayDecimals == 2);
            XCTAssertTrue(currencies[1].code == "BTC");
            XCTAssertTrue(currencies[1].issuer ==
                "GAOO3LWBC4XF6VWRP5ESJ6IBHAISVJMSBTALHOQM2EZG7Q477UWA6L7U");
            XCTAssertTrue(currencies[1].displayDecimals == 7);
            XCTAssertTrue(currencies[1].anchorAssetType == "crypto");
            XCTAssertTrue(currencies[1].anchorAsset == "BTC");
            XCTAssertTrue(currencies[1].redemptionInstructions ==
                "Use SEP6 with our federation server");
            XCTAssertTrue(currencies[1]
                .collateralAddresses
                .contains("2C1mCx3ukix1KfegAY5zgQJV7sanAciZpv"));
            XCTAssertTrue(currencies[1].collateralAddressSignatures.contains(
                "304502206e21798a42fae0e854281abd38bacd1aeed3ee3738d9e1446618c4571d10"));
            XCTAssertTrue(currencies[2].code == "GOAT");
            XCTAssertTrue(currencies[2].issuer ==
                "GD5T6IPRNCKFOHQWT264YPKOZAWUMMZOLZBJ6BNQMUGPWGRLBK3U7ZNP");
            XCTAssertTrue(currencies[2].displayDecimals == 2);
            XCTAssertTrue(currencies[2].name == "goat share");
            XCTAssertTrue(currencies[2].desc ==
                "1 GOAT token entitles you to a share of revenue from Elkins Goat Farm.");
            XCTAssertTrue(currencies[2].conditions ==
                "There will only ever be 10,000 GOAT tokens in existence. We will distribute the revenue share annually on Jan. 15th");
            XCTAssertTrue(currencies[2].image ==
                "https://static.thenounproject.com/png/2292360-200.png");
            XCTAssertTrue(currencies[2].fixedNumber == 10000);
            
            let validators = stellarToml.validatorsInformation
            
            XCTAssertTrue(validators[0].alias == "domain-au");
            XCTAssertTrue(validators[0].displayName == "Domain Australia");
            XCTAssertTrue(validators[0].host == "core-au.domain.com:11625");
            XCTAssertTrue(validators[0].publicKey ==
                "GD5DJQDDBKGAYNEAXU562HYGOOSYAEOO6AS53PZXBOZGCP5M2OPGMZV3");
            XCTAssertTrue(validators[0].history ==
                "http://history.domain.com/prd/core-live/core_live_001/");
            XCTAssertTrue(validators[1].alias == "domain-sg");
            XCTAssertTrue(validators[1].displayName == "Domain Singapore");
            XCTAssertTrue(validators[1].host == "core-sg.domain.com:11625");
            XCTAssertTrue(validators[1].publicKey ==
                "GAENZLGHJGJRCMX5VCHOLHQXU3EMCU5XWDNU4BGGJFNLI2EL354IVBK7");
            XCTAssertTrue(validators[1].history ==
                "http://history.domain.com/prd/core-live/core_live_002/");
            XCTAssertTrue(validators[2].alias == "domain-us");
            XCTAssertTrue(validators[2].displayName == "Domain United States");
            XCTAssertTrue(validators[2].host == "core-us.domain.com:11625");
            XCTAssertTrue(validators[2].publicKey ==
                "GAOO3LWBC4XF6VWRP5ESJ6IBHAISVJMSBTALHOQM2EZG7Q477UWA6L7U");
            XCTAssertTrue(validators[2].history ==
                "http://history.domain.com/prd/core-live/core_live_003/");
            
            
        } catch {
            XCTAssertTrue(false)
        }
    }
    
    var tomlSampleV2: String {
        get {
            return """
            # Sample stellar.toml
            VERSION="2.0.0"
            
            NETWORK_PASSPHRASE="Public Global Stellar Network ; September 2015"
            FEDERATION_SERVER="https://api.domain.com/federation"
            AUTH_SERVER="https://api.domain.com/auth"
            TRANSFER_SERVER="https://api.domain.com"
            SIGNING_KEY="GBBHQ7H4V6RRORKYLHTCAWP6MOHNORRFJSDPXDFYDGJB2LPZUFPXUEW3"
            HORIZON_URL="https://horizon.domain.com"
            ACCOUNTS=[
            "GD5DJQDDBKGAYNEAXU562HYGOOSYAEOO6AS53PZXBOZGCP5M2OPGMZV3",
            "GAENZLGHJGJRCMX5VCHOLHQXU3EMCU5XWDNU4BGGJFNLI2EL354IVBK7",
            "GAOO3LWBC4XF6VWRP5ESJ6IBHAISVJMSBTALHOQM2EZG7Q477UWA6L7U"
            ]
            
            [DOCUMENTATION]
            ORG_NAME="Organization Name"
            ORG_DBA="Organization DBA"
            ORG_URL="https://www.domain.com"
            ORG_LOGO="https://www.domain.com/awesomelogo.png"
            ORG_DESCRIPTION="Description of issuer"
            ORG_PHYSICAL_ADDRESS="123 Sesame Street, New York, NY 12345, United States"
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
            image="https://static.thenounproject.com/png/2292360-200.png"
            fixed_number=10000
            
            [[VALIDATORS]]
            ALIAS="domain-au"
            DISPLAY_NAME="Domain Australia"
            HOST="core-au.domain.com:11625"
            PUBLIC_KEY="GD5DJQDDBKGAYNEAXU562HYGOOSYAEOO6AS53PZXBOZGCP5M2OPGMZV3"
            HISTORY="http://history.domain.com/prd/core-live/core_live_001/"
            
            [[VALIDATORS]]
            ALIAS="domain-sg"
            DISPLAY_NAME="Domain Singapore"
            HOST="core-sg.domain.com:11625"
            PUBLIC_KEY="GAENZLGHJGJRCMX5VCHOLHQXU3EMCU5XWDNU4BGGJFNLI2EL354IVBK7"
            HISTORY="http://history.domain.com/prd/core-live/core_live_002/"
            
            [[VALIDATORS]]
            ALIAS="domain-us"
            DISPLAY_NAME="Domain United States"
            HOST="core-us.domain.com:11625"
            PUBLIC_KEY="GAOO3LWBC4XF6VWRP5ESJ6IBHAISVJMSBTALHOQM2EZG7Q477UWA6L7U"
            HISTORY="http://history.domain.com/prd/core-live/core_live_003/"
            
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
}
