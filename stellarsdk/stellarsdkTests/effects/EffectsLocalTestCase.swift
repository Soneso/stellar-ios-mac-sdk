//
//  EffectsLocalTestCase.swift
//  stellarsdkTests
//
//  Created by Rogobete Christian on 19.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class EffectsLocalTestCase: XCTestCase {
    let sdk = StellarSDK()
    var effectsResponsesMock: EffectsResponsesMock? = nil
    var mockRegistered = false
    
    override func setUp() {
        super.setUp()
        
        if !mockRegistered {
            URLProtocol.registerClass(ServerMock.self)
            mockRegistered = true
        }
        
        effectsResponsesMock = EffectsResponsesMock()
        let allEffectTypesResponse = successResponse()
        effectsResponsesMock?.addEffectsResponse(key: "19", response: allEffectTypesResponse)
        
    }
    
    override func tearDown() {
        effectsResponsesMock = nil
        super.tearDown()
    }
    
    func testLoadEffects() {
        let expectation = XCTestExpectation(description: "Get effects and parse their details")
        
        sdk.effects.getEffects(limit: 19) { (response) -> (Void) in
            switch response {
            case .success(let effectsResponse):
                validateResult(effectsResponse:effectsResponse)
            case .failure(_):
                XCTAssert(false)
            }
            expectation.fulfill()
        }
        
        func validateResult(effectsResponse:PageResponse<EffectResponse>) {
            
            XCTAssertNotNil(effectsResponse.links)
            XCTAssertNotNil(effectsResponse.links.selflink)
            XCTAssertEqual(effectsResponse.links.selflink.href, "https://horizon-testnet.stellar.org/effects?order=desc&limit=19&cursor=")
            XCTAssertNil(effectsResponse.links.selflink.templated)
            
            XCTAssertNotNil(effectsResponse.links.next)
            XCTAssertEqual(effectsResponse.links.next?.href, "https://horizon-testnet.stellar.org/effects?order=desc&limit=19&cursor=32069348273168385-1")
            XCTAssertNil(effectsResponse.links.next?.templated)
            
            XCTAssertNotNil(effectsResponse.links.prev)
            XCTAssertEqual(effectsResponse.links.prev?.href, "https://horizon-testnet.stellar.org/effects?order=asc&limit=19&cursor=32069369748004865-2")
            XCTAssertNil(effectsResponse.links.prev?.templated)
            
            XCTAssertEqual(effectsResponse.records.count, 3)

            for record in effectsResponse.records {
                switch record.effectType {
                    case EffectType.accountCreated:
                        if record is AccountCreatedEffectResponse {
                            validateAccountCreatedEffectResponse(effectResponse: record as! AccountCreatedEffectResponse)
                        } else {
                            XCTAssert(false)
                        }
                    case EffectType.accountRemoved:
                        if record is AccountRemovedEffectResponse {
                            validateAccountRemovedEffectResponse(effectResponse: record as! AccountRemovedEffectResponse)
                        } else {
                            XCTAssert(false)
                        }
                    case EffectType.accountCredited:
                        if record is AccountCreditedEffectResponse {
                            validateAccountCreditedEffectResponse(effectResponse: record as! AccountCreditedEffectResponse)
                        } else {
                            XCTAssert(false)
                        }
                    case EffectType.accountDebited:
                        if record is AccountDebitedEffectResponse {
                            validateAccountDebitedEffectResponse(effectResponse: record as! AccountDebitedEffectResponse)
                        } else {
                            XCTAssert(false)
                        }
                    case EffectType.accountThresholdsUpdated:
                        if record is AccountThresholdsUpdatedEffectResponse {
                            validateAccountThresholdsUpdatedEffectResponse(effectResponse: record as! AccountThresholdsUpdatedEffectResponse)
                        } else {
                            XCTAssert(false)
                        }
                    case EffectType.accountHomeDomainUpdated:
                        if record is AccountHomeDomainUpdatedEffectResponse {
                            validateAccountHomeDomainUpdatedEffectResponse(effectResponse: record as! AccountHomeDomainUpdatedEffectResponse)
                        } else {
                            XCTAssert(false)
                        }
                    case EffectType.accountFlagsUpdated:
                        if record is AccountFlagsUpdatedEffectResponse {
                            validateAccountFlagsUpdatedEffectResponse(effectResponse: record as! AccountFlagsUpdatedEffectResponse)
                        } else {
                            XCTAssert(false)
                        }
                    case EffectType.signerCreated:
                        if record is SignerCreatedEffectResponse {
                            validateSignerCreatedEffectResponse(effectResponse: record as! SignerCreatedEffectResponse)
                        } else {
                            XCTAssert(false)
                        }
                    case EffectType.signerRemoved:
                        if record is SignerRemovedEffectResponse {
                            validateSignerRemovedEffectResponse(effectResponse: record as! SignerRemovedEffectResponse)
                        } else {
                            XCTAssert(false)
                        }
                    case EffectType.signerUpdated:
                        if record is SignerUpdatedEffectResponse {
                            validateSignerUpdatedEffectResponse(effectResponse: record as! SignerUpdatedEffectResponse)
                        } else {
                            XCTAssert(false)
                        }
                    case EffectType.trustlineCreated:
                        if record is TrustlineCreatedEffectResponse {
                            validateTrustlineCreatedEffectResponse(effectResponse: record as! TrustlineCreatedEffectResponse)
                        } else {
                            XCTAssert(false)
                        }
                    case EffectType.trustlineRemoved:
                        if record is TrustlineRemovedEffectResponse {
                            validateTrustlineRemovedEffectResponse(effectResponse: record as! TrustlineRemovedEffectResponse)
                        } else {
                            XCTAssert(false)
                        }
                    case EffectType.trustlineUpdated:
                        if record is TrustlineUpdatedEffectResponse {
                            validateTrustlineUpdatedEffectResponse(effectResponse: record as! TrustlineUpdatedEffectResponse)
                        } else {
                            XCTAssert(false)
                        }
                    case EffectType.trustlineAuthorized:
                        if record is TrustlineAuthorizedEffectResponse {
                            validateTrustlineAuthorizedEffectResponse(effectResponse: record as! TrustlineAuthorizedEffectResponse)
                        } else {
                            XCTAssert(false)
                        }
                    case EffectType.trustlineDeauthorized:
                        if record is TrustlineDeauthorizedEffectResponse {
                            validateTrustlineDeauthorizedEffectResponse(effectResponse: record as! TrustlineDeauthorizedEffectResponse)
                        } else {
                            XCTAssert(false)
                        }
                    case EffectType.offerCreated:
                        if record is OfferCreatedEffectResponse {
                            validateOfferCreatedEffectResponse(effectResponse: record as! OfferCreatedEffectResponse)
                        } else {
                            XCTAssert(false)
                        }
                    case EffectType.offerRemoved:
                        if record is OfferRemovedEffectResponse {
                            validateOfferRemovedEffectResponse(effectResponse: record as! OfferRemovedEffectResponse)
                        } else {
                            XCTAssert(false)
                        }
                    case EffectType.offerUpdated:
                        if record is OfferUpdatedEffectResponse {
                            validateOfferUpdatedEffectResponse(effectResponse: record as! OfferUpdatedEffectResponse)
                        } else {
                            XCTAssert(false)
                        }
                    case EffectType.tradeEffect:
                        if record is TradeEffectResponse {
                            validateTradeEffectResponse(effectResponse: record as! TradeEffectResponse)
                        } else {
                            XCTAssert(false)
                        }
                }
            }
        }
        
        // validate account created effect response
        func validateAccountCreatedEffectResponse(effectResponse: AccountCreatedEffectResponse) {
            XCTAssertNotNil(effectResponse.links)
            XCTAssertNotNil(effectResponse.links.operation)
            XCTAssertEqual(effectResponse.links.operation.href, "https://horizon-testnet.stellar.org/operations/32069356863102977")
            XCTAssertNil(effectResponse.links.operation.templated)
            
            XCTAssertNotNil(effectResponse.links.succeeds)
            XCTAssertEqual(effectResponse.links.succeeds.href, "https://horizon-testnet.stellar.org/effects?order=desc&cursor=32069356863102977-1")
            XCTAssertNil(effectResponse.links.succeeds.templated)
            
            XCTAssertNotNil(effectResponse.links.precedes)
            XCTAssertEqual(effectResponse.links.precedes.href, "https://horizon-testnet.stellar.org/effects?order=asc&cursor=32069356863102977-1")
            XCTAssertNil(effectResponse.links.precedes.templated)
            
            XCTAssertEqual(effectResponse.id, "0032069356863102977-0000000001")
            XCTAssertEqual(effectResponse.pagingToken, "32069356863102977-1")
            XCTAssertEqual(effectResponse.account, "GCCVAKZQOWB6GUW22A4EZHDROG5KHI2QF53K4ZFFURSDPZFKW6EBJAAY")
            XCTAssertEqual(effectResponse.effectTypeString, EffectTypeAsString.ACCOUNT_CREATED)
            XCTAssertEqual(effectResponse.effectType, EffectType.accountCreated)
            XCTAssertEqual(effectResponse.startingBalance, "10000.0000000")
            
        }
        
        // validate account created effect response
        func validateAccountRemovedEffectResponse(effectResponse: AccountRemovedEffectResponse) {
            XCTAssertNotNil(effectResponse.links)
            XCTAssertNotNil(effectResponse.links.operation)
            XCTAssertEqual(effectResponse.links.operation.href, "http://horizon-testnet.stellar.org/operations/65571265847297")
            XCTAssertNil(effectResponse.links.operation.templated)
            
            XCTAssertNotNil(effectResponse.links.succeeds)
            XCTAssertEqual(effectResponse.links.succeeds.href, "http://horizon-testnet.stellar.org/effects?order=desc&cursor=65571265847297-1")
            XCTAssertNil(effectResponse.links.succeeds.templated)
            
            XCTAssertNotNil(effectResponse.links.precedes)
            XCTAssertEqual(effectResponse.links.precedes.href, "http://horizon-testnet.stellar.org/effects?order=asc&cursor=65571265847297-1")
            XCTAssertNil(effectResponse.links.precedes.templated)
            
            XCTAssertEqual(effectResponse.id, "0000065571265847297-0000000001")
            XCTAssertEqual(effectResponse.pagingToken, "65571265847297-1")
            XCTAssertEqual(effectResponse.account, "GCBQ6JRBPF3SXQBQ6SO5MRBE7WVV4UCHYOSHQGXSZNPZLFRYVYOWBZRQ")
            XCTAssertEqual(effectResponse.effectTypeString, EffectTypeAsString.ACCOUNT_REMOVED)
            XCTAssertEqual(effectResponse.effectType, EffectType.accountRemoved)
        }
        
        // validate account credited effect response
        func validateAccountCreditedEffectResponse(effectResponse: AccountCreditedEffectResponse) {
            XCTAssertNotNil(effectResponse.links)
            XCTAssertNotNil(effectResponse.links.operation)
            XCTAssertEqual(effectResponse.links.operation.href, "http://horizon-testnet.stellar.org/operations/13563506724865")
            XCTAssertNil(effectResponse.links.operation.templated)
            
            XCTAssertNotNil(effectResponse.links.succeeds)
            XCTAssertEqual(effectResponse.links.succeeds.href, "http://horizon-testnet.stellar.org/effects?order=desc&cursor=13563506724865-1")
            XCTAssertNil(effectResponse.links.succeeds.templated)
            
            XCTAssertNotNil(effectResponse.links.precedes)
            XCTAssertEqual(effectResponse.links.precedes.href, "http://horizon-testnet.stellar.org/effects?order=asc&cursor=13563506724865-1")
            XCTAssertNil(effectResponse.links.precedes.templated)
            
            XCTAssertEqual(effectResponse.id, "0000013563506724865-0000000001")
            XCTAssertEqual(effectResponse.pagingToken, "13563506724865-1")
            XCTAssertEqual(effectResponse.account, "GDLGTRIBFH24364GPWPUS45GUFC2GU4ARPGWTXVCPLGTUHX3IOS3ON47")
            XCTAssertEqual(effectResponse.effectTypeString, EffectTypeAsString.ACCOUNT_CREDITED)
            XCTAssertEqual(effectResponse.effectType, EffectType.accountCredited)
            XCTAssertEqual(effectResponse.assetType, AssetTypeAsString.NATIVE)
            XCTAssertNil(effectResponse.assetCode)
            XCTAssertNil(effectResponse.assetIssuer)
            XCTAssertEqual(effectResponse.amount, "1000.0")
        }
        
        // validate account debited effect response
        func validateAccountDebitedEffectResponse(effectResponse: AccountDebitedEffectResponse) {
            // TODO
        }
        
        // validate account thresholds updated effect response
        func validateAccountThresholdsUpdatedEffectResponse(effectResponse: AccountThresholdsUpdatedEffectResponse) {
            // TODO
        }
            
        // validate account home domain updated effect response
        func validateAccountHomeDomainUpdatedEffectResponse(effectResponse: AccountHomeDomainUpdatedEffectResponse) {
            // TODO
        }
        
        // validate account flags updated effect response
        func validateAccountFlagsUpdatedEffectResponse(effectResponse: AccountFlagsUpdatedEffectResponse) {
            // TODO
        }
        
        // validate signer created effect response
        func validateSignerCreatedEffectResponse(effectResponse: SignerCreatedEffectResponse) {
            // TODO
        }
        
        // validate signer removed effect response
        func validateSignerRemovedEffectResponse(effectResponse: SignerRemovedEffectResponse) {
            // TODO
        }
        
        // validate signer updated effect response
        func validateSignerUpdatedEffectResponse(effectResponse: SignerUpdatedEffectResponse) {
            // TODO
        }
        
        // validate trustline created effect response
        func validateTrustlineCreatedEffectResponse(effectResponse: TrustlineCreatedEffectResponse) {
            // TODO
        }
        
        // validate trustline removed effect response
        func validateTrustlineRemovedEffectResponse(effectResponse: TrustlineRemovedEffectResponse) {
            // TODO
        }
        
        // validate trustline updated effect response
        func validateTrustlineUpdatedEffectResponse(effectResponse: TrustlineUpdatedEffectResponse) {
            // TODO
        }
        
        // validate trustline authorized effect response
        func validateTrustlineAuthorizedEffectResponse(effectResponse: TrustlineAuthorizedEffectResponse) {
            // TODO
        }
        
        // validate trustline deauthorized effect response
        func validateTrustlineDeauthorizedEffectResponse(effectResponse: TrustlineDeauthorizedEffectResponse) {
            // TODO
        }
        
        // validate offer created effect response
        func validateOfferCreatedEffectResponse(effectResponse: OfferCreatedEffectResponse) {
            // TODO
        }
        
        // validate offer removed effect response
        func validateOfferRemovedEffectResponse(effectResponse: OfferRemovedEffectResponse) {
            // TODO
        }
        
        // validate offer updated effect response
        func validateOfferUpdatedEffectResponse(effectResponse: OfferUpdatedEffectResponse) {
            // TODO
        }
        
        // validate trade  effect response
        func validateTradeEffectResponse(effectResponse: TradeEffectResponse) {
            // TODO
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    private func successResponse() -> String {
        
        // account created
        var effectsResponseString = """
        {
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/effects?order=desc&limit=19&cursor="
                },
                "next": {
                    "href": "https://horizon-testnet.stellar.org/effects?order=desc&limit=19&cursor=32069348273168385-1"
                },
                "prev": {
                    "href": "https://horizon-testnet.stellar.org/effects?order=asc&limit=19&cursor=32069369748004865-2"
                }
            },
            "_embedded": {
                "records": [
        """
        
        effectsResponseString.append(accountCreatedEffect)
        effectsResponseString.append("," + accountRemovedEffect)
        effectsResponseString.append("," + accountCreditedEffect)
//        effectsResponseString.append("," + accountDebitedEffect)
//        effectsResponseString.append("," + accountThresholdsUpdatedEffect)
//        effectsResponseString.append("," + accountHomeDomainUpdatedEffect)
//        effectsResponseString.append("," + accountFlagsUpdatedEffect)
//        effectsResponseString.append("," + signerCreatedEffect)
//        effectsResponseString.append("," + signerRemovedEffect)
//        effectsResponseString.append("," + signerUpdatedEffect)
//        effectsResponseString.append("," + trustlineCreatedEffect)
//        effectsResponseString.append("," + trustlineRemovedEffect)
//        effectsResponseString.append("," + trustlineUpdatedEffect)
//        effectsResponseString.append("," + trustlineAuthorizedEffect)
//        effectsResponseString.append("," + trustlineDeauthorizedEffect)
//        effectsResponseString.append("," + offerCreatedEffect)
//        effectsResponseString.append("," + offerRemovedEffect)
//        effectsResponseString.append("," + offerUpdatedEffect)
//        effectsResponseString.append("," + tradeEffect)
        
    
        let end = """
                    ]
                }
            }
        """
        
        effectsResponseString.append(end)
        return effectsResponseString
    }
    
    private let accountCreatedEffect = """
            {
                "_links": {
                    "operation": {
                        "href": "https://horizon-testnet.stellar.org/operations/32069356863102977"
                    },
                    "succeeds": {
                        "href": "https://horizon-testnet.stellar.org/effects?order=desc&cursor=32069356863102977-1"
                    },
                    "precedes": {
                        "href": "https://horizon-testnet.stellar.org/effects?order=asc&cursor=32069356863102977-1"
                    }
                },
                "id": "0032069356863102977-0000000001",
                "paging_token": "32069356863102977-1",
                "account": "GCCVAKZQOWB6GUW22A4EZHDROG5KHI2QF53K4ZFFURSDPZFKW6EBJAAY",
                "type": "account_created",
                "type_i": 0,
                "starting_balance": "10000.0000000"
            }
    """
    
    private let accountRemovedEffect = """
            {
                "_links": {
                    "operation": {
                        "href": "http://horizon-testnet.stellar.org/operations/65571265847297"
                    },
                    "succeeds": {
                        "href": "http://horizon-testnet.stellar.org/effects?order=desc&cursor=65571265847297-1"
                    },
                    "precedes": {
                        "href": "http://horizon-testnet.stellar.org/effects?order=asc&cursor=65571265847297-1"
                    }
                },
                "id": "0000065571265847297-0000000001",
                "paging_token": "65571265847297-1",
                "account": "GCBQ6JRBPF3SXQBQ6SO5MRBE7WVV4UCHYOSHQGXSZNPZLFRYVYOWBZRQ",
                "type": "account_removed",
                "type_i": 1
            }
    """
    
    private let accountCreditedEffect = """
            {
                "_links": {
                   "operation": {
                        "href": "http://horizon-testnet.stellar.org/operations/13563506724865"
                    },
                   "succeeds": {
                        "href": "http://horizon-testnet.stellar.org/effects?order=desc&cursor=13563506724865-1"
                    },
                    "precedes": {
                        "href": "http://horizon-testnet.stellar.org/effects?order=asc&cursor=13563506724865-1"
                    }
                },
                "id": "0000013563506724865-0000000001",
                "paging_token": "13563506724865-1",
                "account": "GDLGTRIBFH24364GPWPUS45GUFC2GU4ARPGWTXVCPLGTUHX3IOS3ON47",
                "type": "account_credited",
                "type_i": 2,
                "asset_type": "native",
                "amount": "1000.0"
            }
    """
    private let accountDebitedEffect = "" //TODO
    private let accountThresholdsUpdatedEffect = "" //TODO
    private let accountHomeDomainUpdatedEffect = "" //TODO
    private let accountFlagsUpdatedEffect = "" //TODO
    private let signerCreatedEffect = "" //TODO
    private let signerRemovedEffect = "" //TODO
    private let signerUpdatedEffect = "" //TODO
    private let trustlineCreatedEffect = "" //TODO
    private let trustlineRemovedEffect = "" //TODO
    private let trustlineUpdatedEffect = "" //TODO
    private let trustlineAuthorizedEffect = "" //TODO
    private let trustlineDeauthorizedEffect = "" //TODO
    private let offerCreatedEffect = "" //TODO
    private let offerRemovedEffect = "" //TODO
    private let offerUpdatedEffect = "" //TODO
    private let tradeEffect = "" //TODO
    
}
