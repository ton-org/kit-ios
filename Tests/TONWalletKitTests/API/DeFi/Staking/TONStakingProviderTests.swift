import Testing
import JavaScriptCore
@testable import TONWalletKit
import _BigInt

@Suite("TONStakingProvider Tests")
struct TONStakingProviderTests {

    private func makeSUT(
        identifierName: String = "tonstakers"
    ) -> (sut: TONStakingProvider<TONTonStakersStakingProviderIdentifier>, mock: MockJSDynamicObject) {
        let mock = MockJSDynamicObject()
        let identifier = TONTonStakersStakingProviderIdentifier(name: identifierName)
        let sut = TONStakingProvider(jsObject: mock, identifier: identifier)
        return (sut, mock)
    }

    private func makeQuoteParams() -> TONStakingQuoteParams<AnyCodable> {
        TONStakingQuoteParams(
            direction: .stake,
            amount: "1000000000"
        )
    }

    private func makeStakeParams() -> TONStakeParams<AnyCodable> {
        let quote = TONStakingQuote(
            direction: .stake,
            rawAmountIn: TONTokenAmount(nanoUnits: BigInt(stringLiteral: "1000000000")),
            rawAmountOut: TONTokenAmount(nanoUnits: BigInt(stringLiteral: "950000000")),
            amountIn: "1",
            amountOut: "0.95",
            network: TONNetwork(chainId: "-239"),
            providerId: "tonstakers"
        )
        let address = TONRawAddress(workchain: 0, hash: Data(repeating: 0xab, count: 32)).userFriendly(isBounceable: true)
        return TONStakeParams(quote: quote, userAddress: address)
    }

    private func makeAddress() -> TONUserFriendlyAddress {
        TONRawAddress(workchain: 0, hash: Data(repeating: 0xab, count: 32)).userFriendly(isBounceable: true)
    }

    @Test("type returns staking")
    func typeReturnsStaking() {
        let (sut, _) = makeSUT()

        #expect(sut.type == .staking)
    }

    @Test("quote calls getQuote on jsObject")
    func quoteCallsGetQuote() async {
        let (sut, mock) = makeSUT()

        _ = try? await sut.quote(params: makeQuoteParams())

        #expect(mock.callRecords.first?.path == "getQuote")
    }

    @Test("quote throws when jsObject throws")
    func quoteThrowsOnError() async {
        let (sut, mock) = makeSUT()
        mock.shouldThrowOnCall = true

        await #expect(throws: (any Error).self) {
            try await sut.quote(params: makeQuoteParams())
        }
    }

    @Test("stakeTransaction calls buildStakeTransaction on jsObject")
    func stakeTransactionCallsBuildStakeTransaction() async {
        let (sut, mock) = makeSUT()

        _ = try? await sut.stakeTransaction(params: makeStakeParams())

        #expect(mock.callRecords.first?.path == "buildStakeTransaction")
    }

    @Test("stakeTransaction throws when jsObject throws")
    func stakeTransactionThrowsOnError() async {
        let (sut, mock) = makeSUT()
        mock.shouldThrowOnCall = true

        await #expect(throws: (any Error).self) {
            try await sut.stakeTransaction(params: makeStakeParams())
        }
    }

    @Test("stakedBalance calls getStakedBalance on jsObject")
    func stakedBalanceCallsGetStakedBalance() async {
        let (sut, mock) = makeSUT()

        _ = try? await sut.stakedBalance(userAddress: makeAddress(), network: TONNetwork(chainId: "-239"))

        #expect(mock.callRecords.first?.path == "getStakedBalance")
    }

    @Test("stakedBalance throws when jsObject throws")
    func stakedBalanceThrowsOnError() async {
        let (sut, mock) = makeSUT()
        mock.shouldThrowOnCall = true

        await #expect(throws: (any Error).self) {
            try await sut.stakedBalance(userAddress: makeAddress(), network: nil)
        }
    }

    @Test("stakingProviderInfo calls getStakingProviderInfo on jsObject")
    func stakingProviderInfoCallsGetStakingProviderInfo() async {
        let (sut, mock) = makeSUT()

        _ = try? await sut.stakingProviderInfo(network: TONNetwork(chainId: "-239"))

        #expect(mock.callRecords.first?.path == "getStakingProviderInfo")
    }

    @Test("stakingProviderInfo throws when jsObject throws")
    func stakingProviderInfoThrowsOnError() async {
        let (sut, mock) = makeSUT()
        mock.shouldThrowOnCall = true

        await #expect(throws: (any Error).self) {
            try await sut.stakingProviderInfo(network: nil)
        }
    }

    @Test("supportedUnstakeModes calls getSupportedUnstakeModes on jsObject")
    func supportedUnstakeModesCallsGetSupportedUnstakeModes() {
        let (sut, mock) = makeSUT()

        _ = try? sut.supportedUnstakeModes()

        #expect(mock.callRecords.first?.path == "getSupportedUnstakeModes")
    }

    @Test("supportedUnstakeModes throws when jsObject throws")
    func supportedUnstakeModesThrowsOnError() {
        let (sut, mock) = makeSUT()
        mock.shouldThrowOnCall = true

        #expect(throws: (any Error).self) {
            try sut.supportedUnstakeModes()
        }
    }

    @Test("JSValueDecodable.from returns provider when providerId exists")
    func fromJSValueWithProviderIdReturnsProvider() throws {
        let context = JSContext()!
        context.evaluateScript("var obj = { providerId: 'tonstakers' }")
        let jsValue = context.objectForKeyedSubscript("obj")!

        let result = try TONStakingProvider<TONTonStakersStakingProviderIdentifier>.from(jsValue)

        #expect(result != nil)
        #expect(result?.identifier.name == "tonstakers")
    }

    @Test("JSValueDecodable.from returns nil when providerId is missing")
    func fromJSValueWithoutProviderIdReturnsNil() throws {
        let context = JSContext()!
        context.evaluateScript("var obj = {}")
        let jsValue = context.objectForKeyedSubscript("obj")!

        let result = try TONStakingProvider<TONTonStakersStakingProviderIdentifier>.from(jsValue)

        #expect(result == nil)
    }
}
