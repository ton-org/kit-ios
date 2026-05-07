import Testing
import JavaScriptCore
@testable import TONWalletKit
import _BigInt

@Suite("TONSwapProvider Tests")
struct TONSwapProviderTests {

    private func makeSUT(
        identifierName: String = "omniston"
    ) -> (sut: TONSwapProvider<TONOmnistonSwapProviderIdentifier>, mock: MockJSDynamicObject) {
        let mock = MockJSDynamicObject()
        let identifier = TONOmnistonSwapProviderIdentifier(name: identifierName)
        let sut = TONSwapProvider(jsObject: mock, identifier: identifier)
        return (sut, mock)
    }

    private func makeQuoteParams() -> TONSwapQuoteParams<TONOmnistonProviderOptions> {
        TONSwapQuoteParams(
            amount: "1.0",
            from: TONSwapToken(address: "ton", decimals: 9, name: "TON", symbol: "TON"),
            to: TONSwapToken(address: "EQUSDT", decimals: 6, name: "USDT", symbol: "USDT"),
            network: TONNetwork(chainId: "-239")
        )
    }

    private func makeSwapParams() -> TONSwapParams<AnyCodable> {
        let token = TONSwapToken(address: "ton", decimals: 9, name: "TON", symbol: "TON")
        let quote = TONSwapQuote(
            fromToken: token,
            toToken: token,
            rawFromAmount: TONTokenAmount(nanoUnits: BigInt(stringLiteral: "1000000000")),
            rawToAmount: TONTokenAmount(nanoUnits: BigInt(stringLiteral: "1000000")),
            fromAmount: "1",
            toAmount: "1",
            rawMinReceived: TONTokenAmount(nanoUnits: BigInt(stringLiteral: "990000")),
            minReceived: "0.99",
            network: TONNetwork(chainId: "-239"),
            providerId: "omniston"
        )
        let hash = Data(repeating: 0xab, count: 32)
        let address = TONRawAddress(workchain: 0, hash: hash).userFriendly(isBounceable: true)
        return TONSwapParams(quote: quote, userAddress: address)
    }

    @Test("init stores identifier")
    func initStoresIdentifier() {
        let (sut, _) = makeSUT(identifierName: "test-provider")

        #expect(sut.identifier.name == "test-provider")
    }

    @Test("type returns .swap")
    func typeReturnsSwap() {
        let (sut, _) = makeSUT()

        #expect(sut.type == .swap)
    }

    @Test("quote(params:) calls getQuote on jsObject")
    func quoteCallsGetQuote() async {
        let (sut, mock) = makeSUT()

        _ = try? await sut.quote(params: makeQuoteParams())

        #expect(mock.callRecords.first?.path == "getQuote")
    }

    @Test("quote(params:) throws when jsObject throws")
    func quoteThrowsOnError() async {
        let (sut, mock) = makeSUT()
        mock.shouldThrowOnCall = true

        await #expect(throws: (any Error).self) {
            try await sut.quote(params: makeQuoteParams())
        }
    }

    @Test("swapTransaction(params:) calls buildSwapTransaction on jsObject")
    func swapTransactionCallsBuildSwapTransaction() async {
        let (sut, mock) = makeSUT()

        _ = try? await sut.swapTransaction(params: makeSwapParams())

        #expect(mock.callRecords.first?.path == "buildSwapTransaction")
    }

    @Test("swapTransaction(params:) throws when jsObject throws")
    func swapTransactionThrowsOnError() async {
        let (sut, mock) = makeSUT()
        mock.shouldThrowOnCall = true

        await #expect(throws: (any Error).self) {
            try await sut.swapTransaction(params: makeSwapParams())
        }
    }

    @Test("JSValueDecodable.from returns provider when providerId exists")
    func fromJSValueWithProviderIdReturnsProvider() throws {
        let context = JSContext()!
        context.evaluateScript("var obj = { providerId: 'test-provider' }")
        let jsValue = context.objectForKeyedSubscript("obj")!

        let result = try TONSwapProvider<TONOmnistonSwapProviderIdentifier>.from(jsValue)

        #expect(result != nil)
        #expect(result?.identifier.name == "test-provider")
    }

    @Test("JSValueDecodable.from returns nil when providerId is missing")
    func fromJSValueWithoutProviderIdReturnsNil() throws {
        let context = JSContext()!
        context.evaluateScript("var obj = {}")
        let jsValue = context.objectForKeyedSubscript("obj")!

        let result = try TONSwapProvider<TONOmnistonSwapProviderIdentifier>.from(jsValue)

        #expect(result == nil)
    }

    @Test("encode(in:) returns jsObject")
    func encodeReturnsJSObject() throws {
        let context = JSContext()!
        let mock = MockJSDynamicObject(jsContext: context)
        let identifier = TONOmnistonSwapProviderIdentifier(name: "omniston")
        let sut = TONSwapProvider(jsObject: mock, identifier: identifier)

        let result = try sut.encode(in: context)

        #expect(result is MockJSDynamicObject)
    }
}
