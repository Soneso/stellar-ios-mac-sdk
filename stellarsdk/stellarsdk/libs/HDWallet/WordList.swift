//
//  WordList.swift
//  WalletKit
//
//  Created by yuzushioh on 2018/01/01.
//  Copyright © 2018 yuzushioh. All rights reserved.
//

public enum WordList {
    case english
    case chineseSimplified
    case chineseTraditional
    case french
    case italian
    case japanese
    case korean
    case spanish
    
    public var words: [String] {
        switch self {
        case .english:
            return englishWords
        case .chineseSimplified:
            return chineseSimplifiedWords
        case .chineseTraditional:
            return chineseTraditionalWords
        case .french:
            return frenchWords
        case .italian:
            return italianWords
        case .japanese:
            return japaneseWords
        case .korean:
            return koreanWords
        case .spanish:
            return spanishWords
        }
    }
}

extension WordList {
    public var englishWords: [String] {
        return ["abandon", "ability", "able", "about", "above", "absent", "absorb", "abstract", "absurd", "abuse", "access", "accident", "account", "accuse", "achieve", "acid", "acoustic", "acquire", "across", "act", "action", "actor", "actress", "actual", "adapt", "add", "addict", "address", "adjust", "admit", "adult"]
    }
    
    public var chineseSimplifiedWords: [String] {
        return ["的"]
    }
    
    public var chineseTraditionalWords: [String] {
        return ["的"]
    }
    
    public var frenchWords: [String] {
        return ["abaisser"]
    }
    
    public var italianWords: [String] {
        return ["abaco"]
    }
    
    public var japaneseWords: [String] {
        return ["あいこくしん"]
    }
    
    public var koreanWords: [String] {
        return ["가격"]
    }
    
    public var spanishWords: [String] {
        return ["ábaco"]
    }
}
