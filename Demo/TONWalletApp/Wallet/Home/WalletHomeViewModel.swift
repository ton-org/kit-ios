//
//  WalletHomeViewModel.swift
//  TONWalletApp
//
//  Created by Nikita Rodionov on 27.04.2026.
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
import Combine
import TONWalletKit

@MainActor
final class WalletHomeViewModel: ObservableObject {
    static let maxAssets = 3
    static let maxNFTs = 5
    static let maxFractionDigits = 5

    @Published private(set) var title: String = "Wallet"
    @Published private(set) var truncatedAddress: String = ""
    @Published private(set) var assets: [WalletHomeAssetItem] = []
    @Published private(set) var nftsPreview: [WalletNFTsListItem] = []
    @Published private(set) var totalBalanceInteger: String = "0"
    @Published private(set) var totalBalanceFraction: String = ""
    @Published private(set) var hasMoreAssets: Bool = false
    @Published private(set) var hasMoreNFTs: Bool = false

    let walletsList: WalletsListViewModel
    private(set) var wallet: WalletViewModel
    private var subscribers = Set<AnyCancellable>()

    init(walletsList: WalletsListViewModel, wallet: WalletViewModel) {
        self.walletsList = walletsList
        self.wallet = wallet

        rebind()
    }

    func bind(toActive wallet: WalletViewModel) {
        guard wallet.id != self.wallet.id else { return }
        self.wallet = wallet
        rebind()
    }

    func loadIfNeeded() {
        Task { await wallet.info.load() }
        Task { await wallet.jettonsViewModel.loadJettons() }
        Task { await wallet.nftsViewModel.loadNFTs() }
    }

    func sendTokensViewModel() -> SendTokensViewModel? {
        wallet.sendTokensViewModel()
    }

    private func rebind() {
        subscribers.removeAll()

        title = displayTitle(for: wallet)
        truncatedAddress = Self.shortAddress(wallet.address)

        wallet.info.$formattedBalance
            .receive(on: DispatchQueue.main)
            .sink { [weak self] balance in
                self?.refreshTotalBalance(tonFormatted: balance)
            }
            .store(in: &subscribers)

        wallet.jettonsViewModel.$jettons
            .receive(on: DispatchQueue.main)
            .sink { [weak self] jettons in
                self?.refreshAssets(jettons: jettons)
            }
            .store(in: &subscribers)

        wallet.nftsViewModel.$nfts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] nfts in
                guard let self else { return }
                self.nftsPreview = Array(nfts.prefix(Self.maxNFTs))
                self.hasMoreNFTs = nfts.count > Self.maxNFTs
            }
            .store(in: &subscribers)

        refreshAssets(jettons: wallet.jettonsViewModel.jettons)
        refreshTotalBalance(tonFormatted: wallet.info.formattedBalance)
    }

    private func refreshTotalBalance(tonFormatted: String?) {
        let trimmed = Self.trim(tonFormatted ?? "0", maxFractionDigits: Self.maxFractionDigits)
        let parts = trimmed.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        totalBalanceInteger = String(parts.first ?? "0")
        if parts.count == 2, let fraction = parts.last, !fraction.isEmpty {
            totalBalanceFraction = ".\(fraction)"
        } else {
            totalBalanceFraction = ""
        }
    }

    private func refreshAssets(jettons: [WalletJettonsListItem]) {
        var items: [WalletHomeAssetItem] = []

        let tonAmount = Self.trim(wallet.info.formattedBalance ?? "0", maxFractionDigits: Self.maxFractionDigits)
        let tonItem = WalletHomeAssetItem(
            id: "ton",
            name: "Toncoin",
            symbol: "TON",
            formattedAmount: "\(tonAmount) TON",
            icon: .ton
        )
        items.append(tonItem)

        for jetton in jettons.prefix(Self.maxAssets - 1) {
            let amount = Self.trim(jetton.balance, maxFractionDigits: Self.maxFractionDigits)
            items.append(
                WalletHomeAssetItem(
                    id: jetton.address,
                    name: jetton.name,
                    symbol: jetton.symbol,
                    formattedAmount: "\(amount) \(jetton.symbol)",
                    icon: jettonIcon(for: jetton)
                )
            )
        }

        assets = items
        hasMoreAssets = jettons.count > (Self.maxAssets - 1)
    }

    private static func trim(_ formatted: String, maxFractionDigits: Int) -> String {
        guard let dotIndex = formatted.firstIndex(of: ".") else { return formatted }
        let fractionStart = formatted.index(after: dotIndex)
        let fraction = formatted[fractionStart...]
        guard fraction.count > maxFractionDigits else { return formatted }
        let cutoff = formatted.index(fractionStart, offsetBy: maxFractionDigits)
        var truncated = String(formatted[..<cutoff])
        while truncated.hasSuffix("0") { truncated.removeLast() }
        if truncated.hasSuffix(".") { truncated.removeLast() }
        return truncated
    }

    private func jettonIcon(for jetton: WalletJettonsListItem) -> WalletHomeAssetItem.Icon {
        if let image = jetton.image {
            return .image(image)
        } else if let url = jetton.imageURL {
            return .url(url)
        }
        return .placeholder(symbol: jetton.symbol)
    }

    private func displayTitle(for wallet: WalletViewModel) -> String {
        if let index = walletsList.wallets.firstIndex(where: { $0.id == wallet.id }) {
            return "Wallet \(index + 1)"
        }
        return "Wallet"
    }

    static func shortAddress(_ address: String) -> String {
        guard address.count > 10 else { return address }
        let prefix = String(address.prefix(4))
        let suffix = String(address.suffix(6))
        return "\(prefix)...\(suffix)"
    }
}
