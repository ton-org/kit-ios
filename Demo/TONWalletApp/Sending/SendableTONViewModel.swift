//
//  SendableTONViewModel.swift
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

final class SendableTONViewModel: SendableTokenViewModel {
    var name: String { "The Open Network" }
    var symbol: String { "TON" }
    var decimals: Int { 9 }
    var requiredAmountInfo: String { "Minimum transaction: 0.0001 TON" }

    private(set) var balance: String

    let wallet: any TONWalletProtocol
    let formatter: TONBalanceFormatter = {
        let formatter = TONBalanceFormatter()
        formatter.nanoUnitDecimalsNumber = 9
        return formatter
    }()

    private let balanceSubject = PassthroughSubject<Void, Never>()
    var balanceChanges: AnyPublisher<Void, Never> { balanceSubject.eraseToAnyPublisher() }

    private var subscribers = Set<AnyCancellable>()

    init(balance: TONBalance, wallet: any TONWalletProtocol) {
        self.balance = formatter.string(from: balance) ?? "Unknown balance"
        self.wallet = wallet
        subscribeToBalanceChanges()
    }

    func send(amount: String, address: String) async throws {
        guard let amount = formatter.amount(from: amount) else {
            return
        }

        let request = TONTransferRequest(
            transferAmount: amount,
            recipientAddress: try TONUserFriendlyAddress(
                value: address
            )
        )
        let transactionRequest = try await wallet.transferTONTransaction(request: request)
        _ = try await wallet.send(transactionRequest: transactionRequest)
    }

    func updateBalance() async throws {
        balance = formatter.string(from: try await wallet.balance()) ?? "Unknown balance"
        balanceSubject.send()
    }

    private func subscribeToBalanceChanges() {
        let address = wallet.address.value
        Task { [weak self] in
            do {
                let publisher = try await TONWalletKit.shared().streaming()
                    .balance(network: .mainnet, address: address)
                guard let self else { return }
                publisher
                    .receive(on: DispatchQueue.main)
                    .sink(
                        receiveCompletion: { _ in },
                        receiveValue: { [weak self] update in
                            guard update.status == .finalized else { return }
                            self?.balance = update.balance
                            self?.balanceSubject.send()
                        }
                    )
                    .store(in: &self.subscribers)
            } catch {
                debugPrint("Failed to subscribe to TON balance stream: \(error)")
            }
        }
    }
}
