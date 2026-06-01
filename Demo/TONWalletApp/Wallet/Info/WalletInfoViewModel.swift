//
//  WalletInfoViewModel.swift
//  TONWalletApp
//
//  Created by Nikita Rodionov on 30.09.2025.
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
import TONWalletKit
import Combine

@MainActor
class WalletInfoViewModel: ObservableObject {
    let wallet: TONWalletProtocol

    var address: String { wallet.address.value }
    
    @Published private(set) var formattedBalance: String?
    private(set) var balance: TONBalance?
    
    private var subscribers = Set<AnyCancellable>()
    
    init(wallet: TONWalletProtocol) {
        self.wallet = wallet
    }
    
    func load() async {
        subscribeToBalanceChanges()
        
        if formattedBalance != nil { return }
        
        do {
            let formatter = TONTokenAmountFormatter()
            let balance = try await wallet.balance()
            self.balance = balance
            self.formattedBalance = formatter.string(from: balance)
        } catch {
            self.formattedBalance = "Unknown balance"
            debugPrint(error.localizedDescription)
        }
    }
    
    func subscribeToBalanceChanges() {
        Task {
            try await TONWalletKit.shared().streaming().balance(network: .mainnet, address: address)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { _ in },
                    receiveValue: { [weak self] update in
                        guard update.status == .finalized else { return }
                        self?.balance = update.rawBalance
                        self?.formattedBalance = update.balance
                    }
                )
                .store(in: &subscribers)
        }
    }
}
