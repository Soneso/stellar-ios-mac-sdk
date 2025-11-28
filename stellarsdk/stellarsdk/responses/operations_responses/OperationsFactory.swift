//
//  OperationFactory.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 06/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Factory class for creating operation response instances from Horizon API JSON data.
///
/// This factory parses the operation type from the JSON response and instantiates the appropriate operation subclass.
/// Operations represent the individual actions that can be performed within a transaction.
///
/// This class is thread-safe and can be used from multiple threads concurrently.
///
/// See [Stellar developer docs](https://developers.stellar.org)
final class OperationsFactory: Sendable {
    
    /// Parses a paginated collection of operations from Horizon API JSON data.
    ///
    /// - Parameter data: The JSON data received from the Horizon API containing an embedded array of operations.
    /// - Returns: A PageResponse containing an array of OperationResponse objects and pagination links.
    /// - Throws: HorizonRequestError.parsingResponseFailed if the JSON cannot be parsed or contains an unknown operation type.
    func operationsFromResponseData(data: Data) throws -> PageResponse<OperationResponse> {
        var operationsList = [OperationResponse]()
        var links: PagingLinksResponse
        let jsonDecoder = JSONDecoder()

        do {
            guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject] else {
                throw HorizonRequestError.parsingResponseFailed(message: "Invalid JSON structure")
            }

            guard let embedded = json["_embedded"] as? [String:AnyObject],
                  let records = embedded["records"] as? [[String:AnyObject]] else {
                throw HorizonRequestError.parsingResponseFailed(message: "Missing or invalid _embedded.records")
            }

            for record in records {
                let jsonRecord = try JSONSerialization.data(withJSONObject: record, options: .prettyPrinted)
                let operation = try operationFromData(data: jsonRecord)
                operationsList.append(operation)
            }

            guard let linksObject = json["_links"] else {
                throw HorizonRequestError.parsingResponseFailed(message: "Missing _links")
            }
            let linksJson = try JSONSerialization.data(withJSONObject: linksObject, options: .prettyPrinted)
            links = try jsonDecoder.decode(PagingLinksResponse.self, from: linksJson)

        } catch {
            throw HorizonRequestError.parsingResponseFailed(message: error.localizedDescription)
        }

        return PageResponse<OperationResponse>(records: operationsList, links: links)
    }
    
    /// Parses a single operation from JSON data.
    ///
    /// - Parameter data: The JSON data representing a single operation.
    /// - Returns: An OperationResponse subclass instance based on the operation type.
    /// - Throws: HorizonRequestError.parsingResponseFailed if the JSON cannot be parsed or contains an unknown operation type.
    func operationFromData(data: Data) throws -> OperationResponse {
        // The class to be used depends on the operation type coded in its json representation.
        guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject] else {
            throw HorizonRequestError.parsingResponseFailed(message: "Invalid JSON structure")
        }
        guard let typeInt = json["type_i"] as? Int else {
            throw HorizonRequestError.parsingResponseFailed(message: "Missing or invalid type_i field")
        }

        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)

        if let type = OperationType(rawValue: Int32(typeInt)) {
            switch type {
            case .accountCreated:
                return try jsonDecoder.decode(AccountCreatedOperationResponse.self, from: data)
            case .payment:
                return try jsonDecoder.decode(PaymentOperationResponse.self, from: data)
            case .pathPayment:
                return try jsonDecoder.decode(PathPaymentStrictReceiveOperationResponse.self, from: data)
            case .manageSellOffer:
                return try jsonDecoder.decode(ManageSellOfferOperationResponse.self, from: data)
            case .manageBuyOffer:
                return try jsonDecoder.decode(ManageBuyOfferOperationResponse.self, from: data)
            case .createPassiveSellOffer:
                return try jsonDecoder.decode(CreatePassiveSellOfferOperationResponse.self, from: data)
            case .setOptions:
                return try jsonDecoder.decode(SetOptionsOperationResponse.self, from: data)
            case .changeTrust:
                return try jsonDecoder.decode(ChangeTrustOperationResponse.self, from: data)
            case .allowTrust:
                return try jsonDecoder.decode(AllowTrustOperationResponse.self, from: data)
            case .accountMerge:
                return try jsonDecoder.decode(AccountMergeOperationResponse.self, from: data)
            case .inflation:
                return try jsonDecoder.decode(InflationOperationResponse.self, from: data)
            case .manageData:
                return try jsonDecoder.decode(ManageDataOperationResponse.self, from: data)
            case .bumpSequence:
                return try jsonDecoder.decode(BumpSequenceOperationResponse.self, from: data)
            case .pathPaymentStrictSend:
                return try jsonDecoder.decode(PathPaymentStrictSendOperationResponse.self, from: data)
            case .createClaimableBalance:
                return try jsonDecoder.decode(CreateClaimableBalanceOperationResponse.self, from: data)
            case .claimClaimableBalance:
                return try jsonDecoder.decode(ClaimClaimableBalanceOperationResponse.self, from: data)
            case .beginSponsoringFutureReserves:
                return try jsonDecoder.decode(BeginSponsoringFutureReservesOperationResponse.self, from: data)
            case .endSponsoringFutureReserves:
                return try jsonDecoder.decode(EndSponsoringFutureReservesOperationResponse.self, from: data)
            case .revokeSponsorship:
                return try jsonDecoder.decode(RevokeSponsorshipOperationResponse.self, from: data)
            case .clawback:
                return try jsonDecoder.decode(ClawbackOperationResponse.self, from: data)
            case .clawbackClaimableBalance:
                return try jsonDecoder.decode(ClawbackClaimableBalanceOperationResponse.self, from: data)
            case .setTrustLineFlags:
                return try jsonDecoder.decode(SetTrustLineFlagsOperationResponse.self, from: data)
            case .liquidityPoolDeposit:
                return try jsonDecoder.decode(LiquidityPoolDepostOperationResponse.self, from: data)
            case .liquidityPoolWithdraw:
                return try jsonDecoder.decode(LiquidityPoolWithdrawOperationResponse.self, from: data)
            case .invokeHostFunction:
                return try jsonDecoder.decode(InvokeHostFunctionOperationResponse.self, from: data)
            case .extendFootprintTTL:
                return try jsonDecoder.decode(ExtendFootprintTTLOperationResponse.self, from: data)
            case .restoreFootprint:
                return try jsonDecoder.decode(RestoreFootprintOperationResponse.self, from: data)
            }
        } else {
            throw HorizonRequestError.parsingResponseFailed(message: "Unknown operation type")
        }
    }
}
