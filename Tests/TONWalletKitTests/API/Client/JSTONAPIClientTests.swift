import Testing
import Foundation
import JavaScriptCore
@testable import TONWalletKit

@Suite("JSTONAPIClient Tests")
struct JSTONAPIClientTests {

    private let testAddress: TONUserFriendlyAddress = {
        let hash = Data(repeating: 0xab, count: 32)
        return TONRawAddress(workchain: 0, hash: hash).userFriendly(isBounceable: true)
    }()

    private func makeSUT() -> (sut: JSTONAPIClient, mock: MockJSDynamicObject) {
        let mock = MockJSDynamicObject()
        let sut = JSTONAPIClient(jsClient: mock)
        return (sut, mock)
    }

    @Test("network() calls getNetwork and returns stubbed value")
    func networkCallsGetNetwork() throws {
        let (sut, mock) = makeSUT()
        mock.stubbedResults["getNetwork"] = TONNetwork.testnet

        let result = try sut.network()

        #expect(mock.callRecords.first?.path == "getNetwork")
        #expect(result == .testnet)
    }

    @Test("network() throws when JSDynamic throws")
    func networkThrowsOnError() {
        let (sut, mock) = makeSUT()
        mock.shouldThrowOnCall = true

        #expect(throws: (any Error).self) {
            try sut.network()
        }
    }

    @Test("send(boc:) calls sendBoc with the boc value")
    func sendCallsSendBoc() async throws {
        let (sut, mock) = makeSUT()
        mock.stubbedAsyncResults["sendBoc"] = "ok" as String
        let boc = try TONBase64(base64Encoded: "dGVzdA==")

        let result = try await sut.send(boc: boc)

        #expect(mock.callRecords.first?.path == "sendBoc")
        #expect(mock.callRecords.first?.args.first as? String == "dGVzdA==")
        #expect(result == "ok")
    }

    @Test("send(boc:) throws when JSDynamic throws")
    func sendThrowsOnError() async throws {
        let (sut, mock) = makeSUT()
        mock.shouldThrowOnCall = true
        let boc = try TONBase64(base64Encoded: "dGVzdA==")

        await #expect(throws: (any Error).self) {
            try await sut.send(boc: boc)
        }
    }

    @Test("runGetMethod() calls runGetMethod and returns stubbed result")
    func runGetMethodCallsRunGetMethod() async throws {
        let (sut, mock) = makeSUT()
        let stub = TONGetMethodResult(gasUsed: 1, stack: [], exitCode: 0)
        mock.stubbedAsyncResults["runGetMethod"] = stub

        let result = try await sut.runGetMethod(
            address: testAddress,
            method: "seqno",
            stack: nil,
            seqno: nil
        )

        #expect(mock.callRecords.first?.path == "runGetMethod")
        #expect(result.gasUsed == stub.gasUsed)
        #expect(result.exitCode == stub.exitCode)
    }

    @Test("runGetMethod() throws when JSDynamic throws")
    func runGetMethodThrowsOnError() async {
        let (sut, mock) = makeSUT()
        mock.shouldThrowOnCall = true

        await #expect(throws: (any Error).self) {
            try await sut.runGetMethod(
                address: testAddress,
                method: "seqno",
                stack: nil,
                seqno: nil
            )
        }
    }

    @Test("masterchainInfo() calls getMasterchainInfo")
    func masterchainInfoCallsGetMasterchainInfo() async throws {
        let (sut, mock) = makeSUT()
        let stub = try TONMasterchainInfo(
            seqno: 42,
            shard: "8000000000000000",
            workchain: -1,
            fileHash: TONHex(hexString: "aabb"),
            rootHash: TONHex(hexString: "ccdd")
        )
        mock.stubbedAsyncResults["getMasterchainInfo"] = stub

        let result = try await sut.masterchainInfo()

        #expect(mock.callRecords.first?.path == "getMasterchainInfo")
        #expect(result.seqno == 42)
    }

    @Test("masterchainInfo() throws when JSDynamic throws")
    func masterchainInfoThrowsOnError() async {
        let (sut, mock) = makeSUT()
        mock.shouldThrowOnCall = true

        await #expect(throws: (any Error).self) {
            try await sut.masterchainInfo()
        }
    }
}
