//
//  KycServerTestCase.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 31.05.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

final class KycServerTestCase: XCTestCase {

    let kycServer = "127.0.0.1"
    
    let successAccount = "GDIODQRBHD32QZWTGOHO2MRZQY2TRG5KTI2NNTFYH2JDYZGMU3NJVAUI"
    let unauthorizedCustomerAccount = "GBTMF7Y4S7S3ZMYLIU5MLVEECJETO7FYIZ5OH3GBDD7W3Z4A6556RTMC"
    let errorAccount = "GBYLNNAUUJQ7YJSGIATU432IJP2QYTTPKIY5AFWT7LFZAIT76QYVLTAG"
    
    var kycService: KycService!
    var putCustomerInfoServerMock: PutCustomerInfoResponseMock!
    var getCustomerResponseServerMock:GetCustomerResponseMock!
    var putVerificationResponseServerMock:PutVerificationResponseMock!
    var deleteCustomerInfoResponseMock: DeleteCustomerInfoResponseMock!
    var putCallbackUrlResponseServerMock:PutCallbackUrlResponseMock!
    
    override func setUp() {
        super.setUp()
        
        URLProtocol.registerClass(ServerMock.self)
        
        putCustomerInfoServerMock = PutCustomerInfoResponseMock(address: kycServer)
        getCustomerResponseServerMock = GetCustomerResponseMock(address: kycServer)
        putVerificationResponseServerMock = PutVerificationResponseMock(address: kycServer)
        deleteCustomerInfoResponseMock = DeleteCustomerInfoResponseMock(address: kycServer)
        putCallbackUrlResponseServerMock = PutCallbackUrlResponseMock(address: kycServer)
        kycService = KycService(kycServiceAddress: "http://\(kycServer)")
    }
    
    override func tearDown() {
        
        
        super.tearDown()
    }
    
    func testPutCustomerInfoSuccess() {
        var request = PutCustomerInfoRequest(jwt: "200_jwt")
        request.fields = [KYCNaturalPersonFieldsEnum.firstName("John"), KYCNaturalPersonFieldsEnum.lastName("Doe")];
        let expectation = XCTestExpectation(description: "Test put customer info success")
        
        kycService.putCustomerInfo(request: request) { (response) -> (Void) in
            switch response {
            case .success:
                XCTAssert(true)
            case .failure(_):
                XCTAssert(false)
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 15.0)
    }
    
    
    func testPutCustomerInfoNotFound() {
        var request = PutCustomerInfoRequest(jwt: "404_jwt")
        request.fields = [KYCNaturalPersonFieldsEnum.firstName("Max"), KYCNaturalPersonFieldsEnum.lastName("Man")];
        let expectation = XCTestExpectation(description: "Test put customer info not found")
        
        kycService.putCustomerInfo(request: request) { (response) -> (Void) in
            switch response {
            case .success:
                XCTAssert(false)
            case .failure(let error):
                switch error {
                case .notFound(let message):
                    XCTAssert(message == "customer with `id` not found")
                    XCTAssert(true)
                default:
                    XCTAssert(false)
                }
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 15.0)
    }
    
    func testPutCustomerInfoBadData() {
        var request = PutCustomerInfoRequest(jwt: "400_jwt")
        request.fields = [KYCNaturalPersonFieldsEnum.photoIdFront("Face".data(using: .utf8)!)];
        let expectation = XCTestExpectation(description: "Test put customer info bad data")
        
        kycService.putCustomerInfo(request: request) { (response) -> (Void) in
            switch response {
            case .success:
                XCTAssert(false)
            case .failure(let error):
                switch error {
                case .badRequest(let message):
                    XCTAssert(message == "'photo_id_front' cannot be decoded. Must be jpg or png.")
                    XCTAssert(true)
                default:
                    XCTAssert(false)
                }
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 15.0)
    }
    
    func testPutCustomerInfoUnauthorized() {
        let request = PutCustomerInfoRequest(jwt: "x_jwt")
        let expectation = XCTestExpectation(description: "Test put customer info bad data")
        
        kycService.putCustomerInfo(request: request) { (response) -> (Void) in
            switch response {
            case .success:
                XCTAssert(false)
            case .failure(let error):
                switch error {
                case .unauthorized(_):
                    XCTAssert(true)
                default:
                    XCTAssert(false)
                }
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 15.0)
    }
    
    func testGetCustomerInfoAccepted() {
        let request = GetCustomerInfoRequest(jwt: "accepted_jwt")
        let expectation = XCTestExpectation(description: "Test get customer accepted response")
        
        kycService.getCustomerInfo(request: request) { (response) -> (Void) in
            switch response {
            case .success(let response):
                XCTAssertEqual(response.status, "ACCEPTED")
                XCTAssert(true)
            case .failure(_):
                XCTAssert(false)
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testGetCustomerSomeInfoNeeded() {
        let request = GetCustomerInfoRequest(jwt: "some_info_jwt")
        let expectation = XCTestExpectation(description: "Test get customer some info needed response")
        
        kycService.getCustomerInfo(request: request) { (response) -> (Void) in
            switch response {
            case .success(let response):
                XCTAssertEqual(response.status, "NEEDS_INFO")
                XCTAssert(true)
            case .failure(_):
                XCTAssert(false)
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testGetCustomerNotFound() {
        let request = GetCustomerInfoRequest(jwt: "404_jwt")
        let expectation = XCTestExpectation(description: "Test get customer not found")
        
        kycService.getCustomerInfo(request: request) { (response) -> (Void) in
            switch response {
            case .success(_):
                XCTAssert(false)
            case .failure(let error):
                switch error {
                case .notFound(let message):
                    XCTAssert(message == "customer not found for id: 7e285e7d-d984-412c-97bc-909d0e399fbf")
                    XCTAssert(true)
                default:
                    XCTAssert(false)
                }
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testGetCustomerBadData() {
        var request = GetCustomerInfoRequest(jwt: "400_jwt")
        request.type = "BUY_DATA"
        let expectation = XCTestExpectation(description: "Test get customer bad data")
        
        kycService.getCustomerInfo(request: request) { (response) -> (Void) in
            switch response {
            case .success(_):
                XCTAssert(false)
            case .failure(let error):
                switch error {
                case .badRequest(let message):
                    XCTAssert(message == "unrecognized 'type' value. see valid values in the /info response")
                    XCTAssert(true)
                default:
                    XCTAssert(false)
                }
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testPutVerificationSuccess() {
        let request = PutCustomerVerificationRequest(id: "391fb415-c223-4608-b2f5-dd1e91e3a986", fields: ["mobile_number_verification": "2735021", "email_verification": "T32U1"], jwt: "200_jwt")

        let expectation = XCTestExpectation(description: "Test put verification success")
        
        kycService.putCustomerVerification(request: request) { (response) -> (Void) in
            switch response {
            case .success(let response):
                XCTAssertEqual(response.status, "ACCEPTED")
                XCTAssert(true)
            case .failure(_):
                XCTAssert(false)
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 15.0)
    }
    
    func testPutVerificationBadData() {
        let request = PutCustomerVerificationRequest(id: "391fb415-c223-4608-b2f5-dd1e91e3a986", fields: ["mobile_number_verification": "1871287"], jwt: "400_jwt")

        let expectation = XCTestExpectation(description: "Test put verification bad data")
        
        kycService.putCustomerVerification(request: request) { (response) -> (Void) in
            switch response {
            case .success(_):
                XCTAssert(false)
            case .failure(let error):
                switch error {
                case .badRequest(let message):
                    XCTAssert(message == "The provided confirmation code was invalid.")
                    XCTAssert(true)
                default:
                    XCTAssert(false)
                }
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 15.0)
    }
    
    func testPutVerificationNotFound() {
        let request = PutCustomerVerificationRequest(id: "391fb415-c223-4608-b2f5-dd1e91e3a986", fields: ["mobile_number_verification": "1871287"], jwt: "404_jwt")

        let expectation = XCTestExpectation(description: "Test put verification customer not found")
        
        kycService.putCustomerVerification(request: request) { (response) -> (Void) in
            switch response {
            case .success(_):
                XCTAssert(false)
            case .failure(let error):
                switch error {
                case .notFound(let message):
                    XCTAssert(message == "customer with `id` not found")
                    XCTAssert(true)
                default:
                    XCTAssert(false)
                }
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 15.0)
    }
    
    func testDeleteCustomerInfoSuccess() {
        let expectation = XCTestExpectation(description: "Test delete customer info success")
        
        kycService.deleteCustomerInfo(account: successAccount, jwt: "200_jwt") { (response) -> (Void) in
            switch response {
            case .success:
                XCTAssert(true)
            case .failure(_):
                XCTAssert(false)
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testDeleteCustomerInfoUnauthorized() {
        let expectation = XCTestExpectation(description: "Test delete customer info unauthorized")
        
        kycService.deleteCustomerInfo(account: unauthorizedCustomerAccount, jwt: "x_jwt") { (response) -> (Void) in
            switch response {
            case .success:
                XCTAssert(false)
            case .failure(let error):
                switch error {
                case .unauthorized(_):
                    XCTAssert(true)
                default:
                    XCTAssert(false)
                }
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testDeleteCustomerInfoNotFound() {
        let expectation = XCTestExpectation(description: "Test delete customer info not found")
        
        kycService.deleteCustomerInfo(account: errorAccount, jwt: "x_jwt") { (response) -> (Void) in
            switch response {
            case .success:
                XCTAssert(false)
            case .failure(let error):
                switch error {
                case .notFound(let message):
                    XCTAssert(message == "customer with `id` not found")
                    XCTAssert(true)
                default:
                    XCTAssert(false)
                }
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testPutCallbackUrlSuccess() {
        let request = PutCustomerCallbackRequest(url: "https://test.com/cb", jwt: "200_jwt")
        let expectation = XCTestExpectation(description: "Test put callback success")
        
        kycService.putCustomerCallback(request: request) { (response) -> (Void) in
            switch response {
            case .success:
                XCTAssert(true)
            case .failure(_):
                XCTAssert(false)
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 15.0)
    }
    
    
    func testPutCallbackNotFound() {
        let request = PutCustomerCallbackRequest(url: "https://test.com/cb", jwt: "404_jwt")
        let expectation = XCTestExpectation(description: "Test put callback not found")
        
        kycService.putCustomerCallback(request: request) { (response) -> (Void) in
            switch response {
            case .success:
                XCTAssert(false)
            case .failure(let error):
                switch error {
                case .notFound(let message):
                    XCTAssert(message == "customer with `id` not found")
                    XCTAssert(true)
                default:
                    XCTAssert(false)
                }
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 15.0)
    }
    
    func testPutCallbackBadData() {
        let request = PutCustomerCallbackRequest(url: "parrot", jwt: "400_jwt")
        let expectation = XCTestExpectation(description: "Test put callback bad data")
        
        kycService.putCustomerCallback(request: request) { (response) -> (Void) in
            switch response {
            case .success:
                XCTAssert(false)
            case .failure(let error):
                switch error {
                case .badRequest(let message):
                    XCTAssert(message == "invalid url")
                    XCTAssert(true)
                default:
                    XCTAssert(false)
                }
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 15.0)
    }
}
