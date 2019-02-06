//
//  BadRequestErrorResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 09.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  Represents a bad request error response from the horizon api (code 400), containing information related to the error
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/errors/bad-request.html "Bad request")
public struct ErrorResponseExtras: Decodable {
    public var envelopeXdr: String
    public var resultXdr: String
    public var resultCodes: ErrorResultCodes

    private enum CodingKeys: String, CodingKey {
        case envelopeXdr = "envelope_xdr"
        case resultXdr = "result_xdr"
        case resultCodes = "result_codes"
    }
}

public struct ErrorResultCodes: Decodable {
    public var transaction: String
    public var operations: [String]
}

public class BadRequestErrorResponse: ErrorResponse {
    public var extras: ErrorResponseExtras

    private enum CodingKeys: String, CodingKey {
        case extras
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        extras = try container.decode(ErrorResponseExtras.self, forKey: .extras)

        try super.init(from: decoder)
    }
}
