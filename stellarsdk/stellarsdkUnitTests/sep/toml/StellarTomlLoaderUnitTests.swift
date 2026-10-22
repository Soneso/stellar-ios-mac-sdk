//
//  StellarTomlLoaderUnitTests.swift
//  stellarsdkUnitTests
//
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

/// stellar.toml loads time out, check the HTTP status, cap the body at the SEP-1 limit and
/// require UTF-8; federation responses are capped.
final class StellarTomlLoaderUnitTests: XCTestCase {

    private let host = "toml.example.com"
    private let validToml = """
        NETWORK_PASSPHRASE="Test SDF Network ; September 2015"
        KYC_SERVER="https://kyc.example.com"
        TRANSFER_SERVER="https://transfer.example.com"
        TRANSFER_SERVER_SEP0024="https://sep24.example.com"

        [DOCUMENTATION]
        ORG_NAME="Example Org"

        """

    override func setUp() {
        super.setUp()
        URLProtocol.registerClass(ServerMock.self)
    }

    override func tearDown() {
        ServerMock.removeAll()
        super.tearDown()
    }

    func testStatus200Loads() async {
        serve(Data(validToml.utf8))
        let result = await StellarToml.from(domain: host)
        XCTAssertEqual(orgName(result), "Example Org")
    }

    func testInsecureDomainLoadsOverHttp() async {
        let mock = serve(Data(validToml.utf8))
        mock.mockHandler = { mock, request in
            mock.statusCode = request.url?.scheme == "http" ? 200 : 404
            return nil
        }
        let result = await StellarToml.from(domain: host, secure: false)
        XCTAssertEqual(orgName(result), "Example Org")
    }

    func testStatus404Fails() async {
        serve(Data(validToml.utf8), status: 404)
        let result = await StellarToml.from(domain: host)
        XCTAssertTrue(isInvalidToml(result))
    }

    func testBodyAtSizeLimitLoads() async {
        serve(toml(ofSize: 102_400))
        let result = await StellarToml.from(domain: host)
        XCTAssertEqual(orgName(result), "Example Org")
    }

    func testBodyAboveSizeLimitFails() async {
        serve(toml(ofSize: 102_401))
        let result = await StellarToml.from(domain: host)
        XCTAssertTrue(isInvalidToml(result))
    }

    func testNonUtf8BodyFails() async {
        serve(Data(validToml.utf8) + Data([0x23, 0xFF, 0x0A]))
        let result = await StellarToml.from(domain: host)
        XCTAssertTrue(isInvalidToml(result))
    }

    func testStalledResponseTimesOut() async {
        serve(Data()).stalls = true
        let start = Date()
        do {
            _ = try await StellarTomlLoader.load(url: URL(string: "https://\(host)/.well-known/stellar.toml")!, timeout: 0.2)
            XCTFail("A stalled response must time out")
        } catch HorizonRequestError.requestFailed(let message, _) {
            XCTAssertEqual(message, "Loading https://toml.example.com/.well-known/stellar.toml exceeded the timeout of 0.2 seconds")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        XCTAssertLessThan(Date().timeIntervalSince(start), 5)
    }

    func testBodyPassingTheCapMidStreamCancelsTheTransfer() async {
        let filler = Data(repeating: UInt8(ascii: "a"), count: 60_000)
        let mock = serve(Data())
        mock.bodyParts = [Data(validToml.utf8) + Data("#".utf8) + filler, filler, filler, filler]
        mock.partDelay = 0.2
        let result = await StellarToml.from(domain: host)
        XCTAssertTrue(isInvalidToml(result))
        // Parts 3 and 4 would arrive within 0.4 seconds if the transfer went on.
        try? await Task.sleep(nanoseconds: 700_000_000)
        XCTAssertEqual(mock.counts.sentParts, 2)
        XCTAssertEqual(mock.counts.stops, 1)
    }

    func testHeadersWithoutBodyEndAtTheDeadline() async {
        let mock = serve(Data())
        mock.bodyParts = []
        do {
            _ = try await StellarTomlLoader.load(url: URL(string: "https://\(host)/.well-known/stellar.toml")!, timeout: 0.3)
            XCTFail("A response that sends no body must end at the deadline")
        } catch HorizonRequestError.requestFailed(let message, _) {
            XCTAssertEqual(message, "Loading https://toml.example.com/.well-known/stellar.toml exceeded the timeout of 0.3 seconds")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        try? await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertEqual(mock.counts.stops, 1)
    }

    func testCurrencyFromUrlChecksStatus() async {
        serve(Data("code=\"USD\"\n".utf8), status: 404, path: "/usd.toml")
        guard case .failure(.invalidToml) = await StellarToml.currencyFrom(url: "https://\(host)/usd.toml") else {
            return XCTFail("A 404 currency document must fail")
        }
    }

    func testKycServiceForDomain() async {
        let mock = serve(Data(validToml.utf8))
        guard case .success(let service) = await KycService.forDomain(domain: "https://\(host)") else { return XCTFail("200 must load") }
        XCTAssertEqual(service.kycServiceAddress, "https://kyc.example.com")
        mock.statusCode = 404
        guard case .failure(.invalidToml) = await KycService.forDomain(domain: "https://\(host)") else { return XCTFail("404 must fail") }
    }

    func testInteractiveServiceForDomain() async {
        let mock = serve(Data(validToml.utf8))
        guard case .success(let service) = await InteractiveService.forDomain(domain: "https://\(host)") else { return XCTFail("200 must load") }
        XCTAssertEqual(service.serviceAddress, "https://sep24.example.com")
        mock.statusCode = 404
        guard case .failure(.invalidToml) = await InteractiveService.forDomain(domain: "https://\(host)") else { return XCTFail("404 must fail") }
    }

    func testTransferServerServiceForDomain() async {
        let mock = serve(Data(validToml.utf8))
        guard case .success(let service) = await TransferServerService.forDomain(domain: "https://\(host)") else { return XCTFail("200 must load") }
        XCTAssertEqual(service.transferServiceAddress, "https://transfer.example.com")
        mock.statusCode = 404
        guard case .failure(.invalidToml) = await TransferServerService.forDomain(domain: "https://\(host)") else { return XCTFail("404 must fail") }
    }

    func testRegulatedAssetsServiceForDomain() async {
        let mock = serve(Data(validToml.utf8))
        guard case .success(let service) = await RegulatedAssetsService.forDomain(domain: "https://\(host)") else { return XCTFail("200 must load") }
        XCTAssertEqual(service.network.passphrase, Network.testnet.passphrase)
        mock.statusCode = 404
        guard case .failure(.invalidToml) = await RegulatedAssetsService.forDomain(domain: "https://\(host)") else { return XCTFail("404 must fail") }
    }

    func testFederationResponseAboveSizeLimitFails() async {
        let accountId = "GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR"
        let memo = String(repeating: "a", count: 102_400)
        let body = #"{"stellar_address":"bob*example.com","account_id":"\#(accountId)","memo_type":"text","memo":"\#(memo)"}"#
        serve(Data(body.utf8), host: "fed.example.com", path: "/federation")
        let result = await Federation(federationAddress: "https://fed.example.com/federation").resolve(account_id: accountId)
        guard case .failure(.horizonError(.requestFailed(let message, _))) = result else {
            return XCTFail("An oversized federation response must fail, got: \(result)")
        }
        XCTAssertEqual(message, "The response from https://fed.example.com/federation?q=\(accountId)&type=id exceeds the limit of 102400 bytes")
    }

    // MARK: - Helpers

    @discardableResult
    private func serve(_ body: Data, status: Int = 200, host: String? = nil, path: String = "/.well-known/stellar.toml") -> RequestMock {
        let mock = RequestMock(host: host ?? self.host, path: path, httpMethod: "GET", statusCode: status) { _, _ in nil }
        mock.bodyData = body
        ServerMock.add(mock: mock)
        return mock
    }

    /// The valid document followed by a comment that fills it to exactly `size` bytes.
    private func toml(ofSize size: Int) -> Data {
        let document = Data(validToml.utf8) + Data("#".utf8)
        return document + Data(repeating: UInt8(ascii: "a"), count: size - document.count)
    }

    private func orgName(_ result: TomlForDomainEnum) -> String? {
        guard case .success(let toml) = result else { return nil }
        return toml.issuerDocumentation.orgName
    }

    private func isInvalidToml(_ result: TomlForDomainEnum) -> Bool {
        guard case .failure(.invalidToml) = result else { return false }
        return true
    }
}
