//
//  WalletConnectionRequestView.swift
//  TONWalletApp
//
//  Created by Nikita Rodionov on 03.10.2025.
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

import SwiftUI
import TONWalletKit

struct WalletConnectionRequestView: View {
    @StateObject var viewModel: WalletConnectionRequestViewModel
    let onNextEvent: (TONWalletKitEvent) -> Void

    @Environment(\.dismiss) var dismiss

    @State private var isWalletSelectionPresented = false

    init(
        viewModel: WalletConnectionRequestViewModel,
        onNextEvent: @escaping (TONWalletKitEvent) -> Void = { _ in }
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onNextEvent = onNextEvent
    }

    private let logoSize: CGFloat = 64
    private let logoCornerRadius: CGFloat = 16
    private let cardCornerRadius: CGFloat = 16

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                logos
                    .padding(.top, 8)

                titleBlock

                walletSelector
                    .padding(.top, 8)

                permissionsCard

                Button("Connect wallet") {
                    viewModel.approve()
                }
                .buttonStyle(.ton(.primary))
                .frame(maxWidth: .infinity)

                Text("Only connect to trusted applications. This will give the dApp access to your wallet address and allow it to request transactions.")
                    .textStyle(.subheadline2)
                    .foregroundStyle(Color.tonTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
            .padding(.horizontal, 16)
            .padding(.top, 44)
            .padding(.bottom, 24)
        }
        .background(Color.tonBgPrimary)
        .overlay(alignment: .topTrailing) {
            closeButton
        }
        .onReceive(viewModel.dismiss) { followUp in
            dismiss()
            if let followUp {
                onNextEvent(followUp)
            }
        }
        .sheet(isPresented: $isWalletSelectionPresented) {
            WalletConnectionWalletSelectionView(
                wallets: viewModel.wallets,
                selectedId: viewModel.selectedWallet?.id,
                onSelect: { wallet in
                    viewModel.selectedWallet = wallet
                    isWalletSelectionPresented = false
                },
                onClose: { isWalletSelectionPresented = false }
            )
            .automaticHeightPresentationDetents()
            .presentationDragIndicator(.visible)
        }
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
                    image
                        .resizable()
                        .scaledToFill()
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
                Text("Connect to")
                    .textStyle(.title1)
                    .foregroundStyle(Color.tonTextPrimary)
                Text(dAppDomainDisplay)
                    .textStyle(.title1)
                    .foregroundStyle(Color.tonTextBrand)
                    .multilineTextAlignment(.center)
            }

            Text(subtitleText)
                .textStyle(.body)
                .foregroundStyle(Color.tonTextSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }

    private var walletSelector: some View {
        Button {
            isWalletSelectionPresented = true
        } label: {
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
                    if let address = viewModel.selectedWallet?.address {
                        Text(shortAddress(address))
                            .textStyle(.subheadline2)
                            .foregroundStyle(Color.tonTextSecondary)
                    }
                }

                Spacer(minLength: 0)

                TONIcon.changeValue.image
                    .resizable()
                    .scaledToFit()
                    .size(24)
                    .foregroundStyle(Color.tonTextSecondary)
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
        .buttonStyle(.plain)
    }

    private var permissionsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Requested permissions:")
                .textStyle(.footnoteCaps)
                .foregroundStyle(Color.tonTextSecondary)

            VStack(alignment: .leading, spacing: 16) {
                ForEach(0..<viewModel.permissions.count, id: \.self) { index in
                    let permission = viewModel.permissions[index]
                    VStack(alignment: .leading, spacing: 4) {
                        Text(permission.title ?? "")
                            .textStyle(.bodySemibold)
                            .foregroundStyle(Color.tonTextPrimary)
                        Text(permission.description ?? "")
                            .textStyle(.subheadline2)
                            .foregroundStyle(Color.tonTextSecondary)
                            .fixedSize(horizontal: false, vertical: true)
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

    private var dAppDomainDisplay: String {
        let host = viewModel.dAppInfo?.url?.host ?? viewModel.dAppInfo?.url?.absoluteString ?? ""
        return host + "?"
    }

    private var subtitleText: String {
        let name = viewModel.dAppInfo?.name ?? "The dApp"
        return "\(name) is requesting access to your wallet address:"
    }

    private func shortAddress(_ address: String) -> String {
        guard address.count > 10 else { return address }
        let prefix = String(address.prefix(6))
        let suffix = String(address.suffix(6))
        return "\(prefix)...\(suffix)"
    }
}
