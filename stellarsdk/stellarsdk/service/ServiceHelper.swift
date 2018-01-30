//
//  ServiceHelper.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 30/01/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

enum Result {
    case success(jsonDictionary: Data)
    case failure(code: Error)
}

typealias ResponseClosure = (_ response:Result) -> (Void)

class ServiceHelper: NSObject {
    let baseURL: String
    
    private override init() {
        baseURL = ""
    }
    
    init(baseURL: String) {
        self.baseURL = baseURL
    }
    
    open func GETRequest(path: String, completion: @escaping ResponseClosure) {
        let url = URL(string: baseURL + path)!
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard error == nil else {
                print(error!)
                return
            }
            guard let data = data else {
                return
            }
            
            let json = try! JSONSerialization.jsonObject(with: data, options: []) as! [String:AnyObject]
            print(json)
            
            completion(.success(jsonDictionary: data))
        }
        
        task.resume()
    }
    
}
