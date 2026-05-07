import Testing
import Foundation
import _BigInt
@testable import TONWalletKit

@Suite("TONWallet Tests")
struct TONWalletTests {

    private let testAddress: TONUserFriendlyAddress = {
        let hash = Data(repeating: 0xab, count: 32)
        return TONRawAddress(workchain: 0, hash: hash)
            .userFriendly(isBounceable: true)
    }()

    private func makeSUT() -> (sut: TONWallet, mock: MockJSDynamicObject) {
        let mock = MockJSDynamicObject()
        let sut = TONWallet(jsWallet: mock, id: "test-wallet", address: testAddress)
        return (sut, mock)
    }

    @Test("init stores id and address")
    func initStoresProperties() {
        let (sut, _) = makeSUT()

        #expect(sut.id == "test-wallet")
        #expect(sut.address == testAddress)
    }

    @Test("balance() calls getBalance")
    func balanceCallsGetBalance() async {
        let (sut, mock) = makeSUT()

        _ = try? await sut.balance()

        #expect(mock.callRecords.first?.path == "getBalance")
    }

    @Test("transferTONTransaction(request:) calls createTransferTonTransaction")
    func transferTONTransactionCallsSingle() async {
        let (sut, mock) = makeSUT()
        let request = TONTransferRequest(
            transferAmount: TONTokenAmount(nanoUnits: BigInt(1_000_000_000)),
            recipientAddress: testAddress
        )

        _ = try? await sut.transferTONTransaction(request: request)

        #expect(mock.callRecords.first?.path == "createTransferTonTransaction")
    }

    @Test("transferTONTransaction(requests:) calls createTransferMultiTonTransaction")
    func transferTONTransactionCallsMulti() async {
        let (sut, mock) = makeSUT()
        let request = TONTransferRequest(
            transferAmount: TONTokenAmount(nanoUnits: BigInt(1_000_000_000)),
            recipientAddress: testAddress
        )

        _ = try? await sut.transferTONTransaction(requests: [request])

        #expect(mock.callRecords.first?.path == "createTransferMultiTonTransaction")
    }

    @Test("send() calls sendTransaction")
    func sendCallsSendTransaction() async {
        let (sut, mock) = makeSUT()
        let request = TONTransactionRequest(messages: [])

        try? await sut.send(transactionRequest: request)

        #expect(mock.callRecords.first?.path == "sendTransaction")
    }

    @Test("preview() calls getTransactionPreview")
    func previewCallsGetTransactionPreview() async {
        let (sut, mock) = makeSUT()
        let request = TONTransactionRequest(messages: [])

        _ = try? await sut.preview(transactionRequest: request)

        #expect(mock.callRecords.first?.path == "getTransactionPreview")
    }

    @Test("transferNFTTransaction() calls createTransferNftTransaction")
    func transferNFTTransactionCalls() async {
        let (sut, mock) = makeSUT()
        let request = TONNFTTransferRequest(
            nftAddress: testAddress,
            recipientAddress: testAddress
        )

        _ = try? await sut.transferNFTTransaction(request: request)

        #expect(mock.callRecords.first?.path == "createTransferNftTransaction")
    }

    @Test("nfts() calls getNfts")
    func nftsCallsGetNfts() async {
        let (sut, mock) = makeSUT()
        let request = TONNFTsRequest()

        _ = try? await sut.nfts(request: request)

        #expect(mock.callRecords.first?.path == "getNfts")
    }

    @Test("jettonBalance() calls getJettonBalance")
    func jettonBalanceCallsGetJettonBalance() async {
        let (sut, mock) = makeSUT()

        _ = try? await sut.jettonBalance(jettonAddress: testAddress)

        #expect(mock.callRecords.first?.path == "getJettonBalance")
    }

    @Test("transferJettonTransaction() calls createTransferJettonTransaction")
    func transferJettonTransactionCalls() async {
        let (sut, mock) = makeSUT()
        let request = TONJettonsTransferRequest(
            jettonAddress: testAddress,
            transferAmount: TONTokenAmount(nanoUnits: BigInt(1_000_000)),
            recipientAddress: testAddress
        )

        _ = try? await sut.transferJettonTransaction(request: request)

        #expect(mock.callRecords.first?.path == "createTransferJettonTransaction")
    }

    @Test("transferNFTTransaction(raw request) calls createTransferNftRawTransaction")
    func transferNFTRawTransactionCalls() async {
        let (sut, mock) = makeSUT()
        let message = TONNFTRawTransferRequestMessage(
            queryId: BigInt(1),
            newOwner: testAddress,
            forwardAmount: BigInt(0)
        )
        let request = TONNFTRawTransferRequest(
            nftAddress: testAddress,
            transferAmount: TONTokenAmount(nanoUnits: BigInt(50_000_000)),
            message: message
        )

        _ = try? await sut.transferNFTTransaction(request: request)

        #expect(mock.callRecords.first?.path == "createTransferNftRawTransaction")
    }

    @Test("nft(address:) calls getNft")
    func nftCallsGetNft() async {
        let (sut, mock) = makeSUT()

        _ = try? await sut.nft(address: testAddress)

        #expect(mock.callRecords.first?.path == "getNft")
    }

    @Test("jettonWalletAddress() calls getJettonWalletAddress")
    func jettonWalletAddressCallsGetJettonWalletAddress() async {
        let (sut, mock) = makeSUT()

        _ = try? await sut.jettonWalletAddress(jettonAddress: testAddress)

        #expect(mock.callRecords.first?.path == "getJettonWalletAddress")
    }

    @Test("jettons() calls getJettons")
    func jettonsCallsGetJettons() async {
        let (sut, mock) = makeSUT()
        let request = TONJettonsRequest(pagination: TONPagination(limit: 10))

        _ = try? await sut.jettons(request: request)

        #expect(mock.callRecords.first?.path == "getJettons")
    }
}
