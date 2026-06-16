//
//  SendableJettonViewModel.swift
//  TONWalletApp
//
//  Created by Nikita Rodionov on 01.11.2025.
//  
//  Copyright (c) 2025 TON Connect
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Foundation
import Combine
import TONWalletKit

final class SendableJettonViewModel: SendableTokenViewModel {
    var name: String { jetton.info.name ?? "Unknown Jetton" }
    var symbol: String {  jetton.info.symbol ?? "UNKNOWN" }
    var decimals: Int { jetton.decimalsNumber ?? 9 }
    var requiredAmountInfo: String { "Enter amount in \(symbol) units" }
    var jettonAddress: TONUserFriendlyAddress? { jetton.address }
    var iconURL: URL? { jetton.info.image?.smallUrl ?? jetton.info.image?.url }
    var balance: String {
        if let streamed = streamedBalance { return streamed }
        return jettonBalance.flatMap { formatter.string(from: $0) } ?? "Unknown Balance"
    }

    private lazy var formatter: TONBalanceFormatter = {
        let formatter = TONBalanceFormatter()
        formatter.nanoUnitDecimalsNumber = decimals
        return formatter
    }()

    let jetton: TONJetton
    let wallet: any TONWalletProtocol
    private(set) var jettonBalance: TONBalance?
    private var streamedBalance: String?

    private let balanceSubject = PassthroughSubject<Void, Never>()
    var balanceChanges: AnyPublisher<Void, Never> { balanceSubject.eraseToAnyPublisher() }

    private var subscribers = Set<AnyCancellable>()

    init(jetton: TONJetton, wallet: any TONWalletProtocol) {
        self.jetton = jetton
        self.jettonBalance = jetton.balance
        self.wallet = wallet
        subscribeToBalanceChanges()
    }

    func send(amount: String, address: String) async throws {
        guard let amount = formatter.amount(from: amount) else {
            return
        }

        let request = TONJettonsTransferRequest(
            jettonAddress: jetton.address,
            transferAmount: amount,
            recipientAddress: try TONUserFriendlyAddress(value: address),
        )

        let transactionRequest = try await wallet.transferJettonTransaction(request: request)
        _ = try await wallet.send(transactionRequest: transactionRequest)
    }

    func updateBalance() async throws {
        let fresh = try await wallet.jettonBalance(jettonAddress: jetton.address)
        self.jettonBalance = fresh
        self.streamedBalance = nil
        balanceSubject.send()
    }

    private func subscribeToBalanceChanges() {
        let ownerAddress = wallet.address.value
        let masterAddress = jetton.address.value
        Task { [weak self] in
            do {
                let publisher = try await TONWalletKit.shared().streaming()
                    .jettons(network: .mainnet, address: ownerAddress)
                guard let self else { return }
                publisher
                    .receive(on: DispatchQueue.main)
                    .sink(
                        receiveCompletion: { _ in },
                        receiveValue: { [weak self] update in
                            guard update.status == .finalized else { return }
                            guard update.masterAddress.value == masterAddress else { return }
                            guard let formatted = update.balance else { return }
                            self?.streamedBalance = formatted
                            self?.balanceSubject.send()
                        }
                    )
                    .store(in: &self.subscribers)
            } catch {
                debugPrint("Failed to subscribe to jetton balance stream: \(error)")
            }
        }
    }
}
