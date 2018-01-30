//
//  Signer.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 30/01/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

class Signer: NSObject, Codable {
    
    var publicKey:String
    var weight:Int
    
    override init() {
        publicKey = ""
        weight = 0
    }
    
    enum CodingKeys: String, CodingKey {
        case publicKey = "public_key"
        case weight
    }
    
}
