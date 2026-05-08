//
//  WalletsListViewModel.swift
//  TONWalletApp
//
//  Created by Nikita Rodionov on 09.10.2025.
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

@MainActor
class WalletsListViewModel: ObservableObject {
    @Published private(set) var wallets: [WalletViewModel] = []
    @Published private(set) var activeWallet: WalletViewModel?

    var onRemoveAll: (() -> Void)?

    private var subscribers = Set<AnyCancellable>()
    private(set) var kit: TONWalletKit?

    let event = PassthroughSubject<Event, Never>()

    private static let activeWalletAddressKey = "activeWalletAddress"

    init(wallets: [WalletViewModel]) {
        self.wallets = wallets
        self.activeWallet = Self.restoreActiveWallet(from: wallets)
    }

    func add(wallets: [TONWalletProtocol]) {
        let viewModels = wallets.map { WalletViewModel(tonWallet: $0) }
        add(wallets: viewModels)
    }

    func add(wallets: [WalletViewModel]) {
        self.wallets.append(contentsOf: wallets)

        wallets.forEach { wallet in
            let id = wallet.id

            wallet.onRemove = { [weak self] in
                self?.remove(walletID: id)

                if self?.wallets.isEmpty == true {
                    self?.onRemoveAll?()
                }
            }
        }

        if activeWallet == nil {
            activeWallet = Self.restoreActiveWallet(from: self.wallets)
        }
    }

    func selectActive(wallet: WalletViewModel) {
        guard wallets.contains(where: { $0.id == wallet.id }) else { return }
        activeWallet = wallet
        UserDefaults.standard.set(wallet.address, forKey: Self.activeWalletAddressKey)
    }

    private static func restoreActiveWallet(from wallets: [WalletViewModel]) -> WalletViewModel? {
        guard !wallets.isEmpty else { return nil }
        let savedAddress = UserDefaults.standard.string(forKey: activeWalletAddressKey)
        return wallets.first(where: { $0.address == savedAddress }) ?? wallets.first
    }
    
    func waitForEvents() {
        subscribers.removeAll()
        
        TONEventsHandler.shared.events
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                switch event {
                case .transactionRequest(let request):
                    self?.event.send(Event(transactionRequest: request))
                case .signDataRequest(let request):
                    self?.event.send(Event(signDataRequest: request))
                case .connectRequest(let request):
                    self?.event.send(Event(connectionRequest: request))
                default: ()
                }
            }
            .store(in: &subscribers)
        
        Task {
            self.kit = await TONWalletKit.shared()
            try kit?.add(eventsHandler: TONEventsHandler.shared)
        }
    }
    
    private func remove(walletID: WalletViewModel.ID) {
        let wasActive = activeWallet?.id == walletID
        self.wallets.removeAll { $0.id == walletID }

        if wasActive {
            activeWallet = wallets.first
            if let address = activeWallet?.address {
                UserDefaults.standard.set(address, forKey: Self.activeWalletAddressKey)
            } else {
                UserDefaults.standard.removeObject(forKey: Self.activeWalletAddressKey)
            }
        }
    }
}

extension WalletsListViewModel {
    
    struct Event: Identifiable {
        let id = UUID()
        let transactionRequest: TONWalletSendTransactionRequest?
        let signDataRequest: TONWalletSignDataRequest?
        let connectionRequest: TONWalletConnectionRequest?
        
        init(
            transactionRequest: TONWalletSendTransactionRequest? = nil,
            signDataRequest: TONWalletSignDataRequest? = nil,
            connectionRequest: TONWalletConnectionRequest? = nil
        ) {
            self.transactionRequest = transactionRequest
            self.signDataRequest = signDataRequest
            self.connectionRequest = connectionRequest
        }
    }
}
