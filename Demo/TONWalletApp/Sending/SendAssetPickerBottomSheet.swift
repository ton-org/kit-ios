//
//  SendAssetPickerBottomSheet.swift
//  TONWalletApp
//
//  Created by Nikita Rodionov on 16.06.2026.
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

// MARK: - Token picker

struct SendTokenPickerBottomSheet: View {
    let tokens: [any SendableTokenViewModel]
    let selected: any SendableTokenViewModel
    let onSelect: (any SendableTokenViewModel) -> Void
    let onClose: () -> Void

    var body: some View {
        SendAssetPickerContainer(title: "Select token", onClose: onClose) {
            ForEach(0..<tokens.count, id: \.self) { index in
                let token = tokens[index]
                SendAssetRow(
                    iconURL: token.iconURL,
                    isNativeTON: token.isNativeTON,
                    symbolForPlaceholder: token.symbol,
                    title: token.name,
                    subtitle: token.symbol,
                    trailing: token.balance,
                    isSelected: token === selected
                ) {
                    onSelect(token)
                    onClose()
                }
            }
        }
    }
}

// MARK: - Fee asset picker

struct FeeAssetPickerBottomSheet: View {
    let assets: [FeeAssetViewModel]
    let selected: FeeAssetViewModel?
    let onSelect: (FeeAssetViewModel) -> Void
    let onClose: () -> Void

    var body: some View {
        SendAssetPickerContainer(title: "Fee asset", onClose: onClose) {
            ForEach(assets) { asset in
                FeeAssetRow(viewModel: asset, isSelected: asset === selected) {
                    onSelect(asset)
                    onClose()
                }
            }
        }
    }
}

/// Observes a single fee-asset view model so the row reflects its resolved ticker/icon as it loads.
/// Triggers the metadata load when it appears.
private struct FeeAssetRow: View {
    @ObservedObject var viewModel: FeeAssetViewModel
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        SendAssetRow(
            iconURL: viewModel.iconURL,
            isNativeTON: false,
            symbolForPlaceholder: viewModel.title,
            title: viewModel.title,
            subtitle: viewModel.subtitle,
            trailing: nil,
            isSelected: isSelected,
            onTap: onTap
        )
        .task { await viewModel.load() }
    }
}

// MARK: - Shared container

private struct SendAssetPickerContainer<Content: View>: View {
    let title: String
    let onClose: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .center, spacing: 24) {
            ZStack {
                HStack {
                    Text(title)
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
                content()
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.tonBgPrimary)
    }
}

// MARK: - Shared row

private struct SendAssetRow: View {
    let iconURL: URL?
    let isNativeTON: Bool
    let symbolForPlaceholder: String
    let title: String
    let subtitle: String
    let trailing: String?
    let isSelected: Bool
    let onTap: () -> Void

    private let iconSize: CGFloat = 44

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                icon
                    .frame(width: iconSize, height: iconSize)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .textStyle(.bodySemibold)
                        .foregroundStyle(Color.tonTextPrimary)
                        .lineLimit(1)
                    Text(subtitle)
                        .textStyle(.subheadline2)
                        .foregroundStyle(Color.tonTextSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                if let trailing {
                    Text(trailing)
                        .textStyle(.bodySemibold)
                        .foregroundStyle(Color.tonTextPrimary)
                        .lineLimit(1)
                }

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

    @ViewBuilder
    private var icon: some View {
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
            Text(initials)
                .textStyle(.subheadline2Semibold)
                .foregroundStyle(Color.tonTextSecondary)
        }
    }

    private var initials: String {
        String(symbolForPlaceholder.trimmingCharacters(in: .whitespaces).prefix(3)).uppercased()
    }
}
