//
//  WalletTransactionRequestView.swift
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

struct WalletTransactionRequestView: View {
    @StateObject var viewModel: WalletTransactionRequestViewModel
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Scrollable content
            VStack(spacing: AppSpacing.spacing(4.0)) {
                // Header
                VStack(spacing: AppSpacing.spacing(2.0)) {
                    Text("Transaction Request")
                        .textXL(weight: .bold)
                        .foregroundColor(Color.TON.gray900)
                    
                    Text("A dApp wants to send a transaction from your wallet")
                        .textSM()
                        .foregroundColor(Color.TON.gray600)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.center)
                }
                
                // DApp Info
                if let dAppInfo = viewModel.dAppInfo {
                    DAppView(dAppInfo: dAppInfo)
                }
                
                // Warning
                HStack(spacing: AppSpacing.spacing(2.0)) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(Color.orange)
                        .font(.system(size: 16))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Warning: This transaction will be irreversible. Only approve if you trust the requesting dApp and understand the transaction details.")
                            .textSM()
                            .foregroundColor(Color.orange)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer()
                }
                .padding(AppSpacing.spacing(3.0))
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
            }
            .padding(AppSpacing.spacing(4.0))
            
            Spacer()
            
            HStack(spacing: AppSpacing.spacing(2.0)) {
                Button("Reject") {
                    viewModel.reject()
                }
                .buttonStyle(TONLegacyButtonStyle(type: .secondary))
                
                Button("Approve") {
                    viewModel.approve()
                }
                .buttonStyle(TONLegacyButtonStyle(type: .primary))
            }
            .padding(AppSpacing.spacing(4.0))
        }
        .onReceive(viewModel.dismiss) { dismiss() }
    }
}
