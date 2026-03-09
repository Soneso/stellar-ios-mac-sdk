//
//  Sep08DocTest.swift
//  stellarsdkIntegrationTests
//
//  Tests for SEP-08 documentation code examples.
//  Uses ServerMock/RequestMock/ResponsesMock for HTTP mocking,
//  following the same patterns as RegulatedAssetsTestCase.swift.
//

import XCTest
import stellarsdk

class Sep08DocTest: XCTestCase {

    let network = Network.testnet
    var service: RegulatedAssetsService!
    var sep08PostSuccessMock: Sep08DocPostSuccessMock!
    var sep08PostPendingMock: Sep08DocPostPendingMock!
    var sep08PostRevisedMock: Sep08DocPostRevisedMock!
    var sep08PostRejectedMock: Sep08DocPostRejectedMock!
    var sep08PostActionRequiredMock: Sep08DocPostActionRequiredMock!
    var sep08FollowNextMock: Sep08DocFollowNextMock!
    var sep08ActionDoneMock: Sep08DocActionDoneMock!

    let issuerKp = try! KeyPair.generateRandomKeyPair()
    let accountAKp = try! KeyPair.generateRandomKeyPair()
    var txB64Xdr: String!

    override func setUp() async throws {
        try await super.setUp()

        URLProtocol.registerClass(ServerMock.self)

        let host = "sep08doc.test"

        sep08PostSuccessMock = Sep08DocPostSuccessMock(host: host)
        sep08PostPendingMock = Sep08DocPostPendingMock(host: host)
        sep08PostRevisedMock = Sep08DocPostRevisedMock(host: host)
        sep08PostRejectedMock = Sep08DocPostRejectedMock(host: host)
        sep08PostActionRequiredMock = Sep08DocPostActionRequiredMock(host: host)
        sep08FollowNextMock = Sep08DocFollowNextMock(host: host)
        sep08ActionDoneMock = Sep08DocActionDoneMock(host: host)

        let stellarToml = try! StellarToml(fromString: """
            VERSION="2.0.0"
            NETWORK_PASSPHRASE="Test SDF Network ; September 2015"

            [[CURRENCIES]]
            code="GOAT"
            issuer="\(issuerKp.accountId)"
            regulated=true
            approval_server="http://sep08doc.test/tx_approve"
            approval_criteria="The goat approval server will ensure that transactions are compliant with regulation"
            """)

        service = try! RegulatedAssetsService(tomlData: stellarToml)

        // Build a simple transaction for use in tests
        let goatAsset = service.regulatedAssets.first!
        let paymentOp = try! PaymentOperation(
            sourceAccountId: accountAKp.accountId,
            destinationAccountId: issuerKp.accountId,
            asset: goatAsset,
            amount: Decimal(10)
        )

        let tx = try! Transaction(
            sourceAccount: Account(keyPair: accountAKp, sequenceNumber: 0),
            operations: [paymentOp],
            memo: Memo.none
        )

        try! tx.sign(keyPair: accountAKp, network: network)
        self.txB64Xdr = try! tx.encodedEnvelope()
    }

    // MARK: - Test: Service creation from TOML (Snippet 2, 3)

    func testServiceCreationFromToml() {
        // Mirrors "From StellarToml data" snippet
        let tomlString = """
        VERSION="2.0.0"
        NETWORK_PASSPHRASE="Test SDF Network ; September 2015"

        [[CURRENCIES]]
        code="REG"
        issuer="GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP"
        regulated=true
        approval_server="https://approval.issuer.example.com"
        approval_criteria="Must pass KYC verification"
        """

        do {
            let toml = try StellarToml(fromString: tomlString)
            let svc = try RegulatedAssetsService(tomlData: toml)
            XCTAssertEqual(1, svc.regulatedAssets.count)
            XCTAssertEqual("REG", svc.regulatedAssets.first!.assetCode)
        } catch {
            XCTFail("Failed to create service from TOML: \(error)")
        }
    }

    // MARK: - Test: Service properties (Snippet 5)

    func testServiceProperties() {
        // Mirrors "Service properties" snippet
        let assets = service.regulatedAssets
        XCTAssertFalse(assets.isEmpty)

        let tomlData = service.tomlData
        XCTAssertNotNil(tomlData)

        let sdk = service.sdk
        XCTAssertNotNil(sdk)

        let network = service.network
        XCTAssertNotNil(network)
    }

    // MARK: - Test: Discovering regulated assets (Snippet 6)

    func testDiscoveringRegulatedAssets() {
        // Mirrors "Discovering regulated assets" snippet
        for asset in service.regulatedAssets {
            // Standard asset properties
            XCTAssertEqual("GOAT", asset.assetCode)
            XCTAssertEqual(issuerKp.accountId, asset.issuerId)

            // SEP-08 specific properties
            XCTAssertEqual("http://sep08doc.test/tx_approve", asset.approvalServer)
            XCTAssertNotNil(asset.approvalCriteria)
        }
    }

    // MARK: - Test: Checking authorization requirements (Snippet 7)
    // NOTE: This test requires testnet accounts. Tested via existing RegulatedAssetsTestCase.
    // Included here as a structural test showing the API pattern.

    func testAuthorizationRequiredApiPattern() async {
        // The authorizationRequired method queries Horizon for issuer flags.
        // Since our mock issuer isn't funded, we expect a failure result (not found).
        // This test verifies the API shape matches the documentation.
        let asset = service.regulatedAssets.first!
        let authResult = await service.authorizationRequired(asset: asset)

        switch authResult {
        case .success(let required):
            // If we get here (unlikely without funded account), just verify the Bool type
            _ = required
        case .failure(_):
            // Expected: issuer account not found on testnet
            break
        }
    }

    // MARK: - Test: Post transaction success (Snippet 1, 8)

    func testPostTransactionSuccess() async {
        let goatAsset = service.regulatedAssets.first!
        let responseEnum = await service.postTransaction(
            txB64Xdr: self.txB64Xdr,
            apporvalServer: goatAsset.approvalServer + "/success"
        )

        switch responseEnum {
        case .success(let response):
            XCTAssertEqual(self.txB64Xdr, response.tx)
            XCTAssertEqual("hello", response.message)
        case .failure(let err):
            XCTFail("Unexpected failure: \(err)")
        default:
            XCTFail("Expected .success response")
        }
    }

    // MARK: - Test: Handling approval responses - all types (Snippet 9)

    func testPostTransactionPending() async {
        let goatAsset = service.regulatedAssets.first!
        let responseEnum = await service.postTransaction(
            txB64Xdr: self.txB64Xdr,
            apporvalServer: goatAsset.approvalServer + "/pending"
        )

        switch responseEnum {
        case .pending(let response):
            XCTAssertEqual(10, response.timeout)
            XCTAssertEqual("hello", response.message)
        case .failure(let err):
            XCTFail("Unexpected failure: \(err)")
        default:
            XCTFail("Expected .pending response")
        }
    }

    func testPostTransactionRevised() async {
        let goatAsset = service.regulatedAssets.first!
        let responseEnum = await service.postTransaction(
            txB64Xdr: self.txB64Xdr,
            apporvalServer: goatAsset.approvalServer + "/revised"
        )

        switch responseEnum {
        case .revised(let response):
            XCTAssertEqual(self.txB64Xdr + self.txB64Xdr, response.tx)
            XCTAssertEqual("hello", response.message)
        case .failure(let err):
            XCTFail("Unexpected failure: \(err)")
        default:
            XCTFail("Expected .revised response")
        }
    }

    func testPostTransactionRejected() async {
        let goatAsset = service.regulatedAssets.first!
        let responseEnum = await service.postTransaction(
            txB64Xdr: self.txB64Xdr,
            apporvalServer: goatAsset.approvalServer + "/rejected"
        )

        switch responseEnum {
        case .rejected(let response):
            XCTAssertEqual("hello", response.error)
        case .failure(let err):
            XCTFail("Unexpected failure: \(err)")
        default:
            XCTFail("Expected .rejected response")
        }
    }

    func testPostTransactionActionRequired() async {
        let goatAsset = service.regulatedAssets.first!
        let responseEnum = await service.postTransaction(
            txB64Xdr: self.txB64Xdr,
            apporvalServer: goatAsset.approvalServer + "/action_required"
        )

        switch responseEnum {
        case .actionRequired(let response):
            XCTAssertEqual("hello", response.message)
            XCTAssertEqual("http://sep08doc.test/action", response.actionUrl)
            XCTAssertEqual("POST", response.actionMethod)
            XCTAssertEqual(2, response.actionFields?.count)
            XCTAssertEqual("email_address", response.actionFields?.first)
            XCTAssertEqual("mobile_number", response.actionFields?.last)
        case .failure(let err):
            XCTFail("Unexpected failure: \(err)")
        default:
            XCTFail("Expected .actionRequired response")
        }
    }

    // MARK: - Test: Handling action required - postAction (Snippet 10)

    func testPostActionFollowNext() async {
        let responseEnum = await service.postAction(
            url: "http://sep08doc.test/action/next",
            actionFields: ["email_address": "test@example.com"]
        )

        switch responseEnum {
        case .nextUrl(let response):
            XCTAssertEqual("Please submit mobile number", response.message)
            XCTAssertEqual("http://sep08doc.test/action", response.nextUrl)
        case .failure(let err):
            XCTFail("Unexpected failure: \(err)")
        default:
            XCTFail("Expected .nextUrl response")
        }
    }

    func testPostActionDone() async {
        let responseEnum = await service.postAction(
            url: "http://sep08doc.test/action/done",
            actionFields: ["mobile_number": "+347282983922"]
        )

        switch responseEnum {
        case .done:
            break // success
        case .failure(let err):
            XCTFail("Unexpected failure: \(err)")
        default:
            XCTFail("Expected .done response")
        }
    }

    // MARK: - Test: Error handling - invalid TOML (Snippet 12)

    func testErrorHandlingInvalidToml() {
        // Missing NETWORK_PASSPHRASE and no network override -> should throw invalidToml
        let tomlString = """
        VERSION="2.0.0"

        [DOCUMENTATION]
        ORG_NAME="Test"
        """

        do {
            let toml = try StellarToml(fromString: tomlString)
            _ = try RegulatedAssetsService(tomlData: toml)
            XCTFail("Expected RegulatedAssetsServiceError.invalidToml to be thrown")
        } catch let error as RegulatedAssetsServiceError {
            switch error {
            case .invalidToml:
                break // expected
            default:
                XCTFail("Expected .invalidToml, got \(error)")
            }
        } catch {
            // StellarToml parsing might also throw — this is acceptable
            return
        }
    }

    // MARK: - Test: Multiple regulated assets from TOML

    func testMultipleRegulatedAssets() {
        let tomlString = """
        VERSION="2.0.0"
        NETWORK_PASSPHRASE="Test SDF Network ; September 2015"

        [[CURRENCIES]]
        code="GOAT"
        issuer="GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP"
        regulated=true
        approval_server="http://goat.io/tx_approve"
        approval_criteria="Goat compliance"

        [[CURRENCIES]]
        code="NOP"
        issuer="GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP"
        display_decimals=2

        [[CURRENCIES]]
        code="JACK"
        issuer="GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP"
        regulated=true
        approval_server="https://jack.io/tx_approve"
        approval_criteria="Jack compliance"
        """

        do {
            let toml = try StellarToml(fromString: tomlString)
            let svc = try RegulatedAssetsService(tomlData: toml)

            // Only regulated assets with approval_server are included
            XCTAssertEqual(2, svc.regulatedAssets.count)

            let goat = svc.regulatedAssets.first!
            XCTAssertEqual("GOAT", goat.assetCode)
            XCTAssertEqual("http://goat.io/tx_approve", goat.approvalServer)
            XCTAssertEqual("Goat compliance", goat.approvalCriteria)

            let jack = svc.regulatedAssets.last!
            XCTAssertEqual("JACK", jack.assetCode)
            XCTAssertEqual("https://jack.io/tx_approve", jack.approvalServer)
            XCTAssertEqual("Jack compliance", jack.approvalCriteria)
        } catch {
            XCTFail("Failed to parse TOML: \(error)")
        }
    }
}

// MARK: - Mock classes (same pattern as RegulatedAssetsTestCase mocks)

private struct Sep08DocPostTestRequest: Decodable {
    var tx: String
    private enum CodingKeys: String, CodingKey {
        case tx
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        tx = try values.decode(String.self, forKey: .tx)
    }
}

class Sep08DocPostSuccessMock: ResponsesMock {
    var host: String
    private let jsonDecoder = JSONDecoder()
    init(host: String) {
        self.host = host
        super.init()
    }
    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            if let data = request.httpBodyStream?.readfully() {
                let request = try! self!.jsonDecoder.decode(Sep08DocPostTestRequest.self, from: data)
                mock.statusCode = 200
                return """
                {
                  "status": "success",
                  "tx": "\(request.tx)",
                  "message": "hello"
                }
                """
            }
            mock.statusCode = 400
            return ""
        }
        return RequestMock(host: host, path: "/tx_approve/success", httpMethod: "POST", mockHandler: handler)
    }
}

class Sep08DocPostPendingMock: ResponsesMock {
    var host: String
    private let jsonDecoder = JSONDecoder()
    init(host: String) {
        self.host = host
        super.init()
    }
    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            if let data = request.httpBodyStream?.readfully() {
                _ = try! self!.jsonDecoder.decode(Sep08DocPostTestRequest.self, from: data)
                mock.statusCode = 200
                return """
                {
                  "status": "pending",
                  "timeout": 10,
                  "message": "hello"
                }
                """
            }
            mock.statusCode = 400
            return ""
        }
        return RequestMock(host: host, path: "/tx_approve/pending", httpMethod: "POST", mockHandler: handler)
    }
}

class Sep08DocPostRevisedMock: ResponsesMock {
    var host: String
    private let jsonDecoder = JSONDecoder()
    init(host: String) {
        self.host = host
        super.init()
    }
    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            if let data = request.httpBodyStream?.readfully() {
                let request = try! self!.jsonDecoder.decode(Sep08DocPostTestRequest.self, from: data)
                mock.statusCode = 200
                return """
                {
                  "status": "revised",
                  "tx": "\(request.tx + request.tx)",
                  "message": "hello"
                }
                """
            }
            mock.statusCode = 400
            return ""
        }
        return RequestMock(host: host, path: "/tx_approve/revised", httpMethod: "POST", mockHandler: handler)
    }
}

class Sep08DocPostRejectedMock: ResponsesMock {
    var host: String
    private let jsonDecoder = JSONDecoder()
    init(host: String) {
        self.host = host
        super.init()
    }
    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            if let data = request.httpBodyStream?.readfully() {
                _ = try! self!.jsonDecoder.decode(Sep08DocPostTestRequest.self, from: data)
                mock.statusCode = 400
                return """
                {
                  "status": "rejected",
                  "error": "hello"
                }
                """
            }
            mock.statusCode = 400
            return ""
        }
        return RequestMock(host: host, path: "/tx_approve/rejected", httpMethod: "POST", mockHandler: handler)
    }
}

class Sep08DocPostActionRequiredMock: ResponsesMock {
    var host: String
    private let jsonDecoder = JSONDecoder()
    init(host: String) {
        self.host = host
        super.init()
    }
    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            if let data = request.httpBodyStream?.readfully() {
                _ = try! self!.jsonDecoder.decode(Sep08DocPostTestRequest.self, from: data)
                mock.statusCode = 200
                return """
                {
                  "status": "action_required",
                  "message": "hello",
                  "action_url": "http://sep08doc.test/action",
                  "action_method": "POST",
                  "action_fields": ["email_address", "mobile_number"]
                }
                """
            }
            mock.statusCode = 400
            return ""
        }
        return RequestMock(host: host, path: "/tx_approve/action_required", httpMethod: "POST", mockHandler: handler)
    }
}

class Sep08DocFollowNextMock: ResponsesMock {
    var host: String
    init(host: String) {
        self.host = host
        super.init()
    }
    override func requestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            if let _ = request.httpBodyStream?.readfully() {
                mock.statusCode = 200
                return """
                {
                  "result": "follow_next_url",
                  "message": "Please submit mobile number",
                  "next_url": "http://sep08doc.test/action"
                }
                """
            }
            mock.statusCode = 400
            return ""
        }
        return RequestMock(host: host, path: "/action/next", httpMethod: "POST", mockHandler: handler)
    }
}

class Sep08DocActionDoneMock: ResponsesMock {
    var host: String
    init(host: String) {
        self.host = host
        super.init()
    }
    override func requestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            if let _ = request.httpBodyStream?.readfully() {
                mock.statusCode = 200
                return """
                {
                  "result": "no_further_action_required"
                }
                """
            }
            mock.statusCode = 400
            return ""
        }
        return RequestMock(host: host, path: "/action/done", httpMethod: "POST", mockHandler: handler)
    }
}
