//
//  RecoveryServiceTestCase.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 27.10.23.
//  Copyright © 2023 Soneso. All rights reserved.
//


import XCTest
import stellarsdk

class RecoveryServiceTestCase: XCTestCase {

    let recoveryServer = "127.0.0.1"
    let addressA = "GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP"
    let signingAddress = "GDRUPBJM7YIJ2NUNAIQJDJ2DQ2JDERY5SJVJVMM6MGE4UBDAMXBHARIA"
    let after = "GA5TKKASNJZGZAP6FH65HO77CST7CJNYRTW4YPBNPXYMZAHHMTHDZKDQ"
    let jwtToken =
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJHQTZVSVhYUEVXWUZJTE5VSVdBQzM3WTRRUEVaTVFWREpIREtWV0ZaSjJLQ1dVQklVNUlYWk5EQSIsImp0aSI6IjE0NGQzNjdiY2IwZTcyY2FiZmRiZGU2MGVhZTBhZDczM2NjNjVkMmE2NTg3MDgzZGFiM2Q2MTZmODg1MTkwMjQiLCJpc3MiOiJodHRwczovL2ZsYXBweS1iaXJkLWRhcHAuZmlyZWJhc2VhcHAuY29tLyIsImlhdCI6MTUzNDI1Nzk5NCwiZXhwIjoxNTM0MzQ0Mzk0fQ.8nbB83Z6vGBgC1X9r3N6oQCFTBzDiITAfCJasRft0z0";

    let senderAddrAuth = Sep30AuthMethod(type: "stellar_address", value: "GBUCAAMD7DYS7226CWUUOZ5Y2QF4JBJWIYU3UWJAFDGJVCR6EU5NJM5H")
    let senderPhoneAuth = Sep30AuthMethod(type: "phone_number", value: "+10000000001")
    let senderEmailAuth = Sep30AuthMethod(type: "email", value: "person1@example.com")

    let receiverAddrAuth = Sep30AuthMethod(type: "stellar_address", value: "GDIL76BC2XGDWLDPXCZVYB3AIZX4MYBN6JUBQPAX5OHRWPSNX3XMLNCS")
    let receiverPhoneAuth = Sep30AuthMethod(type: "phone_number", value: "+10000000002")
    let receiverEmailAuth = Sep30AuthMethod(type: "email", value: "person2@example.com")

    var senderIdentity:Sep30RequestIdentity!
    var receiverIdentity:Sep30RequestIdentity!

    let transaction =
        "AAAAAgAAAABswQhbaeSlgckYVKxb8pH08s5tqVVpGXYw1kCpbqv6lQAAAGQAIa4PAAAAAQAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAABQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAACWhlbGxvLmNvbQAAAAAAAAAAAAAAAAAAAA==";
    let signature = "YpVelqPYVKxb8pH08s5AKsYTPwQhbaeSlgcktqwAKsYTPwQhbaeS";
    let networkPassphrase = "Test SDF Network ; September 2015";

    var recoveryService: RecoveryService!
    var sep30RegisterAccountMock: Sep30RegisterAccountResponseMock!
    var sep30UpdateIdentitiesMock: Sep30UpdateIdentitiesResponseMock!
    var sep30SignTransactionMock: Sep30SignTransactionResponseMock!
    var sep30AccountDetailsMock: Sep30AccountDetailsResponseMock!
    var sep30DeleteAccountMock: Sep30DeleteAccountResponseMock!
    var sep30ListAccountsMock: Sep30ListAccountsResponseMock!
    var sep30BadRequestErrMock: Sep30ErrResponseMock!
    var sep30UnauthRequestErrMock: Sep30ErrResponseMock!
    var sep30NotFoundRequestErrMock: Sep30ErrResponseMock!

    override func setUp() {
        super.setUp()

        URLProtocol.registerClass(ServerMock.self)
        sep30RegisterAccountMock = Sep30RegisterAccountResponseMock(host: recoveryServer, address: addressA)
        sep30UpdateIdentitiesMock = Sep30UpdateIdentitiesResponseMock(host: recoveryServer, address: addressA)
        sep30SignTransactionMock = Sep30SignTransactionResponseMock(host: recoveryServer, address: addressA, signingAddress: signingAddress)
        sep30AccountDetailsMock = Sep30AccountDetailsResponseMock(host: recoveryServer, address: addressA)
        sep30DeleteAccountMock = Sep30DeleteAccountResponseMock(host: recoveryServer, address: addressA)
        sep30ListAccountsMock = Sep30ListAccountsResponseMock(host: recoveryServer)
        sep30BadRequestErrMock = Sep30ErrResponseMock(host: recoveryServer, address: "BAD_REQ")
        sep30UnauthRequestErrMock = Sep30ErrResponseMock(host: recoveryServer, address: "UNAUTH")
        sep30NotFoundRequestErrMock = Sep30ErrResponseMock(host: recoveryServer, address: "NOT_FOUND")
        recoveryService = RecoveryService(serviceAddress: "http://\(recoveryServer)")
        senderIdentity = Sep30RequestIdentity(role: "sender", authMethods: [senderAddrAuth, senderPhoneAuth, senderEmailAuth])
        receiverIdentity = Sep30RequestIdentity(role: "receiver", authMethods: [receiverAddrAuth, receiverPhoneAuth, receiverEmailAuth])

    }

    // MARK: - Register Account Tests

    func testRegisterAccount() async {

        let request = Sep30Request(identities: [senderIdentity, receiverIdentity])
        let responseEnum = await recoveryService.registerAccount(address: addressA, request: request, jwt: jwtToken)
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual(self.addressA, response.address)
            XCTAssertEqual(2, response.identities.count)
            XCTAssertEqual(1, response.signers.count)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testRegisterAccountWithSingleIdentity() async {
        let singleIdentityMock = Sep30SingleIdentityResponseMock(host: recoveryServer, address: "SINGLE_IDENTITY")
        let singleIdentityService = RecoveryService(serviceAddress: "http://\(recoveryServer)")

        let ownerAuth = Sep30AuthMethod(type: "stellar_address", value: "GBUCAAMD7DYS7226CWUUOZ5Y2QF4JBJWIYU3UWJAFDGJVCR6EU5NJM5H")
        let ownerIdentity = Sep30RequestIdentity(role: "owner", authMethods: [ownerAuth])
        let request = Sep30Request(identities: [ownerIdentity])

        let responseEnum = await singleIdentityService.registerAccount(address: "SINGLE_IDENTITY", request: request, jwt: jwtToken)
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual(addressA, response.address)
            XCTAssertEqual(1, response.identities.count)
            XCTAssertEqual("owner", response.identities[0].role)
            XCTAssertEqual(1, response.signers.count)
            XCTAssertEqual(signingAddress, response.signers[0].key)
        case .failure(let error):
            XCTFail("Expected success but got failure: \(error.localizedDescription)")
        }

        _ = singleIdentityMock
    }

    func testRegisterAccountConflictError() async {
        let conflictMock = Sep30ErrResponseMock(host: recoveryServer, address: "CONFLICT")

        let request = Sep30Request(identities: [senderIdentity, receiverIdentity])
        let responseEnum = await recoveryService.registerAccount(address: "CONFLICT", request: request, jwt: jwtToken)
        switch responseEnum {
        case .success(_):
            XCTFail("Expected conflict error but got success")
        case .failure(let err):
            switch err {
            case .conflict(let message):
                XCTAssertEqual("account already exists", message)
            default:
                XCTFail("Expected conflict error but got: \(err)")
            }
        }

        _ = conflictMock
    }

    func testRegisterAccountBadRequest() async {
        let request = Sep30Request(identities: [senderIdentity, receiverIdentity])
        let responseEnum = await recoveryService.registerAccount(address: "BAD_REQ", request: request, jwt: jwtToken)
        switch responseEnum {
        case .success(_):
            XCTFail("Expected bad request error but got success")
        case .failure(let err):
            switch err {
            case .badRequest(let message):
                XCTAssertEqual("bad request", message)
            default:
                XCTFail("Expected bad request error but got: \(err)")
            }
        }
    }

    func testRegisterAccountUnauthorized() async {
        let request = Sep30Request(identities: [senderIdentity, receiverIdentity])
        let responseEnum = await recoveryService.registerAccount(address: "UNAUTH", request: request, jwt: jwtToken)
        switch responseEnum {
        case .success(_):
            XCTFail("Expected unauthorized error but got success")
        case .failure(let err):
            switch err {
            case .unauthorized(let message):
                XCTAssertEqual("unauthorized", message)
            default:
                XCTFail("Expected unauthorized error but got: \(err)")
            }
        }
    }

    // MARK: - Update Identities Tests

    func testUpdateIdentities() async {

        let request = Sep30Request(identities: [senderIdentity, receiverIdentity])
        let responseEnum = await recoveryService.updateIdentitiesForAccount(address: addressA, request: request, jwt: jwtToken)
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual(self.addressA, response.address)
            XCTAssertEqual(2, response.identities.count)
            XCTAssertEqual(1, response.signers.count)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testUpdateIdentitiesBadRequest() async {
        let badReqMock = Sep30AccountOperationErrMock(
            host: recoveryServer,
            address: "UPDATE_BAD_REQ",
            httpMethod: "PUT",
            statusCode: 400,
            errorMessage: "invalid identity format"
        )

        let request = Sep30Request(identities: [senderIdentity])
        let responseEnum = await recoveryService.updateIdentitiesForAccount(address: "UPDATE_BAD_REQ", request: request, jwt: jwtToken)
        switch responseEnum {
        case .success(_):
            XCTFail("Expected bad request error but got success")
        case .failure(let err):
            switch err {
            case .badRequest(let message):
                XCTAssertEqual("invalid identity format", message)
            default:
                XCTFail("Expected bad request error but got: \(err)")
            }
        }

        _ = badReqMock
    }

    func testUpdateIdentitiesUnauthorized() async {
        let unauthMock = Sep30AccountOperationErrMock(
            host: recoveryServer,
            address: "UPDATE_UNAUTH",
            httpMethod: "PUT",
            statusCode: 401,
            errorMessage: "token expired"
        )

        let request = Sep30Request(identities: [senderIdentity])
        let responseEnum = await recoveryService.updateIdentitiesForAccount(address: "UPDATE_UNAUTH", request: request, jwt: jwtToken)
        switch responseEnum {
        case .success(_):
            XCTFail("Expected unauthorized error but got success")
        case .failure(let err):
            switch err {
            case .unauthorized(let message):
                XCTAssertEqual("token expired", message)
            default:
                XCTFail("Expected unauthorized error but got: \(err)")
            }
        }

        _ = unauthMock
    }

    func testUpdateIdentitiesNotFound() async {
        let notFoundMock = Sep30AccountOperationErrMock(
            host: recoveryServer,
            address: "UPDATE_NOT_FOUND",
            httpMethod: "PUT",
            statusCode: 404,
            errorMessage: "account not registered"
        )

        let request = Sep30Request(identities: [senderIdentity])
        let responseEnum = await recoveryService.updateIdentitiesForAccount(address: "UPDATE_NOT_FOUND", request: request, jwt: jwtToken)
        switch responseEnum {
        case .success(_):
            XCTFail("Expected not found error but got success")
        case .failure(let err):
            switch err {
            case .notFound(let message):
                XCTAssertEqual("account not registered", message)
            default:
                XCTFail("Expected not found error but got: \(err)")
            }
        }

        _ = notFoundMock
    }

    func testUpdateIdentitiesConflict() async {
        let conflictMock = Sep30AccountOperationErrMock(
            host: recoveryServer,
            address: "UPDATE_CONFLICT",
            httpMethod: "PUT",
            statusCode: 409,
            errorMessage: "identity already exists"
        )

        let request = Sep30Request(identities: [senderIdentity])
        let responseEnum = await recoveryService.updateIdentitiesForAccount(address: "UPDATE_CONFLICT", request: request, jwt: jwtToken)
        switch responseEnum {
        case .success(_):
            XCTFail("Expected conflict error but got success")
        case .failure(let err):
            switch err {
            case .conflict(let message):
                XCTAssertEqual("identity already exists", message)
            default:
                XCTFail("Expected conflict error but got: \(err)")
            }
        }

        _ = conflictMock
    }

    // MARK: - Sign Transaction Tests

    func testSignTransaction() async {
        let responseEnum = await recoveryService.signTransaction(address: addressA, signingAddress: signingAddress, transaction:transaction, jwt: jwtToken)
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual(self.signature, response.signature)
            XCTAssertEqual(self.networkPassphrase, response.networkPassphrase)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testSignTransactionBadRequest() async {
        let badReqMock = Sep30SignTransactionErrMock(
            host: recoveryServer,
            address: "BAD_REQ",
            signingAddress: signingAddress
        )

        let responseEnum = await recoveryService.signTransaction(
            address: "BAD_REQ",
            signingAddress: signingAddress,
            transaction: transaction,
            jwt: jwtToken
        )
        switch responseEnum {
        case .success(_):
            XCTFail("Expected bad request error but got success")
        case .failure(let err):
            switch err {
            case .badRequest(let message):
                XCTAssertEqual("invalid transaction format", message)
            default:
                XCTFail("Expected bad request error but got: \(err)")
            }
        }

        _ = badReqMock
    }

    func testSignTransactionUnauthorized() async {
        let unauthMock = Sep30SignTransactionErrMock(
            host: recoveryServer,
            address: "UNAUTH",
            signingAddress: signingAddress
        )

        let responseEnum = await recoveryService.signTransaction(
            address: "UNAUTH",
            signingAddress: signingAddress,
            transaction: transaction,
            jwt: jwtToken
        )
        switch responseEnum {
        case .success(_):
            XCTFail("Expected unauthorized error but got success")
        case .failure(let err):
            switch err {
            case .unauthorized(let message):
                XCTAssertEqual("jwt token expired", message)
            default:
                XCTFail("Expected unauthorized error but got: \(err)")
            }
        }

        _ = unauthMock
    }

    func testSignTransactionNotFound() async {
        let notFoundMock = Sep30SignTransactionErrMock(
            host: recoveryServer,
            address: "NOT_FOUND",
            signingAddress: signingAddress
        )

        let responseEnum = await recoveryService.signTransaction(
            address: "NOT_FOUND",
            signingAddress: signingAddress,
            transaction: transaction,
            jwt: jwtToken
        )
        switch responseEnum {
        case .success(_):
            XCTFail("Expected not found error but got success")
        case .failure(let err):
            switch err {
            case .notFound(let message):
                XCTAssertEqual("account not found", message)
            default:
                XCTFail("Expected not found error but got: \(err)")
            }
        }

        _ = notFoundMock
    }

    func testSignTransactionInvalidSigner() async {
        let invalidSignerMock = Sep30SignTransactionErrMock(
            host: recoveryServer,
            address: addressA,
            signingAddress: "INVALID_SIGNER"
        )

        let responseEnum = await recoveryService.signTransaction(
            address: addressA,
            signingAddress: "INVALID_SIGNER",
            transaction: transaction,
            jwt: jwtToken
        )
        switch responseEnum {
        case .success(_):
            XCTFail("Expected not found error for invalid signer but got success")
        case .failure(let err):
            switch err {
            case .notFound(let message):
                XCTAssertEqual("signer not found for account", message)
            default:
                XCTFail("Expected not found error but got: \(err)")
            }
        }

        _ = invalidSignerMock
    }

    // MARK: - Account Details Tests

    func testAccountDetails() async {
        let responseEnum = await recoveryService.accountDetails(address: addressA, jwt: jwtToken)
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual(self.addressA, response.address)
            XCTAssertEqual(2, response.identities.count)
            XCTAssertEqual(1, response.signers.count)
            XCTAssertTrue(response.identities[0].authenticated!)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testAccountDetailsBadRequest() async {
        let badReqMock = Sep30AccountOperationErrMock(
            host: recoveryServer,
            address: "DETAILS_BAD_REQ",
            httpMethod: "GET",
            statusCode: 400,
            errorMessage: "malformed account address"
        )

        let responseEnum = await recoveryService.accountDetails(address: "DETAILS_BAD_REQ", jwt: jwtToken)
        switch responseEnum {
        case .success(_):
            XCTFail("Expected bad request error but got success")
        case .failure(let err):
            switch err {
            case .badRequest(let message):
                XCTAssertEqual("malformed account address", message)
            default:
                XCTFail("Expected bad request error but got: \(err)")
            }
        }

        _ = badReqMock
    }

    func testAccountDetailsUnauthorized() async {
        let unauthMock = Sep30AccountOperationErrMock(
            host: recoveryServer,
            address: "DETAILS_UNAUTH",
            httpMethod: "GET",
            statusCode: 401,
            errorMessage: "invalid jwt signature"
        )

        let responseEnum = await recoveryService.accountDetails(address: "DETAILS_UNAUTH", jwt: jwtToken)
        switch responseEnum {
        case .success(_):
            XCTFail("Expected unauthorized error but got success")
        case .failure(let err):
            switch err {
            case .unauthorized(let message):
                XCTAssertEqual("invalid jwt signature", message)
            default:
                XCTFail("Expected unauthorized error but got: \(err)")
            }
        }

        _ = unauthMock
    }

    func testAccountDetailsNotFound() async {
        let notFoundMock = Sep30AccountOperationErrMock(
            host: recoveryServer,
            address: "DETAILS_NOT_FOUND",
            httpMethod: "GET",
            statusCode: 404,
            errorMessage: "no account registered with this address"
        )

        let responseEnum = await recoveryService.accountDetails(address: "DETAILS_NOT_FOUND", jwt: jwtToken)
        switch responseEnum {
        case .success(_):
            XCTFail("Expected not found error but got success")
        case .failure(let err):
            switch err {
            case .notFound(let message):
                XCTAssertEqual("no account registered with this address", message)
            default:
                XCTFail("Expected not found error but got: \(err)")
            }
        }

        _ = notFoundMock
    }

    func testAccountDetailsWithMultipleSigners() async {
        let multipleSignersMock = Sep30MultipleSignersResponseMock(
            host: recoveryServer,
            address: "MULTI_SIGNERS"
        )

        let responseEnum = await recoveryService.accountDetails(address: "MULTI_SIGNERS", jwt: jwtToken)
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual(addressA, response.address)
            XCTAssertEqual(3, response.identities.count)
            XCTAssertEqual("owner", response.identities[0].role)
            XCTAssertEqual("sender", response.identities[1].role)
            XCTAssertEqual("receiver", response.identities[2].role)
            XCTAssertTrue(response.identities[0].authenticated!)
            XCTAssertNil(response.identities[1].authenticated)
            XCTAssertNil(response.identities[2].authenticated)
            XCTAssertEqual(3, response.signers.count)
            XCTAssertEqual(signingAddress, response.signers[0].key)
            XCTAssertEqual("GBTPAH6NWK25GESZYJ3XWPTNQUIMYNK7VU7R4NSTMZXOEKCOBKJVJ2XY", response.signers[1].key)
            XCTAssertEqual("GAOCJE4737GYN2EGCGWPNNCDVDKX7XKC4UKOKIF7CRRYIFLPZLH3U3UN", response.signers[2].key)
        case .failure(let error):
            XCTFail("Expected success but got failure: \(error.localizedDescription)")
        }

        _ = multipleSignersMock
    }

    // MARK: - Delete Account Tests

    func testDeleteAccount() async {
        let responseEnum = await recoveryService.deleteAccount(address: addressA, jwt: jwtToken)
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual(self.addressA, response.address)
            XCTAssertEqual(2, response.identities.count)
            XCTAssertEqual(1, response.signers.count)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testDeleteAccountBadRequest() async {
        let badReqMock = Sep30AccountOperationErrMock(
            host: recoveryServer,
            address: "DELETE_BAD_REQ",
            httpMethod: "DELETE",
            statusCode: 400,
            errorMessage: "invalid request format"
        )

        let responseEnum = await recoveryService.deleteAccount(address: "DELETE_BAD_REQ", jwt: jwtToken)
        switch responseEnum {
        case .success(_):
            XCTFail("Expected bad request error but got success")
        case .failure(let err):
            switch err {
            case .badRequest(let message):
                XCTAssertEqual("invalid request format", message)
            default:
                XCTFail("Expected bad request error but got: \(err)")
            }
        }

        _ = badReqMock
    }

    func testDeleteAccountUnauthorized() async {
        let unauthMock = Sep30AccountOperationErrMock(
            host: recoveryServer,
            address: "DELETE_UNAUTH",
            httpMethod: "DELETE",
            statusCode: 401,
            errorMessage: "not authorized to delete this account"
        )

        let responseEnum = await recoveryService.deleteAccount(address: "DELETE_UNAUTH", jwt: jwtToken)
        switch responseEnum {
        case .success(_):
            XCTFail("Expected unauthorized error but got success")
        case .failure(let err):
            switch err {
            case .unauthorized(let message):
                XCTAssertEqual("not authorized to delete this account", message)
            default:
                XCTFail("Expected unauthorized error but got: \(err)")
            }
        }

        _ = unauthMock
    }

    func testDeleteAccountNotFound() async {
        let notFoundMock = Sep30AccountOperationErrMock(
            host: recoveryServer,
            address: "DELETE_NOT_FOUND",
            httpMethod: "DELETE",
            statusCode: 404,
            errorMessage: "account does not exist"
        )

        let responseEnum = await recoveryService.deleteAccount(address: "DELETE_NOT_FOUND", jwt: jwtToken)
        switch responseEnum {
        case .success(_):
            XCTFail("Expected not found error but got success")
        case .failure(let err):
            switch err {
            case .notFound(let message):
                XCTAssertEqual("account does not exist", message)
            default:
                XCTFail("Expected not found error but got: \(err)")
            }
        }

        _ = notFoundMock
    }

    // MARK: - List Accounts Tests

    func testListAccounts() async {
        let responseEnum = await recoveryService.accounts(jwt: jwtToken, after: after)
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual(3, response.accounts.count)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testListAccountsWithPagination() async {
        // Test that the 'after' parameter constructs the correct path by verifying the
        // service can handle paginated responses with various authenticated states
        // Note: This uses the setup mock which returns all 3 accounts
        let responseEnum = await recoveryService.accounts(jwt: jwtToken, after: after)
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual(3, response.accounts.count)
            // Verify authenticated states are properly decoded
            XCTAssertTrue(response.accounts[0].identities[0].authenticated!)
            XCTAssertTrue(response.accounts[1].identities[0].authenticated!)
            XCTAssertNil(response.accounts[1].identities[1].authenticated)
            XCTAssertNil(response.accounts[2].identities[0].authenticated)
            XCTAssertTrue(response.accounts[2].identities[1].authenticated!)
        case .failure(let error):
            XCTFail("Expected success but got failure: \(error.localizedDescription)")
        }
    }

    func testListAccountsEmpty() {
        // Test empty accounts response decoding directly
        let jsonString = """
        {
            "accounts": []
        }
        """

        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()

        do {
            let response = try decoder.decode(Sep30AccountsResponse.self, from: jsonData)
            XCTAssertEqual(0, response.accounts.count)
        } catch {
            XCTFail("Failed to decode empty accounts response: \(error)")
        }
    }

    func testListAccountsWithoutAfterParameter() async {
        // This tests the accounts() method without the 'after' pagination parameter
        // by calling with after: nil (using the setup mock which returns 3 accounts)
        let responseEnum = await recoveryService.accounts(jwt: jwtToken)
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual(3, response.accounts.count)
            XCTAssertEqual("GBND3FJRQBNFJ4ACERGEXUXU4RKK3ZV2N3FRRFU3ONYU6SJUN6EZXPTD", response.accounts[0].address)
            XCTAssertEqual("GA7BLNSL55T2UAON5DYLQHJTR43IPT2O4QG6PAMSNLJJL7JMXKZYYVFJ", response.accounts[1].address)
            XCTAssertEqual("GD62WD2XTOCAENMB34FB2SEW6JHPB7AFYQAJ5OCQ3TYRW5MOJXLKGTMM", response.accounts[2].address)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testRecoveryServiceErrorTypes() {
        // Test that RecoveryServiceError enum cases have correct messages
        let badRequestError = RecoveryServiceError.badRequest(message: "invalid query parameters")
        let unauthorizedError = RecoveryServiceError.unauthorized(message: "missing authorization header")
        let notFoundError = RecoveryServiceError.notFound(message: "account not found")
        let conflictError = RecoveryServiceError.conflict(message: "account already exists")
        let parsingError = RecoveryServiceError.parsingResponseFailed(message: "invalid json")

        switch badRequestError {
        case .badRequest(let message):
            XCTAssertEqual("invalid query parameters", message)
        default:
            XCTFail("Expected badRequest")
        }

        switch unauthorizedError {
        case .unauthorized(let message):
            XCTAssertEqual("missing authorization header", message)
        default:
            XCTFail("Expected unauthorized")
        }

        switch notFoundError {
        case .notFound(let message):
            XCTAssertEqual("account not found", message)
        default:
            XCTFail("Expected notFound")
        }

        switch conflictError {
        case .conflict(let message):
            XCTAssertEqual("account already exists", message)
        default:
            XCTFail("Expected conflict")
        }

        switch parsingError {
        case .parsingResponseFailed(let message):
            XCTAssertEqual("invalid json", message)
        default:
            XCTFail("Expected parsingResponseFailed")
        }
    }

    // MARK: - Response Model Tests

    func testSep30RequestToJson() {
        let ownerAuth = Sep30AuthMethod(type: "stellar_address", value: "GBUCAAMD7DYS7226CWUUOZ5Y2QF4JBJWIYU3UWJAFDGJVCR6EU5NJM5H")
        let ownerIdentity = Sep30RequestIdentity(role: "owner", authMethods: [ownerAuth])
        let request = Sep30Request(identities: [ownerIdentity])

        let json = request.toJson()

        XCTAssertNotNil(json["identities"])
        let identitiesJson = json["identities"] as! [[String: Any]]
        XCTAssertEqual(1, identitiesJson.count)

        let identityJson = identitiesJson[0]
        XCTAssertEqual("owner", identityJson["role"] as? String)

        let authMethodsJson = identityJson["auth_methods"] as! [[String: Any]]
        XCTAssertEqual(1, authMethodsJson.count)
        XCTAssertEqual("stellar_address", authMethodsJson[0]["type"] as? String)
        XCTAssertEqual("GBUCAAMD7DYS7226CWUUOZ5Y2QF4JBJWIYU3UWJAFDGJVCR6EU5NJM5H", authMethodsJson[0]["value"] as? String)
    }

    func testSep30RequestToJsonWithMultipleIdentities() {
        let request = Sep30Request(identities: [senderIdentity, receiverIdentity])

        let json = request.toJson()

        XCTAssertNotNil(json["identities"])
        let identitiesJson = json["identities"] as! [[String: Any]]
        XCTAssertEqual(2, identitiesJson.count)

        let senderJson = identitiesJson[0]
        XCTAssertEqual("sender", senderJson["role"] as? String)
        let senderAuthMethods = senderJson["auth_methods"] as! [[String: Any]]
        XCTAssertEqual(3, senderAuthMethods.count)

        let receiverJson = identitiesJson[1]
        XCTAssertEqual("receiver", receiverJson["role"] as? String)
        let receiverAuthMethods = receiverJson["auth_methods"] as! [[String: Any]]
        XCTAssertEqual(3, receiverAuthMethods.count)
    }

    func testSep30AuthMethodToJson() {
        let authMethod = Sep30AuthMethod(type: "email", value: "test@example.com")
        let json = authMethod.toJson()

        XCTAssertEqual("email", json["type"] as? String)
        XCTAssertEqual("test@example.com", json["value"] as? String)
    }

    func testSep30RequestIdentityToJson() {
        let authMethods = [
            Sep30AuthMethod(type: "stellar_address", value: "GTEST..."),
            Sep30AuthMethod(type: "phone_number", value: "+12025551234"),
            Sep30AuthMethod(type: "email", value: "user@example.com")
        ]
        let identity = Sep30RequestIdentity(role: "owner", authMethods: authMethods)

        let json = identity.toJson()

        XCTAssertEqual("owner", json["role"] as? String)
        let authMethodsJson = json["auth_methods"] as! [[String: Any]]
        XCTAssertEqual(3, authMethodsJson.count)
        XCTAssertEqual("stellar_address", authMethodsJson[0]["type"] as? String)
        XCTAssertEqual("phone_number", authMethodsJson[1]["type"] as? String)
        XCTAssertEqual("email", authMethodsJson[2]["type"] as? String)
    }

    func testSep30SignatureResponseDecoding() {
        let jsonString = """
        {
            "signature": "base64EncodedSignature==",
            "network_passphrase": "Public Global Stellar Network ; September 2015"
        }
        """

        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()

        do {
            let response = try decoder.decode(Sep30SignatureResponse.self, from: jsonData)
            XCTAssertEqual("base64EncodedSignature==", response.signature)
            XCTAssertEqual("Public Global Stellar Network ; September 2015", response.networkPassphrase)
        } catch {
            XCTFail("Failed to decode Sep30SignatureResponse: \(error)")
        }
    }

    func testSep30AccountResponseDecoding() {
        let jsonString = """
        {
            "address": "GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP",
            "identities": [
                { "role": "owner", "authenticated": true },
                { "role": "sender" }
            ],
            "signers": [
                { "key": "GDRUPBJM7YIJ2NUNAIQJDJ2DQ2JDERY5SJVJVMM6MGE4UBDAMXBHARIA" }
            ]
        }
        """

        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()

        do {
            let response = try decoder.decode(Sep30AccountResponse.self, from: jsonData)
            XCTAssertEqual(addressA, response.address)
            XCTAssertEqual(2, response.identities.count)
            XCTAssertEqual("owner", response.identities[0].role)
            XCTAssertTrue(response.identities[0].authenticated!)
            XCTAssertEqual("sender", response.identities[1].role)
            XCTAssertNil(response.identities[1].authenticated)
            XCTAssertEqual(1, response.signers.count)
            XCTAssertEqual(signingAddress, response.signers[0].key)
        } catch {
            XCTFail("Failed to decode Sep30AccountResponse: \(error)")
        }
    }

    func testSep30AccountsResponseDecoding() {
        let jsonString = """
        {
            "accounts": [
                {
                    "address": "GBND3FJRQBNFJ4ACERGEXUXU4RKK3ZV2N3FRRFU3ONYU6SJUN6EZXPTD",
                    "identities": [{ "role": "owner" }],
                    "signers": [{ "key": "GBTPAH6NWK25GESZYJ3XWPTNQUIMYNK7VU7R4NSTMZXOEKCOBKJVJ2XY" }]
                },
                {
                    "address": "GA7BLNSL55T2UAON5DYLQHJTR43IPT2O4QG6PAMSNLJJL7JMXKZYYVFJ",
                    "identities": [{ "role": "sender" }, { "role": "receiver" }],
                    "signers": [{ "key": "GAOCJE4737GYN2EGCGWPNNCDVDKX7XKC4UKOKIF7CRRYIFLPZLH3U3UN" }]
                }
            ]
        }
        """

        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()

        do {
            let response = try decoder.decode(Sep30AccountsResponse.self, from: jsonData)
            XCTAssertEqual(2, response.accounts.count)
            XCTAssertEqual("GBND3FJRQBNFJ4ACERGEXUXU4RKK3ZV2N3FRRFU3ONYU6SJUN6EZXPTD", response.accounts[0].address)
            XCTAssertEqual("GA7BLNSL55T2UAON5DYLQHJTR43IPT2O4QG6PAMSNLJJL7JMXKZYYVFJ", response.accounts[1].address)
        } catch {
            XCTFail("Failed to decode Sep30AccountsResponse: \(error)")
        }
    }

    // MARK: - Legacy Error Tests (Backward Compatibility)

    func testBadReqErr() async {
        let request = Sep30Request(identities: [senderIdentity, receiverIdentity])
        let responseEnum = await recoveryService.registerAccount(address: "BAD_REQ", request: request, jwt: jwtToken)
        switch responseEnum {
        case .success(_):
            XCTFail()
        case .failure(let err):
            switch err {
            case .badRequest(let message):
                XCTAssertEqual("bad request", message)
            default:
                XCTFail()
            }
        }
    }

    func testUnauthorizedErr() async {

        let request = Sep30Request(identities: [senderIdentity, receiverIdentity])
        let responseEnum = await recoveryService.registerAccount(address: "UNAUTH", request: request, jwt: jwtToken)
        switch responseEnum {
        case .success(_):
            XCTFail()
        case .failure(let err):
            switch err {
            case .unauthorized(let message):
                XCTAssertEqual("unauthorized", message)
            default:
                XCTFail()
            }
        }
    }

    func testNotFoundErr() async {

        let request = Sep30Request(identities: [senderIdentity, receiverIdentity])
        let responseEnum = await recoveryService.registerAccount(address: "NOT_FOUND", request: request, jwt: jwtToken)
        switch responseEnum {
        case .success(_):
            XCTFail()
        case .failure(let err):
            switch err {
            case .notFound(let message):
                XCTAssertEqual("not found", message)
            default:
                XCTFail()
            }
        }
    }
}

