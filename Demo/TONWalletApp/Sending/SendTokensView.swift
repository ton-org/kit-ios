//
//  SendTokensView.swift
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
import SwiftUI

struct SendTokensView: View {
    @StateObject var viewModel: SendTokensViewModel

    @State private var showTokenPicker = false
    @State private var showFeeAssetPicker = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    tokenSelectorCard
                    recipientCard
                    amountCard

                    if showSummary {
                        summaryCard
                    }

                    if viewModel.canUseGasless {
                        gaslessCard
                    }

                    warningCard
                }
                .padding(16)
            }

            sendBar
        }
        .background(Color.tonBgSecondary)
        .navigationTitle("Send \(viewModel.selectedToken.symbol)")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showTokenPicker) {
            SendTokenPickerBottomSheet(
                tokens: viewModel.availableTokens,
                selected: viewModel.selectedToken,
                onSelect: { viewModel.select(token: $0) },
                onClose: { showTokenPicker = false }
            )
            .automaticHeightPresentationDetents()
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showFeeAssetPicker) {
            FeeAssetPickerBottomSheet(
                assets: viewModel.feeAssets,
                selected: viewModel.selectedFeeAsset,
                onSelect: { viewModel.selectedFeeAsset = $0 },
                onClose: { showFeeAssetPicker = false }
            )
            .automaticHeightPresentationDetents()
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Token selector

    private var tokenSelectorCard: some View {
        Button {
            showTokenPicker = true
        } label: {
            HStack(spacing: 12) {
                AssetIconView(
                    iconURL: viewModel.selectedToken.iconURL,
                    isNativeTON: viewModel.selectedToken.isNativeTON,
                    symbol: viewModel.selectedToken.symbol
                )
                .frame(width: 44, height: 44)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.selectedToken.name)
                        .textStyle(.bodySemibold)
                        .foregroundStyle(Color.tonTextPrimary)
                        .lineLimit(1)
                    Text("Balance: \(viewModel.selectedToken.balance) \(viewModel.selectedToken.symbol)")
                        .textStyle(.subheadline2)
                        .foregroundStyle(Color.tonTextSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                TONIcon.chevronDown.image
                    .resizable()
                    .scaledToFit()
                    .size(20)
                    .foregroundStyle(Color.tonTextSecondary)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .widget()
    }

    // MARK: - Recipient

    private var recipientCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recipient address")
                .textStyle(.bodySemibold)
                .foregroundStyle(Color.tonTextPrimary)

            TextField("EQ…", text: $viewModel.recipientAddress)
                .textFieldStyle(TONTextFieldStyle())
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .keyboardType(.asciiCapable)

            Text("Enter the recipient's TON address")
                .textStyle(.subheadline2)
                .foregroundStyle(Color.tonTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .widget()
    }

    // MARK: - Amount

    private var amountCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Amount (\(viewModel.selectedToken.symbol))")
                    .textStyle(.bodySemibold)
                    .foregroundStyle(Color.tonTextPrimary)

                Spacer()

                Button {
                    viewModel.useMaxAmount()
                } label: {
                    Text("Max")
                        .textStyle(.subheadline2Semibold)
                        .foregroundStyle(Color.tonTextBrand)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.tonBgBrandSubtle)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            TextField("0.0", text: $viewModel.amount)
                .textFieldStyle(TONTextFieldStyle())
                .keyboardType(.decimalPad)

            Text(viewModel.selectedToken.requiredAmountInfo)
                .textStyle(.subheadline2)
                .foregroundStyle(Color.tonTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .widget()
    }

    // MARK: - Summary

    private var summaryCard: some View {
        VStack(spacing: 10) {
            summaryRow(title: "To", value: shortAddress(viewModel.recipientAddress))
            summaryRow(title: "Amount", value: "\(viewModel.amount) \(viewModel.selectedToken.symbol)")

            Divider()

            HStack {
                Text("You'll send")
                    .textStyle(.bodySemibold)
                    .foregroundStyle(Color.tonTextPrimary)
                Spacer()
                Text("\(viewModel.amount) \(viewModel.selectedToken.symbol)")
                    .textStyle(.bodySemibold)
                    .foregroundStyle(Color.tonTextPrimary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .widget()
    }

    private func summaryRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .textStyle(.body)
                .foregroundStyle(Color.tonTextSecondary)
            Spacer()
            Text(value)
                .textStyle(.body)
                .foregroundStyle(Color.tonTextPrimary)
                .lineLimit(1)
        }
    }

    // MARK: - Gasless

    private var gaslessCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Gasless")
                        .textStyle(.bodySemibold)
                        .foregroundStyle(Color.tonTextPrimary)
                    Text("Pay the network fee in a jetton")
                        .textStyle(.subheadline2)
                        .foregroundStyle(Color.tonTextSecondary)
                }

                Spacer()

                Toggle("", isOn: $viewModel.gaslessEnabled)
                    .labelsHidden()
                    .toggleStyle(.tonSwitch)
            }

            if viewModel.gaslessEnabled {
                Divider()

                Button {
                    showFeeAssetPicker = true
                } label: {
                    HStack {
                        Text("Fee asset")
                            .textStyle(.body)
                            .foregroundStyle(Color.tonTextSecondary)
                        Spacer()
                        Text(viewModel.selectedFeeAsset?.symbol ?? "Select")
                            .textStyle(.bodySemibold)
                            .foregroundStyle(
                                viewModel.selectedFeeAsset == nil
                                    ? Color.tonTextSecondary
                                    : Color.tonTextPrimary
                            )
                        TONIcon.chevronDown.image
                            .resizable()
                            .scaledToFit()
                            .size(16)
                            .foregroundStyle(Color.tonTextSecondary)
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)

                HStack {
                    Text("Gas fee")
                        .textStyle(.body)
                        .foregroundStyle(Color.tonTextSecondary)
                    Spacer()
                    Text(gaslessFeeText)
                        .textStyle(.bodySemibold)
                        .foregroundStyle(Color.tonTextPrimary)
                }

                if let error = viewModel.gaslessError {
                    Text(error)
                        .textStyle(.subheadline2)
                        .foregroundStyle(Color.tonTextError)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .widget()
    }

    private var gaslessFeeText: String {
        if viewModel.gaslessError != nil { return "—" }
        if viewModel.isQuoting { return "Calculating…" }
        return viewModel.gaslessFeeText ?? "—"
    }

    // MARK: - Warning

    private var warningCard: some View {
        HStack(spacing: 12) {
            TONIcon.info.image
                .resizable()
                .scaledToFit()
                .size(20)
                .foregroundStyle(Color.tonTextSecondary)

            Text("Transfers are irreversible. Double-check the recipient address before sending.")
                .textStyle(.subheadline2)
                .foregroundStyle(Color.tonTextSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .widget(style: .block(.warning))
    }

    // MARK: - Send bar

    private var sendBar: some View {
        VStack(spacing: 0) {
            Divider()

            Button(viewModel.sendButtonTitle) {
                viewModel.send()
            }
            .buttonStyle(.ton(.primary.isLoading(viewModel.isSending)))
            .disabled(!viewModel.canSend)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
        .background(Color.tonBgPrimary)
    }

    // MARK: - Helpers

    private var showSummary: Bool {
        !viewModel.recipientAddress.isEmpty && !viewModel.amount.isEmpty
    }

    private func shortAddress(_ address: String) -> String {
        guard address.count > 12 else { return address }
        return "\(address.prefix(6))…\(address.suffix(6))"
    }
}

// MARK: - Asset icon

private struct AssetIconView: View {
    let iconURL: URL?
    let isNativeTON: Bool
    let symbol: String

    var body: some View {
        if isNativeTON {
            TONIcon.ton.image
                .resizable()
                .renderingMode(.original)
                .scaledToFit()
        } else if let iconURL {
            AsyncImage(url: iconURL) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                placeholder
            }
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        ZStack {
            Color.tonBgFillTertiary
            Text(String(symbol.prefix(3)).uppercased())
                .textStyle(.subheadline2Semibold)
                .foregroundStyle(Color.tonTextSecondary)
        }
    }
}
