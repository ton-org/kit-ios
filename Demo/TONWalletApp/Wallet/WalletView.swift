//
//  WalletView.swift
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
import SwiftUI

struct WalletView: View {
    @ObservedObject var viewModel: WalletViewModel
    
    @EnvironmentObject var appStateManager: TONWalletAppStateManager
    
    let onSend: (SendTokensViewModel) -> Void
    let onSwap: (SwapViewModel) -> Void
    let onStaking: (StakingViewModel) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 16.0) {
                WalletInfoView(viewModel: viewModel.info) {
                    if let viewModel = viewModel.sendTokensViewModel() {
                        onSend(viewModel)
                    }
                }
                .widget()

                Button("Swap") {
                    onSwap(viewModel.swapViewModel())
                }
                .buttonStyle(TONLegacyButtonStyle(type: .secondary))
                
                WalletDAppConnectionView(viewModel: viewModel.dAppConnection)
                    .widget()
                
                WalletDAppDisconnectionView(viewModel: viewModel.dAppDisconnect)
                
                WalletNFTsListView(viewModel: viewModel.nftsViewModel)
                    .widget()
                
                WalletJettonsListView(viewModel: viewModel.jettonsViewModel)
                    .widget()
            }
            .padding(16.0)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.TON.gray100)
        .navigationTitle("TON Wallet")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(
                    action: {
                        viewModel.remove()
                    },
                    label: {
                        Image(systemName: "trash")
                            .foregroundStyle(Color.TON.red600)
                    }
                )
            }
        }
    }
}
