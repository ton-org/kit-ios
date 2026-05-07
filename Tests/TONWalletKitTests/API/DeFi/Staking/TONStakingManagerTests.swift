import Testing
import JavaScriptCore
@testable import TONWalletKit
import _BigInt

@Suite("TONStakingManager Tests")
struct TONStakingManagerTests {

    private func makeSUT() -> (sut: TONStakingManager, mock: MockJSDynamicObject) {
        let mock = MockJSDynamicObject()
        let sut = TONStakingManager(jsObject: mock)
        return (sut, mock)
    }

    private func makeProvider() -> TONStakingProvider<TONTonStakersStakingProviderIdentifier> {
        let providerMock = MockJSDynamicObject()
        let identifier = TONTonStakersStakingProviderIdentifier(name: "tonstakers")
        return TONStakingProvider(jsObject: providerMock, identifier: identifier)
    }

    private func makeIdentifier(name: String = "tonstakers") -> TONTonStakersStakingProviderIdentifier {
        TONTonStakersStakingProviderIdentifier(name: name)
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

    @Test("register calls registerProvider on jsObject")
    func registerCallsRegisterProvider() throws {
        let (sut, mock) = makeSUT()

        try sut.register(provider: makeProvider())

        #expect(mock.callRecords.first?.path == "registerProvider")
    }

    @Test("set(defaultProviderId:) calls setDefaultProvider on jsObject")
    func setDefaultProviderIdCallsSetDefaultProvider() throws {
        let (sut, mock) = makeSUT()

        try sut.set(defaultProviderId: makeIdentifier())

        #expect(mock.callRecords.first?.path == "setDefaultProvider")
    }

    @Test("provider(with:) calls getProvider on jsObject")
    func providerWithIdCallsGetProvider() throws {
        let (sut, mock) = makeSUT()

        _ = try sut.provider(with: makeIdentifier())

        #expect(mock.callRecords.first?.path == "getProvider")
    }

    @Test("registeredProviders calls getRegisteredProviders on jsObject")
    func registeredProvidersCallsGetRegisteredProviders() throws {
        let (sut, mock) = makeSUT()
        mock.stubbedResults["getRegisteredProviders"] = ["tonstakers"] as [String]

        let result = try sut.registeredProviders()

        #expect(mock.callRecords.first?.path == "getRegisteredProviders")
        #expect(result.map { $0.name } == ["tonstakers"])
    }

    @Test("hasProvider(with:) calls hasProvider on jsObject")
    func hasProviderCallsHasProvider() throws {
        let (sut, mock) = makeSUT()
        mock.stubbedResults["hasProvider"] = true

        let result = try sut.hasProvider(with: makeIdentifier())

        #expect(mock.callRecords.first?.path == "hasProvider")
        #expect(result == true)
    }

    @Test("quote(params:identifier:) calls getQuote with params and identifier name")
    func quoteWithIdentifierCallsGetQuote() async {
        let (sut, mock) = makeSUT()

        _ = try? await sut.quote(params: makeQuoteParams(), identifier: makeIdentifier())

        #expect(mock.callRecords.first?.path == "getQuote")
        #expect(mock.callRecords.first?.args.count == 2)
    }

    @Test("quote(params:) calls getQuote with params only")
    func quoteWithoutIdentifierCallsGetQuote() async {
        let (sut, mock) = makeSUT()

        _ = try? await sut.quote(params: makeQuoteParams())

        #expect(mock.callRecords.first?.path == "getQuote")
        #expect(mock.callRecords.first?.args.count == 1)
    }

    @Test("stakeTransaction(params:identifier:) calls buildStakeTransaction with params and identifier name")
    func stakeTransactionWithIdentifierCallsBuildStakeTransaction() async {
        let (sut, mock) = makeSUT()

        _ = try? await sut.stakeTransaction(params: makeStakeParams(), identifier: makeIdentifier())

        #expect(mock.callRecords.first?.path == "buildStakeTransaction")
        #expect(mock.callRecords.first?.args.count == 2)
    }

    @Test("stakeTransaction(params:) calls buildStakeTransaction with params only")
    func stakeTransactionWithoutIdentifierCallsBuildStakeTransaction() async {
        let (sut, mock) = makeSUT()

        _ = try? await sut.stakeTransaction(params: makeStakeParams())

        #expect(mock.callRecords.first?.path == "buildStakeTransaction")
        #expect(mock.callRecords.first?.args.count == 1)
    }

    @Test("stakedBalance calls getStakedBalance with address, network and identifier name")
    func stakedBalanceWithIdentifierCallsGetStakedBalance() async {
        let (sut, mock) = makeSUT()

        _ = try? await sut.stakedBalance(
            userAddress: makeAddress(),
            network: TONNetwork(chainId: "-239"),
            identifier: makeIdentifier()
        )

        #expect(mock.callRecords.first?.path == "getStakedBalance")
        #expect(mock.callRecords.first?.args.count == 3)
    }

    @Test("stakedBalance with nil identifier passes nil")
    func stakedBalanceWithNilIdentifierPassesNil() async {
        let (sut, mock) = makeSUT()

        _ = try? await sut.stakedBalance(
            userAddress: makeAddress(),
            network: nil,
            identifier: nil
        )

        #expect(mock.callRecords.first?.path == "getStakedBalance")
    }

    @Test("stakingProviderInfo calls getStakingProviderInfo with network and identifier name")
    func stakingProviderInfoWithIdentifierCallsGetStakingProviderInfo() async {
        let (sut, mock) = makeSUT()

        _ = try? await sut.stakingProviderInfo(
            network: TONNetwork(chainId: "-239"),
            identifier: makeIdentifier()
        )

        #expect(mock.callRecords.first?.path == "getStakingProviderInfo")
    }

    @Test("supportedUnstakeModes calls getSupportedUnstakeModes with identifier name")
    func supportedUnstakeModesWithIdentifierCallsGetSupportedUnstakeModes() {
        let (sut, mock) = makeSUT()

        _ = try? sut.supportedUnstakeModes(identifier: makeIdentifier())

        #expect(mock.callRecords.first?.path == "getSupportedUnstakeModes")
    }

    @Test("supportedUnstakeModes with nil identifier passes nil")
    func supportedUnstakeModesWithNilIdentifierPassesNil() {
        let (sut, mock) = makeSUT()

        _ = try? sut.supportedUnstakeModes(identifier: nil)

        #expect(mock.callRecords.first?.path == "getSupportedUnstakeModes")
    }

    @Test("JSValueDecodable.from returns manager")
    func fromJSValueReturnsManager() throws {
        let context = JSContext()!
        let jsValue = JSValue(object: [:], in: context)!

        let result = try TONStakingManager.from(jsValue)

        #expect(result != nil)
    }
}
