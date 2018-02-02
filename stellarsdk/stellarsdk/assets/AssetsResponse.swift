//
//  AllAssetsResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 02.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

public class AssetsResponse: NSObject, Codable {
    
    var assets:[Asset]
    
    public init(assets: [Asset]) {
        self.assets = assets
    }
}
