//
//  StellarSDK.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 29/01/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

public class StellarSDK: NSObject {
    
    public var configurations: Configs
    public var accounts: AccountService
    
    public override init() {
        configurations = Configs()
        accounts = AccountService(baseURL: configurations.horizonURL)
    }
    
    public init(configurations: Configs) {
        self.configurations = configurations
        self.accounts = AccountService(baseURL: configurations.horizonURL)
    }
    
}
