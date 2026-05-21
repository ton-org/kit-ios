//
//  CreateWalletView.swift
//  TONWalletApp
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
import UIKit

@MainActor
struct CreateWalletView: View {
    @StateObject var viewModel = CreateWalletViewModel()

    let onAddWallet: (TONWalletProtocol) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("Recovery phrase")
                            .textStyle(.title2)
                            .foregroundStyle(Color.tonTextPrimary)
                        Text("This is the only way you will be able to recover your account. Please store it somewhere safe!")
                            .textStyle(.body)
                            .foregroundStyle(Color.tonTextSecondary)
                            .multilineTextAlignment(.center)
                    }

                    if viewModel.isGenerating {
                        TONLoader()
                            .size(24)
                            .padding(.vertical, 48)
                    } else {
                        MnemonicWordsGrid(words: viewModel.mnemonic.value)

                        Button("Copy phrase") {
                            UIPasteboard.general.string = viewModel.mnemonic.value.joined(separator: " ")
                        }
                        .buttonStyle(.ton(.tertiary.small))
                        .fixedSize(horizontal: true, vertical: false)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }

            Button("Continue") {
                Task {
                    if let wallet = await viewModel.add() {
                        onAddWallet(wallet)
                    }
                }
            }
            .buttonStyle(.ton(.primary.isLoading(viewModel.isAdding)))
            .disabled(!viewModel.canContinue)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color.tonBgPrimary)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.generate()
        }
    }
}

private struct MnemonicWordsGrid: View {
    let words: [String]

    private let columns = 2

    var body: some View {
        let rows = (words.count + columns - 1) / columns

        HStack(alignment: .top, spacing: 24) {
            ForEach(0..<columns, id: \.self) { column in
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(0..<rows, id: \.self) { row in
                        let index = column * rows + row
                        if index < words.count {
                            MnemonicWordRow(index: index + 1, word: words[index])
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

private struct MnemonicWordRow: View {
    let index: Int
    let word: String

    var body: some View {
        HStack(spacing: 8) {
            Text("\(index)")
                .textStyle(.body)
                .foregroundStyle(Color.tonTextSecondary)
                .frame(width: 24, alignment: .trailing)
                .monospacedDigit()

            Text(word)
                .textStyle(.bodySemibold)
                .foregroundStyle(Color.tonTextPrimary)
        }
    }
}
