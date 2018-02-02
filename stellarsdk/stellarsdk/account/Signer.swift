//
//  Signer.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 30/01/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

public class Signer: NSObject, Codable {
    
    public var publicKey:String
    public var weight:Int
    
    override init() {
        publicKey = ""
        weight = 0
    }
    
    enum CodingKeys: String, CodingKey {
        case publicKey = "public_key"
        case weight
    }
    
}
