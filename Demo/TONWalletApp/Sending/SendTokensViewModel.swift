//
//  SendTokensViewModel.swift
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

@MainActor
class SendTokensViewModel: ObservableObject {

    // MARK: - Form

    @Published var recipientAddress = ""
    @Published var amount = ""
    @Published private(set) var selectedToken: any SendableTokenViewModel
    @Published private(set) var isSending = false

    // MARK: - Gasless

    @Published var gaslessEnabled = false
    @Published private(set) var feeAssets: [FeeAsset] = []
    @Published var selectedFeeAsset: FeeAsset?
    @Published private(set) var isQuoting = false
    @Published private(set) var gaslessFeeText: String?
    @Published private(set) var gaslessError: String?

    private let tokens: [any SendableTokenViewModel]
    private let network: TONNetwork = .mainnet

    private var relayAddress: TONUserFriendlyAddress?
    private var currentQuote: TONGaslessQuote?

    private var quoteTask: Task<Void, Never>?
    private var configTask: Task<Void, Never>?
    private var balanceSubscribers = Set<AnyCancellable>()
    private var subscribers = Set<AnyCancellable>()

    /// USDT jetton master on mainnet — preferred default fee asset, mirroring the JS demo.
    private static let usdtMasterMainnet = "EQCxE6mUtQJKFnGfaROTKOt1lZbDiiX1kCixRv7Nw2Id_sDs"

    /// Per-jetton display metadata, keyed by master address, built from the available tokens.
    private lazy var jettonMetadata: [String: FeeAsset] = {
        var map: [String: FeeAsset] = [:]
        for token in tokens {
            guard let address = token.jettonAddress else { continue }
            map[address.value] = FeeAsset(
                address: address,
                symbol: token.symbol,
                decimals: token.decimals,
                iconURL: token.iconURL
            )
        }
        return map
    }()

    var availableTokens: [any SendableTokenViewModel] {
        return tokens
    }

    /// Gasless is offered only for jettons (native TON already pays its own gas).
    var canUseGasless: Bool {
        selectedToken.jettonAddress != nil
    }

    var sendButtonTitle: String {
        (gaslessEnabled && canUseGasless) ? "Send Gasless" : "Send \(selectedToken.symbol)"
    }

    var canSend: Bool {
        guard !recipientAddress.isEmpty, !amount.isEmpty, !isSending else {
            return false
        }
        if gaslessEnabled && canUseGasless {
            return selectedFeeAsset != nil && !isQuoting && currentQuote != nil && gaslessError == nil
        }
        return true
    }

    init?(tokens: [any SendableTokenViewModel]) {
        if tokens.isEmpty {
            return nil
        }

        self.tokens = tokens
        self.selectedToken = tokens[0]

        for token in tokens {
            token.balanceChanges
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    self?.objectWillChange.send()
                }
                .store(in: &balanceSubscribers)
        }

        observeGaslessToggle()
        observeQuoteInputs()
    }

    // MARK: - Token selection

    func select(token: any SendableTokenViewModel) {
        selectedToken = token
        recipientAddress = ""
        amount = ""
        feeAssets = []
        selectedFeeAsset = nil
        relayAddress = nil
        gaslessEnabled = false
        clearGaslessQuote()
    }

    func useMaxAmount() {
        amount = selectedToken.balance
    }

    // MARK: - Sending

    func send() {
        if isSending { return }

        isSending = true

        Task { [weak self] in
            guard let self else { return }
            do {
                if self.gaslessEnabled && self.canUseGasless {
                    try await self.sendGasless()
                } else {
                    try await self.selectedToken.send(amount: self.amount, address: self.recipientAddress)
                }
                try? await self.selectedToken.updateBalance()
                self.objectWillChange.send()
            } catch {
                self.gaslessError = "Failed to send transaction"
                debugPrint(error)
            }
            self.isSending = false
        }
    }

    private func sendGasless() async throws {
        guard
            let jettonAddress = selectedToken.jettonAddress,
            let feeAsset = selectedFeeAsset,
            let relay = relayAddress
        else {
            throw SendTokensError.gaslessNotReady
        }

        let wallet = selectedToken.wallet
        let formatter = makeFormatter(decimals: selectedToken.decimals)

        guard let transferAmount = formatter.amount(from: amount) else {
            throw SendTokensError.invalidAmount
        }

        let recipient = try TONUserFriendlyAddress(value: recipientAddress)
        let gasless = try await TONWalletKit.shared().gasless()

        // Re-quote at send time: the displayed quote may have expired in the meantime.
        let quote = try await gaslessQuote(
            gasless: gasless,
            wallet: wallet,
            jettonAddress: jettonAddress,
            feeAsset: feeAsset,
            transferAmount: transferAmount,
            recipient: recipient,
            relay: relay
        )

        let signInput = TONTransactionRequest(
            messages: quote.messages,
            network: quote.network,
            validUntil: quote.validUntil,
            fromAddress: wallet.address.value
        )
        let internalBoc = try await wallet.signedSignMessage(input: signInput, fakeSignature: false)

        let sendParams = TONGaslessSendParams(
            network: network,
            walletPublicKey: try wallet.publicKey(),
            internalBoc: internalBoc
        )
        _ = try await gasless.sendTransaction(params: sendParams)
    }

    // MARK: - Gasless config & quoting

    private func observeGaslessToggle() {
        $gaslessEnabled
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                guard let self else { return }
                if enabled {
                    self.loadGaslessConfig()
                } else {
                    self.clearGaslessQuote()
                }
            }
            .store(in: &subscribers)
    }

    private func observeQuoteInputs() {
        Publishers.CombineLatest4($recipientAddress, $amount, $selectedFeeAsset, $gaslessEnabled)
            .dropFirst()
            .debounce(for: .milliseconds(400), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.requoteIfNeeded()
            }
            .store(in: &subscribers)
    }

    private func loadGaslessConfig() {
        configTask?.cancel()
        gaslessError = nil

        configTask = Task { [weak self] in
            guard let self else { return }
            do {
                let gasless = try await TONWalletKit.shared().gasless()
                let config = try await gasless.config(network: self.network)
                if Task.isCancelled { return }

                self.relayAddress = config.relayAddress
                self.feeAssets = self.resolveFeeAssets(from: config.supportedAssets)
                if self.selectedFeeAsset == nil {
                    self.selectedFeeAsset = self.pickDefaultFeeAsset(self.feeAssets)
                }
            } catch {
                if Task.isCancelled { return }
                self.gaslessError = "Failed to load gasless configuration"
                debugPrint(error)
            }
        }
    }

    private func requoteIfNeeded() {
        quoteTask?.cancel()

        guard
            gaslessEnabled,
            let jettonAddress = selectedToken.jettonAddress,
            let feeAsset = selectedFeeAsset,
            let relay = relayAddress,
            !recipientAddress.isEmpty,
            !amount.isEmpty
        else {
            return
        }

        let wallet = selectedToken.wallet
        let formatter = makeFormatter(decimals: selectedToken.decimals)

        guard let transferAmount = formatter.amount(from: amount) else {
            currentQuote = nil
            gaslessFeeText = nil
            return
        }

        guard let recipient = try? TONUserFriendlyAddress(value: recipientAddress) else {
            currentQuote = nil
            gaslessFeeText = nil
            gaslessError = "Invalid recipient address"
            return
        }

        isQuoting = true
        gaslessError = nil

        quoteTask = Task { [weak self] in
            guard let self else { return }
            do {
                let gasless = try await TONWalletKit.shared().gasless()
                let quote = try await self.gaslessQuote(
                    gasless: gasless,
                    wallet: wallet,
                    jettonAddress: jettonAddress,
                    feeAsset: feeAsset,
                    transferAmount: transferAmount,
                    recipient: recipient,
                    relay: relay
                )
                if Task.isCancelled { return }

                self.currentQuote = quote
                self.gaslessFeeText = self.format(fee: quote.fee, asset: feeAsset)
                self.isQuoting = false
            } catch {
                if Task.isCancelled { return }
                self.currentQuote = nil
                self.gaslessFeeText = nil
                self.gaslessError = "Failed to get gasless quote"
                self.isQuoting = false
                debugPrint(error)
            }
        }
    }

    private func gaslessQuote(
        gasless: any TONGaslessManagerProtocol,
        wallet: any TONWalletProtocol,
        jettonAddress: TONUserFriendlyAddress,
        feeAsset: FeeAsset,
        transferAmount: TONTokenAmount,
        recipient: TONUserFriendlyAddress,
        relay: TONUserFriendlyAddress
    ) async throws -> TONGaslessQuote {
        // Build the jetton transfer with the relayer as `responseDestination` so residual
        // gas is returned to the relayer (mirrors the JS gasless send flow).
        let request = TONJettonsTransferRequest(
            jettonAddress: jettonAddress,
            transferAmount: transferAmount,
            recipientAddress: recipient,
            responseDestination: relay
        )
        let transaction = try await wallet.transferJettonTransaction(request: request)

        let params = TONGaslessQuoteParams(
            network: network,
            feeAsset: feeAsset.address,
            walletAddress: wallet.address,
            walletPublicKey: try wallet.publicKey(),
            messages: transaction.messages
        )
        return try await gasless.quote(params: params)
    }

    private func clearGaslessQuote() {
        quoteTask?.cancel()
        currentQuote = nil
        gaslessFeeText = nil
        gaslessError = nil
        isQuoting = false
    }

    // MARK: - Fee asset resolution

    private func resolveFeeAssets(from supported: [TONGaslessSupportedAsset]) -> [FeeAsset] {
        supported.map { asset in
            if let known = jettonMetadata[asset.address.value] {
                return known
            }
            return FeeAsset(
                address: asset.address,
                symbol: shortAddress(asset.address.value),
                decimals: 9,
                iconURL: nil
            )
        }
    }

    private func pickDefaultFeeAsset(_ assets: [FeeAsset]) -> FeeAsset? {
        if let usdt = assets.first(where: { $0.address.value == Self.usdtMasterMainnet }) {
            return usdt
        }
        return assets.first
    }

    // MARK: - Helpers

    private func makeFormatter(decimals: Int) -> TONBalanceFormatter {
        let formatter = TONBalanceFormatter()
        formatter.nanoUnitDecimalsNumber = decimals
        return formatter
    }

    private func format(fee: TONTokenAmount, asset: FeeAsset) -> String {
        let formatter = makeFormatter(decimals: asset.decimals)
        let value = formatter.string(from: fee) ?? "0"
        return "\(value) \(asset.symbol)"
    }

    private func shortAddress(_ address: String) -> String {
        guard address.count > 8 else { return address }
        return "\(address.prefix(4))…\(address.suffix(4))"
    }
}

enum SendTokensError: LocalizedError {
    case gaslessNotReady
    case invalidAmount

    var errorDescription: String? {
        switch self {
        case .gaslessNotReady: return "Gasless is not ready yet"
        case .invalidAmount: return "Invalid amount"
        }
    }
}
