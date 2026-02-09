//
//  KycAmlFieldsUnitTests.swift
//  stellarsdk
//
//  Created by Soneso
//  Copyright © 2024 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

final class KycAmlFieldsUnitTests: XCTestCase {

    // MARK: - KYCNaturalPersonFieldsEnum Tests

    func testNaturalPersonLastName() {
        let field = KYCNaturalPersonFieldsEnum.lastName("Doe")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "last_name")
        XCTAssertEqual(String(data: data, encoding: .utf8), "Doe")
    }

    func testNaturalPersonFirstName() {
        let field = KYCNaturalPersonFieldsEnum.firstName("John")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "first_name")
        XCTAssertEqual(String(data: data, encoding: .utf8), "John")
    }

    func testNaturalPersonAdditionalName() {
        let field = KYCNaturalPersonFieldsEnum.additionalName("Michael")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "additional_name")
        XCTAssertEqual(String(data: data, encoding: .utf8), "Michael")
    }

    func testNaturalPersonAddressCountryCode() {
        let field = KYCNaturalPersonFieldsEnum.addressCountryCode("USA")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "address_country_code")
        XCTAssertEqual(String(data: data, encoding: .utf8), "USA")
    }

    func testNaturalPersonStateOrProvince() {
        let field = KYCNaturalPersonFieldsEnum.stateOrProvince("California")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "state_or_province")
        XCTAssertEqual(String(data: data, encoding: .utf8), "California")
    }

    func testNaturalPersonCity() {
        let field = KYCNaturalPersonFieldsEnum.city("San Francisco")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "city")
        XCTAssertEqual(String(data: data, encoding: .utf8), "San Francisco")
    }

    func testNaturalPersonPostalCode() {
        let field = KYCNaturalPersonFieldsEnum.postalCode("94102")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "postal_code")
        XCTAssertEqual(String(data: data, encoding: .utf8), "94102")
    }

    func testNaturalPersonAddress() {
        let address = "123 Main St\nSan Francisco, CA 94102\nUSA"
        let field = KYCNaturalPersonFieldsEnum.address(address)
        let (key, data) = field.parameter

        XCTAssertEqual(key, "address")
        XCTAssertEqual(String(data: data, encoding: .utf8), address)
    }

    func testNaturalPersonMobileNumber() {
        let field = KYCNaturalPersonFieldsEnum.mobileNumber("+14155551234")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "mobile_number")
        XCTAssertEqual(String(data: data, encoding: .utf8), "+14155551234")
    }

    func testNaturalPersonMobileNumberFormat() {
        let field = KYCNaturalPersonFieldsEnum.mobileNumberFormat("E.164")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "mobile_number_format")
        XCTAssertEqual(String(data: data, encoding: .utf8), "E.164")
    }

    func testNaturalPersonEmailAddress() {
        let field = KYCNaturalPersonFieldsEnum.emailAddress("john.doe@example.com")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "email_address")
        XCTAssertEqual(String(data: data, encoding: .utf8), "john.doe@example.com")
    }

    func testNaturalPersonBirthDate() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")

        guard let birthDate = dateFormatter.date(from: "1976-07-04") else {
            XCTFail("Failed to create birth date")
            return
        }

        let field = KYCNaturalPersonFieldsEnum.birthDate(birthDate)
        let (key, data) = field.parameter

        XCTAssertEqual(key, "birth_date")

        let dateString = String(data: data, encoding: .utf8)
        XCTAssertNotNil(dateString)
        XCTAssertTrue(dateString!.contains("1976-07-04"))
    }

    func testNaturalPersonBirthPlace() {
        let field = KYCNaturalPersonFieldsEnum.birthPlace("New York, NY, USA")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "birth_place")
        XCTAssertEqual(String(data: data, encoding: .utf8), "New York, NY, USA")
    }

    func testNaturalPersonBirthCountryCode() {
        let field = KYCNaturalPersonFieldsEnum.birthCountryCode("USA")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "birth_country_code")
        XCTAssertEqual(String(data: data, encoding: .utf8), "USA")
    }

    func testNaturalPersonTaxId() {
        let field = KYCNaturalPersonFieldsEnum.taxId("123-45-6789")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "tax_id")
        XCTAssertEqual(String(data: data, encoding: .utf8), "123-45-6789")
    }

    func testNaturalPersonTaxIdName() {
        let field = KYCNaturalPersonFieldsEnum.taxIdName("SSN")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "tax_id_name")
        XCTAssertEqual(String(data: data, encoding: .utf8), "SSN")
    }

    func testNaturalPersonOccupation() {
        let field = KYCNaturalPersonFieldsEnum.occupation(2310)
        let (key, data) = field.parameter

        XCTAssertEqual(key, "occupation")
        XCTAssertGreaterThan(data.count, 0)
    }

    func testNaturalPersonEmployerName() {
        let field = KYCNaturalPersonFieldsEnum.employerName("Acme Corporation")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "employer_name")
        XCTAssertEqual(String(data: data, encoding: .utf8), "Acme Corporation")
    }

    func testNaturalPersonEmployerAddress() {
        let field = KYCNaturalPersonFieldsEnum.employerAddress("456 Business Ave, Suite 100")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "employer_address")
        XCTAssertEqual(String(data: data, encoding: .utf8), "456 Business Ave, Suite 100")
    }

    func testNaturalPersonLanguageCode() {
        let field = KYCNaturalPersonFieldsEnum.languageCode("en")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "language_code")
        XCTAssertEqual(String(data: data, encoding: .utf8), "en")
    }

    func testNaturalPersonIdType() {
        let field = KYCNaturalPersonFieldsEnum.idType("passport")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "id_type")
        XCTAssertEqual(String(data: data, encoding: .utf8), "passport")
    }

    func testNaturalPersonIdCountryCode() {
        let field = KYCNaturalPersonFieldsEnum.idCountryCode("USA")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "id_country_code")
        XCTAssertEqual(String(data: data, encoding: .utf8), "USA")
    }

    func testNaturalPersonIdIssueDate() {
        let field = KYCNaturalPersonFieldsEnum.idIssueDate("2020-01-15")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "id_issue_date")
        XCTAssertEqual(String(data: data, encoding: .utf8), "2020-01-15")
    }

    func testNaturalPersonIdExpirationDate() {
        let field = KYCNaturalPersonFieldsEnum.idExpirationDate("2030-01-15")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "id_expiration_date")
        XCTAssertEqual(String(data: data, encoding: .utf8), "2030-01-15")
    }

    func testNaturalPersonIdNumber() {
        let field = KYCNaturalPersonFieldsEnum.idNumber("P123456789")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "id_number")
        XCTAssertEqual(String(data: data, encoding: .utf8), "P123456789")
    }

    func testNaturalPersonPhotoIdFront() {
        let imageData = Data([0xFF, 0xD8, 0xFF, 0xE0])
        let field = KYCNaturalPersonFieldsEnum.photoIdFront(imageData)
        let (key, data) = field.parameter

        XCTAssertEqual(key, "photo_id_front")
        XCTAssertEqual(data, imageData)
    }

    func testNaturalPersonPhotoIdBack() {
        let imageData = Data([0xFF, 0xD8, 0xFF, 0xE1])
        let field = KYCNaturalPersonFieldsEnum.photoIdBack(imageData)
        let (key, data) = field.parameter

        XCTAssertEqual(key, "photo_id_back")
        XCTAssertEqual(data, imageData)
    }

    func testNaturalPersonNotaryApprovalOfPhotoId() {
        let imageData = Data([0x89, 0x50, 0x4E, 0x47])
        let field = KYCNaturalPersonFieldsEnum.notaryApprovalOfPhotoId(imageData)
        let (key, data) = field.parameter

        XCTAssertEqual(key, "notary_approval_of_photo_id")
        XCTAssertEqual(data, imageData)
    }

    func testNaturalPersonIpAddress() {
        let field = KYCNaturalPersonFieldsEnum.ipAddress("192.168.1.100")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "ip_address")
        XCTAssertEqual(String(data: data, encoding: .utf8), "192.168.1.100")
    }

    func testNaturalPersonPhotoProofResidence() {
        let imageData = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A])
        let field = KYCNaturalPersonFieldsEnum.photoProofResidence(imageData)
        let (key, data) = field.parameter

        XCTAssertEqual(key, "photo_proof_residence")
        XCTAssertEqual(data, imageData)
    }

    func testNaturalPersonSex() {
        let field = KYCNaturalPersonFieldsEnum.sex("male")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "sex")
        XCTAssertEqual(String(data: data, encoding: .utf8), "male")
    }

    func testNaturalPersonProofOfIncome() {
        let documentData = Data([0x25, 0x50, 0x44, 0x46])
        let field = KYCNaturalPersonFieldsEnum.proofOfIncome(documentData)
        let (key, data) = field.parameter

        XCTAssertEqual(key, "proof_of_income")
        XCTAssertEqual(data, documentData)
    }

    func testNaturalPersonProofOfLiveness() {
        let videoData = Data([0x00, 0x00, 0x00, 0x20, 0x66, 0x74, 0x79, 0x70])
        let field = KYCNaturalPersonFieldsEnum.proofOfLiveness(videoData)
        let (key, data) = field.parameter

        XCTAssertEqual(key, "proof_of_liveness")
        XCTAssertEqual(data, videoData)
    }

    func testNaturalPersonReferralId() {
        let field = KYCNaturalPersonFieldsEnum.referralId("REF-12345")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "referral_id")
        XCTAssertEqual(String(data: data, encoding: .utf8), "REF-12345")
    }

    // MARK: - KYCFinancialAccountFieldsEnum Tests

    func testFinancialAccountBankName() {
        let field = KYCFinancialAccountFieldsEnum.bankName("Chase Bank")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "bank_name")
        XCTAssertEqual(String(data: data, encoding: .utf8), "Chase Bank")
    }

    func testFinancialAccountBankAccountType() {
        let field = KYCFinancialAccountFieldsEnum.bankAccountType("checking")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "bank_account_type")
        XCTAssertEqual(String(data: data, encoding: .utf8), "checking")
    }

    func testFinancialAccountBankAccountNumber() {
        let field = KYCFinancialAccountFieldsEnum.bankAccountNumber("1234567890")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "bank_account_number")
        XCTAssertEqual(String(data: data, encoding: .utf8), "1234567890")
    }

    func testFinancialAccountBankNumber() {
        let field = KYCFinancialAccountFieldsEnum.bankNumber("021000021")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "bank_number")
        XCTAssertEqual(String(data: data, encoding: .utf8), "021000021")
    }

    func testFinancialAccountBankPhoneNumber() {
        let field = KYCFinancialAccountFieldsEnum.bankPhoneNumber("+18005551234")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "bank_phone_number")
        XCTAssertEqual(String(data: data, encoding: .utf8), "+18005551234")
    }

    func testFinancialAccountBankBranchNumber() {
        let field = KYCFinancialAccountFieldsEnum.bankBranchNumber("001")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "bank_branch_number")
        XCTAssertEqual(String(data: data, encoding: .utf8), "001")
    }

    func testFinancialAccountExternalTransferMemo() {
        let field = KYCFinancialAccountFieldsEnum.externalTransferMemo("MEMO-123456")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "external_transfer_memo")
        XCTAssertEqual(String(data: data, encoding: .utf8), "MEMO-123456")
    }

    func testFinancialAccountClabeNumber() {
        let field = KYCFinancialAccountFieldsEnum.clabeNumber("032180000118359719")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "clabe_number")
        XCTAssertEqual(String(data: data, encoding: .utf8), "032180000118359719")
    }

    func testFinancialAccountCbuNumber() {
        let field = KYCFinancialAccountFieldsEnum.cbuNumber("0170012300000012345678")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "cbu_number")
        XCTAssertEqual(String(data: data, encoding: .utf8), "0170012300000012345678")
    }

    func testFinancialAccountCbuAlias() {
        let field = KYCFinancialAccountFieldsEnum.cbuAlias("john.doe.alias")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "cbu_alias")
        XCTAssertEqual(String(data: data, encoding: .utf8), "john.doe.alias")
    }

    func testFinancialAccountMobileMoneyNumber() {
        let field = KYCFinancialAccountFieldsEnum.mobileMoneyNumber("+254712345678")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "mobile_money_number")
        XCTAssertEqual(String(data: data, encoding: .utf8), "+254712345678")
    }

    func testFinancialAccountMobileMoneyProvider() {
        let field = KYCFinancialAccountFieldsEnum.mobileMoneyProvider("M-Pesa")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "mobile_money_provider")
        XCTAssertEqual(String(data: data, encoding: .utf8), "M-Pesa")
    }

    func testFinancialAccountCryptoAddress() {
        let field = KYCFinancialAccountFieldsEnum.cryptoAddress("GDIODQRBHD32QZWTGOHO2MRZQY2TRG5KTI2NNTFYH2JDYZGMU3NJVAUI")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "crypto_address")
        XCTAssertEqual(String(data: data, encoding: .utf8), "GDIODQRBHD32QZWTGOHO2MRZQY2TRG5KTI2NNTFYH2JDYZGMU3NJVAUI")
    }

    func testFinancialAccountCryptoMemo() {
        let field = KYCFinancialAccountFieldsEnum.cryptoMemo("123456789")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "crypto_memo")
        XCTAssertEqual(String(data: data, encoding: .utf8), "123456789")
    }

    // MARK: - KYCOrganizationFieldsEnum Tests

    func testOrganizationName() {
        let field = KYCOrganizationFieldsEnum.name("Acme Corporation Inc.")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "organization.name")
        XCTAssertEqual(String(data: data, encoding: .utf8), "Acme Corporation Inc.")
    }

    func testOrganizationVATNumber() {
        let field = KYCOrganizationFieldsEnum.VATNumber("GB123456789")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "organization.VAT_number")
        XCTAssertEqual(String(data: data, encoding: .utf8), "GB123456789")
    }

    func testOrganizationRegistrationNumber() {
        let field = KYCOrganizationFieldsEnum.registrationNumber("12345678")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "organization.registration_number")
        XCTAssertEqual(String(data: data, encoding: .utf8), "12345678")
    }

    func testOrganizationRegistrationDate() {
        let field = KYCOrganizationFieldsEnum.registrationDate("2010-05-15")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "organization.registration_date")
        XCTAssertEqual(String(data: data, encoding: .utf8), "2010-05-15")
    }

    func testOrganizationRegisteredAddress() {
        let address = "100 Corporate Blvd\nNew York, NY 10001\nUSA"
        let field = KYCOrganizationFieldsEnum.registeredAddress(address)
        let (key, data) = field.parameter

        XCTAssertEqual(key, "organization.registered_address")
        XCTAssertEqual(String(data: data, encoding: .utf8), address)
    }

    func testOrganizationNumberOfShareholders() {
        let field = KYCOrganizationFieldsEnum.numberOfShareholders(5)
        let (key, data) = field.parameter

        XCTAssertEqual(key, "organization.number_of_shareholders")
        XCTAssertGreaterThan(data.count, 0)
    }

    func testOrganizationShareholderName() {
        let field = KYCOrganizationFieldsEnum.shareholderName("Jane Smith")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "organization.shareholder_name")
        XCTAssertEqual(String(data: data, encoding: .utf8), "Jane Smith")
    }

    func testOrganizationPhotoIncorporationDoc() {
        let documentData = Data([0x25, 0x50, 0x44, 0x46, 0x2D])
        let field = KYCOrganizationFieldsEnum.photoIncorporationDoc(documentData)
        let (key, data) = field.parameter

        XCTAssertEqual(key, "organization.photo_incorporation_doc")
        XCTAssertEqual(data, documentData)
    }

    func testOrganizationPhotoProofAddress() {
        let imageData = Data([0xFF, 0xD8, 0xFF, 0xE0])
        let field = KYCOrganizationFieldsEnum.photoProofAddress(imageData)
        let (key, data) = field.parameter

        XCTAssertEqual(key, "organization.photo_proof_address")
        XCTAssertEqual(data, imageData)
    }

    func testOrganizationAddressCountryCode() {
        let field = KYCOrganizationFieldsEnum.addressCountryCode("USA")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "organization.address_country_code")
        XCTAssertEqual(String(data: data, encoding: .utf8), "USA")
    }

    func testOrganizationStateOrProvince() {
        let field = KYCOrganizationFieldsEnum.stateOrProvince("New York")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "organization.state_or_province")
        XCTAssertEqual(String(data: data, encoding: .utf8), "New York")
    }

    func testOrganizationCity() {
        let field = KYCOrganizationFieldsEnum.city("New York")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "organization.city")
        XCTAssertEqual(String(data: data, encoding: .utf8), "New York")
    }

    func testOrganizationPostalCode() {
        let field = KYCOrganizationFieldsEnum.postalCode("10001")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "organization.postal_code")
        XCTAssertEqual(String(data: data, encoding: .utf8), "10001")
    }

    func testOrganizationDirectorName() {
        let field = KYCOrganizationFieldsEnum.directorName("Robert Johnson")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "organization.director_name")
        XCTAssertEqual(String(data: data, encoding: .utf8), "Robert Johnson")
    }

    func testOrganizationWebsite() {
        let field = KYCOrganizationFieldsEnum.website("https://www.acmecorp.com")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "organization.website")
        XCTAssertEqual(String(data: data, encoding: .utf8), "https://www.acmecorp.com")
    }

    func testOrganizationEmail() {
        let field = KYCOrganizationFieldsEnum.email("contact@acmecorp.com")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "organization.email")
        XCTAssertEqual(String(data: data, encoding: .utf8), "contact@acmecorp.com")
    }

    func testOrganizationPhone() {
        let field = KYCOrganizationFieldsEnum.phone("+12125551234")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "organization.phone")
        XCTAssertEqual(String(data: data, encoding: .utf8), "+12125551234")
    }

    // MARK: - KYCCardFieldsEnum Tests

    func testCardNumber() {
        let field = KYCCardFieldsEnum.number("4532123456789012")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "card.number")
        XCTAssertEqual(String(data: data, encoding: .utf8), "4532123456789012")
    }

    func testCardExpirationDate() {
        let field = KYCCardFieldsEnum.expirationDate("29-11")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "card.expiration_date")
        XCTAssertEqual(String(data: data, encoding: .utf8), "29-11")
    }

    func testCardCvc() {
        let field = KYCCardFieldsEnum.cvc("123")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "card.cvc")
        XCTAssertEqual(String(data: data, encoding: .utf8), "123")
    }

    func testCardHolderName() {
        let field = KYCCardFieldsEnum.holderName("JOHN DOE")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "card.holder_name")
        XCTAssertEqual(String(data: data, encoding: .utf8), "JOHN DOE")
    }

    func testCardNetwork() {
        let field = KYCCardFieldsEnum.network("Visa")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "card.network")
        XCTAssertEqual(String(data: data, encoding: .utf8), "Visa")
    }

    func testCardPostalCode() {
        let field = KYCCardFieldsEnum.postalCode("94102")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "card.postal_code")
        XCTAssertEqual(String(data: data, encoding: .utf8), "94102")
    }

    func testCardCountryCode() {
        let field = KYCCardFieldsEnum.countryCode("US")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "card.country_code")
        XCTAssertEqual(String(data: data, encoding: .utf8), "US")
    }

    func testCardStateOrProvince() {
        let field = KYCCardFieldsEnum.stateOrProvince("CA")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "card.state_or_province")
        XCTAssertEqual(String(data: data, encoding: .utf8), "CA")
    }

    func testCardCity() {
        let field = KYCCardFieldsEnum.city("San Francisco")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "card.city")
        XCTAssertEqual(String(data: data, encoding: .utf8), "San Francisco")
    }

    func testCardAddress() {
        let address = "123 Main St\nSan Francisco, CA 94102"
        let field = KYCCardFieldsEnum.address(address)
        let (key, data) = field.parameter

        XCTAssertEqual(key, "card.address")
        XCTAssertEqual(String(data: data, encoding: .utf8), address)
    }

    func testCardToken() {
        let field = KYCCardFieldsEnum.token("tok_1A2B3C4D5E6F7G8H")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "card.token")
        XCTAssertEqual(String(data: data, encoding: .utf8), "tok_1A2B3C4D5E6F7G8H")
    }

    // MARK: - Edge Case Tests

    func testEmptyStringFields() {
        let field = KYCNaturalPersonFieldsEnum.firstName("")
        let (key, data) = field.parameter

        XCTAssertEqual(key, "first_name")
        XCTAssertEqual(String(data: data, encoding: .utf8), "")
    }

    func testSpecialCharactersInFields() {
        let specialName = "José María O'Connor-Smith"
        let field = KYCNaturalPersonFieldsEnum.firstName(specialName)
        let (key, data) = field.parameter

        XCTAssertEqual(key, "first_name")
        XCTAssertEqual(String(data: data, encoding: .utf8), specialName)
    }

    func testUnicodeCharactersInFields() {
        let unicodeName = "李明 中文测试"
        let field = KYCNaturalPersonFieldsEnum.lastName(unicodeName)
        let (key, data) = field.parameter

        XCTAssertEqual(key, "last_name")
        XCTAssertEqual(String(data: data, encoding: .utf8), unicodeName)
    }

    func testMultilineAddressField() {
        let multilineAddress = "Line 1\nLine 2\nLine 3\nLine 4"
        let field = KYCNaturalPersonFieldsEnum.address(multilineAddress)
        let (key, data) = field.parameter

        XCTAssertEqual(key, "address")
        XCTAssertEqual(String(data: data, encoding: .utf8), multilineAddress)
    }

    func testEmptyBinaryData() {
        let emptyData = Data()
        let field = KYCNaturalPersonFieldsEnum.photoIdFront(emptyData)
        let (key, data) = field.parameter

        XCTAssertEqual(key, "photo_id_front")
        XCTAssertEqual(data, emptyData)
    }

    func testLargeBinaryData() {
        let largeData = Data(repeating: 0xFF, count: 1024 * 1024)
        let field = KYCNaturalPersonFieldsEnum.photoProofResidence(largeData)
        let (key, data) = field.parameter

        XCTAssertEqual(key, "photo_proof_residence")
        XCTAssertEqual(data, largeData)
        XCTAssertEqual(data.count, 1024 * 1024)
    }

    func testZeroOccupationCode() {
        let field = KYCNaturalPersonFieldsEnum.occupation(0)
        let (key, data) = field.parameter

        XCTAssertEqual(key, "occupation")
        XCTAssertGreaterThan(data.count, 0)
    }

    func testNegativeOccupationCode() {
        let field = KYCNaturalPersonFieldsEnum.occupation(-1)
        let (key, data) = field.parameter

        XCTAssertEqual(key, "occupation")
        XCTAssertGreaterThan(data.count, 0)
    }

    func testZeroNumberOfShareholders() {
        let field = KYCOrganizationFieldsEnum.numberOfShareholders(0)
        let (key, data) = field.parameter

        XCTAssertEqual(key, "organization.number_of_shareholders")
        XCTAssertGreaterThan(data.count, 0)
    }

    func testEmailWithSpecialCharacters() {
        let email = "user+tag@sub.domain.co.uk"
        let field = KYCNaturalPersonFieldsEnum.emailAddress(email)
        let (key, data) = field.parameter

        XCTAssertEqual(key, "email_address")
        XCTAssertEqual(String(data: data, encoding: .utf8), email)
    }

    func testInternationalPhoneNumbers() {
        let phoneNumbers = [
            "+14155551234",
            "+442071234567",
            "+81312345678",
            "+61291234567"
        ]

        for phoneNumber in phoneNumbers {
            let field = KYCNaturalPersonFieldsEnum.mobileNumber(phoneNumber)
            let (key, data) = field.parameter

            XCTAssertEqual(key, "mobile_number")
            XCTAssertEqual(String(data: data, encoding: .utf8), phoneNumber)
        }
    }

    func testURLFormats() {
        let urls = [
            "https://www.example.com",
            "http://example.com",
            "https://sub.example.com:8080/path",
            "https://example.com/path?query=value&other=123"
        ]

        for url in urls {
            let field = KYCOrganizationFieldsEnum.website(url)
            let (key, data) = field.parameter

            XCTAssertEqual(key, "organization.website")
            XCTAssertEqual(String(data: data, encoding: .utf8), url)
        }
    }

    func testDateFormatting() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")

        guard let testDate = dateFormatter.date(from: "2000-01-01") else {
            XCTFail("Failed to create test date")
            return
        }

        let field = KYCNaturalPersonFieldsEnum.birthDate(testDate)
        let (key, data) = field.parameter

        XCTAssertEqual(key, "birth_date")
        let dateString = String(data: data, encoding: .utf8)
        XCTAssertNotNil(dateString)
        XCTAssertTrue(dateString!.contains("2000-01-01"))
    }

}
