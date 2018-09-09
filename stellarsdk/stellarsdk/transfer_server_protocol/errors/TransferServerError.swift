//
//  TransferServerError.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 07/09/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum InformationNeededEnum {
    case nonInteractive(info:CustomerInformationNeededNonInteractive)
    case interactive(info:CustomerInformationNeededInteractive)
    case status(info:CustomerInformationStatus)
}

/// Errors thrown by the federation requests
public enum TransferServerError: Error {
    case invalidDomain
    case invalidToml
    case noTransferServerSet
    case parsingResponseFailed(message:String)
    case anchorError(message:String)
    case informationNeeded(response:InformationNeededEnum)
    case horizonError(error: HorizonRequestError)
}
