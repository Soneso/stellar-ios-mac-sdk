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
    
    func testPutCustomerInfoSuccess() async {
        var request = PutCustomerInfoRequest(jwt: "200_jwt")
        request.fields = [KYCNaturalPersonFieldsEnum.firstName("John"), KYCNaturalPersonFieldsEnum.lastName("Doe")];
        let responseEnum = await kycService.putCustomerInfo(request: request)
        switch responseEnum {
        case .success(_):
            return
        case .failure(_):
            XCTFail()
        }
    }
    
    
    func testPutCustomerInfoNotFound() async {
        var request = PutCustomerInfoRequest(jwt: "404_jwt")
        request.fields = [KYCNaturalPersonFieldsEnum.firstName("Max"), KYCNaturalPersonFieldsEnum.lastName("Man")];
        let responseEnum = await kycService.putCustomerInfo(request: request)
        switch responseEnum {
        case .success(_):
            XCTFail()
        case .failure(let error):
            switch error {
            case .notFound(let message):
                XCTAssertEqual("customer with `id` not found", message)
            default:
                XCTFail()
            }
        }
    }
    
    func testPutCustomerInfoBadData() async {
        var request = PutCustomerInfoRequest(jwt: "400_jwt")
        request.fields = [KYCNaturalPersonFieldsEnum.photoIdFront("Face".data(using: .utf8)!)];
        let responseEnum = await kycService.putCustomerInfo(request: request)
        switch responseEnum {
        case .success(_):
            XCTFail()
        case .failure(let error):
            switch error {
            case .badRequest(let message):
                XCTAssertEqual("'photo_id_front' cannot be decoded. Must be jpg or png.", message)
            default:
                XCTFail()
            }
        }
    }
    
    func testPutCustomerInfoUnauthorized() async {
        let request = PutCustomerInfoRequest(jwt: "x_jwt")
        let responseEnum = await kycService.putCustomerInfo(request: request)
        switch responseEnum {
        case .success(_):
            XCTFail()
        case .failure(let error):
            switch error {
            case .unauthorized(_):
                return
            default:
                XCTFail()
            }
        }
    }
    
    func testGetCustomerInfoAccepted() async {
        let request = GetCustomerInfoRequest(jwt: "accepted_jwt")
        let responseEnum = await kycService.getCustomerInfo(request: request)
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual("ACCEPTED", response.status)
        case .failure(_):
            XCTFail()
        }
    }
    
    func testGetCustomerSomeInfoNeeded() async {
        let request = GetCustomerInfoRequest(jwt: "some_info_jwt")
        let responseEnum = await kycService.getCustomerInfo(request: request)
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual("NEEDS_INFO", response.status)
        case .failure(_):
            XCTFail()
        }
    }
    
    func testGetCustomerNotFound() async {
        let request = GetCustomerInfoRequest(jwt: "404_jwt")
        let responseEnum = await kycService.getCustomerInfo(request: request)
        switch responseEnum {
        case .success(_):
            XCTFail()
        case .failure(let error):
            switch error {
            case .notFound(let message):
                XCTAssertEqual("customer not found for id: 7e285e7d-d984-412c-97bc-909d0e399fbf", message)
            default:
                XCTFail()
            }
        }
    }
    
    func testGetCustomerBadData() async {
        var request = GetCustomerInfoRequest(jwt: "400_jwt")
        request.type = "BUY_DATA"
        let responseEnum = await kycService.getCustomerInfo(request: request)
        switch responseEnum {
        case .success(_):
            XCTFail()
        case .failure(let error):
            switch error {
            case .badRequest(let message):
                XCTAssertEqual("unrecognized 'type' value. see valid values in the /info response", message)
            default:
                XCTFail()
            }
        }
    }
    
    func testPutVerificationSuccess() async {
        let request = PutCustomerVerificationRequest(id: "391fb415-c223-4608-b2f5-dd1e91e3a986", fields: ["mobile_number_verification": "2735021", "email_verification": "T32U1"], jwt: "200_jwt")
        let responseEnum = await kycService.putCustomerVerification(request: request)
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual("ACCEPTED", response.status)
        case .failure(_):
            XCTFail()
        }
    }
    
    func testPutVerificationBadData() async {
        let request = PutCustomerVerificationRequest(id: "391fb415-c223-4608-b2f5-dd1e91e3a986", fields: ["mobile_number_verification": "1871287"], jwt: "400_jwt")
        let responseEnum = await kycService.putCustomerVerification(request: request)
        switch responseEnum {
        case .success(_):
            XCTFail()
        case .failure(let error):
            switch error {
            case .badRequest(let message):
                XCTAssertEqual("The provided confirmation code was invalid.", message)
            default:
                XCTFail()
            }
        }
    }
    
    func testPutVerificationNotFound() async {
        let request = PutCustomerVerificationRequest(id: "391fb415-c223-4608-b2f5-dd1e91e3a986", fields: ["mobile_number_verification": "1871287"], jwt: "404_jwt")
        let responseEnum = await kycService.putCustomerVerification(request: request)
        switch responseEnum {
        case .success(_):
            XCTFail()
        case .failure(let error):
            switch error {
            case .notFound(let message):
                XCTAssertEqual("customer with `id` not found", message)
            default:
                XCTFail()
            }
        }
    }
    
    func testDeleteCustomerInfoSuccess() async {
        let responseEnum = await kycService.deleteCustomerInfo(account: successAccount, jwt: "200_jwt")
        switch responseEnum {
        case .success:
            return
        case .failure(_):
            XCTFail()
        }
    }
    
    func testDeleteCustomerInfoUnauthorized() async {
        let responseEnum = await kycService.deleteCustomerInfo(account: unauthorizedCustomerAccount, jwt: "x_jwt")
        switch responseEnum {
        case .success:
            XCTFail()
        case .failure(let error):
            switch error {
            case .unauthorized(_):
                return
            default:
                XCTFail()
            }
        }
    }
    
    func testDeleteCustomerInfoNotFound() async {
        let responseEnum = await kycService.deleteCustomerInfo(account: errorAccount, jwt: "x_jwt")
        switch responseEnum {
        case .success:
            XCTFail()
        case .failure(let error):
            switch error {
            case .notFound(let message):
                XCTAssertEqual("customer with `id` not found", message)
            default:
                XCTFail()
            }
        }
    }
    
    func testPutCallbackUrlSuccess() async {
        let request = PutCustomerCallbackRequest(url: "https://test.com/cb", jwt: "200_jwt")
        let responseEnum = await kycService.putCustomerCallback(request: request)
        switch responseEnum {
        case .success:
            return
        case .failure(_):
            XCTFail()
        }
    }
    
    
    func testPutCallbackNotFound() async {
        let request = PutCustomerCallbackRequest(url: "https://test.com/cb", jwt: "404_jwt")
        let responseEnum = await kycService.putCustomerCallback(request: request)
        switch responseEnum {
        case .success:
            XCTFail()
        case .failure(let error):
            switch error {
            case .notFound(let message):
                XCTAssertEqual("customer with `id` not found", message)
            default:
                XCTFail()
            }
        }
    }
    
    func testPutCallbackBadData() async {
        let request = PutCustomerCallbackRequest(url: "parrot", jwt: "400_jwt")
        let responseEnum = await kycService.putCustomerCallback(request: request)
        switch responseEnum {
        case .success:
            XCTFail()
        case .failure(let error):
            switch error {
            case .badRequest(let message):
                XCTAssertEqual("invalid url", message)
            default:
                XCTFail()
            }
        }
    }
}
