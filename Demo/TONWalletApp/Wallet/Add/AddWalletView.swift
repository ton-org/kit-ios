//
//  AddWalletView.swift
//  TONWalletApp
//
//  Created by Nikita Rodionov on 12.09.2025.
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

import Foundation
import Combine
import SwiftUI
import TONWalletKit

@MainActor
struct AddWalletView: View {
    @StateObject var viewModel = AddWalletViewModel()

    let onAddWallet: (TONWalletProtocol) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("Import a wallet")
                            .textStyle(.title2)
                            .foregroundStyle(Color.tonTextPrimary)
                        Text("Enter your secret recovery phrase")
                            .textStyle(.body)
                            .foregroundStyle(Color.tonTextSecondary)
                            .multilineTextAlignment(.center)
                    }

                    MnemonicInputView(mnemonic: $viewModel.mnemonic)
                        .allowsHitTesting(!viewModel.isAdding)
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
            .disabled(!viewModel.canAdd)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color.tonBgPrimary)
        .navigationBarTitleDisplayMode(.inline)
    }
}
