//
//  WalletSignDataRequestView.swift
//  TONWalletApp
//
//  Created by Nikita Rodionov on 10.10.2025.
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

struct WalletSignDataRequestView: View {
    @StateObject var viewModel: WalletSignDataRequestViewModel

    @Environment(\.dismiss) var dismiss

    private let logoSize: CGFloat = 64
    private let logoCornerRadius: CGFloat = 16
    private let cardCornerRadius: CGFloat = 16

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                logos
                    .padding(.top, 24)

                titleBlock
                    .padding(.top, 24)

                walletRow
                    .padding(.top, 24)

                dataCard
                    .padding(.top, 16)

                TONHoldButton(
                    title: "Hold to sign",
                    icon: TONIcon.fingerprint.image,
                    duration: 3,
                    onComplete: { viewModel.approve() }
                )
                .padding(.top, 24)

                Text("Only sign data if you trust the requesting dApp and understand what you're signing. Signing data can have security implications.")
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
                Text("Sign data for")
                    .textStyle(.title1)
                    .foregroundStyle(Color.tonTextPrimary)
                Text(dAppDomainDisplay)
                    .textStyle(.title1)
                    .foregroundStyle(Color.tonTextBrand)
                    .multilineTextAlignment(.center)
            }

            Text("dApp wants you to sign data with your wallet:")
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

    @ViewBuilder
    private var dataCard: some View {
        switch viewModel.signData {
        case .cell(let cell):
            dataCardLayout(
                background: Color.tonBgSecondary,
                captionColor: Color.tonTextSecondary
            ) {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Content")
                            .textStyle(.bodySemibold)
                            .foregroundStyle(Color.tonTextPrimary)
                        Text(cell.content.value)
                            .textStyle(.subheadline2)
                            .foregroundStyle(Color.tonTextSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Schema")
                            .textStyle(.bodySemibold)
                            .foregroundStyle(Color.tonTextPrimary)
                        Text(cell.schema)
                            .textStyle(.subheadline2)
                            .foregroundStyle(Color.tonTextSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

        case .binary(let binary):
            dataCardLayout(
                background: Color.tonBgSuccessSubtle,
                captionColor: Color.tonTextSuccess
            ) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Binary Data")
                        .textStyle(.bodySemibold)
                        .foregroundStyle(Color.tonTextPrimary)
                    Text("Content:")
                        .textStyle(.subheadline2)
                        .foregroundStyle(Color.tonTextSecondary)
                        .padding(.top, 8)
                    Text(binary.content.value)
                        .textStyle(.subheadline2)
                        .foregroundStyle(Color.tonTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

        case .text(let text):
            dataCardLayout(
                background: Color.tonBgBrandSubtle,
                captionColor: Color.tonTextBrand
            ) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Text Message")
                        .textStyle(.bodySemibold)
                        .foregroundStyle(Color.tonTextPrimary)
                    Text(text.content)
                        .textStyle(.body)
                        .foregroundStyle(Color.tonTextPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    @ViewBuilder
    private func dataCardLayout<Content: View>(
        background: Color,
        captionColor: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Data to sign")
                .textStyle(.footnoteCaps)
                .foregroundStyle(captionColor)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: cardCornerRadius)
                .fill(background)
        )
    }

    private var dAppDomainDisplay: String {
        let host = viewModel.dAppInfo?.url?.host ?? viewModel.dAppInfo?.url?.absoluteString ?? ""
        return host + "?"
    }

    private func shortAddress(_ address: String) -> String {
        guard address.count > 10 else { return address }
        let prefix = String(address.prefix(6))
        let suffix = String(address.suffix(6))
        return "\(prefix)...\(suffix)"
    }
}
