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
    
    func testGetEffects() {
        let expectation = XCTestExpectation(description: "Get effects and parse their details succesffully")
        
        sdk.effects.getEffects(limit: 19) { (response) -> (Void) in
            switch response {
            case .success(let effectsResponse):
                validateResult(effectsResponse:effectsResponse)
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"GE Test", horizonRequestError: error)
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
            
            XCTAssertEqual(effectsResponse.records.count, 19)

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
            XCTAssertNotNil(effectResponse.links)
            XCTAssertNotNil(effectResponse.links.operation)
            XCTAssertEqual(effectResponse.links.operation.href, "http://horizon-testnet.stellar.org/operations/65571265843201")
            XCTAssertNil(effectResponse.links.operation.templated)
            
            XCTAssertNotNil(effectResponse.links.succeeds)
            XCTAssertEqual(effectResponse.links.succeeds.href, "http://horizon-testnet.stellar.org/effects?order=desc&cursor=65571265843201-2")
            XCTAssertNil(effectResponse.links.succeeds.templated)
            
            XCTAssertNotNil(effectResponse.links.precedes)
            XCTAssertEqual(effectResponse.links.precedes.href, "http://horizon-testnet.stellar.org/effects?order=asc&cursor=65571265843201-2")
            XCTAssertNil(effectResponse.links.precedes.templated)
            
            XCTAssertEqual(effectResponse.id, "0000065571265843201-0000000002")
            XCTAssertEqual(effectResponse.pagingToken, "65571265843201-2")
            XCTAssertEqual(effectResponse.account, "GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H")
            XCTAssertEqual(effectResponse.effectTypeString, EffectTypeAsString.ACCOUNT_DEBITED)
            XCTAssertEqual(effectResponse.effectType, EffectType.accountDebited)
            XCTAssertEqual(effectResponse.assetType, AssetTypeAsString.NATIVE)
            XCTAssertNil(effectResponse.assetCode)
            XCTAssertNil(effectResponse.assetIssuer)
            XCTAssertEqual(effectResponse.amount, "30.0")
        }
        
        // validate account thresholds updated effect response
        func validateAccountThresholdsUpdatedEffectResponse(effectResponse: AccountThresholdsUpdatedEffectResponse) {
            XCTAssertNotNil(effectResponse.links)
            XCTAssertNotNil(effectResponse.links.operation)
            XCTAssertEqual(effectResponse.links.operation.href, "http://horizon-testnet.stellar.org/operations/18970870550529")
            XCTAssertNil(effectResponse.links.operation.templated)
            
            XCTAssertNotNil(effectResponse.links.succeeds)
            XCTAssertEqual(effectResponse.links.succeeds.href, "http://horizon-testnet.stellar.org/effects?order=desc&cursor=18970870550529-1")
            XCTAssertNil(effectResponse.links.succeeds.templated)
            
            XCTAssertNotNil(effectResponse.links.precedes)
            XCTAssertEqual(effectResponse.links.precedes.href, "http://horizon-testnet.stellar.org/effects?order=asc&cursor=18970870550529-1")
            XCTAssertNil(effectResponse.links.precedes.templated)
            
            XCTAssertEqual(effectResponse.id, "0000018970870550529-0000000001")
            XCTAssertEqual(effectResponse.pagingToken, "18970870550529-1")
            XCTAssertEqual(effectResponse.account, "GA6U5X6WOPNKKDKQULBR7IDHDBAQKOWPHYEC7WSXHZBFEYFD3XVZAKOO")
            XCTAssertEqual(effectResponse.effectTypeString, EffectTypeAsString.ACCOUNT_THRESHOLDS_UPDATED)
            XCTAssertEqual(effectResponse.effectType, EffectType.accountThresholdsUpdated)
            XCTAssertEqual(effectResponse.lowThreshold, 2)
            XCTAssertEqual(effectResponse.medThreshold, 3)
            XCTAssertEqual(effectResponse.highThreshold, 4)
        }
            
        // validate account home domain updated effect response
        func validateAccountHomeDomainUpdatedEffectResponse(effectResponse: AccountHomeDomainUpdatedEffectResponse) {
            XCTAssertNotNil(effectResponse.links)
            XCTAssertNotNil(effectResponse.links.operation)
            XCTAssertEqual(effectResponse.links.operation.href, "http://horizon-testnet.stellar.org/operations/18970870550529")
            XCTAssertNil(effectResponse.links.operation.templated)
            
            XCTAssertNotNil(effectResponse.links.succeeds)
            XCTAssertEqual(effectResponse.links.succeeds.href, "http://horizon-testnet.stellar.org/effects?order=desc&cursor=18970870550529-1")
            XCTAssertNil(effectResponse.links.succeeds.templated)
            
            XCTAssertNotNil(effectResponse.links.precedes)
            XCTAssertEqual(effectResponse.links.precedes.href, "http://horizon-testnet.stellar.org/effects?order=asc&cursor=18970870550529-1")
            XCTAssertNil(effectResponse.links.precedes.templated)
            
            XCTAssertEqual(effectResponse.id, "0000018970870550529-0000000001")
            XCTAssertEqual(effectResponse.pagingToken, "18970870550529-1")
            XCTAssertEqual(effectResponse.account, "GA6U5X6WOPNKKDKQULBR7IDHDBAQKOWPHYEC7WSXHZBFEYFD3XVZAKOO")
            XCTAssertEqual(effectResponse.effectTypeString, EffectTypeAsString.ACCOUNT_HOME_DOMAIN_UPDATED)
            XCTAssertEqual(effectResponse.effectType, EffectType.accountHomeDomainUpdated)
            XCTAssertEqual(effectResponse.homeDomain, "stellar.org")
        }
        
        // validate account flags updated effect response
        func validateAccountFlagsUpdatedEffectResponse(effectResponse: AccountFlagsUpdatedEffectResponse) {
            XCTAssertNotNil(effectResponse.links)
            XCTAssertNotNil(effectResponse.links.operation)
            XCTAssertEqual(effectResponse.links.operation.href, "http://horizon-testnet.stellar.org/operations/18970870550529")
            XCTAssertNil(effectResponse.links.operation.templated)
            
            XCTAssertNotNil(effectResponse.links.succeeds)
            XCTAssertEqual(effectResponse.links.succeeds.href, "http://horizon-testnet.stellar.org/effects?order=desc&cursor=18970870550529-1")
            XCTAssertNil(effectResponse.links.succeeds.templated)
            
            XCTAssertNotNil(effectResponse.links.precedes)
            XCTAssertEqual(effectResponse.links.precedes.href, "http://horizon-testnet.stellar.org/effects?order=asc&cursor=18970870550529-1")
            XCTAssertNil(effectResponse.links.precedes.templated)
            
            XCTAssertEqual(effectResponse.id, "0000018970870550529-0000000001")
            XCTAssertEqual(effectResponse.pagingToken, "18970870550529-1")
            XCTAssertEqual(effectResponse.account, "GA6U5X6WOPNKKDKQULBR7IDHDBAQKOWPHYEC7WSXHZBFEYFD3XVZAKOO")
            XCTAssertEqual(effectResponse.effectTypeString, EffectTypeAsString.ACCOUNT_FLAGS_UPDATED)
            XCTAssertEqual(effectResponse.effectType, EffectType.accountFlagsUpdated)
            XCTAssertEqual(effectResponse.authRequired, false)
            XCTAssertEqual(effectResponse.authRevocable, true)
        }
        
        // validate signer created effect response
        func validateSignerCreatedEffectResponse(effectResponse: SignerCreatedEffectResponse) {
            XCTAssertNotNil(effectResponse.links)
            XCTAssertNotNil(effectResponse.links.operation)
            XCTAssertEqual(effectResponse.links.operation.href, "http://horizon-testnet.stellar.org/operations/65571265859585")
            XCTAssertNil(effectResponse.links.operation.templated)
            
            XCTAssertNotNil(effectResponse.links.succeeds)
            XCTAssertEqual(effectResponse.links.succeeds.href, "http://horizon-testnet.stellar.org/effects?order=desc&cursor=65571265859585-3")
            XCTAssertNil(effectResponse.links.succeeds.templated)
            
            XCTAssertNotNil(effectResponse.links.precedes)
            XCTAssertEqual(effectResponse.links.precedes.href, "http://horizon-testnet.stellar.org/effects?order=asc&cursor=65571265859585-3")
            XCTAssertNil(effectResponse.links.precedes.templated)
            
            XCTAssertEqual(effectResponse.id, "0000065571265859585-0000000003")
            XCTAssertEqual(effectResponse.pagingToken, "65571265859585-3")
            XCTAssertEqual(effectResponse.account, "GB24LPGAHYTWRYOXIDKXLI55SBRWW42T3TZKDAAW3BOJX4ADVIATFTLU")
            XCTAssertEqual(effectResponse.effectTypeString, EffectTypeAsString.SIGNER_CREATED)
            XCTAssertEqual(effectResponse.effectType, EffectType.signerCreated)
            XCTAssertEqual(effectResponse.weight, 1)
            XCTAssertEqual(effectResponse.publicKey, "GB24LPGAHYTWRYOXIDKXLI55SBRWW42T3TZKDAAW3BOJX4ADVIATFTLU")
        }
        
        // validate signer removed effect response
        func validateSignerRemovedEffectResponse(effectResponse: SignerRemovedEffectResponse) {
            XCTAssertNotNil(effectResponse.links)
            XCTAssertNotNil(effectResponse.links.operation)
            XCTAssertEqual(effectResponse.links.operation.href, "http://horizon-testnet.stellar.org/operations/43658342567940")
            XCTAssertNil(effectResponse.links.operation.templated)
            
            XCTAssertNotNil(effectResponse.links.succeeds)
            XCTAssertEqual(effectResponse.links.succeeds.href, "http://horizon-testnet.stellar.org/effects?order=desc&cursor=43658342567940-2")
            XCTAssertNil(effectResponse.links.succeeds.templated)
            
            XCTAssertNotNil(effectResponse.links.precedes)
            XCTAssertEqual(effectResponse.links.precedes.href, "http://horizon-testnet.stellar.org/effects?order=asc&cursor=43658342567940-2")
            XCTAssertNil(effectResponse.links.precedes.templated)
            
            XCTAssertEqual(effectResponse.id, "0000043658342567940-0000000002")
            XCTAssertEqual(effectResponse.pagingToken, "43658342567940-2")
            XCTAssertEqual(effectResponse.account, "GCFKT6BN2FEASCEVDNHEC4LLFT2KLUUPEMKM4OJPEJ65H2AEZ7IH4RV6")
            XCTAssertEqual(effectResponse.effectTypeString, EffectTypeAsString.SIGNER_REMOVED)
            XCTAssertEqual(effectResponse.effectType, EffectType.signerRemoved)
            XCTAssertEqual(effectResponse.weight, 0)
            XCTAssertEqual(effectResponse.publicKey, "GCFKT6BN2FEASCEVDNHEC4LLFT2KLUUPEMKM4OJPEJ65H2AEZ7IH4RV6")
        }
        
        // validate signer updated effect response
        func validateSignerUpdatedEffectResponse(effectResponse: SignerUpdatedEffectResponse) {
            XCTAssertNotNil(effectResponse.links)
            XCTAssertNotNil(effectResponse.links.operation)
            XCTAssertEqual(effectResponse.links.operation.href, "http://horizon-testnet.stellar.org/operations/43658342567940")
            XCTAssertNil(effectResponse.links.operation.templated)
            
            XCTAssertNotNil(effectResponse.links.succeeds)
            XCTAssertEqual(effectResponse.links.succeeds.href, "http://horizon-testnet.stellar.org/effects?order=desc&cursor=43658342567940-2")
            XCTAssertNil(effectResponse.links.succeeds.templated)
            
            XCTAssertNotNil(effectResponse.links.precedes)
            XCTAssertEqual(effectResponse.links.precedes.href, "http://horizon-testnet.stellar.org/effects?order=asc&cursor=43658342567940-2")
            XCTAssertNil(effectResponse.links.precedes.templated)
            
            XCTAssertEqual(effectResponse.id, "0000043658342567940-0000000002")
            XCTAssertEqual(effectResponse.pagingToken, "43658342567940-2")
            XCTAssertEqual(effectResponse.account, "GCFKT6BN2FEASCEVDNHEC4LLFT2KLUUPEMKM4OJPEJ65H2AEZ7IH4RV6")
            XCTAssertEqual(effectResponse.effectTypeString, EffectTypeAsString.SIGNER_UPDATED)
            XCTAssertEqual(effectResponse.effectType, EffectType.signerUpdated)
            XCTAssertEqual(effectResponse.weight, 2)
            XCTAssertEqual(effectResponse.publicKey, "GCFKT6BN2FEASCEVDNHEC4LLFT2KLUUPEMKM4OJPEJ65H2AEZ7IH4RV6")
        }
        
        // validate trustline created effect response
        func validateTrustlineCreatedEffectResponse(effectResponse: TrustlineCreatedEffectResponse) {
            XCTAssertNotNil(effectResponse.links)
            XCTAssertNotNil(effectResponse.links.operation)
            XCTAssertEqual(effectResponse.links.operation.href, "http://horizon-testnet.stellar.org/operations/33788507721730")
            XCTAssertNil(effectResponse.links.operation.templated)
            
            XCTAssertNotNil(effectResponse.links.succeeds)
            XCTAssertEqual(effectResponse.links.succeeds.href, "http://horizon-testnet.stellar.org/effects?order=desc&cursor=33788507721730-2")
            XCTAssertNil(effectResponse.links.succeeds.templated)
            
            XCTAssertNotNil(effectResponse.links.precedes)
            XCTAssertEqual(effectResponse.links.precedes.href, "http://horizon-testnet.stellar.org/effects?order=asc&cursor=33788507721730-2")
            XCTAssertNil(effectResponse.links.precedes.templated)
            
            XCTAssertEqual(effectResponse.id, "0000033788507721730-0000000002")
            XCTAssertEqual(effectResponse.pagingToken, "33788507721730-2")
            XCTAssertEqual(effectResponse.account, "GA6U5X6WOPNKKDKQULBR7IDHDBAQKOWPHYEC7WSXHZBFEYFD3XVZAKOO")
            XCTAssertEqual(effectResponse.effectTypeString, EffectTypeAsString.TRUSTLINE_CREATED)
            XCTAssertEqual(effectResponse.effectType, EffectType.trustlineCreated)
            XCTAssertEqual(effectResponse.assetType, AssetTypeAsString.CREDIT_ALPHANUM4)
            XCTAssertEqual(effectResponse.assetCode, "EUR")
            XCTAssertEqual(effectResponse.assetIssuer, "GAZN3PPIDQCSP5JD4ETQQQ2IU2RMFYQTAL4NNQZUGLLO2XJJJ3RDSDGA")
            XCTAssertEqual(effectResponse.limit, "1000.0")
        }
        
        // validate trustline removed effect response
        func validateTrustlineRemovedEffectResponse(effectResponse: TrustlineRemovedEffectResponse) {
            XCTAssertNotNil(effectResponse.links)
            XCTAssertNotNil(effectResponse.links.operation)
            XCTAssertEqual(effectResponse.links.operation.href, "http://horizon-testnet.stellar.org/operations/33788507721730")
            XCTAssertNil(effectResponse.links.operation.templated)
            
            XCTAssertNotNil(effectResponse.links.succeeds)
            XCTAssertEqual(effectResponse.links.succeeds.href, "http://horizon-testnet.stellar.org/effects?order=desc&cursor=33788507721730-2")
            XCTAssertNil(effectResponse.links.succeeds.templated)
            
            XCTAssertNotNil(effectResponse.links.precedes)
            XCTAssertEqual(effectResponse.links.precedes.href, "http://horizon-testnet.stellar.org/effects?order=asc&cursor=33788507721730-2")
            XCTAssertNil(effectResponse.links.precedes.templated)
            
            XCTAssertEqual(effectResponse.id, "0000033788507721730-0000000002")
            XCTAssertEqual(effectResponse.pagingToken, "33788507721730-2")
            XCTAssertEqual(effectResponse.account, "GA6U5X6WOPNKKDKQULBR7IDHDBAQKOWPHYEC7WSXHZBFEYFD3XVZAKOO")
            XCTAssertEqual(effectResponse.effectTypeString, EffectTypeAsString.TRUSTLINE_REMOVED)
            XCTAssertEqual(effectResponse.effectType, EffectType.trustlineRemoved)
            XCTAssertEqual(effectResponse.assetType, AssetTypeAsString.CREDIT_ALPHANUM4)
            XCTAssertEqual(effectResponse.assetCode, "EUR")
            XCTAssertEqual(effectResponse.assetIssuer, "GAZN3PPIDQCSP5JD4ETQQQ2IU2RMFYQTAL4NNQZUGLLO2XJJJ3RDSDGA")
            XCTAssertEqual(effectResponse.limit, "0.0")
        }
        
        // validate trustline updated effect response
        func validateTrustlineUpdatedEffectResponse(effectResponse: TrustlineUpdatedEffectResponse) {
            XCTAssertNotNil(effectResponse.links)
            XCTAssertNotNil(effectResponse.links.operation)
            XCTAssertEqual(effectResponse.links.operation.href, "http://horizon-testnet.stellar.org/operations/33788507721730")
            XCTAssertNil(effectResponse.links.operation.templated)
            
            XCTAssertNotNil(effectResponse.links.succeeds)
            XCTAssertEqual(effectResponse.links.succeeds.href, "http://horizon-testnet.stellar.org/effects?order=desc&cursor=33788507721730-2")
            XCTAssertNil(effectResponse.links.succeeds.templated)
            
            XCTAssertNotNil(effectResponse.links.precedes)
            XCTAssertEqual(effectResponse.links.precedes.href, "http://horizon-testnet.stellar.org/effects?order=asc&cursor=33788507721730-2")
            XCTAssertNil(effectResponse.links.precedes.templated)
            
            XCTAssertEqual(effectResponse.id, "0000033788507721730-0000000002")
            XCTAssertEqual(effectResponse.pagingToken, "33788507721730-2")
            XCTAssertEqual(effectResponse.account, "GA6U5X6WOPNKKDKQULBR7IDHDBAQKOWPHYEC7WSXHZBFEYFD3XVZAKOO")
            XCTAssertEqual(effectResponse.effectTypeString, EffectTypeAsString.TRUSTLINE_UPDATED)
            XCTAssertEqual(effectResponse.effectType, EffectType.trustlineUpdated)
            XCTAssertEqual(effectResponse.assetType, AssetTypeAsString.CREDIT_ALPHANUM12)
            XCTAssertEqual(effectResponse.assetCode, "TESTTEST")
            XCTAssertEqual(effectResponse.assetIssuer, "GAZN3PPIDQCSP5JD4ETQQQ2IU2RMFYQTAL4NNQZUGLLO2XJJJ3RDSDGA")
            XCTAssertEqual(effectResponse.limit, "100.0")
        }
        
        // validate trustline authorized effect response
        func validateTrustlineAuthorizedEffectResponse(effectResponse: TrustlineAuthorizedEffectResponse) {
            XCTAssertNotNil(effectResponse.links)
            XCTAssertNotNil(effectResponse.links.operation)
            XCTAssertEqual(effectResponse.links.operation.href, "http://horizon-testnet.stellar.org/operations/33788507721730")
            XCTAssertNil(effectResponse.links.operation.templated)
            
            XCTAssertNotNil(effectResponse.links.succeeds)
            XCTAssertEqual(effectResponse.links.succeeds.href, "http://horizon-testnet.stellar.org/effects?order=desc&cursor=33788507721730-2")
            XCTAssertNil(effectResponse.links.succeeds.templated)
            
            XCTAssertNotNil(effectResponse.links.precedes)
            XCTAssertEqual(effectResponse.links.precedes.href, "http://horizon-testnet.stellar.org/effects?order=asc&cursor=33788507721730-2")
            XCTAssertNil(effectResponse.links.precedes.templated)
            
            XCTAssertEqual(effectResponse.id, "0000033788507721730-0000000002")
            XCTAssertEqual(effectResponse.pagingToken, "33788507721730-2")
            XCTAssertEqual(effectResponse.account, "GA6U5X6WOPNKKDKQULBR7IDHDBAQKOWPHYEC7WSXHZBFEYFD3XVZAKOO")
            XCTAssertEqual(effectResponse.effectTypeString, EffectTypeAsString.TRUSTLINE_AUTHORIZED)
            XCTAssertEqual(effectResponse.effectType, EffectType.trustlineAuthorized)
            XCTAssertEqual(effectResponse.assetType, AssetTypeAsString.CREDIT_ALPHANUM12)
            XCTAssertEqual(effectResponse.assetCode, "TESTTEST")
            XCTAssertEqual(effectResponse.assetIssuer, "GAZN3PPIDQCSP5JD4ETQQQ2IU2RMFYQTAL4NNQZUGLLO2XJJJ3RDSDGA")
            XCTAssertEqual(effectResponse.limit, "100.0")
        }
        
        // validate trustline deauthorized effect response
        func validateTrustlineDeauthorizedEffectResponse(effectResponse: TrustlineDeauthorizedEffectResponse) {
            XCTAssertNotNil(effectResponse.links)
            XCTAssertNotNil(effectResponse.links.operation)
            XCTAssertEqual(effectResponse.links.operation.href, "http://horizon-testnet.stellar.org/operations/33788507721730")
            XCTAssertNil(effectResponse.links.operation.templated)
            
            XCTAssertNotNil(effectResponse.links.succeeds)
            XCTAssertEqual(effectResponse.links.succeeds.href, "http://horizon-testnet.stellar.org/effects?order=desc&cursor=33788507721730-2")
            XCTAssertNil(effectResponse.links.succeeds.templated)
            
            XCTAssertNotNil(effectResponse.links.precedes)
            XCTAssertEqual(effectResponse.links.precedes.href, "http://horizon-testnet.stellar.org/effects?order=asc&cursor=33788507721730-2")
            XCTAssertNil(effectResponse.links.precedes.templated)
            
            XCTAssertEqual(effectResponse.id, "0000033788507721730-0000000002")
            XCTAssertEqual(effectResponse.pagingToken, "33788507721730-2")
            XCTAssertEqual(effectResponse.account, "GA6U5X6WOPNKKDKQULBR7IDHDBAQKOWPHYEC7WSXHZBFEYFD3XVZAKOO")
            XCTAssertEqual(effectResponse.effectTypeString, EffectTypeAsString.TRUSTLINE_DEAUTHORIZED)
            XCTAssertEqual(effectResponse.effectType, EffectType.trustlineDeauthorized)
            XCTAssertEqual(effectResponse.assetType, AssetTypeAsString.CREDIT_ALPHANUM4)
            XCTAssertEqual(effectResponse.assetCode, "EUR")
            XCTAssertEqual(effectResponse.assetIssuer, "GAZN3PPIDQCSP5JD4ETQQQ2IU2RMFYQTAL4NNQZUGLLO2XJJJ3RDSDGA")
            XCTAssertEqual(effectResponse.limit, "100.0")
        }
        
        // validate offer created effect response
        func validateOfferCreatedEffectResponse(effectResponse: OfferCreatedEffectResponse) {
            XCTAssertNotNil(effectResponse.links)
            XCTAssertNotNil(effectResponse.links.operation)
            XCTAssertEqual(effectResponse.links.operation.href, "http://horizon-testnet.stellar.org/operations/33788507721730")
            XCTAssertNil(effectResponse.links.operation.templated)
            
            XCTAssertNotNil(effectResponse.links.succeeds)
            XCTAssertEqual(effectResponse.links.succeeds.href, "http://horizon-testnet.stellar.org/effects?order=desc&cursor=33788507721730-2")
            XCTAssertNil(effectResponse.links.succeeds.templated)
            
            XCTAssertNotNil(effectResponse.links.precedes)
            XCTAssertEqual(effectResponse.links.precedes.href, "http://horizon-testnet.stellar.org/effects?order=asc&cursor=33788507721730-2")
            XCTAssertNil(effectResponse.links.precedes.templated)
            
            XCTAssertEqual(effectResponse.id, "0000033788507721730-0000000002")
            XCTAssertEqual(effectResponse.pagingToken, "33788507721730-2")
            XCTAssertEqual(effectResponse.account, "GA6U5X6WOPNKKDKQULBR7IDHDBAQKOWPHYEC7WSXHZBFEYFD3XVZAKOO")
            XCTAssertEqual(effectResponse.effectTypeString, EffectTypeAsString.OFFER_CREATED)
            XCTAssertEqual(effectResponse.effectType, EffectType.offerCreated)
        }
        
        // validate offer removed effect response
        func validateOfferRemovedEffectResponse(effectResponse: OfferRemovedEffectResponse) {
            XCTAssertNotNil(effectResponse.links)
            XCTAssertNotNil(effectResponse.links.operation)
            XCTAssertEqual(effectResponse.links.operation.href, "http://horizon-testnet.stellar.org/operations/33788507721730")
            XCTAssertNil(effectResponse.links.operation.templated)
            
            XCTAssertNotNil(effectResponse.links.succeeds)
            XCTAssertEqual(effectResponse.links.succeeds.href, "http://horizon-testnet.stellar.org/effects?order=desc&cursor=33788507721730-2")
            XCTAssertNil(effectResponse.links.succeeds.templated)
            
            XCTAssertNotNil(effectResponse.links.precedes)
            XCTAssertEqual(effectResponse.links.precedes.href, "http://horizon-testnet.stellar.org/effects?order=asc&cursor=33788507721730-2")
            XCTAssertNil(effectResponse.links.precedes.templated)
            
            XCTAssertEqual(effectResponse.id, "0000033788507721730-0000000002")
            XCTAssertEqual(effectResponse.pagingToken, "33788507721730-2")
            XCTAssertEqual(effectResponse.account, "GA6U5X6WOPNKKDKQULBR7IDHDBAQKOWPHYEC7WSXHZBFEYFD3XVZAKOO")
            XCTAssertEqual(effectResponse.effectTypeString, EffectTypeAsString.OFFER_REMOVED)
            XCTAssertEqual(effectResponse.effectType, EffectType.offerRemoved)
        }
        
        // validate offer updated effect response
        func validateOfferUpdatedEffectResponse(effectResponse: OfferUpdatedEffectResponse) {
            XCTAssertNotNil(effectResponse.links)
            XCTAssertNotNil(effectResponse.links.operation)
            XCTAssertEqual(effectResponse.links.operation.href, "http://horizon-testnet.stellar.org/operations/33788507721730")
            XCTAssertNil(effectResponse.links.operation.templated)
            
            XCTAssertNotNil(effectResponse.links.succeeds)
            XCTAssertEqual(effectResponse.links.succeeds.href, "http://horizon-testnet.stellar.org/effects?order=desc&cursor=33788507721730-2")
            XCTAssertNil(effectResponse.links.succeeds.templated)
            
            XCTAssertNotNil(effectResponse.links.precedes)
            XCTAssertEqual(effectResponse.links.precedes.href, "http://horizon-testnet.stellar.org/effects?order=asc&cursor=33788507721730-2")
            XCTAssertNil(effectResponse.links.precedes.templated)
            
            XCTAssertEqual(effectResponse.id, "0000033788507721730-0000000002")
            XCTAssertEqual(effectResponse.pagingToken, "33788507721730-2")
            XCTAssertEqual(effectResponse.account, "GA6U5X6WOPNKKDKQULBR7IDHDBAQKOWPHYEC7WSXHZBFEYFD3XVZAKOO")
            XCTAssertEqual(effectResponse.effectTypeString, EffectTypeAsString.OFFER_UPDATED)
            XCTAssertEqual(effectResponse.effectType, EffectType.offerUpdated)
        }
        
        // validate trade  effect response
        func validateTradeEffectResponse(effectResponse: TradeEffectResponse) {
            XCTAssertNotNil(effectResponse.links)
            XCTAssertNotNil(effectResponse.links.operation)
            XCTAssertEqual(effectResponse.links.operation.href, "http://horizon-testnet.stellar.org/operations/33788507721730")
            XCTAssertNil(effectResponse.links.operation.templated)
            
            XCTAssertNotNil(effectResponse.links.succeeds)
            XCTAssertEqual(effectResponse.links.succeeds.href, "http://horizon-testnet.stellar.org/effects?order=desc&cursor=33788507721730-2")
            XCTAssertNil(effectResponse.links.succeeds.templated)
            
            XCTAssertNotNil(effectResponse.links.precedes)
            XCTAssertEqual(effectResponse.links.precedes.href, "http://horizon-testnet.stellar.org/effects?order=asc&cursor=33788507721730-2")
            XCTAssertNil(effectResponse.links.precedes.templated)
            
            XCTAssertEqual(effectResponse.id, "0000033788507721730-0000000002")
            XCTAssertEqual(effectResponse.pagingToken, "33788507721730-2")
            XCTAssertEqual(effectResponse.account, "GA6U5X6WOPNKKDKQULBR7IDHDBAQKOWPHYEC7WSXHZBFEYFD3XVZAKOO")
            XCTAssertEqual(effectResponse.effectTypeString, EffectTypeAsString.TRADE)
            XCTAssertEqual(effectResponse.effectType, EffectType.tradeEffect)
            XCTAssertEqual(effectResponse.seller, "GCVHDLN6EHZBYW2M3BQIY32C23E4GPIRZZDBNF2Q73DAZ5VJDRGSMYRB")
            XCTAssertEqual(effectResponse.offerId, 1)
            XCTAssertEqual(effectResponse.soldAmount, "1000.0")
            XCTAssertEqual(effectResponse.soldAssetType, AssetTypeAsString.CREDIT_ALPHANUM4)
            XCTAssertEqual(effectResponse.soldAssetCode, "EUR")
            XCTAssertEqual(effectResponse.soldAssetIssuer, "GCWVFBJ24754I5GXG4JOEB72GJCL3MKWC7VAEYWKGQHPVH3ENPNBSKWS")
            XCTAssertEqual(effectResponse.boughtAmount, "60.0")
            XCTAssertEqual(effectResponse.boughtAssetType, AssetTypeAsString.CREDIT_ALPHANUM12)
            XCTAssertEqual(effectResponse.boughtAssetCode, "TESTTEST")
            XCTAssertEqual(effectResponse.boughtAssetIssuer, "GAHXPUDP3AK6F2QQM4FIRBGPNGKLRDDSTQCVKEXXKKRHJZUUQ23D5BU7")
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
        effectsResponseString.append("," + accountDebitedEffect)
        effectsResponseString.append("," + accountThresholdsUpdatedEffect)
        effectsResponseString.append("," + accountHomeDomainUpdatedEffect)
        effectsResponseString.append("," + accountFlagsUpdatedEffect)
        effectsResponseString.append("," + signerCreatedEffect)
        effectsResponseString.append("," + signerRemovedEffect)
        effectsResponseString.append("," + signerUpdatedEffect)
        effectsResponseString.append("," + trustlineCreatedEffect)
        effectsResponseString.append("," + trustlineRemovedEffect)
        effectsResponseString.append("," + trustlineUpdatedEffect)
        effectsResponseString.append("," + trustlineAuthorizedEffect)
        effectsResponseString.append("," + trustlineDeauthorizedEffect)
        effectsResponseString.append("," + offerCreatedEffect)
        effectsResponseString.append("," + offerRemovedEffect)
        effectsResponseString.append("," + offerUpdatedEffect)
        effectsResponseString.append("," + tradeEffect)
        
    
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
    private let accountDebitedEffect = """
            {
                "_links": {
                   "operation": {
                        "href": "http://horizon-testnet.stellar.org/operations/65571265843201"
                    },
                   "succeeds": {
                        "href": "http://horizon-testnet.stellar.org/effects?order=desc&cursor=65571265843201-2"
                    },
                    "precedes": {
                        "href": "http://horizon-testnet.stellar.org/effects?order=asc&cursor=65571265843201-2"
                    }
                },
                "id": "0000065571265843201-0000000002",
                "paging_token": "65571265843201-2",
                "account": "GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H",
                "type": "account_debited",
                "type_i": 3,
                "asset_type": "native",
                "amount": "30.0"
            }
    """
    private let accountThresholdsUpdatedEffect = """
            {
                "_links": {
                   "operation": {
                        "href": "http://horizon-testnet.stellar.org/operations/18970870550529"
                    },
                   "succeeds": {
                        "href": "http://horizon-testnet.stellar.org/effects?order=desc&cursor=18970870550529-1"
                    },
                    "precedes": {
                        "href": "http://horizon-testnet.stellar.org/effects?order=asc&cursor=18970870550529-1"
                    }
                },
                "id": "0000018970870550529-0000000001",
                "paging_token": "18970870550529-1",
                "account": "GA6U5X6WOPNKKDKQULBR7IDHDBAQKOWPHYEC7WSXHZBFEYFD3XVZAKOO",
                "type": "account_thresholds_updated",
                "type_i": 4,
                "low_threshold": 2,
                "med_threshold": 3,
                "high_threshold": 4
            }
    """
    private let accountHomeDomainUpdatedEffect = """
            {
                "_links": {
                   "operation": {
                        "href": "http://horizon-testnet.stellar.org/operations/18970870550529"
                    },
                   "succeeds": {
                        "href": "http://horizon-testnet.stellar.org/effects?order=desc&cursor=18970870550529-1"
                    },
                    "precedes": {
                        "href": "http://horizon-testnet.stellar.org/effects?order=asc&cursor=18970870550529-1"
                    }
                },
                "id": "0000018970870550529-0000000001",
                "paging_token": "18970870550529-1",
                "account": "GA6U5X6WOPNKKDKQULBR7IDHDBAQKOWPHYEC7WSXHZBFEYFD3XVZAKOO",
                "type": "account_home_domain_updated",
                "type_i": 5,
                "home_domain": "stellar.org"
            }
    """
    private let accountFlagsUpdatedEffect = """
            {
                "_links": {
                   "operation": {
                        "href": "http://horizon-testnet.stellar.org/operations/18970870550529"
                    },
                   "succeeds": {
                        "href": "http://horizon-testnet.stellar.org/effects?order=desc&cursor=18970870550529-1"
                    },
                    "precedes": {
                        "href": "http://horizon-testnet.stellar.org/effects?order=asc&cursor=18970870550529-1"
                    }
                },
                "id": "0000018970870550529-0000000001",
                "paging_token": "18970870550529-1",
                "account": "GA6U5X6WOPNKKDKQULBR7IDHDBAQKOWPHYEC7WSXHZBFEYFD3XVZAKOO",
                "type": "account_flags_updated",
                "type_i": 6,
                "auth_required": false,
                "auth_revocable": true
            }
    """
    private let signerCreatedEffect = """
            {
                "_links": {
                   "operation": {
                        "href": "http://horizon-testnet.stellar.org/operations/65571265859585"
                    },
                   "succeeds": {
                        "href": "http://horizon-testnet.stellar.org/effects?order=desc&cursor=65571265859585-3"
                    },
                    "precedes": {
                        "href": "http://horizon-testnet.stellar.org/effects?order=asc&cursor=65571265859585-3"
                    }
                },
                "id": "0000065571265859585-0000000003",
                "paging_token": "65571265859585-3",
                "account": "GB24LPGAHYTWRYOXIDKXLI55SBRWW42T3TZKDAAW3BOJX4ADVIATFTLU",
                "type": "signer_created",
                "type_i": 10,
                "weight": 1,
                "public_key": "GB24LPGAHYTWRYOXIDKXLI55SBRWW42T3TZKDAAW3BOJX4ADVIATFTLU"
            }
    """
    private let signerRemovedEffect = """
            {
                "_links": {
                   "operation": {
                        "href": "http://horizon-testnet.stellar.org/operations/43658342567940"
                    },
                   "succeeds": {
                        "href": "http://horizon-testnet.stellar.org/effects?order=desc&cursor=43658342567940-2"
                    },
                    "precedes": {
                        "href": "http://horizon-testnet.stellar.org/effects?order=asc&cursor=43658342567940-2"
                    }
                },
                "id": "0000043658342567940-0000000002",
                "paging_token": "43658342567940-2",
                "account": "GCFKT6BN2FEASCEVDNHEC4LLFT2KLUUPEMKM4OJPEJ65H2AEZ7IH4RV6",
                "type": "signer_removed",
                "type_i": 11,
                "weight": 0,
                "public_key": "GCFKT6BN2FEASCEVDNHEC4LLFT2KLUUPEMKM4OJPEJ65H2AEZ7IH4RV6"
            }
    """
    private let signerUpdatedEffect = """
            {
                "_links": {
                   "operation": {
                        "href": "http://horizon-testnet.stellar.org/operations/43658342567940"
                    },
                   "succeeds": {
                        "href": "http://horizon-testnet.stellar.org/effects?order=desc&cursor=43658342567940-2"
                    },
                    "precedes": {
                        "href": "http://horizon-testnet.stellar.org/effects?order=asc&cursor=43658342567940-2"
                    }
                },
                "id": "0000043658342567940-0000000002",
                "paging_token": "43658342567940-2",
                "account": "GCFKT6BN2FEASCEVDNHEC4LLFT2KLUUPEMKM4OJPEJ65H2AEZ7IH4RV6",
                "type": "signer_updated",
                "type_i": 12,
                "weight": 2,
                "public_key": "GCFKT6BN2FEASCEVDNHEC4LLFT2KLUUPEMKM4OJPEJ65H2AEZ7IH4RV6"
            }
    """
    private let trustlineCreatedEffect = """
            {
                "_links": {
                   "operation": {
                        "href": "http://horizon-testnet.stellar.org/operations/33788507721730"
                    },
                   "succeeds": {
                        "href": "http://horizon-testnet.stellar.org/effects?order=desc&cursor=33788507721730-2"
                    },
                    "precedes": {
                        "href": "http://horizon-testnet.stellar.org/effects?order=asc&cursor=33788507721730-2"
                    }
                },
                "id": "0000033788507721730-0000000002",
                "paging_token": "33788507721730-2",
                "account": "GA6U5X6WOPNKKDKQULBR7IDHDBAQKOWPHYEC7WSXHZBFEYFD3XVZAKOO",
                "type": "trustline_created",
                "type_i": 20,
                "asset_type": "credit_alphanum4",
                "asset_code": "EUR",
                "asset_issuer": "GAZN3PPIDQCSP5JD4ETQQQ2IU2RMFYQTAL4NNQZUGLLO2XJJJ3RDSDGA",
                "limit": "1000.0"
            }
    """
    private let trustlineRemovedEffect = """
            {
                "_links": {
                   "operation": {
                        "href": "http://horizon-testnet.stellar.org/operations/33788507721730"
                    },
                   "succeeds": {
                        "href": "http://horizon-testnet.stellar.org/effects?order=desc&cursor=33788507721730-2"
                    },
                    "precedes": {
                        "href": "http://horizon-testnet.stellar.org/effects?order=asc&cursor=33788507721730-2"
                    }
                },
                "id": "0000033788507721730-0000000002",
                "paging_token": "33788507721730-2",
                "account": "GA6U5X6WOPNKKDKQULBR7IDHDBAQKOWPHYEC7WSXHZBFEYFD3XVZAKOO",
                "type": "trustline_removed",
                "type_i": 21,
                "asset_type": "credit_alphanum4",
                "asset_code": "EUR",
                "asset_issuer": "GAZN3PPIDQCSP5JD4ETQQQ2IU2RMFYQTAL4NNQZUGLLO2XJJJ3RDSDGA",
                "limit": "0.0"
            }
    """
    private let trustlineUpdatedEffect = """
            {
                "_links": {
                   "operation": {
                        "href": "http://horizon-testnet.stellar.org/operations/33788507721730"
                    },
                   "succeeds": {
                        "href": "http://horizon-testnet.stellar.org/effects?order=desc&cursor=33788507721730-2"
                    },
                    "precedes": {
                        "href": "http://horizon-testnet.stellar.org/effects?order=asc&cursor=33788507721730-2"
                    }
                },
                "id": "0000033788507721730-0000000002",
                "paging_token": "33788507721730-2",
                "account": "GA6U5X6WOPNKKDKQULBR7IDHDBAQKOWPHYEC7WSXHZBFEYFD3XVZAKOO",
                "type": "trustline_updated",
                "type_i": 22,
                "asset_type": "credit_alphanum12",
                "asset_code": "TESTTEST",
                "asset_issuer": "GAZN3PPIDQCSP5JD4ETQQQ2IU2RMFYQTAL4NNQZUGLLO2XJJJ3RDSDGA",
                "limit": "100.0"
            }
    """
    private let trustlineAuthorizedEffect = """
            {
                "_links": {
                   "operation": {
                        "href": "http://horizon-testnet.stellar.org/operations/33788507721730"
                    },
                   "succeeds": {
                        "href": "http://horizon-testnet.stellar.org/effects?order=desc&cursor=33788507721730-2"
                    },
                    "precedes": {
                        "href": "http://horizon-testnet.stellar.org/effects?order=asc&cursor=33788507721730-2"
                    }
                },
                "id": "0000033788507721730-0000000002",
                "paging_token": "33788507721730-2",
                "account": "GA6U5X6WOPNKKDKQULBR7IDHDBAQKOWPHYEC7WSXHZBFEYFD3XVZAKOO",
                "type": "trustline_authorized",
                "type_i": 23,
                "asset_type": "credit_alphanum12",
                "asset_code": "TESTTEST",
                "asset_issuer": "GAZN3PPIDQCSP5JD4ETQQQ2IU2RMFYQTAL4NNQZUGLLO2XJJJ3RDSDGA",
                "limit": "100.0"
            }
    """
    private let trustlineDeauthorizedEffect = """
            {
                "_links": {
                   "operation": {
                        "href": "http://horizon-testnet.stellar.org/operations/33788507721730"
                    },
                   "succeeds": {
                        "href": "http://horizon-testnet.stellar.org/effects?order=desc&cursor=33788507721730-2"
                    },
                    "precedes": {
                        "href": "http://horizon-testnet.stellar.org/effects?order=asc&cursor=33788507721730-2"
                    }
                },
                "id": "0000033788507721730-0000000002",
                "paging_token": "33788507721730-2",
                "account": "GA6U5X6WOPNKKDKQULBR7IDHDBAQKOWPHYEC7WSXHZBFEYFD3XVZAKOO",
                "type": "trustline_deauthorized",
                "type_i": 24,
                "asset_type": "credit_alphanum4",
                "asset_code": "EUR",
                "asset_issuer": "GAZN3PPIDQCSP5JD4ETQQQ2IU2RMFYQTAL4NNQZUGLLO2XJJJ3RDSDGA",
                "limit": "100.0"
            }
    """
    private let offerCreatedEffect = """
            {
                "_links": {
                   "operation": {
                        "href": "http://horizon-testnet.stellar.org/operations/33788507721730"
                    },
                   "succeeds": {
                        "href": "http://horizon-testnet.stellar.org/effects?order=desc&cursor=33788507721730-2"
                    },
                    "precedes": {
                        "href": "http://horizon-testnet.stellar.org/effects?order=asc&cursor=33788507721730-2"
                    }
                },
                "id": "0000033788507721730-0000000002",
                "paging_token": "33788507721730-2",
                "account": "GA6U5X6WOPNKKDKQULBR7IDHDBAQKOWPHYEC7WSXHZBFEYFD3XVZAKOO",
                "type": "offer_created",
                "type_i": 30
            }
    """
    private let offerRemovedEffect = """
            {
                "_links": {
                   "operation": {
                        "href": "http://horizon-testnet.stellar.org/operations/33788507721730"
                    },
                   "succeeds": {
                        "href": "http://horizon-testnet.stellar.org/effects?order=desc&cursor=33788507721730-2"
                    },
                    "precedes": {
                        "href": "http://horizon-testnet.stellar.org/effects?order=asc&cursor=33788507721730-2"
                    }
                },
                "id": "0000033788507721730-0000000002",
                "paging_token": "33788507721730-2",
                "account": "GA6U5X6WOPNKKDKQULBR7IDHDBAQKOWPHYEC7WSXHZBFEYFD3XVZAKOO",
                "type": "offer_removed",
                "type_i": 31
            }
    """
    private let offerUpdatedEffect = """
            {
                "_links": {
                   "operation": {
                        "href": "http://horizon-testnet.stellar.org/operations/33788507721730"
                    },
                   "succeeds": {
                        "href": "http://horizon-testnet.stellar.org/effects?order=desc&cursor=33788507721730-2"
                    },
                    "precedes": {
                        "href": "http://horizon-testnet.stellar.org/effects?order=asc&cursor=33788507721730-2"
                    }
                },
                "id": "0000033788507721730-0000000002",
                "paging_token": "33788507721730-2",
                "account": "GA6U5X6WOPNKKDKQULBR7IDHDBAQKOWPHYEC7WSXHZBFEYFD3XVZAKOO",
                "type": "offer_updated",
                "type_i": 32
            }
    """
    private let tradeEffect = """
            {
                "_links": {
                   "operation": {
                        "href": "http://horizon-testnet.stellar.org/operations/33788507721730"
                    },
                   "succeeds": {
                        "href": "http://horizon-testnet.stellar.org/effects?order=desc&cursor=33788507721730-2"
                    },
                    "precedes": {
                        "href": "http://horizon-testnet.stellar.org/effects?order=asc&cursor=33788507721730-2"
                    }
                },
                "id": "0000033788507721730-0000000002",
                "paging_token": "33788507721730-2",
                "account": "GA6U5X6WOPNKKDKQULBR7IDHDBAQKOWPHYEC7WSXHZBFEYFD3XVZAKOO",
                "type": "trade",
                "type_i": 33,
                "seller": "GCVHDLN6EHZBYW2M3BQIY32C23E4GPIRZZDBNF2Q73DAZ5VJDRGSMYRB",
                "offer_id": 1,
                "sold_amount": "1000.0",
                "sold_asset_type": "credit_alphanum4",
                "sold_asset_code": "EUR",
                "sold_asset_issuer": "GCWVFBJ24754I5GXG4JOEB72GJCL3MKWC7VAEYWKGQHPVH3ENPNBSKWS",
                "bought_amount": "60.0",
                "bought_asset_type": "credit_alphanum12",
                "bought_asset_code": "TESTTEST",
                "bought_asset_issuer": "GAHXPUDP3AK6F2QQM4FIRBGPNGKLRDDSTQCVKEXXKKRHJZUUQ23D5BU7"
            }
    """
    
}
