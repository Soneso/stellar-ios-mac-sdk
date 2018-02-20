//
//  Data+Hash.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 19/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit
import CSwiftyCommonCrypto

extension Data {

    var sha256: Data {
        get {
            var digest = Data(count: Int(CC_SHA256_DIGEST_LENGTH))
            
            _ = digest.withUnsafeMutableBytes { (digestBytes) in
                self.withUnsafeBytes { (stringBytes) in
                    CC_SHA256(stringBytes, CC_LONG(self.count), digestBytes)
                }
            }
            return digest
        }
    }
    
}

extension String {
    
    var sha256: Data {
        get {
            let data = self.data(using: .utf8)!
            var digest = Data(count: Int(CC_SHA256_DIGEST_LENGTH))
            
            _ = digest.withUnsafeMutableBytes { (digestBytes) in
                data.withUnsafeBytes { (stringBytes) in
                    CC_SHA256(stringBytes, CC_LONG(data.count), digestBytes)
                }
            }
            return digest
        }
    }
    
}
