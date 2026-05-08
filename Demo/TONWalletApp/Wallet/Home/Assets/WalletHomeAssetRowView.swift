//
//  WalletHomeAssetRowView.swift
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

struct WalletHomeAssetRowView: View {
    let item: WalletHomeAssetItem

    private let iconSize: CGFloat = 48

    var body: some View {
        HStack(spacing: 12) {
            iconView
                .frame(width: iconSize, height: iconSize)
                .clipShape(Circle())

            Text(item.name)
                .textStyle(.bodySemibold)
                .foregroundStyle(Color.tonTextPrimary)
                .lineLimit(1)

            Spacer(minLength: 8)

            Text(item.formattedAmount)
                .textStyle(.bodySemibold)
                .foregroundStyle(Color.tonTextPrimary)
                .lineLimit(1)
        }
        .frame(minHeight: iconSize)
    }

    @ViewBuilder
    private var iconView: some View {
        switch item.icon {
        case .ton:
            TONIcon.ton.image
                .resizable()
                .renderingMode(.original)
                .scaledToFit()
        case .image(let image):
            image
                .resizable()
                .scaledToFill()
        case .url(let url):
            AsyncImage(url: url) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                placeholderView(symbol: item.symbol)
            }
        case .placeholder(let symbol):
            placeholderView(symbol: symbol)
        }
    }

    private func placeholderView(symbol: String) -> some View {
        ZStack {
            Color.tonBgFillTertiary
            Text(symbolInitials(symbol))
                .textStyle(.subheadline2Semibold)
                .foregroundStyle(Color.tonTextSecondary)
        }
    }

    private func symbolInitials(_ symbol: String) -> String {
        let trimmed = symbol.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "?" }
        return String(trimmed.prefix(3)).uppercased()
    }
}
