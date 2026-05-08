//
//  WalletsBottomSheetRowView.swift
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

struct WalletsBottomSheetRowView: View {
    let title: String
    let truncatedAddress: String
    let fullAddress: String
    let isActive: Bool
    let onSelect: () -> Void
    let onMore: () -> Void

    private let iconSize: CGFloat = 48

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onSelect) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(Color.tonBgFillTertiary)
                        TONIcon.wallet.image
                            .resizable()
                            .scaledToFit()
                            .size(24)
                            .foregroundStyle(Color.tonTextSecondary)
                    }
                    .frame(width: iconSize, height: iconSize)

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
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)

            if isActive {
                TONIcon.tick.image
                    .resizable()
                    .scaledToFit()
                    .size(20)
                    .foregroundStyle(Color.tonTextBrand)
            }

            Button(action: onMore) {
                TONIcon.more.image
                    .resizable()
                    .scaledToFit()
                    .size(24)
                    .foregroundStyle(Color.tonTextSecondary)
                    .frame(width: 24, height: 24)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
    }
}
