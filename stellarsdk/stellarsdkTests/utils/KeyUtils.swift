//
//  KeyUtils.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 07/11/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class KeyUtils: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testKeyUtilsPublicKey() {
        let publicKey = "GAYYAL2XJKSQHQ7RJG7MXHTXPZFPUWPCV46UZLBEEF7FAHIQ36FT7ATA"
   
        do {
            let data = try publicKey.decodeEd25519PublicKey()
            let encodedKey = try data.encodeEd25519PublicKey()
            
            XCTAssertTrue(publicKey == encodedKey)
        } catch {
            XCTAssertTrue(false)
        }
    }
    
    func testKeyUtilsMuxedAccountM() {
        let accountId = "MAQAA5L65LSYH7CQ3VTJ7F3HHLGCL3DSLAR2Y47263D56MNNGHSQSAAAAAAAAAAE2LP26"
        
        do {
            let mux = try accountId.decodeMuxedAccount()
            var muxEncoded = try XDREncoder.encode(mux)
            let muxData = Data(bytes: &muxEncoded, count: muxEncoded.count)
            let muxId = try muxData.encodeMuxedAccount()
            
            XCTAssertTrue(accountId == muxId)
        } catch {
            XCTAssertTrue(false)
        }
    }

    func testKeyUtilsMuxedAccountP() {
        let accountId = "GBJRYVWMCM4IYZDEB7AUB7Q4IY64HLLWD5A3ZLONHDEDZ66YSU4IXS5N"
        
        do {
            let mux = try accountId.decodeMuxedAccount()
            var muxEncoded = try XDREncoder.encode(mux)
            let muxData = Data(bytes: &muxEncoded, count: muxEncoded.count)
            let muxId = try muxData.encodeMuxedAccount()
            XCTAssertTrue(accountId == muxId)
        } catch {
            XCTAssertTrue(false)
        }
    }
    
    func testKeyUtilsPrivateKey() {
        let publicKey = "SBXLH5ZCTJR2VKCDFKUQWP2WI4B5HKWDRQQ4TUZLFE47MQ4LZEAHCBLU"
        
        do {
            let data = try publicKey.decodeEd25519SecretSeed()
            let encodedKey = try data.encodeEd25519SecretSeed()
            
            XCTAssertTrue(publicKey == encodedKey)
        } catch {
            XCTAssertTrue(false)
        }
    }
    
    func testKeyUtilsSignedPayload32() {
        let accountId = "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ"
        let success = "PA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAQACAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DUPB6IBZGM"
        let dataStr = "0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20"
        do {
            let data = try Data(base16Encoded: dataStr)//"0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20".uppercased().data(using: String.ExtendedEncoding.hexadecimal)
            let pk = try PublicKey(accountId: accountId)
            let payloadSigner = Ed25519SignedPayload(ed25519: pk.wrappedData32(), payload: data)
            let encoded = try payloadSigner.encodeSignedPayload()
            XCTAssertTrue(encoded == success)
            let signedPayload = try encoded.decodeSignedPayload()
            XCTAssertTrue(try signedPayload.publicKey().accountId == accountId)
            let ddata = signedPayload.payload.base16EncodedString()
            XCTAssertTrue(ddata == dataStr)
        } catch {
            XCTAssertTrue(false)
        }
    }
    
    func testKeyUtilsSignedPayload16() {
        let accountId = "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ"
        let success = "PA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAOQCAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DUAAAAFGBU"
        let dataStr = "0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d"
        do {
            let data = try Data(base16Encoded: dataStr)
            let pk = try PublicKey(accountId: accountId)
            let payloadSigner = Ed25519SignedPayload(ed25519: pk.wrappedData32(), payload: data)
            let encoded = try payloadSigner.encodeSignedPayload()
            XCTAssertTrue(encoded == success)
            let signedPayload = try encoded.decodeSignedPayload()
            XCTAssertTrue(try signedPayload.publicKey().accountId == accountId)
            let ddata = signedPayload.payload.base16EncodedString()
            XCTAssertTrue(ddata == dataStr)
        } catch {
            XCTAssertTrue(false)
        }
    }
    
    func testKeyUtilsSignedPayloadToLong() {
        let accountId = "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ"
        let dataStr = "0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f200102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f2001"
        do {
            let data = try Data(base16Encoded: dataStr)
            let _ = try Signer.signedPayload(accountId: accountId, payload: data)
            XCTAssertTrue(false)
        } catch {
            XCTAssertTrue(true)
        }
    }
    
    func testSignPayloadSigner() {
        do {
            let seedData = try Data(base16Encoded: "1123740522f11bfef6b3671f51e159ccf589ccf8965262dd5f97d1721d383dd4")
            let kp = KeyPair(seed: try Seed(bytes: [UInt8](seedData)))
            let payload = Data([1,2,3,4,5])
            let sig = kp.signPayloadDecorated(payload)
            let sigHint = Data([UInt8(0xFF & 252), 65, 0, 50])
            XCTAssertTrue(sig.hint.wrapped.elementsEqual(sigHint))
            XCTAssertTrue(true)
        } catch {
            XCTAssertTrue(false)
        }
    }
    
    func testSignPayloadSignerLessThanHint() {
        do {
            let seedData = try Data(base16Encoded: "1123740522f11bfef6b3671f51e159ccf589ccf8965262dd5f97d1721d383dd4")
            let kp = KeyPair(seed: try Seed(bytes: [UInt8](seedData)))
            let payload = Data([1,2,3])
            let sig = kp.signPayloadDecorated(payload)
            let sigHint = Data([UInt8(255), 64, 7, 55])
            XCTAssertTrue(sig.hint.wrapped.elementsEqual(sigHint))
            XCTAssertTrue(true)
        } catch {
            XCTAssertTrue(false)
        }
    }
}
