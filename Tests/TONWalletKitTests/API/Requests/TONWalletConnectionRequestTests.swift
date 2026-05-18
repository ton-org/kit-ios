import Testing
import Foundation
@testable import TONWalletKit

@Suite("TONWalletConnectionRequest Tests")
struct TONWalletConnectionRequestTests {

    private let testAddress: TONUserFriendlyAddress = {
        let hash = Data(repeating: 0xab, count: 32)
        return TONRawAddress(workchain: 0, hash: hash).userFriendly(isBounceable: true)
    }()

    private func makeEvent() -> TONConnectionRequestEvent {
        TONConnectionRequestEvent(
            id: "event-1",
            requestedItems: [],
            preview: TONConnectionRequestEventPreview(permissions: [])
        )
    }

    @Test("approve(walletId:) calls getWallet then approveConnectRequest")
    func approveWalletIdCallsApprove() async throws {
        let mock = MockJSDynamicObject()
        let event = makeEvent()
        let sut = TONWalletConnectionRequest(context: mock, event: event)

        try? await sut.approve(walletId: "w1")

        let paths = mock.callRecords.map(\.path)
        #expect(paths.contains("walletKit.getWallet"))
    }

    @Test("approve(wallet:) calls approveConnectRequest")
    func approveWalletCallsApprove() async throws {
        let mock = MockJSDynamicObject()
        let event = makeEvent()
        let sut = TONWalletConnectionRequest(context: mock, event: event)
        let walletMock = MockJSDynamicObject()
        let wallet = TONWallet(jsWallet: walletMock, id: "w1", address: testAddress, client: MockAPIClient())

        try await sut.approve(wallet: wallet)

        let paths = mock.callRecords.map(\.path)
        #expect(paths.contains("walletKit.approveConnectRequest"))
    }

    @Test("reject() calls rejectConnectRequest")
    func rejectCallsReject() async throws {
        let mock = MockJSDynamicObject()
        let event = makeEvent()
        let sut = TONWalletConnectionRequest(context: mock, event: event)

        try await sut.reject()

        let paths = mock.callRecords.map(\.path)
        #expect(paths.contains("walletKit.rejectConnectRequest"))
    }

    @Test("approve(wallet:) with throwing context throws")
    func approveThrowsOnError() async {
        let mock = MockJSDynamicObject()
        mock.shouldThrowOnCall = true
        let event = makeEvent()
        let sut = TONWalletConnectionRequest(context: mock, event: event)
        let walletMock = MockJSDynamicObject()
        let wallet = TONWallet(jsWallet: walletMock, id: "w1", address: testAddress, client: MockAPIClient())

        await #expect(throws: (any Error).self) {
            try await sut.approve(wallet: wallet)
        }
    }

    @Test("reject() with throwing context throws")
    func rejectThrowsOnError() async {
        let mock = MockJSDynamicObject()
        mock.shouldThrowOnCall = true
        let event = makeEvent()
        let sut = TONWalletConnectionRequest(context: mock, event: event)

        await #expect(throws: (any Error).self) {
            try await sut.reject()
        }
    }
}
