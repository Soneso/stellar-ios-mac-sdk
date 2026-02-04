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
        effectsResponsesMock?.addEffectsResponse(key: "53", response: allEffectTypesResponse)
        
    }
    
    override func tearDown() {
        effectsResponsesMock = nil
        super.tearDown()
    }
    
    func testGetEffects() async {
        let response = await sdk.effects.getEffects(limit: 53)
        switch response {
        case .success(let page):
            validateResult(effectsResponse:page)
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"testGetEffects()", horizonRequestError: error)
            XCTFail()
        }
        
        func validateResult(effectsResponse:PageResponse<EffectResponse>) {
            
            XCTAssertNotNil(effectsResponse.links)
            XCTAssertNotNil(effectsResponse.links.selflink)
            XCTAssertEqual(effectsResponse.links.selflink.href, "https://horizon-testnet.stellar.org/effects?order=desc&limit=53&cursor=")
            XCTAssertNil(effectsResponse.links.selflink.templated)

            XCTAssertNotNil(effectsResponse.links.next)
            XCTAssertEqual(effectsResponse.links.next?.href, "https://horizon-testnet.stellar.org/effects?order=desc&limit=53&cursor=32069348273168385-1")
            XCTAssertNil(effectsResponse.links.next?.templated)

            XCTAssertNotNil(effectsResponse.links.prev)
            XCTAssertEqual(effectsResponse.links.prev?.href, "https://horizon-testnet.stellar.org/effects?order=asc&limit=53&cursor=32069369748004865-2")
            XCTAssertNil(effectsResponse.links.prev?.templated)
            
            XCTAssertEqual(effectsResponse.records.count, 53)

            for record in effectsResponse.records {
                switch record.effectType {
                    case .accountCreated:
                        if record is AccountCreatedEffectResponse {
                            validateAccountCreatedEffectResponse(effectResponse: record as! AccountCreatedEffectResponse)
                        } else {
                            XCTFail()
                        }
                    case .accountRemoved:
                        if record is AccountRemovedEffectResponse {
                            validateAccountRemovedEffectResponse(effectResponse: record as! AccountRemovedEffectResponse)
                        } else {
                            XCTFail()
                        }
                    case .accountCredited:
                        if record is AccountCreditedEffectResponse {
                            validateAccountCreditedEffectResponse(effectResponse: record as! AccountCreditedEffectResponse)
                        } else {
                            XCTFail()
                        }
                    case .accountDebited:
                        if record is AccountDebitedEffectResponse {
                            validateAccountDebitedEffectResponse(effectResponse: record as! AccountDebitedEffectResponse)
                        } else {
                            XCTFail()
                        }
                    case .accountThresholdsUpdated:
                        if record is AccountThresholdsUpdatedEffectResponse {
                            validateAccountThresholdsUpdatedEffectResponse(effectResponse: record as! AccountThresholdsUpdatedEffectResponse)
                        } else {
                            XCTFail()
                        }
                    case .accountHomeDomainUpdated:
                        if record is AccountHomeDomainUpdatedEffectResponse {
                            validateAccountHomeDomainUpdatedEffectResponse(effectResponse: record as! AccountHomeDomainUpdatedEffectResponse)
                        } else {
                            XCTFail()
                        }
                    case .accountFlagsUpdated:
                        if record is AccountFlagsUpdatedEffectResponse {
                            validateAccountFlagsUpdatedEffectResponse(effectResponse: record as! AccountFlagsUpdatedEffectResponse)
                        } else {
                            XCTFail()
                        }
                    case .signerCreated:
                        if record is SignerCreatedEffectResponse {
                            validateSignerCreatedEffectResponse(effectResponse: record as! SignerCreatedEffectResponse)
                        } else {
                            XCTFail()
                        }
                    case .signerRemoved:
                        if record is SignerRemovedEffectResponse {
                            validateSignerRemovedEffectResponse(effectResponse: record as! SignerRemovedEffectResponse)
                        } else {
                            XCTFail()
                        }
                    case .signerUpdated:
                        if record is SignerUpdatedEffectResponse {
                            validateSignerUpdatedEffectResponse(effectResponse: record as! SignerUpdatedEffectResponse)
                        } else {
                            XCTFail()
                        }
                    case .trustlineCreated:
                        if record is TrustlineCreatedEffectResponse {
                            validateTrustlineCreatedEffectResponse(effectResponse: record as! TrustlineCreatedEffectResponse)
                        } else {
                            XCTFail()
                        }
                    case .trustlineRemoved:
                        if record is TrustlineRemovedEffectResponse {
                            validateTrustlineRemovedEffectResponse(effectResponse: record as! TrustlineRemovedEffectResponse)
                        } else {
                            XCTFail()
                        }
                    case .trustlineUpdated:
                        if record is TrustlineUpdatedEffectResponse {
                            validateTrustlineUpdatedEffectResponse(effectResponse: record as! TrustlineUpdatedEffectResponse)
                        } else {
                            XCTFail()
                        }
                    case .trustlineAuthorized:
                        if record is TrustlineAuthorizedEffectResponse {
                            validateTrustlineAuthorizedEffectResponse(effectResponse: record as! TrustlineAuthorizedEffectResponse)
                        } else {
                            XCTFail()
                        }
                    case .trustlineDeauthorized:
                        if record is TrustlineDeauthorizedEffectResponse {
                            validateTrustlineDeauthorizedEffectResponse(effectResponse: record as! TrustlineDeauthorizedEffectResponse)
                        } else {
                            XCTFail()
                        }
                case .trustlineAuthorizedToMaintainLiabilities:
                        if record is TrustlineAuthorizedToMaintainLiabilitiesEffecResponse {
                            XCTAssert(true)
                        } else {
                            XCTFail()
                        }
                    case .offerCreated:
                        if record is OfferCreatedEffectResponse {
                            validateOfferCreatedEffectResponse(effectResponse: record as! OfferCreatedEffectResponse)
                        } else {
                            XCTFail()
                        }
                    case .offerRemoved:
                        if record is OfferRemovedEffectResponse {
                            validateOfferRemovedEffectResponse(effectResponse: record as! OfferRemovedEffectResponse)
                        } else {
                            XCTFail()
                        }
                    case .offerUpdated:
                        if record is OfferUpdatedEffectResponse {
                            validateOfferUpdatedEffectResponse(effectResponse: record as! OfferUpdatedEffectResponse)
                        } else {
                            XCTFail()
                        }
                    case .tradeEffect:
                        if record is TradeEffectResponse {
                            validateTradeEffectResponse(effectResponse: record as! TradeEffectResponse)
                        } else {
                            XCTFail()
                        }
                    case .accountInflationDestinationUpdated:
                        if record is AccountInflationDestinationUpdatedEffectResponse {
                            validateAccountInflationDestinationUpdatedEffectResponse(effectResponse: record as! AccountInflationDestinationUpdatedEffectResponse)
                        } else {
                            XCTFail()
                        }
                    case .dataCreatedEffect:
                        if record is DataCreatedEffectResponse {
                            validateDataCreatedEffectResponse(effectResponse: record as! DataCreatedEffectResponse)
                        } else {
                            XCTFail()
                        }
                    case .dataRemovedEffect:
                        if record is DataRemovedEffectResponse {
                            validateDataRemovedEffectResponse(effectResponse: record as! DataRemovedEffectResponse)
                        } else {
                            XCTFail()
                        }
                    case .dataUpdatedEffect:
                        if record is DataUpdatedEffectResponse {
                            validateDataUpdatedEffectResponse(effectResponse: record as! DataUpdatedEffectResponse)
                        } else {
                            XCTFail()
                        }
                    case .sequenceBumpedEffect:
                        if record is SequenceBumpedEffectResponse {
                            validateBumpSequenceEffectResponse(effectResponse: record as! SequenceBumpedEffectResponse)
                        } else {
                            XCTFail()
                        }
                    case .claimableBalanceCreatedEffect:
                        if record is ClaimableBalanceCreatedEffectResponse {
                            validateClaimableBalanceCreatedEffectResponse(effectResponse: record as! ClaimableBalanceCreatedEffectResponse)
                        } else {
                            XCTFail()
                        }
                    case .claimableBalanceClaimantCreatedEffect:
                        if record is ClaimableBalanceClaimantCreatedEffectResponse {
                            validateClaimableBalanceClaimantCreatedEffectResponse(effectResponse: record as! ClaimableBalanceClaimantCreatedEffectResponse)
                        } else {
                            XCTFail()
                        }
                    case .claimableBalanceClaimedEffect:
                        if record is ClaimableBalanceClaimedEffectResponse {
                            validateClaimableBalanceClaimedEffectResponse(effectResponse: record as! ClaimableBalanceClaimedEffectResponse)
                        } else {
                            XCTFail()
                        }
                    case .accountSponsorshipCreated:
                        if record is AccountSponsorshipCreatedEffectResponse {
                            validateAccountSponsorshipCreatedEffectResponse(effectResponse: record as! AccountSponsorshipCreatedEffectResponse)
                        } else {
                            XCTFail()
                        }
                    case .accountSponsorshipUpdated:
                        if record is AccountSponsorshipUpdatedEffectResponse {
                            validateAccountSponsorshipUpdatedEffectResponse(effectResponse: record as! AccountSponsorshipUpdatedEffectResponse)
                        } else {
                            XCTFail()
                        }
                    case .accountSponsorshipRemoved:
                        if record is AccountSponsorshipRemovedEffectResponse {
                            validateAccountSponsorshipRemovedEffectResponse(effectResponse: record as! AccountSponsorshipRemovedEffectResponse)
                        } else {
                            XCTFail()
                        }
                    case .trustlineSponsorshipCreated:
                        if record is TrustlineSponsorshipCreatedEffectResponse {
                            validateTrustlineSponsorshipCreatedEffectResponse(effectResponse: record as! TrustlineSponsorshipCreatedEffectResponse)
                        } else {
                            XCTFail()
                        }
                    case .trustlineSponsorshipUpdated:
                        if record is TrustlineSponsorshipUpdatedEffectResponse {
                            validateTrustlineSponsorshipUpdatedEffectResponse(effectResponse: record as! TrustlineSponsorshipUpdatedEffectResponse)
                        } else {
                            XCTFail()
                        }
                    case .trustlineSponsorshipRemoved:
                        if record is TrustlineSponsorshipRemovedEffectResponse {
                            validateTrustlineSponsorshipRemovedEffectResponse(effectResponse: record as! TrustlineSponsorshipRemovedEffectResponse)
                        } else {
                            XCTFail()
                        }
                    case .dataSponsorshipCreated:
                        if record is DataSponsorshipCreatedEffectResponse {
                            validateDataSponsorshipCreatedEffectResponse(effectResponse: record as! DataSponsorshipCreatedEffectResponse)
                        } else {
                            XCTFail()
                        }
                    case .dataSponsorshipUpdated:
                        if record is DataSponsorshipUpdatedEffectResponse {
                            validateDataSponsorshipUpdatedEffectResponse(effectResponse: record as! DataSponsorshipUpdatedEffectResponse)
                        } else {
                            XCTFail()
                        }
                    case .dataSponsorshipRemoved:
                        if record is DataSponsorshipRemovedEffectResponse {
                            validateDataSponsorshipRemovedEffectResponse(effectResponse: record as! DataSponsorshipRemovedEffectResponse)
                        } else {
                            XCTFail()
                        }
                    case .claimableBalanceSponsorshipCreated:
                        if record is ClaimableBalanceSponsorshipCreatedEffectResponse {
                            validateClaimableBalanceSponsorshipCreatedEffectResponse(effectResponse: record as! ClaimableBalanceSponsorshipCreatedEffectResponse)
                        } else {
                            XCTFail()
                        }
                    case .claimableBalanceSponsorshipUpdated:
                        if record is ClaimableBalanceSponsorshipUpdatedEffectResponse {
                            validateClaimableBalanceSponsorshipUpdatedEffectResponse(effectResponse: record as! ClaimableBalanceSponsorshipUpdatedEffectResponse)
                        } else {
                            XCTFail()
                        }
                    case .claimableBalanceSponsorshipRemoved:
                        if record is ClaimableBalanceSponsorshipRemovedEffectResponse {
                            validateClaimableBalanceSponsorshipRemovedEffectResponse(effectResponse: record as! ClaimableBalanceSponsorshipRemovedEffectResponse)
                        } else {
                            XCTFail()
                        }
                    case .signerBalanceSponsorshipCreated:
                        if record is SignerSponsorshipCreatedEffectResponse {
                            validateSignerSponsorshipCreatedEffectResponse(effectResponse: record as! SignerSponsorshipCreatedEffectResponse)
                        } else {
                            XCTFail()
                        }
                    case .signerBalanceSponsorshipUpdated:
                        if record is SignerSponsorshipUpdatedEffectResponse {
                            validateSignerSponsorshipUpdatedEffectResponse(effectResponse: record as! SignerSponsorshipUpdatedEffectResponse)
                        } else {
                            XCTFail()
                        }
                    case .signerBalanceSponsorshipRemoved:
                        if record is SignerSponsorshipRemovedEffectResponse {
                            validateSignerSponsorshipRemovedEffectResponse(effectResponse: record as! SignerSponsorshipRemovedEffectResponse)
                        } else {
                            XCTFail()
                        }
                    case .claimablaBalanceClawedBack:
                        if record is ClaimableBalanceClawedBackEffectResponse {
                            validateClaimableBalanceClawedBackEffectResponse(effectResponse: record as! ClaimableBalanceClawedBackEffectResponse)
                        } else {
                            XCTFail()
                        }
                    case .trustlineFlagsUpdated:
                        if record is TrustLineFlagsUpdatedEffectResponse {
                            XCTAssert(true)
                        } else {
                            XCTFail()
                        }
                    case .liquidityPoolDeposited:
                        if record is LiquidityPoolDepositedEffectResponse {
                            validateLiquidityPoolDepositedEffectResponse(effectResponse: record as! LiquidityPoolDepositedEffectResponse)
                        } else {
                            XCTFail()
                        }
                    case .liquidityPoolWithdrew:
                        if record is LiquidityPoolWithdrewEffectResponse {
                            validateLiquidityPoolWithdrewEffectResponse(effectResponse: record as! LiquidityPoolWithdrewEffectResponse)
                        } else {
                            XCTFail()
                        }
                    case .liquidityPoolTrade:
                        if record is LiquidityPoolTradeEffectResponse {
                            validateLiquidityPoolTradeEffectResponse(effectResponse: record as! LiquidityPoolTradeEffectResponse)
                        } else {
                            XCTFail()
                        }
                    case .liquidityPoolCreated:
                        if record is LiquidityPoolCreatedEffectResponse {
                            validateLiquidityPoolCreatedEffectResponse(effectResponse: record as! LiquidityPoolCreatedEffectResponse)
                        } else {
                            XCTFail()
                        }
                    case .liquidityPoolRemoved:
                        if record is LiquidityPoolRemovedEffectResponse {
                            validateLiquidityPoolRemovedEffectResponse(effectResponse: record as! LiquidityPoolRemovedEffectResponse)
                        } else {
                            XCTFail()
                        }
                    case .liquidityPoolRevoked:
                        if record is LiquidityPoolRevokedEffectResponse {
                            validateLiquidityPoolRevokedEffectResponse(effectResponse: record as! LiquidityPoolRevokedEffectResponse)
                        } else {
                            XCTFail()
                        }
                    case .contractCredited:
                        if record is ContractCreditedEffectResponse {
                            validateContractCreditedEffectResponse(effectResponse: record as! ContractCreditedEffectResponse)
                        } else {
                            XCTFail()
                        }
                    case .contractDebited:
                        if record is ContractDebitedEffectResponse {
                            validateContractDebitedEffectResponse(effectResponse: record as! ContractDebitedEffectResponse)
                        } else {
                            XCTFail()
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
            XCTAssertEqual(effectResponse.offerId, "1")
            XCTAssertEqual(effectResponse.soldAmount, "1000.0")
            XCTAssertEqual(effectResponse.soldAssetType, AssetTypeAsString.CREDIT_ALPHANUM4)
            XCTAssertEqual(effectResponse.soldAssetCode, "EUR")
            XCTAssertEqual(effectResponse.soldAssetIssuer, "GCWVFBJ24754I5GXG4JOEB72GJCL3MKWC7VAEYWKGQHPVH3ENPNBSKWS")
            XCTAssertEqual(effectResponse.boughtAmount, "60.0")
            XCTAssertEqual(effectResponse.boughtAssetType, AssetTypeAsString.CREDIT_ALPHANUM12)
            XCTAssertEqual(effectResponse.boughtAssetCode, "TESTTEST")
            XCTAssertEqual(effectResponse.boughtAssetIssuer, "GAHXPUDP3AK6F2QQM4FIRBGPNGKLRDDSTQCVKEXXKKRHJZUUQ23D5BU7")
        }
        
        func validateAccountInflationDestinationUpdatedEffectResponse(effectResponse: AccountInflationDestinationUpdatedEffectResponse) {
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
        }
        
        // validate account created effect response
        func validateDataCreatedEffectResponse(effectResponse: DataCreatedEffectResponse) {
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
            XCTAssertEqual(effectResponse.effectTypeString, EffectTypeAsString.MANAGE_DATA)
            XCTAssertEqual(effectResponse.effectType, EffectType.dataCreatedEffect)
        }
        
        // validate account created effect response
        func validateDataRemovedEffectResponse(effectResponse: DataRemovedEffectResponse) {
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
            XCTAssertEqual(effectResponse.effectTypeString, EffectTypeAsString.MANAGE_DATA)
            XCTAssertEqual(effectResponse.effectType, EffectType.dataRemovedEffect)
        }
        
        // validate account created effect response
        func validateDataUpdatedEffectResponse(effectResponse: DataUpdatedEffectResponse) {
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
            XCTAssertEqual(effectResponse.effectTypeString, EffectTypeAsString.MANAGE_DATA)
            XCTAssertEqual(effectResponse.effectType, EffectType.dataUpdatedEffect)
        }
        
        // validate account created effect response
        func validateBumpSequenceEffectResponse(effectResponse: SequenceBumpedEffectResponse) {
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
            XCTAssertEqual(effectResponse.effectTypeString, EffectTypeAsString.BUMP_SEQUENCE)
            XCTAssertEqual(effectResponse.effectType, EffectType.sequenceBumpedEffect)
        }

        // validate claimable balance effects
        func validateClaimableBalanceCreatedEffectResponse(effectResponse: ClaimableBalanceCreatedEffectResponse) {
            XCTAssertEqual(effectResponse.id, "0150684654087864322-0000000001")
            XCTAssertEqual(effectResponse.pagingToken, "150684654087864322-1")
            XCTAssertEqual(effectResponse.account, "GBHNGLLIE3KWGKCHIKMHJ5HVZHYIK7WTBE4QF5PLAKL4CJGSEU7HZIW5")
            XCTAssertEqual(effectResponse.effectType, EffectType.claimableBalanceCreatedEffect)
            XCTAssertEqual(effectResponse.balanceId, "0000000048a70acdec712be9547d19f7e58adc22e35e0f5bcf3897a0353ab5dd4c5d61f4")
            XCTAssertEqual(effectResponse.amount, "900.0000000")
        }

        func validateClaimableBalanceClaimantCreatedEffectResponse(effectResponse: ClaimableBalanceClaimantCreatedEffectResponse) {
            XCTAssertEqual(effectResponse.id, "0150684654087864322-0000000003")
            XCTAssertEqual(effectResponse.pagingToken, "150684654087864322-3")
            XCTAssertEqual(effectResponse.account, "GCBMP2WKIAX7KVDRCSFXJWFM5P7HDCGTCC76U5XR52OYII6AOWS7G3DT")
            XCTAssertEqual(effectResponse.effectType, EffectType.claimableBalanceClaimantCreatedEffect)
            XCTAssertEqual(effectResponse.balanceId, "0000000048a70acdec712be9547d19f7e58adc22e35e0f5bcf3897a0353ab5dd4c5d61f4")
            XCTAssertEqual(effectResponse.amount, "900.0000000")
            XCTAssertTrue(effectResponse.predicate.unconditional ?? false)
        }

        func validateClaimableBalanceClaimedEffectResponse(effectResponse: ClaimableBalanceClaimedEffectResponse) {
            XCTAssertEqual(effectResponse.id, "0150803053451329538-0000000001")
            XCTAssertEqual(effectResponse.pagingToken, "150803053451329538-1")
            XCTAssertEqual(effectResponse.account, "GANVXZ2DQ2FFLVCBSVMBBNVWSXS6YVEDP247EN4C3CM3I32XR4U3OU2I")
            XCTAssertEqual(effectResponse.effectType, EffectType.claimableBalanceClaimedEffect)
            XCTAssertEqual(effectResponse.balanceId, "0000000016cbeff27945d389e9123231ec916f7bb848c0579ceca12e2bfab5c34ce0da24")
            XCTAssertEqual(effectResponse.amount, "1.0000000")
        }

        func validateClaimableBalanceClawedBackEffectResponse(effectResponse: ClaimableBalanceClawedBackEffectResponse) {
            XCTAssertEqual(effectResponse.id, "0003513936083165185-0000000001")
            XCTAssertEqual(effectResponse.pagingToken, "3513936083165185-1")
            XCTAssertEqual(effectResponse.account, "GD5YHBKE7FSUUZIOSL4ED6UKMM2HZAYBYGZI7KRCTMFDTOO6SGZCQB4Z")
            XCTAssertEqual(effectResponse.effectType, EffectType.claimablaBalanceClawedBack)
            XCTAssertEqual(effectResponse.balanceId, "000000001fe36f3ce6ab6a6423b18b5947ce8890157ae77bb17faeb765814ad040b74ce1")
        }

        // validate sponsorship effects
        func validateAccountSponsorshipCreatedEffectResponse(effectResponse: AccountSponsorshipCreatedEffectResponse) {
            XCTAssertEqual(effectResponse.id, "0150661134846902274-0000000004")
            XCTAssertEqual(effectResponse.effectType, EffectType.accountSponsorshipCreated)
            XCTAssertEqual(effectResponse.sponsor, "GCZGSFPITKVJPJERJIVLCQK5YIHYTDXCY45ZHU3IRCUC53SXSCAL44JV")
        }

        func validateAccountSponsorshipUpdatedEffectResponse(effectResponse: AccountSponsorshipUpdatedEffectResponse) {
            XCTAssertEqual(effectResponse.id, "0151324471070908417-0000000004")
            XCTAssertEqual(effectResponse.effectType, EffectType.accountSponsorshipUpdated)
            XCTAssertEqual(effectResponse.newSponsor, "GCZGSFPITKVJPJERJIVLCQK5YIHYTDXCY45ZHU3IRCUC53SXSCAL44JV")
            XCTAssertEqual(effectResponse.formerSponsor, "GA7PT6IPFVC4FGG273ZHGCNGG2O52F3B6CLVSI4SNIYOXLUNIOSFCK4F")
        }

        func validateAccountSponsorshipRemovedEffectResponse(effectResponse: AccountSponsorshipRemovedEffectResponse) {
            XCTAssertEqual(effectResponse.id, "0151324471070908417-0000000004")
            XCTAssertEqual(effectResponse.effectType, EffectType.accountSponsorshipRemoved)
            XCTAssertEqual(effectResponse.formerSponsor, "GA7PT6IPFVC4FGG273ZHGCNGG2O52F3B6CLVSI4SNIYOXLUNIOSFCK4F")
        }

        func validateTrustlineSponsorshipCreatedEffectResponse(effectResponse: TrustlineSponsorshipCreatedEffectResponse) {
            XCTAssertEqual(effectResponse.id, "0150661134846902276-0000000002")
            XCTAssertEqual(effectResponse.effectType, EffectType.trustlineSponsorshipCreated)
            XCTAssertEqual(effectResponse.sponsor, "GCZGSFPITKVJPJERJIVLCQK5YIHYTDXCY45ZHU3IRCUC53SXSCAL44JV")
            XCTAssertEqual(effectResponse.asset, "USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN")
        }

        func validateTrustlineSponsorshipUpdatedEffectResponse(effectResponse: TrustlineSponsorshipUpdatedEffectResponse) {
            XCTAssertEqual(effectResponse.id, "0150661134846902277-0000000002")
            XCTAssertEqual(effectResponse.effectType, EffectType.trustlineSponsorshipUpdated)
            XCTAssertEqual(effectResponse.newSponsor, "GCZGSFPITKVJPJERJIVLCQK5YIHYTDXCY45ZHU3IRCUC53SXSCAL44JV")
            XCTAssertEqual(effectResponse.formerSponsor, "GA7PT6IPFVC4FGG273ZHGCNGG2O52F3B6CLVSI4SNIYOXLUNIOSFCK4F")
        }

        func validateTrustlineSponsorshipRemovedEffectResponse(effectResponse: TrustlineSponsorshipRemovedEffectResponse) {
            XCTAssertEqual(effectResponse.id, "0150661134846902278-0000000002")
            XCTAssertEqual(effectResponse.effectType, EffectType.trustlineSponsorshipRemoved)
            XCTAssertEqual(effectResponse.formerSponsor, "GA7PT6IPFVC4FGG273ZHGCNGG2O52F3B6CLVSI4SNIYOXLUNIOSFCK4F")
        }

        func validateDataSponsorshipCreatedEffectResponse(effectResponse: DataSponsorshipCreatedEffectResponse) {
            XCTAssertEqual(effectResponse.id, "0003520460138483714-0000000002")
            XCTAssertEqual(effectResponse.effectType, EffectType.dataSponsorshipCreated)
            XCTAssertEqual(effectResponse.sponsor, "GDDQTK5V3E3JFGLZZTJTKURTVY7QJPNQLTR5QS5HIWZWY5XPYIO5YELN")
            XCTAssertEqual(effectResponse.dataName, "test_data")
        }

        func validateDataSponsorshipUpdatedEffectResponse(effectResponse: DataSponsorshipUpdatedEffectResponse) {
            XCTAssertEqual(effectResponse.id, "0003520460138483715-0000000002")
            XCTAssertEqual(effectResponse.effectType, EffectType.dataSponsorshipUpdated)
            XCTAssertEqual(effectResponse.newSponsor, "GDDQTK5V3E3JFGLZZTJTKURTVY7QJPNQLTR5QS5HIWZWY5XPYIO5YELN")
            XCTAssertEqual(effectResponse.formerSponsor, "GA7PT6IPFVC4FGG273ZHGCNGG2O52F3B6CLVSI4SNIYOXLUNIOSFCK4F")
        }

        func validateDataSponsorshipRemovedEffectResponse(effectResponse: DataSponsorshipRemovedEffectResponse) {
            XCTAssertEqual(effectResponse.id, "0003520460138483716-0000000002")
            XCTAssertEqual(effectResponse.effectType, EffectType.dataSponsorshipRemoved)
            XCTAssertEqual(effectResponse.formerSponsor, "GA7PT6IPFVC4FGG273ZHGCNGG2O52F3B6CLVSI4SNIYOXLUNIOSFCK4F")
        }

        func validateClaimableBalanceSponsorshipCreatedEffectResponse(effectResponse: ClaimableBalanceSponsorshipCreatedEffectResponse) {
            XCTAssertEqual(effectResponse.id, "0150661134846902279-0000000002")
            XCTAssertEqual(effectResponse.effectType, EffectType.claimableBalanceSponsorshipCreated)
            XCTAssertEqual(effectResponse.sponsor, "GCZGSFPITKVJPJERJIVLCQK5YIHYTDXCY45ZHU3IRCUC53SXSCAL44JV")
        }

        func validateClaimableBalanceSponsorshipUpdatedEffectResponse(effectResponse: ClaimableBalanceSponsorshipUpdatedEffectResponse) {
            XCTAssertEqual(effectResponse.id, "0150661134846902280-0000000002")
            XCTAssertEqual(effectResponse.effectType, EffectType.claimableBalanceSponsorshipUpdated)
            XCTAssertEqual(effectResponse.newSponsor, "GCZGSFPITKVJPJERJIVLCQK5YIHYTDXCY45ZHU3IRCUC53SXSCAL44JV")
            XCTAssertEqual(effectResponse.formerSponsor, "GA7PT6IPFVC4FGG273ZHGCNGG2O52F3B6CLVSI4SNIYOXLUNIOSFCK4F")
        }

        func validateClaimableBalanceSponsorshipRemovedEffectResponse(effectResponse: ClaimableBalanceSponsorshipRemovedEffectResponse) {
            XCTAssertEqual(effectResponse.id, "0150661134846902281-0000000002")
            XCTAssertEqual(effectResponse.effectType, EffectType.claimableBalanceSponsorshipRemoved)
            XCTAssertEqual(effectResponse.formerSponsor, "GA7PT6IPFVC4FGG273ZHGCNGG2O52F3B6CLVSI4SNIYOXLUNIOSFCK4F")
        }

        func validateSignerSponsorshipCreatedEffectResponse(effectResponse: SignerSponsorshipCreatedEffectResponse) {
            XCTAssertEqual(effectResponse.id, "0150661134846902275-0000000002")
            XCTAssertEqual(effectResponse.effectType, EffectType.signerBalanceSponsorshipCreated)
            XCTAssertEqual(effectResponse.sponsor, "GCZGSFPITKVJPJERJIVLCQK5YIHYTDXCY45ZHU3IRCUC53SXSCAL44JV")
            XCTAssertEqual(effectResponse.signer, "GD6632TYLXUKGVFNQYSC2AC752YZWR7VFNJZ5X7HYPKBLZKK5YVWQ54S")
        }

        func validateSignerSponsorshipUpdatedEffectResponse(effectResponse: SignerSponsorshipUpdatedEffectResponse) {
            XCTAssertEqual(effectResponse.id, "0150661134846902282-0000000002")
            XCTAssertEqual(effectResponse.effectType, EffectType.signerBalanceSponsorshipUpdated)
            XCTAssertEqual(effectResponse.newSponsor, "GCZGSFPITKVJPJERJIVLCQK5YIHYTDXCY45ZHU3IRCUC53SXSCAL44JV")
            XCTAssertEqual(effectResponse.formerSponsor, "GA7PT6IPFVC4FGG273ZHGCNGG2O52F3B6CLVSI4SNIYOXLUNIOSFCK4F")
        }

        func validateSignerSponsorshipRemovedEffectResponse(effectResponse: SignerSponsorshipRemovedEffectResponse) {
            XCTAssertEqual(effectResponse.id, "0150661134846902283-0000000002")
            XCTAssertEqual(effectResponse.effectType, EffectType.signerBalanceSponsorshipRemoved)
            XCTAssertEqual(effectResponse.formerSponsor, "GA7PT6IPFVC4FGG273ZHGCNGG2O52F3B6CLVSI4SNIYOXLUNIOSFCK4F")
        }

        // validate liquidity pool effects
        func validateLiquidityPoolDepositedEffectResponse(effectResponse: LiquidityPoolDepositedEffectResponse) {
            XCTAssertEqual(effectResponse.id, "0001579044726386689-0000000001")
            XCTAssertEqual(effectResponse.effectType, EffectType.liquidityPoolDeposited)
            XCTAssertEqual(effectResponse.liquidityPool.poolId, "2c0bfa623845dd101cbf074a1ca1ae4b2458cc8d0104ad65939ebe2cd9054355")
            XCTAssertEqual(effectResponse.sharesReceived, "250.0000000")
            XCTAssertEqual(effectResponse.reservesDeposited.count, 2)
        }

        func validateLiquidityPoolWithdrewEffectResponse(effectResponse: LiquidityPoolWithdrewEffectResponse) {
            XCTAssertEqual(effectResponse.id, "0001579096265998337-0000000001")
            XCTAssertEqual(effectResponse.effectType, EffectType.liquidityPoolWithdrew)
            XCTAssertEqual(effectResponse.liquidityPool.poolId, "2c0bfa623845dd101cbf074a1ca1ae4b2458cc8d0104ad65939ebe2cd9054355")
            XCTAssertEqual(effectResponse.sharesRedeemed, "100.0000000")
            XCTAssertEqual(effectResponse.reservesReceived.count, 2)
        }

        func validateLiquidityPoolTradeEffectResponse(effectResponse: LiquidityPoolTradeEffectResponse) {
            XCTAssertEqual(effectResponse.id, "0001579418388553729-0000000003")
            XCTAssertEqual(effectResponse.effectType, EffectType.liquidityPoolTrade)
            XCTAssertEqual(effectResponse.liquidityPool.poolId, "2c0bfa623845dd101cbf074a1ca1ae4b2458cc8d0104ad65939ebe2cd9054355")
            XCTAssertEqual(effectResponse.sold.amount, "18.9931895")
            XCTAssertEqual(effectResponse.bought.amount, "20.0000000")
        }

        func validateLiquidityPoolCreatedEffectResponse(effectResponse: LiquidityPoolCreatedEffectResponse) {
            XCTAssertEqual(effectResponse.id, "0001578868632723457-0000000002")
            XCTAssertEqual(effectResponse.effectType, EffectType.liquidityPoolCreated)
            XCTAssertEqual(effectResponse.liquidityPool.poolId, "2c0bfa623845dd101cbf074a1ca1ae4b2458cc8d0104ad65939ebe2cd9054355")
        }

        func validateLiquidityPoolRemovedEffectResponse(effectResponse: LiquidityPoolRemovedEffectResponse) {
            XCTAssertEqual(effectResponse.id, "0179972298072752130-0000000002")
            XCTAssertEqual(effectResponse.effectType, EffectType.liquidityPoolRemoved)
            XCTAssertEqual(effectResponse.liquidityPoolId, "89c11017d16552c152536092d7440a2cd4cf4bf7df2c7e7552b56e6bcac98d95")
        }

        func validateLiquidityPoolRevokedEffectResponse(effectResponse: LiquidityPoolRevokedEffectResponse) {
            XCTAssertEqual(effectResponse.id, "0223514693699710977-0000000007")
            XCTAssertEqual(effectResponse.effectType, EffectType.liquidityPoolRevoked)
            XCTAssertEqual(effectResponse.liquidityPool.poolId, "a6cad36777565bf0d52f89319416fb5e73149d07b9814c5baaddea0d53ef2baa")
            XCTAssertEqual(effectResponse.sharesRevoked, "0.5000000")
            XCTAssertEqual(effectResponse.reservesRevoked.count, 2)
        }

        func validateContractCreditedEffectResponse(effectResponse: ContractCreditedEffectResponse) {
            XCTAssertEqual(effectResponse.id, "0000021517786157057-0000000002")
            XCTAssertEqual(effectResponse.effectType, EffectType.contractCredited)
            XCTAssertEqual(effectResponse.contract, "CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK")
            XCTAssertEqual(effectResponse.amount, "100.0000000")
            XCTAssertEqual(effectResponse.assetType, AssetTypeAsString.NATIVE)
        }

        func validateContractDebitedEffectResponse(effectResponse: ContractDebitedEffectResponse) {
            XCTAssertEqual(effectResponse.id, "0000021517786157058-0000000002")
            XCTAssertEqual(effectResponse.effectType, EffectType.contractDebited)
            XCTAssertEqual(effectResponse.contract, "CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK")
            XCTAssertEqual(effectResponse.amount, "100.0000000")
            XCTAssertEqual(effectResponse.assetType, AssetTypeAsString.NATIVE)
        }
    }
    
    private func successResponse() -> String {
        
        // account created
        var effectsResponseString = """
        {
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/effects?order=desc&limit=53&cursor="
                },
                "next": {
                    "href": "https://horizon-testnet.stellar.org/effects?order=desc&limit=53&cursor=32069348273168385-1"
                },
                "prev": {
                    "href": "https://horizon-testnet.stellar.org/effects?order=asc&limit=53&cursor=32069369748004865-2"
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
        effectsResponseString.append("," + accountInflationDestinationUpdatedEffect)
        effectsResponseString.append("," + dataCreatedEffect)
        effectsResponseString.append("," + dataRemovedEffect)
        effectsResponseString.append("," + dataUpdatedEffect)
        effectsResponseString.append("," + bumpSequenceEffect)
        effectsResponseString.append("," + trustlineAuthorizedToMaintainLiabilitiesEffect)
        effectsResponseString.append("," + trustlineFlagsUpdatedEffect)
        effectsResponseString.append("," + claimableBalanceCreatedEffect)
        effectsResponseString.append("," + claimableBalanceClaimantCreatedEffect)
        effectsResponseString.append("," + claimableBalanceClaimedEffect)
        effectsResponseString.append("," + claimableBalanceClawedBackEffect)
        effectsResponseString.append("," + accountSponsorshipCreatedEffect)
        effectsResponseString.append("," + accountSponsorshipUpdatedEffect)
        effectsResponseString.append("," + accountSponsorshipRemovedEffect)
        effectsResponseString.append("," + trustlineSponsorshipCreatedEffect)
        effectsResponseString.append("," + trustlineSponsorshipUpdatedEffect)
        effectsResponseString.append("," + trustlineSponsorshipRemovedEffect)
        effectsResponseString.append("," + dataSponsorshipCreatedEffect)
        effectsResponseString.append("," + dataSponsorshipUpdatedEffect)
        effectsResponseString.append("," + dataSponsorshipRemovedEffect)
        effectsResponseString.append("," + claimableBalanceSponsorshipCreatedEffect)
        effectsResponseString.append("," + claimableBalanceSponsorshipUpdatedEffect)
        effectsResponseString.append("," + claimableBalanceSponsorshipRemovedEffect)
        effectsResponseString.append("," + signerSponsorshipCreatedEffect)
        effectsResponseString.append("," + signerSponsorshipUpdatedEffect)
        effectsResponseString.append("," + signerSponsorshipRemovedEffect)
        effectsResponseString.append("," + liquidityPoolDepositedEffect)
        effectsResponseString.append("," + liquidityPoolWithdrewEffect)
        effectsResponseString.append("," + liquidityPoolTradeEffect)
        effectsResponseString.append("," + liquidityPoolCreatedEffect)
        effectsResponseString.append("," + liquidityPoolRemovedEffect)
        effectsResponseString.append("," + liquidityPoolRevokedEffect)
        effectsResponseString.append("," + contractCreditedEffect)
        effectsResponseString.append("," + contractDebitedEffect)


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
                "created_at": "2017-03-20T19:50:52Z",
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
                "created_at": "2017-03-20T19:50:52Z",
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
                "created_at": "2017-03-20T19:50:52Z",
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
                "created_at": "2017-03-20T19:50:52Z",
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
                "created_at": "2017-03-20T19:50:52Z",
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
                "created_at": "2017-03-20T19:50:52Z",
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
                "created_at": "2017-03-20T19:50:52Z",
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
                "created_at": "2017-03-20T19:50:52Z",
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
                "created_at": "2017-03-20T19:50:52Z",
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
                "created_at": "2017-03-20T19:50:52Z",
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
                "created_at": "2017-03-20T19:50:52Z",
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
                "created_at": "2017-03-20T19:50:52Z",
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
                "created_at": "2017-03-20T19:50:52Z",
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
                "created_at": "2017-03-20T19:50:52Z",
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
                "created_at": "2017-03-20T19:50:52Z",
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
                "created_at": "2017-03-20T19:50:52Z",
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
                "created_at": "2017-03-20T19:50:52Z",
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
                "created_at": "2017-03-20T19:50:52Z",
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
                "created_at": "2017-03-20T19:50:52Z",
                "type_i": 33,
                "seller": "GCVHDLN6EHZBYW2M3BQIY32C23E4GPIRZZDBNF2Q73DAZ5VJDRGSMYRB",
                "offer_id": "1",
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
    private let bumpSequenceEffect = """
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
                "type": "bump_sequence",
                "created_at": "2017-03-20T19:50:52Z",
                "type_i": 43,
                "new_seq": "79473726952833048"
            }
    """
    private let dataCreatedEffect = """
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
                "type": "manage_data",
                "created_at": "2017-03-20T19:50:52Z",
                "type_i": 40,
                "name": "test_data",
                "value": "dGVzdF92YWx1ZQ=="
            }
    """
    private let dataRemovedEffect = """
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
                "type": "manage_data",
                "created_at": "2017-03-20T19:50:52Z",
                "type_i": 41,
                "name": "test_data"
            }
    """
    private let dataUpdatedEffect = """
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
                "type": "manage_data",
                "created_at": "2017-03-20T19:50:52Z",
                "type_i": 42,
                "name": "test_data",
                "value": "dGVzdF92YWx1ZQ=="
            }
    """

    private let trustlineAuthorizedToMaintainLiabilitiesEffect = """
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
                "type": "trustline_authorized_to_maintain_liabilities",
                "created_at": "2017-03-20T19:50:52Z",
                "type_i": 25,
                "asset_type": "credit_alphanum4",
                "asset_code": "EUR",
                "asset_issuer": "GAZN3PPIDQCSP5JD4ETQQQ2IU2RMFYQTAL4NNQZUGLLO2XJJJ3RDSDGA",
                "limit": "100.0"
            }
    """

    private let trustlineFlagsUpdatedEffect = """
            {
                "_links": {
                   "operation": {
                        "href": "http://horizon-testnet.stellar.org/operations/33788507721731"
                    },
                   "succeeds": {
                        "href": "http://horizon-testnet.stellar.org/effects?order=desc&cursor=33788507721731-2"
                    },
                    "precedes": {
                        "href": "http://horizon-testnet.stellar.org/effects?order=asc&cursor=33788507721731-2"
                    }
                },
                "id": "0000033788507721731-0000000002",
                "paging_token": "33788507721731-2",
                "account": "GA6U5X6WOPNKKDKQULBR7IDHDBAQKOWPHYEC7WSXHZBFEYFD3XVZAKOO",
                "type": "trustline_flags_updated",
                "created_at": "2017-03-20T19:50:52Z",
                "type_i": 26,
                "trustor": "GA6U5X6WOPNKKDKQULBR7IDHDBAQKOWPHYEC7WSXHZBFEYFD3XVZAKOO",
                "asset_type": "credit_alphanum4",
                "asset_code": "EUR",
                "asset_issuer": "GAZN3PPIDQCSP5JD4ETQQQ2IU2RMFYQTAL4NNQZUGLLO2XJJJ3RDSDGA",
                "authorized_flag": true,
                "authorized_to_maintain_liabilites_flag": false,
                "clawback_enabled_flag": false
            }
    """

    private let accountInflationDestinationUpdatedEffect = """
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
                "type": "account_inflation_destination_updated",
                "created_at": "2017-03-20T19:50:52Z",
                "type_i": 7
            }
    """

    // Claimable Balance Effects
    private let claimableBalanceCreatedEffect = """
            {
                "_links": {
                    "operation": {
                        "href": "https://horizon.stellar.org/operations/150684654087864322"
                    },
                    "succeeds": {
                        "href": "https://horizon.stellar.org/effects?order=desc&cursor=150684654087864322-1"
                    },
                    "precedes": {
                        "href": "https://horizon.stellar.org/effects?order=asc&cursor=150684654087864322-1"
                    }
                },
                "id": "0150684654087864322-0000000001",
                "paging_token": "150684654087864322-1",
                "account": "GBHNGLLIE3KWGKCHIKMHJ5HVZHYIK7WTBE4QF5PLAKL4CJGSEU7HZIW5",
                "type": "claimable_balance_created",
                "type_i": 50,
                "created_at": "2021-04-24T14:16:59Z",
                "asset": "native",
                "balance_id": "0000000048a70acdec712be9547d19f7e58adc22e35e0f5bcf3897a0353ab5dd4c5d61f4",
                "amount": "900.0000000"
            }
    """

    private let claimableBalanceClaimantCreatedEffect = """
            {
                "_links": {
                    "operation": {
                        "href": "https://horizon.stellar.org/operations/150684654087864322"
                    },
                    "succeeds": {
                        "href": "https://horizon.stellar.org/effects?order=desc&cursor=150684654087864322-3"
                    },
                    "precedes": {
                        "href": "https://horizon.stellar.org/effects?order=asc&cursor=150684654087864322-3"
                    }
                },
                "id": "0150684654087864322-0000000003",
                "paging_token": "150684654087864322-3",
                "account": "GCBMP2WKIAX7KVDRCSFXJWFM5P7HDCGTCC76U5XR52OYII6AOWS7G3DT",
                "type": "claimable_balance_claimant_created",
                "type_i": 51,
                "created_at": "2021-04-24T14:16:59Z",
                "asset": "native",
                "balance_id": "0000000048a70acdec712be9547d19f7e58adc22e35e0f5bcf3897a0353ab5dd4c5d61f4",
                "amount": "900.0000000",
                "predicate": {
                    "unconditional": true
                }
            }
    """

    private let claimableBalanceClaimedEffect = """
            {
                "_links": {
                    "operation": {
                        "href": "https://horizon.stellar.org/operations/150803053451329538"
                    },
                    "succeeds": {
                        "href": "https://horizon.stellar.org/effects?order=desc&cursor=150803053451329538-1"
                    },
                    "precedes": {
                        "href": "https://horizon.stellar.org/effects?order=asc&cursor=150803053451329538-1"
                    }
                },
                "id": "0150803053451329538-0000000001",
                "paging_token": "150803053451329538-1",
                "account": "GANVXZ2DQ2FFLVCBSVMBBNVWSXS6YVEDP247EN4C3CM3I32XR4U3OU2I",
                "type": "claimable_balance_claimed",
                "type_i": 52,
                "created_at": "2021-04-26T07:35:19Z",
                "asset": "native",
                "balance_id": "0000000016cbeff27945d389e9123231ec916f7bb848c0579ceca12e2bfab5c34ce0da24",
                "amount": "1.0000000"
            }
    """

    private let claimableBalanceClawedBackEffect = """
            {
                "_links": {
                    "operation": {
                        "href": "https://horizon-testnet.stellar.org/operations/3513936083165185"
                    },
                    "succeeds": {
                        "href": "https://horizon-testnet.stellar.org/effects?order=desc&cursor=3513936083165185-1"
                    },
                    "precedes": {
                        "href": "https://horizon-testnet.stellar.org/effects?order=asc&cursor=3513936083165185-1"
                    }
                },
                "id": "0003513936083165185-0000000001",
                "paging_token": "3513936083165185-1",
                "account": "GD5YHBKE7FSUUZIOSL4ED6UKMM2HZAYBYGZI7KRCTMFDTOO6SGZCQB4Z",
                "type": "claimable_balance_clawed_back",
                "type_i": 80,
                "created_at": "2021-05-06T03:48:05Z",
                "balance_id": "000000001fe36f3ce6ab6a6423b18b5947ce8890157ae77bb17faeb765814ad040b74ce1"
            }
    """

    // Sponsorship Effects
    private let accountSponsorshipCreatedEffect = """
            {
                "_links": {
                    "operation": {
                        "href": "https://horizon.stellar.org/operations/150661134846902274"
                    },
                    "succeeds": {
                        "href": "https://horizon.stellar.org/effects?order=desc&cursor=150661134846902274-4"
                    },
                    "precedes": {
                        "href": "https://horizon.stellar.org/effects?order=asc&cursor=150661134846902274-4"
                    }
                },
                "id": "0150661134846902274-0000000004",
                "paging_token": "150661134846902274-4",
                "account": "GDUQFAHWHQ6AUP6Q5MDAHILRG222CRF35HPUVRI66L7HXKHFJAQGHICR",
                "type": "account_sponsorship_created",
                "type_i": 60,
                "created_at": "2021-04-24T06:02:51Z",
                "sponsor": "GCZGSFPITKVJPJERJIVLCQK5YIHYTDXCY45ZHU3IRCUC53SXSCAL44JV"
            }
    """

    private let accountSponsorshipUpdatedEffect = """
            {
                "_links": {
                    "operation": {
                        "href": "https://horizon-testnet.stellar.org/operations/151324471070908417"
                    },
                    "succeeds": {
                        "href": "https://horizon-testnet.stellar.org/effects?order=desc&cursor=151324471070908417-4"
                    },
                    "precedes": {
                        "href": "https://horizon-testnet.stellar.org/effects?order=asc&cursor=151324471070908417-4"
                    }
                },
                "id": "0151324471070908417-0000000004",
                "paging_token": "151324471070908417-4",
                "account": "GAHM22VLSTZHTY7RP64UYKG4VR7DDFGDGKJ4GVRRS77D7M6EMXG5XTNS",
                "type": "account_sponsorship_updated",
                "type_i": 61,
                "created_at": "2021-05-03T20:29:17Z",
                "former_sponsor": "GA7PT6IPFVC4FGG273ZHGCNGG2O52F3B6CLVSI4SNIYOXLUNIOSFCK4F",
                "new_sponsor": "GCZGSFPITKVJPJERJIVLCQK5YIHYTDXCY45ZHU3IRCUC53SXSCAL44JV"
            }
    """

    private let accountSponsorshipRemovedEffect = """
            {
                "_links": {
                    "operation": {
                        "href": "https://horizon.stellar.org/operations/151324471070908417"
                    },
                    "succeeds": {
                        "href": "https://horizon.stellar.org/effects?order=desc&cursor=151324471070908417-4"
                    },
                    "precedes": {
                        "href": "https://horizon.stellar.org/effects?order=asc&cursor=151324471070908417-4"
                    }
                },
                "id": "0151324471070908417-0000000004",
                "paging_token": "151324471070908417-4",
                "account": "GAHM22VLSTZHTY7RP64UYKG4VR7DDFGDGKJ4GVRRS77D7M6EMXG5XTNS",
                "type": "account_sponsorship_removed",
                "type_i": 62,
                "created_at": "2021-05-03T20:29:17Z",
                "former_sponsor": "GA7PT6IPFVC4FGG273ZHGCNGG2O52F3B6CLVSI4SNIYOXLUNIOSFCK4F"
            }
    """

    private let trustlineSponsorshipCreatedEffect = """
            {
                "_links": {
                    "operation": {
                        "href": "https://horizon.stellar.org/operations/150661134846902276"
                    },
                    "succeeds": {
                        "href": "https://horizon.stellar.org/effects?order=desc&cursor=150661134846902276-2"
                    },
                    "precedes": {
                        "href": "https://horizon.stellar.org/effects?order=asc&cursor=150661134846902276-2"
                    }
                },
                "id": "0150661134846902276-0000000002",
                "paging_token": "150661134846902276-2",
                "account": "GDUQFAHWHQ6AUP6Q5MDAHILRG222CRF35HPUVRI66L7HXKHFJAQGHICR",
                "type": "trustline_sponsorship_created",
                "type_i": 63,
                "created_at": "2021-04-24T06:02:51Z",
                "asset_type": "credit_alphanum4",
                "asset": "USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN",
                "sponsor": "GCZGSFPITKVJPJERJIVLCQK5YIHYTDXCY45ZHU3IRCUC53SXSCAL44JV"
            }
    """

    private let trustlineSponsorshipUpdatedEffect = """
            {
                "_links": {
                    "operation": {
                        "href": "https://horizon.stellar.org/operations/150661134846902277"
                    },
                    "succeeds": {
                        "href": "https://horizon.stellar.org/effects?order=desc&cursor=150661134846902277-2"
                    },
                    "precedes": {
                        "href": "https://horizon.stellar.org/effects?order=asc&cursor=150661134846902277-2"
                    }
                },
                "id": "0150661134846902277-0000000002",
                "paging_token": "150661134846902277-2",
                "account": "GDUQFAHWHQ6AUP6Q5MDAHILRG222CRF35HPUVRI66L7HXKHFJAQGHICR",
                "type": "trustline_sponsorship_updated",
                "type_i": 64,
                "created_at": "2021-04-24T06:02:51Z",
                "asset_type": "credit_alphanum4",
                "asset": "USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN",
                "former_sponsor": "GA7PT6IPFVC4FGG273ZHGCNGG2O52F3B6CLVSI4SNIYOXLUNIOSFCK4F",
                "new_sponsor": "GCZGSFPITKVJPJERJIVLCQK5YIHYTDXCY45ZHU3IRCUC53SXSCAL44JV"
            }
    """

    private let trustlineSponsorshipRemovedEffect = """
            {
                "_links": {
                    "operation": {
                        "href": "https://horizon.stellar.org/operations/150661134846902278"
                    },
                    "succeeds": {
                        "href": "https://horizon.stellar.org/effects?order=desc&cursor=150661134846902278-2"
                    },
                    "precedes": {
                        "href": "https://horizon.stellar.org/effects?order=asc&cursor=150661134846902278-2"
                    }
                },
                "id": "0150661134846902278-0000000002",
                "paging_token": "150661134846902278-2",
                "account": "GDUQFAHWHQ6AUP6Q5MDAHILRG222CRF35HPUVRI66L7HXKHFJAQGHICR",
                "type": "trustline_sponsorship_removed",
                "type_i": 65,
                "created_at": "2021-04-24T06:02:51Z",
                "asset_type": "credit_alphanum4",
                "asset": "USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN",
                "former_sponsor": "GA7PT6IPFVC4FGG273ZHGCNGG2O52F3B6CLVSI4SNIYOXLUNIOSFCK4F"
            }
    """

    private let dataSponsorshipCreatedEffect = """
            {
                "_links": {
                    "operation": {
                        "href": "https://horizon-testnet.stellar.org/operations/3520460138483714"
                    },
                    "succeeds": {
                        "href": "https://horizon-testnet.stellar.org/effects?order=desc&cursor=3520460138483714-2"
                    },
                    "precedes": {
                        "href": "https://horizon-testnet.stellar.org/effects?order=asc&cursor=3520460138483714-2"
                    }
                },
                "id": "0003520460138483714-0000000002",
                "paging_token": "3520460138483714-2",
                "account": "GAJADTBH23KY25XZPBZDS5NKV5ZXTIMDGORKSQCHE4DVVLEHSXSV2EQK",
                "type": "data_sponsorship_created",
                "type_i": 66,
                "created_at": "2021-05-06T06:01:13Z",
                "data_name": "test_data",
                "sponsor": "GDDQTK5V3E3JFGLZZTJTKURTVY7QJPNQLTR5QS5HIWZWY5XPYIO5YELN"
            }
    """

    private let dataSponsorshipUpdatedEffect = """
            {
                "_links": {
                    "operation": {
                        "href": "https://horizon-testnet.stellar.org/operations/3520460138483715"
                    },
                    "succeeds": {
                        "href": "https://horizon-testnet.stellar.org/effects?order=desc&cursor=3520460138483715-2"
                    },
                    "precedes": {
                        "href": "https://horizon-testnet.stellar.org/effects?order=asc&cursor=3520460138483715-2"
                    }
                },
                "id": "0003520460138483715-0000000002",
                "paging_token": "3520460138483715-2",
                "account": "GAJADTBH23KY25XZPBZDS5NKV5ZXTIMDGORKSQCHE4DVVLEHSXSV2EQK",
                "type": "data_sponsorship_updated",
                "type_i": 67,
                "created_at": "2021-05-06T06:01:13Z",
                "data_name": "test_data",
                "former_sponsor": "GA7PT6IPFVC4FGG273ZHGCNGG2O52F3B6CLVSI4SNIYOXLUNIOSFCK4F",
                "new_sponsor": "GDDQTK5V3E3JFGLZZTJTKURTVY7QJPNQLTR5QS5HIWZWY5XPYIO5YELN"
            }
    """

    private let dataSponsorshipRemovedEffect = """
            {
                "_links": {
                    "operation": {
                        "href": "https://horizon-testnet.stellar.org/operations/3520460138483716"
                    },
                    "succeeds": {
                        "href": "https://horizon-testnet.stellar.org/effects?order=desc&cursor=3520460138483716-2"
                    },
                    "precedes": {
                        "href": "https://horizon-testnet.stellar.org/effects?order=asc&cursor=3520460138483716-2"
                    }
                },
                "id": "0003520460138483716-0000000002",
                "paging_token": "3520460138483716-2",
                "account": "GAJADTBH23KY25XZPBZDS5NKV5ZXTIMDGORKSQCHE4DVVLEHSXSV2EQK",
                "type": "data_sponsorship_removed",
                "type_i": 68,
                "created_at": "2021-05-06T06:01:13Z",
                "data_name": "test_data",
                "former_sponsor": "GA7PT6IPFVC4FGG273ZHGCNGG2O52F3B6CLVSI4SNIYOXLUNIOSFCK4F"
            }
    """

    private let claimableBalanceSponsorshipCreatedEffect = """
            {
                "_links": {
                    "operation": {
                        "href": "https://horizon.stellar.org/operations/150661134846902279"
                    },
                    "succeeds": {
                        "href": "https://horizon.stellar.org/effects?order=desc&cursor=150661134846902279-2"
                    },
                    "precedes": {
                        "href": "https://horizon.stellar.org/effects?order=asc&cursor=150661134846902279-2"
                    }
                },
                "id": "0150661134846902279-0000000002",
                "paging_token": "150661134846902279-2",
                "account": "GDUQFAHWHQ6AUP6Q5MDAHILRG222CRF35HPUVRI66L7HXKHFJAQGHICR",
                "type": "claimable_balance_sponsorship_created",
                "type_i": 69,
                "created_at": "2021-04-24T06:02:51Z",
                "balance_id": "0000000048a70acdec712be9547d19f7e58adc22e35e0f5bcf3897a0353ab5dd4c5d61f4",
                "sponsor": "GCZGSFPITKVJPJERJIVLCQK5YIHYTDXCY45ZHU3IRCUC53SXSCAL44JV"
            }
    """

    private let claimableBalanceSponsorshipUpdatedEffect = """
            {
                "_links": {
                    "operation": {
                        "href": "https://horizon.stellar.org/operations/150661134846902280"
                    },
                    "succeeds": {
                        "href": "https://horizon.stellar.org/effects?order=desc&cursor=150661134846902280-2"
                    },
                    "precedes": {
                        "href": "https://horizon.stellar.org/effects?order=asc&cursor=150661134846902280-2"
                    }
                },
                "id": "0150661134846902280-0000000002",
                "paging_token": "150661134846902280-2",
                "account": "GDUQFAHWHQ6AUP6Q5MDAHILRG222CRF35HPUVRI66L7HXKHFJAQGHICR",
                "type": "claimable_balance_sponsorship_updated",
                "type_i": 70,
                "created_at": "2021-04-24T06:02:51Z",
                "balance_id": "0000000048a70acdec712be9547d19f7e58adc22e35e0f5bcf3897a0353ab5dd4c5d61f4",
                "former_sponsor": "GA7PT6IPFVC4FGG273ZHGCNGG2O52F3B6CLVSI4SNIYOXLUNIOSFCK4F",
                "new_sponsor": "GCZGSFPITKVJPJERJIVLCQK5YIHYTDXCY45ZHU3IRCUC53SXSCAL44JV"
            }
    """

    private let claimableBalanceSponsorshipRemovedEffect = """
            {
                "_links": {
                    "operation": {
                        "href": "https://horizon.stellar.org/operations/150661134846902281"
                    },
                    "succeeds": {
                        "href": "https://horizon.stellar.org/effects?order=desc&cursor=150661134846902281-2"
                    },
                    "precedes": {
                        "href": "https://horizon.stellar.org/effects?order=asc&cursor=150661134846902281-2"
                    }
                },
                "id": "0150661134846902281-0000000002",
                "paging_token": "150661134846902281-2",
                "account": "GDUQFAHWHQ6AUP6Q5MDAHILRG222CRF35HPUVRI66L7HXKHFJAQGHICR",
                "type": "claimable_balance_sponsorship_removed",
                "type_i": 71,
                "created_at": "2021-04-24T06:02:51Z",
                "balance_id": "0000000048a70acdec712be9547d19f7e58adc22e35e0f5bcf3897a0353ab5dd4c5d61f4",
                "former_sponsor": "GA7PT6IPFVC4FGG273ZHGCNGG2O52F3B6CLVSI4SNIYOXLUNIOSFCK4F"
            }
    """

    private let signerSponsorshipCreatedEffect = """
            {
                "_links": {
                    "operation": {
                        "href": "https://horizon.stellar.org/operations/150661134846902275"
                    },
                    "succeeds": {
                        "href": "https://horizon.stellar.org/effects?order=desc&cursor=150661134846902275-2"
                    },
                    "precedes": {
                        "href": "https://horizon.stellar.org/effects?order=asc&cursor=150661134846902275-2"
                    }
                },
                "id": "0150661134846902275-0000000002",
                "paging_token": "150661134846902275-2",
                "account": "GDUQFAHWHQ6AUP6Q5MDAHILRG222CRF35HPUVRI66L7HXKHFJAQGHICR",
                "type": "signer_sponsorship_created",
                "type_i": 72,
                "created_at": "2021-04-24T06:02:51Z",
                "signer": "GD6632TYLXUKGVFNQYSC2AC752YZWR7VFNJZ5X7HYPKBLZKK5YVWQ54S",
                "sponsor": "GCZGSFPITKVJPJERJIVLCQK5YIHYTDXCY45ZHU3IRCUC53SXSCAL44JV"
            }
    """

    private let signerSponsorshipUpdatedEffect = """
            {
                "_links": {
                    "operation": {
                        "href": "https://horizon.stellar.org/operations/150661134846902282"
                    },
                    "succeeds": {
                        "href": "https://horizon.stellar.org/effects?order=desc&cursor=150661134846902282-2"
                    },
                    "precedes": {
                        "href": "https://horizon.stellar.org/effects?order=asc&cursor=150661134846902282-2"
                    }
                },
                "id": "0150661134846902282-0000000002",
                "paging_token": "150661134846902282-2",
                "account": "GDUQFAHWHQ6AUP6Q5MDAHILRG222CRF35HPUVRI66L7HXKHFJAQGHICR",
                "type": "signer_sponsorship_updated",
                "type_i": 73,
                "created_at": "2021-04-24T06:02:51Z",
                "signer": "GD6632TYLXUKGVFNQYSC2AC752YZWR7VFNJZ5X7HYPKBLZKK5YVWQ54S",
                "former_sponsor": "GA7PT6IPFVC4FGG273ZHGCNGG2O52F3B6CLVSI4SNIYOXLUNIOSFCK4F",
                "new_sponsor": "GCZGSFPITKVJPJERJIVLCQK5YIHYTDXCY45ZHU3IRCUC53SXSCAL44JV"
            }
    """

    private let signerSponsorshipRemovedEffect = """
            {
                "_links": {
                    "operation": {
                        "href": "https://horizon.stellar.org/operations/150661134846902283"
                    },
                    "succeeds": {
                        "href": "https://horizon.stellar.org/effects?order=desc&cursor=150661134846902283-2"
                    },
                    "precedes": {
                        "href": "https://horizon.stellar.org/effects?order=asc&cursor=150661134846902283-2"
                    }
                },
                "id": "0150661134846902283-0000000002",
                "paging_token": "150661134846902283-2",
                "account": "GDUQFAHWHQ6AUP6Q5MDAHILRG222CRF35HPUVRI66L7HXKHFJAQGHICR",
                "type": "signer_sponsorship_removed",
                "type_i": 74,
                "created_at": "2021-04-24T06:02:51Z",
                "signer": "GD6632TYLXUKGVFNQYSC2AC752YZWR7VFNJZ5X7HYPKBLZKK5YVWQ54S",
                "former_sponsor": "GA7PT6IPFVC4FGG273ZHGCNGG2O52F3B6CLVSI4SNIYOXLUNIOSFCK4F"
            }
    """

    // Liquidity Pool Effects
    private let liquidityPoolDepositedEffect = """
            {
                "_links": {
                    "operation": {
                        "href": "https://horizon-testnet.stellar.org/operations/1579044726386689"
                    },
                    "succeeds": {
                        "href": "https://horizon-testnet.stellar.org/effects?order=desc&cursor=1579044726386689-1"
                    },
                    "precedes": {
                        "href": "https://horizon-testnet.stellar.org/effects?order=asc&cursor=1579044726386689-1"
                    }
                },
                "id": "0001579044726386689-0000000001",
                "paging_token": "1579044726386689-1",
                "account": "GAQXAWHCM4A7SQCT3BOSVEGRI2OOB7LO2CMFOYFF6YRXU4VQSB5V2V2K",
                "type": "liquidity_pool_deposited",
                "type_i": 90,
                "created_at": "2021-10-07T18:06:32Z",
                "liquidity_pool": {
                    "id": "2c0bfa623845dd101cbf074a1ca1ae4b2458cc8d0104ad65939ebe2cd9054355",
                    "fee_bp": 30,
                    "type": "constant_product",
                    "total_trustlines": "1",
                    "total_shares": "200.0000000",
                    "reserves": [
                        {
                            "asset": "COOL:GAZKB7OEYRUVL6TSBXI74D2IZS4JRCPBXJZ37MDDYAEYBOMHXUYIX5YL",
                            "amount": "250.0000000"
                        },
                        {
                            "asset": "native",
                            "amount": "250.0000000"
                        }
                    ]
                },
                "reserves_deposited": [
                    {
                        "asset": "COOL:GAZKB7OEYRUVL6TSBXI74D2IZS4JRCPBXJZ37MDDYAEYBOMHXUYIX5YL",
                        "amount": "250.0000000"
                    },
                    {
                        "asset": "native",
                        "amount": "250.0000000"
                    }
                ],
                "shares_received": "250.0000000"
            }
    """

    private let liquidityPoolWithdrewEffect = """
            {
                "_links": {
                    "operation": {
                        "href": "https://horizon-testnet.stellar.org/operations/1579096265998337"
                    },
                    "succeeds": {
                        "href": "https://horizon-testnet.stellar.org/effects?order=desc&cursor=1579096265998337-1"
                    },
                    "precedes": {
                        "href": "https://horizon-testnet.stellar.org/effects?order=asc&cursor=1579096265998337-1"
                    }
                },
                "id": "0001579096265998337-0000000001",
                "paging_token": "1579096265998337-1",
                "account": "GAQXAWHCM4A7SQCT3BOSVEGRI2OOB7LO2CMFOYFF6YRXU4VQSB5V2V2K",
                "type": "liquidity_pool_withdrew",
                "type_i": 91,
                "created_at": "2021-10-07T18:07:37Z",
                "liquidity_pool": {
                    "id": "2c0bfa623845dd101cbf074a1ca1ae4b2458cc8d0104ad65939ebe2cd9054355",
                    "fee_bp": 30,
                    "type": "constant_product",
                    "total_trustlines": "1",
                    "total_shares": "400.0000000",
                    "reserves": [
                        {
                            "asset": "COOL:GAZKB7OEYRUVL6TSBXI74D2IZS4JRCPBXJZ37MDDYAEYBOMHXUYIX5YL",
                            "amount": "400.0000000"
                        },
                        {
                            "asset": "native",
                            "amount": "400.0000000"
                        }
                    ]
                },
                "reserves_received": [
                    {
                        "asset": "COOL:GAZKB7OEYRUVL6TSBXI74D2IZS4JRCPBXJZ37MDDYAEYBOMHXUYIX5YL",
                        "amount": "100.0000000"
                    },
                    {
                        "asset": "native",
                        "amount": "100.0000000"
                    }
                ],
                "shares_redeemed": "100.0000000"
            }
    """

    private let liquidityPoolTradeEffect = """
            {
                "_links": {
                    "operation": {
                        "href": "https://horizon-testnet.stellar.org/operations/1579418388553729"
                    },
                    "succeeds": {
                        "href": "https://horizon-testnet.stellar.org/effects?order=desc&cursor=1579418388553729-3"
                    },
                    "precedes": {
                        "href": "https://horizon-testnet.stellar.org/effects?order=asc&cursor=1579418388553729-3"
                    }
                },
                "id": "0001579418388553729-0000000003",
                "paging_token": "1579418388553729-3",
                "account": "GARIJI33DZEOA2HT7H5Q3E7W6KY2KBOYA6ZSUHKNNWNQR75JSQMU3SRJ",
                "type": "liquidity_pool_trade",
                "type_i": 92,
                "created_at": "2021-10-07T18:14:06Z",
                "liquidity_pool": {
                    "id": "2c0bfa623845dd101cbf074a1ca1ae4b2458cc8d0104ad65939ebe2cd9054355",
                    "fee_bp": 30,
                    "type": "constant_product",
                    "total_trustlines": "1",
                    "total_shares": "400.0000000",
                    "reserves": [
                        {
                            "asset": "COOL:GAZKB7OEYRUVL6TSBXI74D2IZS4JRCPBXJZ37MDDYAEYBOMHXUYIX5YL",
                            "amount": "381.0068105"
                        },
                        {
                            "asset": "native",
                            "amount": "420.0000000"
                        }
                    ]
                },
                "sold": {
                    "asset": "COOL:GAZKB7OEYRUVL6TSBXI74D2IZS4JRCPBXJZ37MDDYAEYBOMHXUYIX5YL",
                    "amount": "18.9931895"
                },
                "bought": {
                    "asset": "native",
                    "amount": "20.0000000"
                }
            }
    """

    private let liquidityPoolCreatedEffect = """
            {
                "_links": {
                    "operation": {
                        "href": "https://horizon-testnet.stellar.org/operations/1578868632723457"
                    },
                    "succeeds": {
                        "href": "https://horizon-testnet.stellar.org/effects?order=desc&cursor=1578868632723457-2"
                    },
                    "precedes": {
                        "href": "https://horizon-testnet.stellar.org/effects?order=asc&cursor=1578868632723457-2"
                    }
                },
                "id": "0001578868632723457-0000000002",
                "paging_token": "1578868632723457-2",
                "account": "GAQXAWHCM4A7SQCT3BOSVEGRI2OOB7LO2CMFOYFF6YRXU4VQSB5V2V2K",
                "type": "liquidity_pool_created",
                "type_i": 93,
                "created_at": "2021-10-07T18:02:57Z",
                "liquidity_pool": {
                    "id": "2c0bfa623845dd101cbf074a1ca1ae4b2458cc8d0104ad65939ebe2cd9054355",
                    "fee_bp": 30,
                    "type": "constant_product",
                    "total_trustlines": "1",
                    "total_shares": "0.0000000",
                    "reserves": [
                        {
                            "asset": "COOL:GAZKB7OEYRUVL6TSBXI74D2IZS4JRCPBXJZ37MDDYAEYBOMHXUYIX5YL",
                            "amount": "0.0000000"
                        },
                        {
                            "asset": "native",
                            "amount": "0.0000000"
                        }
                    ]
                }
            }
    """

    private let liquidityPoolRemovedEffect = """
            {
                "_links": {
                    "operation": {
                        "href": "https://horizon.stellar.org/operations/179972298072752130"
                    },
                    "succeeds": {
                        "href": "https://horizon.stellar.org/effects?order=desc&cursor=179972298072752130-2"
                    },
                    "precedes": {
                        "href": "https://horizon.stellar.org/effects?order=asc&cursor=179972298072752130-2"
                    }
                },
                "id": "0179972298072752130-0000000002",
                "paging_token": "179972298072752130-2",
                "account": "GBKM2YMDONW2XPZH5PJXVDFKC4U4AXRV4TZXP53YSAJPA6ZWGCJ7YGVZ",
                "type": "liquidity_pool_removed",
                "type_i": 94,
                "created_at": "2022-07-24T12:40:09Z",
                "liquidity_pool_id": "89c11017d16552c152536092d7440a2cd4cf4bf7df2c7e7552b56e6bcac98d95"
            }
    """

    private let liquidityPoolRevokedEffect = """
            {
                "_links": {
                    "operation": {
                        "href": "https://horizon.stellar.org/operations/223514693699710977"
                    },
                    "succeeds": {
                        "href": "https://horizon.stellar.org/effects?order=desc&cursor=223514693699710977-7"
                    },
                    "precedes": {
                        "href": "https://horizon.stellar.org/effects?order=asc&cursor=223514693699710977-7"
                    }
                },
                "id": "0223514693699710977-0000000007",
                "paging_token": "223514693699710977-7",
                "account": "GAMQXNIL2IV7YV3GIBQG56RCJAGTCW3WU64XDOM2M5N7A3OJWQZT5BNB",
                "type": "liquidity_pool_revoked",
                "type_i": 95,
                "created_at": "2024-06-09T06:26:06Z",
                "liquidity_pool": {
                    "id": "a6cad36777565bf0d52f89319416fb5e73149d07b9814c5baaddea0d53ef2baa",
                    "fee_bp": 30,
                    "type": "constant_product",
                    "total_trustlines": "1",
                    "total_shares": "1.0000000",
                    "reserves": [
                        {
                            "asset": "native",
                            "amount": "0.0000011"
                        },
                        {
                            "asset": "BTC:GAMQXNIL2IV7YV3GIBQG56RCJAGTCW3WU64XDOM2M5N7A3OJWQZT5BNB",
                            "amount": "1000502.0030091"
                        }
                    ]
                },
                "reserves_revoked": [
                    {
                        "asset": "native",
                        "amount": "0.0000011",
                        "claimable_balance_id": "00000000b69563dc3491932aa21baf799f7f1831831c7fc4b21ea8eac97578b48ddc884c"
                    },
                    {
                        "asset": "BTC:GAMQXNIL2IV7YV3GIBQG56RCJAGTCW3WU64XDOM2M5N7A3OJWQZT5BNB",
                        "amount": "1000502.0030091",
                        "claimable_balance_id": "000000006708d006dc9d6b8601249383b25ac17198596493ff80c8dd8e6218b0c44ef472"
                    }
                ],
                "shares_revoked": "0.5000000"
            }
    """

    // Contract Effects
    private let contractCreditedEffect = """
            {
                "_links": {
                    "operation": {
                        "href": "http://100.83.15.43:8000/operations/21517786157057"
                    },
                    "succeeds": {
                        "href": "http://100.83.15.43:8000/effects?order=desc&cursor=21517786157057-2"
                    },
                    "precedes": {
                        "href": "http://100.83.15.43:8000/effects?order=asc&cursor=21517786157057-2"
                    }
                },
                "id": "0000021517786157057-0000000002",
                "paging_token": "21517786157057-2",
                "account": "GDAT5HWTGIU4TSSZ4752OUC4SABDLTLZFRPZUJ3D6LKBNEPA7V2CIG54",
                "type": "contract_credited",
                "type_i": 96,
                "created_at": "2023-09-19T05:43:12Z",
                "asset_type": "native",
                "contract": "CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK",
                "amount": "100.0000000"
            }
    """

    private let contractDebitedEffect = """
            {
                "_links": {
                    "operation": {
                        "href": "http://100.83.15.43:8000/operations/21517786157058"
                    },
                    "succeeds": {
                        "href": "http://100.83.15.43:8000/effects?order=desc&cursor=21517786157058-2"
                    },
                    "precedes": {
                        "href": "http://100.83.15.43:8000/effects?order=asc&cursor=21517786157058-2"
                    }
                },
                "id": "0000021517786157058-0000000002",
                "paging_token": "21517786157058-2",
                "account": "GDAT5HWTGIU4TSSZ4752OUC4SABDLTLZFRPZUJ3D6LKBNEPA7V2CIG54",
                "type": "contract_debited",
                "type_i": 97,
                "created_at": "2023-09-19T05:43:12Z",
                "asset_type": "native",
                "contract": "CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK",
                "amount": "100.0000000"
            }
    """

}
