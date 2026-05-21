//
//  CreateWalletViewModel.swift
//  TONWalletApp
//
//  Copyright (c) 2026 TON Connect
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

@MainActor
class CreateWalletViewModel: ObservableObject {
    @Published var mnemonic: TONMnemonic = TONMnemonic()
    @Published var isGenerating = false
    @Published var isAdding = false

    private var walletAdapter: (any TONWalletAdapterProtocol)?
    private let storage = WalletsStorage()

    var canContinue: Bool { walletAdapter != nil && !isGenerating }

    func generate() async {
        if walletAdapter != nil { return }

        isGenerating = true
        defer { isGenerating = false }

        do {
            let kit = await TONWalletKit.shared()
            let result = try await kit.createWallet(
                parameters: TONV5R1WalletParameters(network: .mainnet, domain: nil)
            )

            mnemonic = result.mnemonic
            walletAdapter = result.walletAdapter
        } catch {
            debugPrint(error.localizedDescription)
        }
    }

    func add() async -> TONWalletProtocol? {
        guard let walletAdapter else { return nil }

        isAdding = true

        let data = WalletData(
            name: "Test",
            mnemonic: mnemonic.value,
            network: TONNetwork.mainnet.chainId,
            version: .v5r1
        )

        do {
            let kit = await TONWalletKit.shared()
            let tonWallet = try await kit.add(walletAdapter: walletAdapter)
            try storage.add(wallet: WalletEntity(address: tonWallet.address.value, data: data))

            return tonWallet
        } catch {
            isAdding = false

            debugPrint(error.localizedDescription)

            return nil
        }
    }
}
