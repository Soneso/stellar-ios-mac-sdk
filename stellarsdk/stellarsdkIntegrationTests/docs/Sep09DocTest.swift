//
//  Sep09DocTest.swift
//  stellarsdkTests
//
//  Created for documentation testing.
//

import Foundation
import XCTest
import stellarsdk

class Sep09DocTest: XCTestCase {

    // MARK: - Natural Person Field Key Constants
    // KYCNaturalPersonFieldKey static members are internal to the SDK module.
    // Keys are verified via the public .parameter property of KYCNaturalPersonFieldsEnum.

    func testNaturalPersonFieldKeyConstants() {
        XCTAssertEqual(KYCNaturalPersonFieldsEnum.firstName("x").parameter.0, "first_name")
        XCTAssertEqual(KYCNaturalPersonFieldsEnum.lastName("x").parameter.0, "last_name")
        XCTAssertEqual(KYCNaturalPersonFieldsEnum.additionalName("x").parameter.0, "additional_name")
        XCTAssertEqual(KYCNaturalPersonFieldsEnum.emailAddress("x").parameter.0, "email_address")
        XCTAssertEqual(KYCNaturalPersonFieldsEnum.birthDate(Date()).parameter.0, "birth_date")
        XCTAssertEqual(KYCNaturalPersonFieldsEnum.birthPlace("x").parameter.0, "birth_place")
        XCTAssertEqual(KYCNaturalPersonFieldsEnum.birthCountryCode("x").parameter.0, "birth_country_code")
        XCTAssertEqual(KYCNaturalPersonFieldsEnum.sex("x").parameter.0, "sex")
        XCTAssertEqual(KYCNaturalPersonFieldsEnum.mobileNumber("x").parameter.0, "mobile_number")
        XCTAssertEqual(KYCNaturalPersonFieldsEnum.mobileNumberFormat("x").parameter.0, "mobile_number_format")
        XCTAssertEqual(KYCNaturalPersonFieldsEnum.addressCountryCode("x").parameter.0, "address_country_code")
        XCTAssertEqual(KYCNaturalPersonFieldsEnum.stateOrProvince("x").parameter.0, "state_or_province")
        XCTAssertEqual(KYCNaturalPersonFieldsEnum.city("x").parameter.0, "city")
        XCTAssertEqual(KYCNaturalPersonFieldsEnum.postalCode("x").parameter.0, "postal_code")
        XCTAssertEqual(KYCNaturalPersonFieldsEnum.address("x").parameter.0, "address")
        XCTAssertEqual(KYCNaturalPersonFieldsEnum.occupation(0).parameter.0, "occupation")
        XCTAssertEqual(KYCNaturalPersonFieldsEnum.employerName("x").parameter.0, "employer_name")
        XCTAssertEqual(KYCNaturalPersonFieldsEnum.employerAddress("x").parameter.0, "employer_address")
        XCTAssertEqual(KYCNaturalPersonFieldsEnum.taxId("x").parameter.0, "tax_id")
        XCTAssertEqual(KYCNaturalPersonFieldsEnum.taxIdName("x").parameter.0, "tax_id_name")
        XCTAssertEqual(KYCNaturalPersonFieldsEnum.idType("x").parameter.0, "id_type")
        XCTAssertEqual(KYCNaturalPersonFieldsEnum.idNumber("x").parameter.0, "id_number")
        XCTAssertEqual(KYCNaturalPersonFieldsEnum.idCountryCode("x").parameter.0, "id_country_code")
        XCTAssertEqual(KYCNaturalPersonFieldsEnum.idIssueDate("x").parameter.0, "id_issue_date")
        XCTAssertEqual(KYCNaturalPersonFieldsEnum.idExpirationDate("x").parameter.0, "id_expiration_date")
        XCTAssertEqual(KYCNaturalPersonFieldsEnum.languageCode("x").parameter.0, "language_code")
        XCTAssertEqual(KYCNaturalPersonFieldsEnum.ipAddress("x").parameter.0, "ip_address")
        XCTAssertEqual(KYCNaturalPersonFieldsEnum.referralId("x").parameter.0, "referral_id")
        let stub = Data()
        XCTAssertEqual(KYCNaturalPersonFieldsEnum.photoIdFront(stub).parameter.0, "photo_id_front")
        XCTAssertEqual(KYCNaturalPersonFieldsEnum.photoIdBack(stub).parameter.0, "photo_id_back")
        XCTAssertEqual(KYCNaturalPersonFieldsEnum.notaryApprovalOfPhotoId(stub).parameter.0, "notary_approval_of_photo_id")
        XCTAssertEqual(KYCNaturalPersonFieldsEnum.photoProofResidence(stub).parameter.0, "photo_proof_residence")
        XCTAssertEqual(KYCNaturalPersonFieldsEnum.proofOfIncome(stub).parameter.0, "proof_of_income")
        XCTAssertEqual(KYCNaturalPersonFieldsEnum.proofOfLiveness(stub).parameter.0, "proof_of_liveness")
    }

    // MARK: - Organization Field Key Constants
    // KYCOrganizationFieldKey static members are internal to the SDK module.
    // Keys are verified via the public .parameter property of KYCOrganizationFieldsEnum.

    func testOrganizationFieldKeyConstants() {
        XCTAssertEqual(KYCOrganizationFieldsEnum.name("x").parameter.0, "organization.name")
        XCTAssertEqual(KYCOrganizationFieldsEnum.VATNumber("x").parameter.0, "organization.VAT_number")
        XCTAssertEqual(KYCOrganizationFieldsEnum.registrationNumber("x").parameter.0, "organization.registration_number")
        XCTAssertEqual(KYCOrganizationFieldsEnum.registrationDate("x").parameter.0, "organization.registration_date")
        XCTAssertEqual(KYCOrganizationFieldsEnum.registeredAddress("x").parameter.0, "organization.registered_address")
        XCTAssertEqual(KYCOrganizationFieldsEnum.numberOfShareholders(0).parameter.0, "organization.number_of_shareholders")
        XCTAssertEqual(KYCOrganizationFieldsEnum.shareholderName("x").parameter.0, "organization.shareholder_name")
        XCTAssertEqual(KYCOrganizationFieldsEnum.directorName("x").parameter.0, "organization.director_name")
        XCTAssertEqual(KYCOrganizationFieldsEnum.addressCountryCode("x").parameter.0, "organization.address_country_code")
        XCTAssertEqual(KYCOrganizationFieldsEnum.stateOrProvince("x").parameter.0, "organization.state_or_province")
        XCTAssertEqual(KYCOrganizationFieldsEnum.city("x").parameter.0, "organization.city")
        XCTAssertEqual(KYCOrganizationFieldsEnum.postalCode("x").parameter.0, "organization.postal_code")
        XCTAssertEqual(KYCOrganizationFieldsEnum.website("x").parameter.0, "organization.website")
        XCTAssertEqual(KYCOrganizationFieldsEnum.email("x").parameter.0, "organization.email")
        XCTAssertEqual(KYCOrganizationFieldsEnum.phone("x").parameter.0, "organization.phone")
        let stub = Data()
        XCTAssertEqual(KYCOrganizationFieldsEnum.photoIncorporationDoc(stub).parameter.0, "organization.photo_incorporation_doc")
        XCTAssertEqual(KYCOrganizationFieldsEnum.photoProofAddress(stub).parameter.0, "organization.photo_proof_address")
    }

    // MARK: - Financial Account Field Key Constants
    // KYCFinancialAccountFieldKey static members are internal to the SDK module.
    // Keys are verified via the public .parameter property of KYCFinancialAccountFieldsEnum.

    func testFinancialAccountFieldKeyConstants() {
        XCTAssertEqual(KYCFinancialAccountFieldsEnum.bankName("x").parameter.0, "bank_name")
        XCTAssertEqual(KYCFinancialAccountFieldsEnum.bankAccountType("x").parameter.0, "bank_account_type")
        XCTAssertEqual(KYCFinancialAccountFieldsEnum.bankAccountNumber("x").parameter.0, "bank_account_number")
        XCTAssertEqual(KYCFinancialAccountFieldsEnum.bankNumber("x").parameter.0, "bank_number")
        XCTAssertEqual(KYCFinancialAccountFieldsEnum.bankPhoneNumber("x").parameter.0, "bank_phone_number")
        XCTAssertEqual(KYCFinancialAccountFieldsEnum.bankBranchNumber("x").parameter.0, "bank_branch_number")
        XCTAssertEqual(KYCFinancialAccountFieldsEnum.externalTransferMemo("x").parameter.0, "external_transfer_memo")
        XCTAssertEqual(KYCFinancialAccountFieldsEnum.clabeNumber("x").parameter.0, "clabe_number")
        XCTAssertEqual(KYCFinancialAccountFieldsEnum.cbuNumber("x").parameter.0, "cbu_number")
        XCTAssertEqual(KYCFinancialAccountFieldsEnum.cbuAlias("x").parameter.0, "cbu_alias")
        XCTAssertEqual(KYCFinancialAccountFieldsEnum.mobileMoneyNumber("x").parameter.0, "mobile_money_number")
        XCTAssertEqual(KYCFinancialAccountFieldsEnum.mobileMoneyProvider("x").parameter.0, "mobile_money_provider")
        XCTAssertEqual(KYCFinancialAccountFieldsEnum.cryptoAddress("x").parameter.0, "crypto_address")
        XCTAssertEqual(KYCFinancialAccountFieldsEnum.cryptoMemo("x").parameter.0, "crypto_memo")
    }

    // MARK: - Card Field Key Constants
    // KYCCardFieldKey static members are internal to the SDK module.
    // Keys are verified via the public .parameter property of KYCCardFieldsEnum.

    func testCardFieldKeyConstants() {
        XCTAssertEqual(KYCCardFieldsEnum.number("x").parameter.0, "card.number")
        XCTAssertEqual(KYCCardFieldsEnum.expirationDate("x").parameter.0, "card.expiration_date")
        XCTAssertEqual(KYCCardFieldsEnum.cvc("x").parameter.0, "card.cvc")
        XCTAssertEqual(KYCCardFieldsEnum.holderName("x").parameter.0, "card.holder_name")
        XCTAssertEqual(KYCCardFieldsEnum.network("x").parameter.0, "card.network")
        XCTAssertEqual(KYCCardFieldsEnum.postalCode("x").parameter.0, "card.postal_code")
        XCTAssertEqual(KYCCardFieldsEnum.countryCode("x").parameter.0, "card.country_code")
        XCTAssertEqual(KYCCardFieldsEnum.stateOrProvince("x").parameter.0, "card.state_or_province")
        XCTAssertEqual(KYCCardFieldsEnum.city("x").parameter.0, "card.city")
        XCTAssertEqual(KYCCardFieldsEnum.address("x").parameter.0, "card.address")
        XCTAssertEqual(KYCCardFieldsEnum.token("x").parameter.0, "card.token")
    }

    // MARK: - Natural Person Fields Enum Parameter Tests

    func testNaturalPersonStringFieldsParameter() {
        // Test that .parameter returns the correct key and UTF-8 encoded value
        let firstNameField = KYCNaturalPersonFieldsEnum.firstName("Maria")
        let (key, data) = firstNameField.parameter
        XCTAssertEqual(key, "first_name")
        XCTAssertEqual(String(data: data, encoding: .utf8), "Maria")

        let lastNameField = KYCNaturalPersonFieldsEnum.lastName("Garcia")
        let (lastKey, lastData) = lastNameField.parameter
        XCTAssertEqual(lastKey, "last_name")
        XCTAssertEqual(String(data: lastData, encoding: .utf8), "Garcia")

        let emailField = KYCNaturalPersonFieldsEnum.emailAddress("maria@example.com")
        let (emailKey, emailData) = emailField.parameter
        XCTAssertEqual(emailKey, "email_address")
        XCTAssertEqual(String(data: emailData, encoding: .utf8), "maria@example.com")

        let mobileField = KYCNaturalPersonFieldsEnum.mobileNumber("+34612345678")
        let (mobileKey, mobileData) = mobileField.parameter
        XCTAssertEqual(mobileKey, "mobile_number")
        XCTAssertEqual(String(data: mobileData, encoding: .utf8), "+34612345678")

        let idTypeField = KYCNaturalPersonFieldsEnum.idType("passport")
        let (idTypeKey, idTypeData) = idTypeField.parameter
        XCTAssertEqual(idTypeKey, "id_type")
        XCTAssertEqual(String(data: idTypeData, encoding: .utf8), "passport")

        let idIssueDateField = KYCNaturalPersonFieldsEnum.idIssueDate("2020-01-15")
        let (idIssueDateKey, idIssueDateData) = idIssueDateField.parameter
        XCTAssertEqual(idIssueDateKey, "id_issue_date")
        XCTAssertEqual(String(data: idIssueDateData, encoding: .utf8), "2020-01-15")

        let idExpirationDateField = KYCNaturalPersonFieldsEnum.idExpirationDate("2030-01-14")
        let (idExpKey, idExpData) = idExpirationDateField.parameter
        XCTAssertEqual(idExpKey, "id_expiration_date")
        XCTAssertEqual(String(data: idExpData, encoding: .utf8), "2030-01-14")

        let referralField = KYCNaturalPersonFieldsEnum.referralId("partner-12345")
        let (refKey, refData) = referralField.parameter
        XCTAssertEqual(refKey, "referral_id")
        XCTAssertEqual(String(data: refData, encoding: .utf8), "partner-12345")
    }

    func testNaturalPersonBirthDateParameter() {
        // birthDate takes a Date and formats it via DateFormatter.iso8601
        let dateComponents = DateComponents(year: 1990, month: 5, day: 15)
        let calendar = Calendar(identifier: .gregorian)
        let birthDate = calendar.date(from: dateComponents)!

        let field = KYCNaturalPersonFieldsEnum.birthDate(birthDate)
        let (key, data) = field.parameter
        XCTAssertEqual(key, "birth_date")

        let dateString = String(data: data, encoding: .utf8)!
        // The formatted date should contain "1990"
        XCTAssertTrue(dateString.contains("1990"), "Birth date string should contain year 1990, got: \(dateString)")
    }

    func testNaturalPersonOccupationParameter() {
        // occupation takes an Int
        let field = KYCNaturalPersonFieldsEnum.occupation(2511)
        let (key, _) = field.parameter
        XCTAssertEqual(key, "occupation")
    }

    func testNaturalPersonBinaryFieldsParameter() {
        // Binary fields return the raw Data with the correct key
        let testData = "fake-image-bytes".data(using: .utf8)!

        let photoFront = KYCNaturalPersonFieldsEnum.photoIdFront(testData)
        let (frontKey, frontData) = photoFront.parameter
        XCTAssertEqual(frontKey, "photo_id_front")
        XCTAssertEqual(frontData, testData)

        let photoBack = KYCNaturalPersonFieldsEnum.photoIdBack(testData)
        let (backKey, backData) = photoBack.parameter
        XCTAssertEqual(backKey, "photo_id_back")
        XCTAssertEqual(backData, testData)

        let notary = KYCNaturalPersonFieldsEnum.notaryApprovalOfPhotoId(testData)
        let (notaryKey, notaryData) = notary.parameter
        XCTAssertEqual(notaryKey, "notary_approval_of_photo_id")
        XCTAssertEqual(notaryData, testData)

        let residence = KYCNaturalPersonFieldsEnum.photoProofResidence(testData)
        let (resKey, resData) = residence.parameter
        XCTAssertEqual(resKey, "photo_proof_residence")
        XCTAssertEqual(resData, testData)

        let income = KYCNaturalPersonFieldsEnum.proofOfIncome(testData)
        let (incKey, incData) = income.parameter
        XCTAssertEqual(incKey, "proof_of_income")
        XCTAssertEqual(incData, testData)

        let liveness = KYCNaturalPersonFieldsEnum.proofOfLiveness(testData)
        let (liveKey, liveData) = liveness.parameter
        XCTAssertEqual(liveKey, "proof_of_liveness")
        XCTAssertEqual(liveData, testData)
    }

    // MARK: - Organization Fields Enum Parameter Tests

    func testOrganizationFieldsParameter() {
        let nameField = KYCOrganizationFieldsEnum.name("Acme Corporation S.L.")
        let (nameKey, nameData) = nameField.parameter
        XCTAssertEqual(nameKey, "organization.name")
        XCTAssertEqual(String(data: nameData, encoding: .utf8), "Acme Corporation S.L.")

        let vatField = KYCOrganizationFieldsEnum.VATNumber("ESB12345678")
        let (vatKey, vatData) = vatField.parameter
        XCTAssertEqual(vatKey, "organization.VAT_number")
        XCTAssertEqual(String(data: vatData, encoding: .utf8), "ESB12345678")

        let regNumField = KYCOrganizationFieldsEnum.registrationNumber("B-12345678")
        let (regKey, regData) = regNumField.parameter
        XCTAssertEqual(regKey, "organization.registration_number")
        XCTAssertEqual(String(data: regData, encoding: .utf8), "B-12345678")

        let regDateField = KYCOrganizationFieldsEnum.registrationDate("2015-06-01")
        let (regDateKey, regDateData) = regDateField.parameter
        XCTAssertEqual(regDateKey, "organization.registration_date")
        XCTAssertEqual(String(data: regDateData, encoding: .utf8), "2015-06-01")

        let directorField = KYCOrganizationFieldsEnum.directorName("Jane Doe")
        let (dirKey, dirData) = directorField.parameter
        XCTAssertEqual(dirKey, "organization.director_name")
        XCTAssertEqual(String(data: dirData, encoding: .utf8), "Jane Doe")

        let websiteField = KYCOrganizationFieldsEnum.website("https://acme-corp.example.com")
        let (webKey, webData) = websiteField.parameter
        XCTAssertEqual(webKey, "organization.website")
        XCTAssertEqual(String(data: webData, encoding: .utf8), "https://acme-corp.example.com")
    }

    func testOrganizationNumberOfShareholdersParameter() {
        // numberOfShareholders takes an Int
        let field = KYCOrganizationFieldsEnum.numberOfShareholders(3)
        let (key, _) = field.parameter
        XCTAssertEqual(key, "organization.number_of_shareholders")
    }

    func testOrganizationBinaryFieldsParameter() {
        let testData = "fake-pdf-bytes".data(using: .utf8)!

        let incDoc = KYCOrganizationFieldsEnum.photoIncorporationDoc(testData)
        let (incKey, incData) = incDoc.parameter
        XCTAssertEqual(incKey, "organization.photo_incorporation_doc")
        XCTAssertEqual(incData, testData)

        let proofAddr = KYCOrganizationFieldsEnum.photoProofAddress(testData)
        let (addrKey, addrData) = proofAddr.parameter
        XCTAssertEqual(addrKey, "organization.photo_proof_address")
        XCTAssertEqual(addrData, testData)
    }

    // MARK: - Financial Account Fields Enum Parameter Tests

    func testFinancialAccountFieldsParameter() {
        let bankNameField = KYCFinancialAccountFieldsEnum.bankName("First National Bank")
        let (bnKey, bnData) = bankNameField.parameter
        XCTAssertEqual(bnKey, "bank_name")
        XCTAssertEqual(String(data: bnData, encoding: .utf8), "First National Bank")

        let accountTypeField = KYCFinancialAccountFieldsEnum.bankAccountType("checking")
        let (atKey, atData) = accountTypeField.parameter
        XCTAssertEqual(atKey, "bank_account_type")
        XCTAssertEqual(String(data: atData, encoding: .utf8), "checking")

        let accountNumField = KYCFinancialAccountFieldsEnum.bankAccountNumber("123456789012")
        let (anKey, anData) = accountNumField.parameter
        XCTAssertEqual(anKey, "bank_account_number")
        XCTAssertEqual(String(data: anData, encoding: .utf8), "123456789012")

        let routingField = KYCFinancialAccountFieldsEnum.bankNumber("021000021")
        let (rKey, rData) = routingField.parameter
        XCTAssertEqual(rKey, "bank_number")
        XCTAssertEqual(String(data: rData, encoding: .utf8), "021000021")

        let clabeField = KYCFinancialAccountFieldsEnum.clabeNumber("012345678901234567")
        let (clKey, clData) = clabeField.parameter
        XCTAssertEqual(clKey, "clabe_number")
        XCTAssertEqual(String(data: clData, encoding: .utf8), "012345678901234567")

        let cbuField = KYCFinancialAccountFieldsEnum.cbuNumber("0123456789012345678901")
        let (cbuKey, cbuData) = cbuField.parameter
        XCTAssertEqual(cbuKey, "cbu_number")
        XCTAssertEqual(String(data: cbuData, encoding: .utf8), "0123456789012345678901")

        let mobileMoneyField = KYCFinancialAccountFieldsEnum.mobileMoneyNumber("+254712345678")
        let (mmKey, mmData) = mobileMoneyField.parameter
        XCTAssertEqual(mmKey, "mobile_money_number")
        XCTAssertEqual(String(data: mmData, encoding: .utf8), "+254712345678")

        let cryptoField = KYCFinancialAccountFieldsEnum.cryptoAddress("GBH4TZYZ4IRCPO44CBOLFUHULU2WGALXTAVESQA6432MBJMABBB4GIYI")
        let (crKey, crData) = cryptoField.parameter
        XCTAssertEqual(crKey, "crypto_address")
        XCTAssertEqual(String(data: crData, encoding: .utf8), "GBH4TZYZ4IRCPO44CBOLFUHULU2WGALXTAVESQA6432MBJMABBB4GIYI")

        let memoField = KYCFinancialAccountFieldsEnum.externalTransferMemo("user-12345")
        let (memoKey, memoData) = memoField.parameter
        XCTAssertEqual(memoKey, "external_transfer_memo")
        XCTAssertEqual(String(data: memoData, encoding: .utf8), "user-12345")
    }

    // MARK: - Card Fields Enum Parameter Tests

    func testCardFieldsParameter() {
        let numberField = KYCCardFieldsEnum.number("4111111111111111")
        let (numKey, numData) = numberField.parameter
        XCTAssertEqual(numKey, "card.number")
        XCTAssertEqual(String(data: numData, encoding: .utf8), "4111111111111111")

        let expField = KYCCardFieldsEnum.expirationDate("29-11")
        let (expKey, expData) = expField.parameter
        XCTAssertEqual(expKey, "card.expiration_date")
        XCTAssertEqual(String(data: expData, encoding: .utf8), "29-11")

        let cvcField = KYCCardFieldsEnum.cvc("123")
        let (cvcKey, cvcData) = cvcField.parameter
        XCTAssertEqual(cvcKey, "card.cvc")
        XCTAssertEqual(String(data: cvcData, encoding: .utf8), "123")

        let holderField = KYCCardFieldsEnum.holderName("JOHN DOE")
        let (holderKey, holderData) = holderField.parameter
        XCTAssertEqual(holderKey, "card.holder_name")
        XCTAssertEqual(String(data: holderData, encoding: .utf8), "JOHN DOE")

        let networkField = KYCCardFieldsEnum.network("Visa")
        let (netKey, netData) = networkField.parameter
        XCTAssertEqual(netKey, "card.network")
        XCTAssertEqual(String(data: netData, encoding: .utf8), "Visa")

        let tokenField = KYCCardFieldsEnum.token("tok_visa_4242")
        let (tokKey, tokData) = tokenField.parameter
        XCTAssertEqual(tokKey, "card.token")
        XCTAssertEqual(String(data: tokData, encoding: .utf8), "tok_visa_4242")

        let countryField = KYCCardFieldsEnum.countryCode("US")
        let (ccKey, ccData) = countryField.parameter
        XCTAssertEqual(ccKey, "card.country_code")
        XCTAssertEqual(String(data: ccData, encoding: .utf8), "US")
    }

    // MARK: - PutCustomerInfoRequest Tests

    func testPutCustomerInfoRequestWithNaturalPersonFields() {
        var request = PutCustomerInfoRequest(jwt: "test-jwt-token")
        request.fields = [
            .firstName("John"),
            .lastName("Doe"),
            .emailAddress("john@example.com"),
        ]

        let params = request.toParameters()

        // Verify text fields are present
        XCTAssertEqual(String(data: params["first_name"]!, encoding: .utf8), "John")
        XCTAssertEqual(String(data: params["last_name"]!, encoding: .utf8), "Doe")
        XCTAssertEqual(String(data: params["email_address"]!, encoding: .utf8), "john@example.com")
    }

    func testPutCustomerInfoRequestWithOrganizationFields() {
        var request = PutCustomerInfoRequest(jwt: "test-jwt-token")
        request.organizationFields = [
            .name("Acme Corp"),
            .VATNumber("US12-3456789"),
            .city("Madrid"),
        ]

        let params = request.toParameters()

        XCTAssertEqual(String(data: params["organization.name"]!, encoding: .utf8), "Acme Corp")
        XCTAssertEqual(String(data: params["organization.VAT_number"]!, encoding: .utf8), "US12-3456789")
        XCTAssertEqual(String(data: params["organization.city"]!, encoding: .utf8), "Madrid")
    }

    func testPutCustomerInfoRequestWithFinancialAccountFields() {
        var request = PutCustomerInfoRequest(jwt: "test-jwt-token")
        request.financialAccountFields = [
            .bankName("Business Bank"),
            .bankAccountNumber("9876543210"),
            .bankNumber("021000021"),
        ]

        let params = request.toParameters()

        XCTAssertEqual(String(data: params["bank_name"]!, encoding: .utf8), "Business Bank")
        XCTAssertEqual(String(data: params["bank_account_number"]!, encoding: .utf8), "9876543210")
        XCTAssertEqual(String(data: params["bank_number"]!, encoding: .utf8), "021000021")
    }

    func testPutCustomerInfoRequestWithCardFields() {
        var request = PutCustomerInfoRequest(jwt: "test-jwt-token")
        request.cardFields = [
            .number("4111111111111111"),
            .expirationDate("29-11"),
            .cvc("123"),
            .holderName("JOHN DOE"),
            .countryCode("US"),
        ]

        let params = request.toParameters()

        XCTAssertEqual(String(data: params["card.number"]!, encoding: .utf8), "4111111111111111")
        XCTAssertEqual(String(data: params["card.expiration_date"]!, encoding: .utf8), "29-11")
        XCTAssertEqual(String(data: params["card.cvc"]!, encoding: .utf8), "123")
        XCTAssertEqual(String(data: params["card.holder_name"]!, encoding: .utf8), "JOHN DOE")
        XCTAssertEqual(String(data: params["card.country_code"]!, encoding: .utf8), "US")
    }

    func testPutCustomerInfoRequestBinaryFieldsSeparation() {
        // Verify that binary fields are placed in the parameters (at the end internally)
        let testImageData = "fake-image".data(using: .utf8)!

        var request = PutCustomerInfoRequest(jwt: "test-jwt-token")
        request.fields = [
            .firstName("John"),
            .lastName("Doe"),
            .photoIdFront(testImageData),
            .photoIdBack(testImageData),
        ]

        let params = request.toParameters()

        // Text fields should be present
        XCTAssertEqual(String(data: params["first_name"]!, encoding: .utf8), "John")
        XCTAssertEqual(String(data: params["last_name"]!, encoding: .utf8), "Doe")

        // Binary fields should also be present
        XCTAssertEqual(params["photo_id_front"], testImageData)
        XCTAssertEqual(params["photo_id_back"], testImageData)
    }

    func testPutCustomerInfoRequestCombinedOrgAndFinancialFields() {
        // Test combining organization fields with financial account fields
        var request = PutCustomerInfoRequest(jwt: "test-jwt-token")
        request.organizationFields = [
            .name("Acme Corp"),
            .VATNumber("US12-3456789"),
        ]
        request.financialAccountFields = [
            .bankName("Business Bank"),
            .bankAccountNumber("9876543210"),
        ]

        let params = request.toParameters()

        // Both organization and financial account fields should be present
        XCTAssertEqual(String(data: params["organization.name"]!, encoding: .utf8), "Acme Corp")
        XCTAssertEqual(String(data: params["organization.VAT_number"]!, encoding: .utf8), "US12-3456789")
        XCTAssertEqual(String(data: params["bank_name"]!, encoding: .utf8), "Business Bank")
        XCTAssertEqual(String(data: params["bank_account_number"]!, encoding: .utf8), "9876543210")
    }

    func testPutCustomerInfoRequestMetadataFields() {
        var request = PutCustomerInfoRequest(jwt: "test-jwt-token")
        request.id = "customer-123"
        request.account = "GABC..."
        request.memo = "12345"
        request.memoType = "id"
        request.type = "sep31-receiver"
        request.transactionId = "tx-456"

        let params = request.toParameters()

        XCTAssertEqual(String(data: params["id"]!, encoding: .utf8), "customer-123")
        XCTAssertEqual(String(data: params["account"]!, encoding: .utf8), "GABC...")
        XCTAssertEqual(String(data: params["memo"]!, encoding: .utf8), "12345")
        XCTAssertEqual(String(data: params["memo_type"]!, encoding: .utf8), "id")
        XCTAssertEqual(String(data: params["type"]!, encoding: .utf8), "sep31-receiver")
        XCTAssertEqual(String(data: params["transaction_id"]!, encoding: .utf8), "tx-456")
    }

    func testPutCustomerInfoRequestExtraFields() {
        var request = PutCustomerInfoRequest(jwt: "test-jwt-token")
        request.fields = [
            .firstName("John"),
        ]
        request.extraFields = ["custom_field": "custom_value"]

        let params = request.toParameters()

        XCTAssertEqual(String(data: params["first_name"]!, encoding: .utf8), "John")
        XCTAssertEqual(String(data: params["custom_field"]!, encoding: .utf8), "custom_value")
    }
}
