//
//  WalletConnectionWalletSelectionView.swift
//  TONWalletApp
//
//  Created by Nikita Rodionov on 29.05.2026.
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

struct WalletConnectionWalletSelectionView: View {
    let wallets: [WalletConnectionRequestViewModel.SelectableWallet]
    let selectedId: UUID?
    let onSelect: (WalletConnectionRequestViewModel.SelectableWallet) -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .center, spacing: 24) {
            ZStack {
                HStack {
                    Text("Wallets")
                        .textStyle(.title3Bold)
                        .foregroundStyle(Color.tonTextPrimary)
                    Spacer()
                }

                HStack {
                    Spacer()
                    Button(action: onClose) {
                        TONIcon.close.image
                            .resizable()
                            .scaledToFit()
                            .size(28)
                    }
                    .buttonStyle(.plain)
                }
            }

            VStack(spacing: 16) {
                ForEach(Array(wallets.enumerated()), id: \.element.id) { index, wallet in
                    walletRow(
                        title: "Wallet \(index + 1)",
                        truncatedAddress: shortAddress(wallet.address),
                        fullAddress: wallet.address,
                        isSelected: wallet.id == selectedId,
                        onTap: { onSelect(wallet) }
                    )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.tonBgPrimary)
    }

    private func walletRow(
        title: String,
        truncatedAddress: String,
        fullAddress: String,
        isSelected: Bool,
        onTap: @escaping () -> Void
    ) -> some View {
        Button(action: onTap) {
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
                    Text(title)
                        .textStyle(.bodySemibold)
                        .foregroundStyle(Color.tonTextPrimary)
                    HStack(spacing: 4) {
                        Text(truncatedAddress)
                            .textStyle(.subheadline2)
                            .foregroundStyle(Color.tonTextSecondary)
                        Button {
                            UIPasteboard.general.string = fullAddress
                        } label: {
                            TONIcon.copy.image
                                .resizable()
                                .scaledToFit()
                                .size(16)
                                .foregroundStyle(Color.tonTextSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer(minLength: 0)

                if isSelected {
                    TONIcon.tick.image
                        .resizable()
                        .scaledToFit()
                        .size(20)
                        .foregroundStyle(Color.tonTextBrand)
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    private func shortAddress(_ address: String) -> String {
        guard address.count > 10 else { return address }
        let prefix = String(address.prefix(6))
        let suffix = String(address.suffix(6))
        return "\(prefix)...\(suffix)"
    }
}
