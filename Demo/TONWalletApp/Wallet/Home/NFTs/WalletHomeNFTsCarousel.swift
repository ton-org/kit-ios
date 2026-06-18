//
//  WalletHomeNFTsCarousel.swift
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

struct WalletHomeNFTsCarousel: View {
    let nfts: [WalletNFTsListItem]
    let onTap: (WalletNFTsListItem) -> Void

    private let imageWidth: CGFloat = 164
    private let imageHeight: CGFloat = 140

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(nfts) { nft in
                    Button {
                        onTap(nft)
                    } label: {
                        card(for: nft)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func card(for nft: WalletNFTsListItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Group {
                if let url = nft.imageURL {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        placeholder
                    }
                } else {
                    placeholder
                }
            }
            .frame(width: imageWidth, height: imageHeight)
            .clipped()

            VStack(alignment: .leading, spacing: 0) {
                Text(displayString(nft.name))
                    .textStyle(.calloutSemibold)
                    .foregroundStyle(Color.tonTextPrimary)
                    .lineLimit(1)
                Text(displayString(shortAddress(nft.address)))
                    .textStyle(.caption1)
                    .foregroundStyle(Color.tonTextSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(width: imageWidth)
        .background(Color.tonBgFillTertiary)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    /// Keeps the line height when a title/subtitle is missing by substituting a space.
    private func displayString(_ value: String) -> String {
        value.isEmpty ? " " : value
    }

    private var placeholder: some View {
        ZStack {
            Color.clear
            TONIcon.doc.image
                .resizable()
                .scaledToFit()
                .size(28)
                .foregroundStyle(Color.tonTextTertiary)
        }
    }

    private func shortAddress(_ address: String) -> String {
        guard address.count > 8 else { return address }
        let suffix = String(address.suffix(6))
        return "#\(suffix)"
    }
}
