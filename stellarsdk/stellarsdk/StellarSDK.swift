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
    public var assets: AssetsService
    public var effects: EffectsService
    public var ledgers: LedgersService
    public var operations: OperationsService
    
    public override init() {
        configurations = Configs()
        accounts = AccountService(baseURL: configurations.horizonURL)
        assets = AssetsService(baseURL: configurations.horizonURL)
        effects = EffectsService(baseURL: configurations.horizonURL)
        ledgers = LedgersService(baseURL: configurations.horizonURL)
        operations = OperationsService(baseURL: configurations.horizonURL)
    }
    
    public init(configurations: Configs) {
        self.configurations = configurations
        self.accounts = AccountService(baseURL: configurations.horizonURL)
        self.assets = AssetsService(baseURL: configurations.horizonURL)
        self.effects = EffectsService(baseURL: configurations.horizonURL)
        self.ledgers = LedgersService(baseURL: configurations.horizonURL)
        self.operations = OperationsService(baseURL: configurations.horizonURL)
    }
    
}
