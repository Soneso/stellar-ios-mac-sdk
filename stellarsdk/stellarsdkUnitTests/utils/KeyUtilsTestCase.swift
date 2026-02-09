//
//  KeyUtils.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 07/11/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class KeyUtilsTestCase: XCTestCase {

    // MARK: - Payload Signing Tests
    // These test cryptographic signing operations, not strkey encoding

    func testSignPayloadSigner() {
        do {
            let seedData = try Data(base16Encoded: "1123740522f11bfef6b3671f51e159ccf589ccf8965262dd5f97d1721d383dd4")
            let kp = KeyPair(seed: try Seed(bytes: [UInt8](seedData)))
            let payload = Data([1,2,3,4,5])
            let sig = kp.signPayloadDecorated(payload)
            let sigHint = Data([UInt8(0xFF & 252), 65, 0, 50])
            XCTAssertTrue(sig.hint.wrapped.elementsEqual(sigHint))
        } catch {
            XCTFail()
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
        } catch {
            XCTFail()
        }
    }
}
