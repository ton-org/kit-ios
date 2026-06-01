//
//  WalletSignMessageRequestView.swift
//  TONWalletApp
//
//  Created by Nikita Rodionov on 19.05.2026.
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

import SwiftUI
import TONWalletKit

struct WalletSignMessageRequestView: View {
    @StateObject var viewModel: WalletSignMessageRequestViewModel

    @Environment(\.dismiss) var dismiss

    private let logoSize: CGFloat = 64
    private let logoCornerRadius: CGFloat = 16
    private let cardCornerRadius: CGFloat = 16
    private let innerCardCornerRadius: CGFloat = 12
    private let addressTruncation = 8

    private static let tonFormatter = TONTokenAmountFormatter()

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                logos
                    .padding(.top, 24)

                titleBlock
                    .padding(.top, 24)

                walletRow
                    .padding(.top, 24)

                transactionCard
                    .padding(.top, 16)

                if let moneyFlow = viewModel.moneyFlow,
                   shouldShowMoneyFlow(moneyFlow: moneyFlow) {
                    moneyFlowCard(moneyFlow: moneyFlow)
                        .padding(.top, 16)
                }

                if let error = viewModel.previewErrorMessage {
                    previewErrorCard(message: error)
                        .padding(.top, 16)
                }

                TONHoldButton(
                    title: "Hold to sign",
                    icon: TONIcon.fingerprint.image,
                    duration: 3,
                    onComplete: { viewModel.approve() }
                )
                .padding(.top, 24)

                Text("This will sign a transaction that the dApp can submit later. Only approve if you trust the requesting dApp.")
                    .textStyle(.subheadline2)
                    .foregroundStyle(Color.tonTextSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 8)
                    .padding(.top, 16)
            }
            .padding(.horizontal, 16)
            .padding(.top, 44)
            .padding(.bottom, 24)
        }
        .background(Color.tonBgPrimary)
        .overlay(alignment: .topTrailing) {
            closeButton
        }
        .onReceive(viewModel.dismiss) { dismiss() }
    }

    private var closeButton: some View {
        Button {
            viewModel.reject()
        } label: {
            TONIcon.close.image
                .resizable()
                .scaledToFit()
                .size(28)
        }
        .buttonStyle(.plain)
        .padding(.top, 16)
        .padding(.trailing, 16)
    }

    private var logos: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: logoCornerRadius)
                .fill(Color.tonBgFillTertiary)
                .frame(width: logoSize, height: logoSize)

            AsyncImage(url: viewModel.dAppInfo?.iconUrl) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                case .empty, .failure:
                    Color.tonBgFillTertiary
                @unknown default:
                    Color.tonBgFillTertiary
                }
            }
            .frame(width: logoSize, height: logoSize)
            .clipShape(RoundedRectangle(cornerRadius: logoCornerRadius))
        }
        .frame(maxWidth: .infinity)
    }

    private var titleBlock: some View {
        VStack(spacing: 8) {
            VStack(spacing: 0) {
                Text("Sign message for")
                    .textStyle(.title1)
                    .foregroundStyle(Color.tonTextPrimary)
                Text(dAppDomainDisplay)
                    .textStyle(.title1)
                    .foregroundStyle(Color.tonTextBrand)
                    .multilineTextAlignment(.center)
            }

            Text("A dApp wants you to sign a transaction without broadcasting it.")
                .textStyle(.body)
                .foregroundStyle(Color.tonTextSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }

    private var walletRow: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color.tonBgFillTertiary)
                TONIcon.wallet.image
                    .resizable()
                    .scaledToFit()
                    .size(24)
                    .foregroundStyle(Color.tonTextSecondary)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 2) {
                Text("Wallet")
                    .textStyle(.bodySemibold)
                    .foregroundStyle(Color.tonTextPrimary)
                if let address = viewModel.walletAddress {
                    Text(shortAddress(address))
                        .textStyle(.subheadline2)
                        .foregroundStyle(Color.tonTextSecondary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: cardCornerRadius)
                .fill(Color.tonBgPrimary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: cardCornerRadius)
                .stroke(Color.tonBgFillTertiary, lineWidth: 1)
        )
    }

    // MARK: Transaction card ("The dApp can submit")

    private var transactionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("The dApp can submit")
                .textStyle(.footnoteCaps)
                .foregroundStyle(Color.tonTextSecondary)

            VStack(alignment: .leading, spacing: 8) {
                let items = viewModel.transactionRequest.items ?? []
                let messages = viewModel.transactionRequest.messages

                if !items.isEmpty {
                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        itemRow(item: item, index: index)
                    }
                } else if !messages.isEmpty {
                    ForEach(Array(messages.enumerated()), id: \.offset) { index, message in
                        messageRow(message: message, index: index)
                    }
                } else {
                    Text("No outgoing messages in this request")
                        .textStyle(.subheadline2)
                        .foregroundStyle(Color.tonTextSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(12)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: cardCornerRadius)
                .fill(Color.tonBgSecondary)
        )
    }

    @ViewBuilder
    private func itemRow(item: TONStructuredItem, index: Int) -> some View {
        switch item {
        case .ton(let ton):
            entryCard(
                title: "Send TON #\(index + 1)",
                toAddress: ton.address,
                amount: tonAmountText(fromNanoString: ton.amount),
                extraLines: [],
                pills: [
                    ton.stateInit != nil ? "State init" : nil,
                    (ton.extraCurrency?.isEmpty == false) ? "Extra currencies" : nil
                ].compactMap { $0 },
                payloads: [
                    ton.payload.map { ("Payload", $0.value) }
                ].compactMap { $0 }
            )
        case .jetton(let jetton):
            entryCard(
                title: "Send jetton #\(index + 1)",
                toAddress: jetton.destination,
                amount: tokenAmountText(fromString: jetton.amount, suffix: nil),
                extraLines: ["Jetton \(shortAddress(jetton.master))"],
                pills: [
                    jetton.attachAmount.flatMap { tonAmountText(fromNanoString: $0).map { "Attach \($0)" } },
                    jetton.forwardAmount.flatMap { tonAmountText(fromNanoString: $0).map { "Forward \($0)" } },
                    jetton.responseDestination.map { "Response \(shortAddress($0))" }
                ].compactMap { $0 },
                payloads: [
                    jetton.customPayload.map { ("Custom payload", $0.value) },
                    jetton.forwardPayload.map { ("Forward payload", $0.value) }
                ].compactMap { $0 }
            )
        case .nft(let nft):
            entryCard(
                title: "Transfer NFT #\(index + 1)",
                toAddress: nft.newOwner,
                amount: nil,
                extraLines: ["NFT \(shortAddress(nft.nftAddress))"],
                pills: [
                    nft.attachAmount.flatMap { tonAmountText(fromNanoString: $0).map { "Attach \($0)" } },
                    nft.forwardAmount.flatMap { tonAmountText(fromNanoString: $0).map { "Forward \($0)" } },
                    nft.responseDestination.map { "Response \(shortAddress($0))" }
                ].compactMap { $0 },
                payloads: [
                    nft.customPayload.map { ("Custom payload", $0.value) },
                    nft.forwardPayload.map { ("Forward payload", $0.value) }
                ].compactMap { $0 }
            )
        }
    }

    private func messageRow(message: TONTransactionRequestMessage, index: Int) -> some View {
        entryCard(
            title: "Message #\(index + 1)",
            toAddress: message.address,
            amount: tonAmountText(message.amount),
            extraLines: [],
            pills: [
                message.stateInit != nil ? "State init" : nil,
                message.mode.flatMap { $0.base.map { "Mode \($0.rawValue)" } },
                (message.extraCurrency?.isEmpty == false) ? "Extra currencies" : nil
            ].compactMap { $0 },
            payloads: [
                message.payload.map { ("Payload", $0.value) }
            ].compactMap { $0 }
        )
    }

    private func entryCard(
        title: String,
        toAddress: String,
        amount: String?,
        extraLines: [String],
        pills: [String],
        payloads: [(String, String)]
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .textStyle(.bodySemibold)
                        .foregroundStyle(Color.tonTextPrimary)
                    Text("To \(shortAddress(toAddress))")
                        .textStyle(.subheadline2)
                        .foregroundStyle(Color.tonTextBrand)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    ForEach(extraLines, id: \.self) { line in
                        Text(line)
                            .textStyle(.subheadline2)
                            .foregroundStyle(Color.tonTextSecondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                Spacer(minLength: 0)
                if let amount {
                    Text(amount)
                        .textStyle(.bodySemibold)
                        .foregroundStyle(Color.tonTextPrimary)
                        .lineLimit(1)
                }
            }

            if !pills.isEmpty {
                HStack(spacing: 6) {
                    ForEach(pills, id: \.self) { pill in
                        TONBadge(pill, style: .gray, uppercase: false)
                    }
                }
            }

            ForEach(payloads.indices, id: \.self) { idx in
                payloadRow(label: payloads[idx].0, value: payloads[idx].1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: innerCardCornerRadius)
                .fill(Color.tonBgPrimary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: innerCardCornerRadius)
                .stroke(Color.tonBgFillTertiary, lineWidth: 1)
        )
    }

    private func payloadRow(label: String, value: String) -> some View {
        let decoded = TextCommentPayloadDecoder.decode(value)
        let display = decoded.map { "Comment \u{201C}\($0)\u{201D}" } ?? truncate(value, max: 48)
        return HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text("\(label): ")
                .textStyle(.subheadline2Semibold)
                .foregroundStyle(Color.tonTextPrimary)
            Text(display)
                .textStyle(.subheadline2)
                .foregroundStyle(Color.tonTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    // MARK: Money flow

    private func shouldShowMoneyFlow(moneyFlow: TONTransactionTraceMoneyFlow) -> Bool {
        guard let preview = viewModel.emulatedPreview, preview.result == .success else { return false }
        if !moneyFlow.ourTransfers.isEmpty { return true }
        return moneyFlow.outputs.nanoUnits != 0 || moneyFlow.inputs.nanoUnits != 0
    }

    @ViewBuilder
    private func moneyFlowCard(moneyFlow: TONTransactionTraceMoneyFlow) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Money flow")
                .textStyle(.footnoteCaps)
                .foregroundStyle(Color.tonTextSecondary)

            if moneyFlow.ourTransfers.isEmpty {
                Text("This transaction doesn't involve any token transfers")
                    .textStyle(.subheadline2)
                    .foregroundStyle(Color.tonTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 4)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(moneyFlow.ourTransfers.enumerated()), id: \.offset) { _, transfer in
                        moneyFlowItemRow(transfer)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: cardCornerRadius)
                .fill(Color.tonBgSecondary)
        )
    }

    private func moneyFlowItemRow(_ transfer: TONTransactionTraceMoneyFlowItem) -> some View {
        let isPositive = transfer.amount.nanoUnits >= 0
        let amountString = Self.tonFormatter.string(from: transfer.amount) ?? "0"
        let prefix = isPositive ? "+" : ""
        let unit = unitLabel(for: transfer)

        return HStack(spacing: 12) {
            Text(assetName(for: transfer))
                .textStyle(.bodySemibold)
                .foregroundStyle(Color.tonTextPrimary)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer(minLength: 0)

            Text("\(prefix)\(amountString) \(unit)")
                .textStyle(.bodySemibold)
                .foregroundStyle(isPositive ? Color.tonTextSuccess : Color.tonTextError)
                .lineLimit(1)
        }
    }

    private func assetName(for transfer: TONTransactionTraceMoneyFlowItem) -> String {
        switch transfer.assetType {
        case .ton: return "TON"
        case .jetton: return transfer.tokenAddress.map { shortAddress($0.value) } ?? "Jetton"
        case .nft: return transfer.tokenAddress.map { shortAddress($0.value) } ?? "NFT"
        }
    }

    private func unitLabel(for transfer: TONTransactionTraceMoneyFlowItem) -> String {
        switch transfer.assetType {
        case .ton: return "TON"
        case .jetton: return ""
        case .nft: return "NFT"
        }
    }

    // MARK: Preview error

    private func previewErrorCard(message: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("Error:")
                .textStyle(.bodySemibold)
                .foregroundStyle(Color.tonTextError)
            Text(message)
                .textStyle(.subheadline2)
                .foregroundStyle(Color.tonTextError)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: innerCardCornerRadius)
                .fill(Color.tonBgPrimary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: innerCardCornerRadius)
                .stroke(Color.tonTextError.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: Helpers

    private var dAppDomainDisplay: String {
        let host = viewModel.dAppInfo?.url?.host ?? viewModel.dAppInfo?.url?.absoluteString ?? ""
        return host + "?"
    }

    private func shortAddress(_ address: String) -> String {
        guard address.count > addressTruncation * 2 else { return address }
        let prefix = String(address.prefix(addressTruncation))
        let suffix = String(address.suffix(addressTruncation))
        return "\(prefix)...\(suffix)"
    }

    private func tonAmountText(_ amount: TONTokenAmount) -> String? {
        Self.tonFormatter.string(from: amount).map { "\($0) TON" }
    }

    private func tonAmountText(fromNanoString nano: String) -> String? {
        guard let amount = TONTokenAmount(nanoUnits: nano) else { return nil }
        return tonAmountText(amount)
    }

    private func tokenAmountText(fromString nano: String, suffix: String?) -> String? {
        guard let amount = TONTokenAmount(nanoUnits: nano) else { return nil }
        guard let formatted = Self.tonFormatter.string(from: amount) else { return nil }
        if let suffix { return "\(formatted) \(suffix)" }
        return formatted
    }

    private func truncate(_ string: String, max: Int) -> String {
        guard string.count > max else { return string }
        return String(string.prefix(max)) + "..."
    }
}
