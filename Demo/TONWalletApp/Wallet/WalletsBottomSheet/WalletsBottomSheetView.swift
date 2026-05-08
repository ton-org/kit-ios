//
//  WalletsBottomSheetView.swift
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

import SwiftUI

struct WalletsBottomSheetView: View {
    @ObservedObject var viewModel: WalletsListViewModel

    let onClose: () -> Void
    let onAddWallet: () -> Void
    let onDelete: (WalletViewModel) -> Void

    @State private var actionSheetWallet: WalletViewModel?

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
                        ZStack {
                            Circle().fill(Color.tonBgFillTertiary)
                            TONIcon.close.image
                                .resizable()
                                .scaledToFit()
                                .size(16)
                                .foregroundStyle(Color.tonTextSecondary)
                        }
                        .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                }
            }

            VStack(spacing: 16) {
                ForEach(viewModel.wallets) { wallet in
                    WalletsBottomSheetRowView(
                        title: walletTitle(for: wallet),
                        truncatedAddress: shortAddress(wallet.address),
                        fullAddress: wallet.address,
                        isActive: viewModel.activeWallet?.id == wallet.id,
                        onSelect: {
                            viewModel.selectActive(wallet: wallet)
                            onClose()
                        },
                        onMore: {
                            actionSheetWallet = wallet
                        }
                    )
                }
            }

            Button(action: onAddWallet) {
                HStack(spacing: 4) {
                    TONIcon.plusLarge.image
                        .resizable()
                        .scaledToFit()
                        .size(24)
                        .foregroundStyle(Color.tonTextOnBrand)
                    Text("Add wallet")
                        .textStyle(.bodySemibold)
                        .foregroundStyle(Color.tonTextOnBrand)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(Color.tonBgBrand)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.tonBgPrimary)
        .confirmationDialog(
            actionSheetWallet.map { walletTitle(for: $0) } ?? "",
            isPresented: Binding(
                get: { actionSheetWallet != nil },
                set: { if !$0 { actionSheetWallet = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete wallet", role: .destructive) {
                if let wallet = actionSheetWallet {
                    onDelete(wallet)
                }
                actionSheetWallet = nil
            }
            Button("Cancel", role: .cancel) {
                actionSheetWallet = nil
            }
        }
    }

    private func walletTitle(for wallet: WalletViewModel) -> String {
        if let index = viewModel.wallets.firstIndex(where: { $0.id == wallet.id }) {
            return "Wallet \(index + 1)"
        }
        return "Wallet"
    }

    private func shortAddress(_ address: String) -> String {
        guard address.count > 10 else { return address }
        let prefix = String(address.prefix(6))
        let suffix = String(address.suffix(6))
        return "\(prefix)...\(suffix)"
    }
}
