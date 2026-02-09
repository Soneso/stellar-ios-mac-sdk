//
//  TransferServerProtocolUnitTests.swift
//  stellarsdkUnitTests
//
//  Created by Soneso on 05/02/2026.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

final class TransferServerProtocolUnitTests: XCTestCase {

    // MARK: - CustomerInformationNeededInteractive Tests

    func testCustomerInformationNeededInteractiveDecoding() throws {
        let json = """
        {
            "type": "interactive_customer_info_needed",
            "url": "https://example.com/kyc?token=abc123"
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(CustomerInformationNeededInteractive.self, from: data)

        XCTAssertEqual(response.type, "interactive_customer_info_needed")
        XCTAssertEqual(response.url, "https://example.com/kyc?token=abc123")
    }

    func testCustomerInformationNeededInteractiveDecodingWithSpecialCharacters() throws {
        let json = """
        {
            "type": "interactive_customer_info_needed",
            "url": "https://example.com/kyc?token=abc123&lang=en&redirect=https://wallet.example.com/callback"
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(CustomerInformationNeededInteractive.self, from: data)

        XCTAssertEqual(response.type, "interactive_customer_info_needed")
        XCTAssertEqual(response.url, "https://example.com/kyc?token=abc123&lang=en&redirect=https://wallet.example.com/callback")
    }

    func testCustomerInformationNeededInteractiveDecodingMissingTypeThrows() throws {
        let json = """
        {
            "url": "https://example.com/kyc"
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        XCTAssertThrowsError(try decoder.decode(CustomerInformationNeededInteractive.self, from: data)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testCustomerInformationNeededInteractiveDecodingMissingURLThrows() throws {
        let json = """
        {
            "type": "interactive_customer_info_needed"
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        XCTAssertThrowsError(try decoder.decode(CustomerInformationNeededInteractive.self, from: data)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testCustomerInformationNeededInteractiveDecodingEmptyStrings() throws {
        let json = """
        {
            "type": "",
            "url": ""
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(CustomerInformationNeededInteractive.self, from: data)

        XCTAssertEqual(response.type, "")
        XCTAssertEqual(response.url, "")
    }

    // MARK: - CustomerInformationNeededNonInteractive Tests

    func testCustomerInformationNeededNonInteractiveDecoding() throws {
        let json = """
        {
            "type": "non_interactive_customer_info_needed",
            "fields": ["email_address", "id_type", "id_number", "photo_id_front"]
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(CustomerInformationNeededNonInteractive.self, from: data)

        XCTAssertEqual(response.type, "non_interactive_customer_info_needed")
        XCTAssertEqual(response.fields.count, 4)
        XCTAssertTrue(response.fields.contains("email_address"))
        XCTAssertTrue(response.fields.contains("id_type"))
        XCTAssertTrue(response.fields.contains("id_number"))
        XCTAssertTrue(response.fields.contains("photo_id_front"))
    }

    func testCustomerInformationNeededNonInteractiveDecodingEmptyFields() throws {
        let json = """
        {
            "type": "non_interactive_customer_info_needed",
            "fields": []
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(CustomerInformationNeededNonInteractive.self, from: data)

        XCTAssertEqual(response.type, "non_interactive_customer_info_needed")
        XCTAssertEqual(response.fields.count, 0)
    }

    func testCustomerInformationNeededNonInteractiveDecodingMissingFieldsThrows() throws {
        let json = """
        {
            "type": "non_interactive_customer_info_needed"
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        XCTAssertThrowsError(try decoder.decode(CustomerInformationNeededNonInteractive.self, from: data)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testCustomerInformationNeededNonInteractiveDecodingSingleField() throws {
        let json = """
        {
            "type": "non_interactive_customer_info_needed",
            "fields": ["email_address"]
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(CustomerInformationNeededNonInteractive.self, from: data)

        XCTAssertEqual(response.type, "non_interactive_customer_info_needed")
        XCTAssertEqual(response.fields.count, 1)
        XCTAssertEqual(response.fields[0], "email_address")
    }

    // MARK: - CustomerInformationStatus Tests

    func testCustomerInformationStatusDecodingPending() throws {
        let json = """
        {
            "type": "customer_info_status",
            "status": "pending",
            "more_info_url": "https://api.example.com/kycstatus?account=GACW7NONV43MZIFHCOKCQJAKSJSISSICFVUJ2C6EZIW5773OU3HD64VI",
            "eta": 3600
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(CustomerInformationStatus.self, from: data)

        XCTAssertEqual(response.type, "customer_info_status")
        XCTAssertEqual(response.status, "pending")
        XCTAssertEqual(response.moreInfoUrl, "https://api.example.com/kycstatus?account=GACW7NONV43MZIFHCOKCQJAKSJSISSICFVUJ2C6EZIW5773OU3HD64VI")
        XCTAssertEqual(response.eta, 3600)
    }

    func testCustomerInformationStatusDecodingDenied() throws {
        let json = """
        {
            "type": "customer_info_status",
            "status": "denied",
            "more_info_url": "https://api.example.com/kycstatus?account=GACW7NONV43MZIFHCOKCQJAKSJSISSICFVUJ2C6EZIW5773OU3HD64VI"
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(CustomerInformationStatus.self, from: data)

        XCTAssertEqual(response.type, "customer_info_status")
        XCTAssertEqual(response.status, "denied")
        XCTAssertEqual(response.moreInfoUrl, "https://api.example.com/kycstatus?account=GACW7NONV43MZIFHCOKCQJAKSJSISSICFVUJ2C6EZIW5773OU3HD64VI")
        XCTAssertNil(response.eta)
    }

    func testCustomerInformationStatusDecodingWithoutOptionalFields() throws {
        let json = """
        {
            "type": "customer_info_status",
            "status": "pending"
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(CustomerInformationStatus.self, from: data)

        XCTAssertEqual(response.type, "customer_info_status")
        XCTAssertEqual(response.status, "pending")
        XCTAssertNil(response.moreInfoUrl)
        XCTAssertNil(response.eta)
    }

    func testCustomerInformationStatusDecodingMissingStatusThrows() throws {
        let json = """
        {
            "type": "customer_info_status"
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        XCTAssertThrowsError(try decoder.decode(CustomerInformationStatus.self, from: data)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    // MARK: - DepositResponse Tests

    func testDepositResponseDecoding() throws {
        let json = """
        {
            "how": "Make a payment to Bank: 121122676 Account: 13719713158835300",
            "id": "9421871e-0623-4356-b7b5-5996da122f3e",
            "eta": 3600,
            "min_amount": 1.0,
            "max_amount": 10000.0,
            "fee_fixed": 5.0,
            "fee_percent": 1.5
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(DepositResponse.self, from: data)

        XCTAssertEqual(response.how, "Make a payment to Bank: 121122676 Account: 13719713158835300")
        XCTAssertEqual(response.id, "9421871e-0623-4356-b7b5-5996da122f3e")
        XCTAssertEqual(response.eta, 3600)
        XCTAssertEqual(response.minAmount, 1.0)
        XCTAssertEqual(response.maxAmount, 10000.0)
        XCTAssertEqual(response.feeFixed, 5.0)
        XCTAssertEqual(response.feePercent, 1.5)
        XCTAssertNil(response.extraInfo)
        XCTAssertNil(response.instructions)
    }

    func testDepositResponseDecodingWithInstructions() throws {
        let json = """
        {
            "how": "Make a payment to Bank: 121122676 Account: 13719713158835300",
            "id": "9421871e-0623-4356-b7b5-5996da122f3e",
            "instructions": {
                "organization.bank_number": {
                    "value": "121122676",
                    "description": "US bank routing number"
                },
                "organization.bank_account_number": {
                    "value": "13719713158835300",
                    "description": "US bank account number"
                }
            }
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(DepositResponse.self, from: data)

        XCTAssertEqual(response.how, "Make a payment to Bank: 121122676 Account: 13719713158835300")
        XCTAssertEqual(response.id, "9421871e-0623-4356-b7b5-5996da122f3e")
        XCTAssertNotNil(response.instructions)
        XCTAssertEqual(response.instructions?.count, 2)

        let bankNumber = response.instructions?["organization.bank_number"]
        XCTAssertEqual(bankNumber?.value, "121122676")
        XCTAssertEqual(bankNumber?.description, "US bank routing number")

        let accountNumber = response.instructions?["organization.bank_account_number"]
        XCTAssertEqual(accountNumber?.value, "13719713158835300")
        XCTAssertEqual(accountNumber?.description, "US bank account number")
    }

    func testDepositResponseDecodingWithExtraInfo() throws {
        let json = """
        {
            "how": "Make a payment to Ripple address",
            "extra_info": {
                "message": "You must include the tag. If the amount is more than 1000 XRP, deposit will take 24h to complete."
            }
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(DepositResponse.self, from: data)

        XCTAssertEqual(response.how, "Make a payment to Ripple address")
        XCTAssertNotNil(response.extraInfo)
        XCTAssertEqual(response.extraInfo?.message, "You must include the tag. If the amount is more than 1000 XRP, deposit will take 24h to complete.")
    }

    func testDepositResponseDecodingMinimalFields() throws {
        let json = """
        {
            "how": "Send BTC to address xyz"
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(DepositResponse.self, from: data)

        XCTAssertEqual(response.how, "Send BTC to address xyz")
        XCTAssertNil(response.id)
        XCTAssertNil(response.eta)
        XCTAssertNil(response.minAmount)
        XCTAssertNil(response.maxAmount)
        XCTAssertNil(response.feeFixed)
        XCTAssertNil(response.feePercent)
        XCTAssertNil(response.extraInfo)
        XCTAssertNil(response.instructions)
    }

    func testDepositResponseDecodingMissingHowThrows() throws {
        let json = """
        {
            "id": "9421871e-0623-4356-b7b5-5996da122f3e"
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        XCTAssertThrowsError(try decoder.decode(DepositResponse.self, from: data)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    // MARK: - DepositInstruction Tests

    func testDepositInstructionDecoding() throws {
        let json = """
        {
            "value": "121122676",
            "description": "US bank routing number"
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let instruction = try decoder.decode(DepositInstruction.self, from: data)

        XCTAssertEqual(instruction.value, "121122676")
        XCTAssertEqual(instruction.description, "US bank routing number")
    }

    func testDepositInstructionDecodingMissingValueThrows() throws {
        let json = """
        {
            "description": "US bank routing number"
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        XCTAssertThrowsError(try decoder.decode(DepositInstruction.self, from: data)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    // MARK: - ExtraInfo Tests

    func testExtraInfoDecoding() throws {
        let json = """
        {
            "message": "You must include the tag"
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let extraInfo = try decoder.decode(ExtraInfo.self, from: data)

        XCTAssertEqual(extraInfo.message, "You must include the tag")
    }

    func testExtraInfoDecodingEmptyObject() throws {
        let json = "{}"

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let extraInfo = try decoder.decode(ExtraInfo.self, from: data)

        XCTAssertNil(extraInfo.message)
    }

    // MARK: - WithdrawResponse Tests

    func testWithdrawResponseDecoding() throws {
        let json = """
        {
            "account_id": "GCIBUCGPOHWMMMFPFTDWBSVHQRT4DIBJ7AD6BZJYDITBK2LCVBYW7HUQ",
            "memo_type": "id",
            "memo": "123",
            "id": "9421871e-0623-4356-b7b5-5996da122f3e",
            "eta": 3600,
            "min_amount": 1.0,
            "max_amount": 10000.0,
            "fee_fixed": 5.0,
            "fee_percent": 1.5
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(WithdrawResponse.self, from: data)

        XCTAssertEqual(response.accountId, "GCIBUCGPOHWMMMFPFTDWBSVHQRT4DIBJ7AD6BZJYDITBK2LCVBYW7HUQ")
        XCTAssertEqual(response.memoType, "id")
        XCTAssertEqual(response.memo, "123")
        XCTAssertEqual(response.id, "9421871e-0623-4356-b7b5-5996da122f3e")
        XCTAssertEqual(response.eta, 3600)
        XCTAssertEqual(response.minAmount, 1.0)
        XCTAssertEqual(response.maxAmount, 10000.0)
        XCTAssertEqual(response.feeFixed, 5.0)
        XCTAssertEqual(response.feePercent, 1.5)
        XCTAssertNil(response.extraInfo)
    }

    func testWithdrawResponseDecodingAllOptional() throws {
        let json = "{}"

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(WithdrawResponse.self, from: data)

        XCTAssertNil(response.accountId)
        XCTAssertNil(response.memoType)
        XCTAssertNil(response.memo)
        XCTAssertNil(response.id)
        XCTAssertNil(response.eta)
        XCTAssertNil(response.minAmount)
        XCTAssertNil(response.maxAmount)
        XCTAssertNil(response.feeFixed)
        XCTAssertNil(response.feePercent)
        XCTAssertNil(response.extraInfo)
    }

    func testWithdrawResponseDecodingWithExtraInfo() throws {
        let json = """
        {
            "account_id": "GCIBUCGPOHWMMMFPFTDWBSVHQRT4DIBJ7AD6BZJYDITBK2LCVBYW7HUQ",
            "extra_info": {
                "message": "Please ensure sufficient balance"
            }
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(WithdrawResponse.self, from: data)

        XCTAssertEqual(response.accountId, "GCIBUCGPOHWMMMFPFTDWBSVHQRT4DIBJ7AD6BZJYDITBK2LCVBYW7HUQ")
        XCTAssertNotNil(response.extraInfo)
        XCTAssertEqual(response.extraInfo?.message, "Please ensure sufficient balance")
    }

    func testWithdrawResponseDecodingHashMemo() throws {
        let json = """
        {
            "account_id": "GCIBUCGPOHWMMMFPFTDWBSVHQRT4DIBJ7AD6BZJYDITBK2LCVBYW7HUQ",
            "memo_type": "hash",
            "memo": "YjliZDJiMjkyYzRlMDllOGViMjJkMDM2MTcxNDkxZTg3YjhkMjA4NmJmOGIyNjU4NzRjOGQxODJjYjljOTAyMA=="
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(WithdrawResponse.self, from: data)

        XCTAssertEqual(response.accountId, "GCIBUCGPOHWMMMFPFTDWBSVHQRT4DIBJ7AD6BZJYDITBK2LCVBYW7HUQ")
        XCTAssertEqual(response.memoType, "hash")
        XCTAssertEqual(response.memo, "YjliZDJiMjkyYzRlMDllOGViMjJkMDM2MTcxNDkxZTg3YjhkMjA4NmJmOGIyNjU4NzRjOGQxODJjYjljOTAyMA==")
    }

    // MARK: - AnchorFeeResponse Tests

    func testAnchorFeeResponseDecoding() throws {
        let json = """
        {
            "fee": 0.013
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(AnchorFeeResponse.self, from: data)

        XCTAssertEqual(response.fee, 0.013)
    }

    func testAnchorFeeResponseDecodingZeroFee() throws {
        let json = """
        {
            "fee": 0.0
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(AnchorFeeResponse.self, from: data)

        XCTAssertEqual(response.fee, 0.0)
    }

    func testAnchorFeeResponseDecodingLargeFee() throws {
        let json = """
        {
            "fee": 12345.6789
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(AnchorFeeResponse.self, from: data)

        XCTAssertEqual(response.fee, 12345.6789)
    }

    func testAnchorFeeResponseDecodingMissingFeeThrows() throws {
        let json = "{}"

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        XCTAssertThrowsError(try decoder.decode(AnchorFeeResponse.self, from: data)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    // MARK: - AnchorInfoResponse Tests

    func testAnchorInfoResponseDecodingMinimal() throws {
        let json = "{}"

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(AnchorInfoResponse.self, from: data)

        XCTAssertNil(response.deposit)
        XCTAssertNil(response.depositExchange)
        XCTAssertNil(response.withdraw)
        XCTAssertNil(response.withdrawExchange)
        XCTAssertNil(response.transactions)
        XCTAssertNil(response.transaction)
        XCTAssertNil(response.fee)
        XCTAssertNil(response.features)
    }

    func testAnchorInfoResponseDecodingWithDeposit() throws {
        let json = """
        {
            "deposit": {
                "USD": {
                    "enabled": true,
                    "authentication_required": true,
                    "min_amount": 0.1,
                    "max_amount": 1000.0
                }
            }
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(AnchorInfoResponse.self, from: data)

        XCTAssertNotNil(response.deposit)
        XCTAssertEqual(response.deposit?.count, 1)

        let usdDeposit = response.deposit?["USD"]
        XCTAssertNotNil(usdDeposit)
        XCTAssertTrue(usdDeposit!.enabled)
        XCTAssertTrue(usdDeposit!.authenticationRequired!)
        XCTAssertEqual(usdDeposit!.minAmount, 0.1)
        XCTAssertEqual(usdDeposit!.maxAmount, 1000.0)
    }

    func testAnchorInfoResponseDecodingWithFeatures() throws {
        let json = """
        {
            "features": {
                "account_creation": true,
                "claimable_balances": true
            }
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(AnchorInfoResponse.self, from: data)

        XCTAssertNotNil(response.features)
        XCTAssertTrue(response.features!.accountCreation)
        XCTAssertTrue(response.features!.claimableBalances)
    }

    func testAnchorInfoResponseDecodingWithTransactionsInfo() throws {
        let json = """
        {
            "transactions": {
                "enabled": true,
                "authentication_required": true
            },
            "transaction": {
                "enabled": true,
                "authentication_required": false
            }
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(AnchorInfoResponse.self, from: data)

        XCTAssertNotNil(response.transactions)
        XCTAssertTrue(response.transactions!.enabled)
        XCTAssertTrue(response.transactions!.authenticationRequired!)

        XCTAssertNotNil(response.transaction)
        XCTAssertTrue(response.transaction!.enabled)
        XCTAssertFalse(response.transaction!.authenticationRequired!)
    }

    // MARK: - DepositAsset Tests

    func testDepositAssetDecodingWithEnabledTrue() throws {
        let json = """
        {
            "enabled": true,
            "authentication_required": false,
            "fee_fixed": 5.0,
            "fee_percent": 1.0,
            "min_amount": 0.1,
            "max_amount": 10000.0
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let asset = try decoder.decode(DepositAsset.self, from: data)

        XCTAssertTrue(asset.enabled)
        XCTAssertFalse(asset.authenticationRequired!)
        XCTAssertEqual(asset.feeFixed, 5.0)
        XCTAssertEqual(asset.feePercent, 1.0)
        XCTAssertEqual(asset.minAmount, 0.1)
        XCTAssertEqual(asset.maxAmount, 10000.0)
    }

    func testDepositAssetDecodingDefaultsToFalseWhenEnabledMissing() throws {
        let json = """
        {
            "authentication_required": true
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let asset = try decoder.decode(DepositAsset.self, from: data)

        XCTAssertFalse(asset.enabled)
        XCTAssertTrue(asset.authenticationRequired!)
    }

    func testDepositAssetDecodingWithFields() throws {
        let json = """
        {
            "enabled": true,
            "fields": {
                "email_address": {
                    "description": "your email address",
                    "optional": true
                },
                "country_code": {
                    "description": "your country code",
                    "optional": false,
                    "choices": ["USA", "CAN", "MEX"]
                }
            }
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let asset = try decoder.decode(DepositAsset.self, from: data)

        XCTAssertTrue(asset.enabled)
        XCTAssertNotNil(asset.fields)
        XCTAssertEqual(asset.fields?.count, 2)

        let emailField = asset.fields?["email_address"]
        XCTAssertEqual(emailField?.description, "your email address")
        XCTAssertTrue(emailField?.optional ?? false)

        let countryField = asset.fields?["country_code"]
        XCTAssertEqual(countryField?.description, "your country code")
        XCTAssertFalse(countryField?.optional ?? true)
        XCTAssertEqual(countryField?.choices?.count, 3)
        XCTAssertTrue(countryField?.choices?.contains("USA") ?? false)
    }

    // MARK: - WithdrawAsset Tests

    func testWithdrawAssetDecodingWithTypes() throws {
        let json = """
        {
            "enabled": true,
            "types": {
                "bank_account": {
                    "fields": {
                        "dest": {
                            "description": "your bank account number"
                        }
                    }
                },
                "cash": {
                    "fields": {
                        "dest": {
                            "description": "your email address",
                            "optional": true
                        }
                    }
                }
            }
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let asset = try decoder.decode(WithdrawAsset.self, from: data)

        XCTAssertTrue(asset.enabled)
        XCTAssertNotNil(asset.types)
        XCTAssertEqual(asset.types?.count, 2)

        let bankAccount = asset.types?["bank_account"]
        XCTAssertNotNil(bankAccount?.fields)
        XCTAssertEqual(bankAccount?.fields?["dest"]?.description, "your bank account number")

        let cash = asset.types?["cash"]
        XCTAssertNotNil(cash?.fields)
        XCTAssertEqual(cash?.fields?["dest"]?.description, "your email address")
        XCTAssertTrue(cash?.fields?["dest"]?.optional ?? false)
    }

    // MARK: - AnchorFeatureFlags Tests

    func testAnchorFeatureFlagsDecodingDefaults() throws {
        let json = "{}"

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let features = try decoder.decode(AnchorFeatureFlags.self, from: data)

        XCTAssertTrue(features.accountCreation)
        XCTAssertFalse(features.claimableBalances)
    }

    func testAnchorFeatureFlagsDecodingExplicitValues() throws {
        let json = """
        {
            "account_creation": false,
            "claimable_balances": true
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let features = try decoder.decode(AnchorFeatureFlags.self, from: data)

        XCTAssertFalse(features.accountCreation)
        XCTAssertTrue(features.claimableBalances)
    }

    // MARK: - AnchorTransactionKind Tests

    func testAnchorTransactionKindRawValues() {
        XCTAssertEqual(AnchorTransactionKind.deposit.rawValue, "deposit")
        XCTAssertEqual(AnchorTransactionKind.depositExchange.rawValue, "deposit-exchange")
        XCTAssertEqual(AnchorTransactionKind.withdrawal.rawValue, "withdrawal")
        XCTAssertEqual(AnchorTransactionKind.withdrawalExchange.rawValue, "withdrawal-exchange")
    }

    func testAnchorTransactionKindFromRawValue() {
        XCTAssertEqual(AnchorTransactionKind(rawValue: "deposit"), .deposit)
        XCTAssertEqual(AnchorTransactionKind(rawValue: "deposit-exchange"), .depositExchange)
        XCTAssertEqual(AnchorTransactionKind(rawValue: "withdrawal"), .withdrawal)
        XCTAssertEqual(AnchorTransactionKind(rawValue: "withdrawal-exchange"), .withdrawalExchange)
        XCTAssertNil(AnchorTransactionKind(rawValue: "invalid"))
    }

    // MARK: - AnchorTransactionStatus Tests

    func testAnchorTransactionStatusRawValues() {
        XCTAssertEqual(AnchorTransactionStatus.completed.rawValue, "completed")
        XCTAssertEqual(AnchorTransactionStatus.pendingExternal.rawValue, "pending_external")
        XCTAssertEqual(AnchorTransactionStatus.pendingAnchor.rawValue, "pending_anchor")
        XCTAssertEqual(AnchorTransactionStatus.pendingStellar.rawValue, "pending_stellar")
        XCTAssertEqual(AnchorTransactionStatus.pendingTrust.rawValue, "pending_trust")
        XCTAssertEqual(AnchorTransactionStatus.pendingUser.rawValue, "pending_user")
        XCTAssertEqual(AnchorTransactionStatus.pendingUserTransferStart.rawValue, "pending_user_transfer_start")
        XCTAssertEqual(AnchorTransactionStatus.pendingUserTransferComplete.rawValue, "pending_user_transfer_complete")
        XCTAssertEqual(AnchorTransactionStatus.pendingCustomerInfoUpdate.rawValue, "pending_customer_info_update")
        XCTAssertEqual(AnchorTransactionStatus.pendingTransactionInfoUpdate.rawValue, "pending_transaction_info_update")
        XCTAssertEqual(AnchorTransactionStatus.incomplete.rawValue, "incomplete")
        XCTAssertEqual(AnchorTransactionStatus.noMarket.rawValue, "no_market")
        XCTAssertEqual(AnchorTransactionStatus.tooSmall.rawValue, "too_small")
        XCTAssertEqual(AnchorTransactionStatus.tooLarge.rawValue, "too_large")
        XCTAssertEqual(AnchorTransactionStatus.error.rawValue, "error")
        XCTAssertEqual(AnchorTransactionStatus.refunded.rawValue, "refunded")
        XCTAssertEqual(AnchorTransactionStatus.expired.rawValue, "expired")
    }

    func testAnchorTransactionStatusFromRawValue() {
        XCTAssertEqual(AnchorTransactionStatus(rawValue: "completed"), .completed)
        XCTAssertEqual(AnchorTransactionStatus(rawValue: "pending_external"), .pendingExternal)
        XCTAssertEqual(AnchorTransactionStatus(rawValue: "expired"), .expired)
        XCTAssertNil(AnchorTransactionStatus(rawValue: "invalid"))
    }

    // MARK: - AnchorTransaction Tests

    func testAnchorTransactionDecodingMinimal() throws {
        let json = """
        {
            "id": "82fhs729f63dh0v4",
            "kind": "deposit",
            "status": "pending_external",
            "started_at": "2017-03-20T17:05:32.000Z"
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let transaction = try decoder.decode(AnchorTransaction.self, from: data)

        XCTAssertEqual(transaction.id, "82fhs729f63dh0v4")
        XCTAssertEqual(transaction.kind, .deposit)
        XCTAssertEqual(transaction.status, .pendingExternal)
        XCTAssertNotNil(transaction.startedAt)
    }

    func testAnchorTransactionDecodingWithRefunds() throws {
        let json = """
        {
            "id": "82fhs729f63dh0v4",
            "kind": "withdrawal",
            "status": "completed",
            "started_at": "2017-03-20T17:05:32.000Z",
            "refunds": {
                "amount_refunded": "10",
                "amount_fee": "5",
                "payments": [
                    {
                        "id": "b9d0b2292c4e09e8eb22d036171491e87b8d2086bf8b265874c8d182cb9c9020",
                        "id_type": "stellar",
                        "amount": "10",
                        "fee": "5"
                    }
                ]
            }
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let transaction = try decoder.decode(AnchorTransaction.self, from: data)

        XCTAssertEqual(transaction.id, "82fhs729f63dh0v4")
        XCTAssertNotNil(transaction.refunds)
        XCTAssertEqual(transaction.refunds?.amountRefunded, "10")
        XCTAssertEqual(transaction.refunds?.amountFee, "5")
        XCTAssertEqual(transaction.refunds?.payments?.count, 1)

        let payment = transaction.refunds?.payments?.first
        XCTAssertEqual(payment?.id, "b9d0b2292c4e09e8eb22d036171491e87b8d2086bf8b265874c8d182cb9c9020")
        XCTAssertEqual(payment?.idType, "stellar")
        XCTAssertEqual(payment?.amount, "10")
        XCTAssertEqual(payment?.fee, "5")
    }

    func testAnchorTransactionDecodingWithFeeDetails() throws {
        let json = """
        {
            "id": "82fhs729f63dh0v4",
            "kind": "deposit",
            "status": "completed",
            "started_at": "2017-03-20T17:05:32.000Z",
            "fee_details": {
                "total": "5.0",
                "asset": "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN",
                "details": [
                    {
                        "name": "Service fee",
                        "amount": "3.0",
                        "description": "Basic service fee"
                    },
                    {
                        "name": "Network fee",
                        "amount": "2.0"
                    }
                ]
            }
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let transaction = try decoder.decode(AnchorTransaction.self, from: data)

        XCTAssertEqual(transaction.id, "82fhs729f63dh0v4")
        XCTAssertNotNil(transaction.feeDetails)
        XCTAssertEqual(transaction.feeDetails?.total, "5.0")
        XCTAssertEqual(transaction.feeDetails?.asset, "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN")
        XCTAssertEqual(transaction.feeDetails?.details?.count, 2)

        let serviceFee = transaction.feeDetails?.details?[0]
        XCTAssertEqual(serviceFee?.name, "Service fee")
        XCTAssertEqual(serviceFee?.amount, "3.0")
        XCTAssertEqual(serviceFee?.description, "Basic service fee")

        let networkFee = transaction.feeDetails?.details?[1]
        XCTAssertEqual(networkFee?.name, "Network fee")
        XCTAssertEqual(networkFee?.amount, "2.0")
        XCTAssertNil(networkFee?.description)
    }

    func testAnchorTransactionDecodingWithRequiredInfoUpdates() throws {
        let json = """
        {
            "id": "52fys79f63dh3v1",
            "kind": "withdrawal",
            "status": "pending_transaction_info_update",
            "started_at": "2017-03-20T17:00:02.000Z",
            "required_info_message": "Please provide bank account",
            "required_info_updates": {
                "transaction": {
                    "dest": {
                        "description": "your bank account number"
                    },
                    "dest_extra": {
                        "description": "your routing number",
                        "optional": true
                    }
                }
            }
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let transaction = try decoder.decode(AnchorTransaction.self, from: data)

        XCTAssertEqual(transaction.id, "52fys79f63dh3v1")
        XCTAssertEqual(transaction.status, .pendingTransactionInfoUpdate)
        XCTAssertEqual(transaction.requiredInfoMessage, "Please provide bank account")
        XCTAssertNotNil(transaction.requiredInfoUpdates)
        XCTAssertEqual(transaction.requiredInfoUpdates?.fields?.count, 2)

        let destField = transaction.requiredInfoUpdates?.fields?["dest"]
        XCTAssertEqual(destField?.description, "your bank account number")

        let destExtraField = transaction.requiredInfoUpdates?.fields?["dest_extra"]
        XCTAssertEqual(destExtraField?.description, "your routing number")
        XCTAssertTrue(destExtraField?.optional ?? false)
    }

    func testAnchorTransactionDecodingWithInstructions() throws {
        let json = """
        {
            "id": "82fhs729f63dh0v4",
            "kind": "deposit",
            "status": "pending_user_transfer_start",
            "started_at": "2017-03-20T17:05:32.000Z",
            "instructions": {
                "organization.bank_number": {
                    "value": "121122676",
                    "description": "US bank routing number"
                }
            }
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let transaction = try decoder.decode(AnchorTransaction.self, from: data)

        XCTAssertEqual(transaction.id, "82fhs729f63dh0v4")
        XCTAssertNotNil(transaction.instructions)
        XCTAssertEqual(transaction.instructions?.count, 1)

        let instruction = transaction.instructions?["organization.bank_number"]
        XCTAssertEqual(instruction?.value, "121122676")
        XCTAssertEqual(instruction?.description, "US bank routing number")
    }

    // MARK: - AnchorTransactionsResponse Tests

    func testAnchorTransactionsResponseDecoding() throws {
        let json = """
        {
            "transactions": [
                {
                    "id": "82fhs729f63dh0v4",
                    "kind": "deposit",
                    "status": "pending_external",
                    "started_at": "2017-03-20T17:05:32.000Z"
                },
                {
                    "id": "72fhs729f63dh0v1",
                    "kind": "withdrawal",
                    "status": "completed",
                    "started_at": "2017-03-20T17:00:02.000Z"
                }
            ]
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(AnchorTransactionsResponse.self, from: data)

        XCTAssertEqual(response.transactions.count, 2)
        XCTAssertEqual(response.transactions[0].id, "82fhs729f63dh0v4")
        XCTAssertEqual(response.transactions[0].kind, .deposit)
        XCTAssertEqual(response.transactions[1].id, "72fhs729f63dh0v1")
        XCTAssertEqual(response.transactions[1].kind, .withdrawal)
    }

    func testAnchorTransactionsResponseDecodingEmpty() throws {
        let json = """
        {
            "transactions": []
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(AnchorTransactionsResponse.self, from: data)

        XCTAssertEqual(response.transactions.count, 0)
    }

    // MARK: - AnchorTransactionResponse Tests

    func testAnchorTransactionResponseDecoding() throws {
        let json = """
        {
            "transaction": {
                "id": "82fhs729f63dh0v4",
                "kind": "deposit",
                "status": "pending_external",
                "started_at": "2017-03-20T17:05:32.000Z"
            }
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(AnchorTransactionResponse.self, from: data)

        XCTAssertEqual(response.transaction.id, "82fhs729f63dh0v4")
        XCTAssertEqual(response.transaction.kind, .deposit)
        XCTAssertEqual(response.transaction.status, .pendingExternal)
    }
}
