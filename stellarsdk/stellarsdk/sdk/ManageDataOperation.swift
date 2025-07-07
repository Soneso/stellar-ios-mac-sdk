//
//  ManageDataOperation.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 16.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents an manage data operation. Allows you to set,modify or delete a Data Entry (name/value pair) that is attached to a particular account. An account can have an arbitrary amount of DataEntries attached to it. Each DataEntry increases the minimum balance needed to be held by the account.
/// See [Stellar Guides] (https://www.stellar.org/developers/learn/concepts/list-of-operations.html#manage-data, "Manage Data Operations").
public class ManageDataOperation:Operation {
    
    public let name:String
    public let data:Data?
    
    /// Creates a new ManageDataOperation object.
    ///
    /// - Parameter sourceAccountId: (optional) source account Id, must be valid, otherwise it will be ignored.
    /// - Parameter name: String up to 64 bytes long. If this is a new Name it will add the given name/value pair to the account. If this Name is already present then the associated value will be modified.
    /// - Parameter value: (optional) If not present then the existing Name will be deleted. If present then this value will be set in the DataEntry. Up to 64 bytes long.
    ///
    public init(sourceAccountId:String?, name:String, data:Data? = nil) {
        self.name = name
        self.data = data
        super.init(sourceAccountId:sourceAccountId)
    }
    
    /// Creates a new ManageDataOperation object from the given ManageDataOperationXDR object.
    ///
    /// - Parameter fromXDR: the ManageDataOperationXDR object to be used to create a new ManageDataOperation object.
    /// - Parameter sourceAccountId: (optional) source account Id, must be valid, otherwise it will be ignored.
    ///
    public init(fromXDR:ManageDataOperationXDR, sourceAccountId:String?) {
        self.name = fromXDR.dataName
        self.data = fromXDR.dataValue
        super.init(sourceAccountId: sourceAccountId)
    }
    
    override func getOperationBodyXDR() throws -> OperationBodyXDR {

        return OperationBodyXDR.manageData(ManageDataOperationXDR(dataName: name,
                                                                  dataValue: data))
    }
}
