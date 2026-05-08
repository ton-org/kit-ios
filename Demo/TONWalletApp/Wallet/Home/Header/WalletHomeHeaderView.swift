//
//  WalletHomeHeaderView.swift
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

struct WalletHomeHeaderView: View {
    let title: String
    let networkLabel: String
    let truncatedAddress: String
    let onTap: () -> Void

    private let iconSize: CGFloat = 36

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                ZStack {
                    Circle().fill(Color.tonBgFillTertiary)
                    TONIcon.wallet.image
                        .resizable()
                        .scaledToFit()
                        .size(20)
                        .foregroundStyle(Color.tonTextSecondary)
                }
                .frame(width: iconSize, height: iconSize)

                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 6) {
                        Text(title)
                            .textStyle(.bodySemibold)
                            .foregroundStyle(Color.tonTextPrimary)
                        TONBadge(networkLabel, style: .gray)
                    }
                    Text(truncatedAddress)
                        .textStyle(.subheadline2)
                        .foregroundStyle(Color.tonTextSecondary)
                }

                Spacer(minLength: 0)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
