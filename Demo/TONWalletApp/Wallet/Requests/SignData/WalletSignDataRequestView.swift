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

struct WalletSignDataRequestView: View {
    @StateObject var viewModel: WalletSignDataRequestViewModel
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Scrollable content
            VStack(spacing: AppSpacing.spacing(4.0)) {
                // Header
                VStack(spacing: AppSpacing.spacing(2.0)) {
                    Text("Sign Data Request")
                        .textXL(weight: .bold)
                        .foregroundColor(Color.TON.gray900)
                    
                    Text("A dApp wants you to sign data with your wallet")
                        .textSM()
                        .foregroundColor(Color.TON.gray600)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.center)
                }
                
                // DApp Info
                if let dAppInfo = viewModel.dAppInfo {
                    DAppView(dAppInfo: dAppInfo)
                }
                
                // Wallet Info
                HStack {
                    Text("Wallet:")
                        .textSM()
                        .foregroundColor(Color.TON.gray600)
                    
                    Spacer()
                    
                    Text(viewModel.walletAddress ?? "Unknown")
                        .textSM(weight: .medium)
                        .foregroundColor(Color.TON.gray900)
                        .truncationMode(.middle)
                }
                
                // Warning
                HStack(spacing: AppSpacing.spacing(2.0)) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(Color.orange)
                        .font(.system(size: 16))
 
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Only sign data if you trust the requesting dApp and understand what you're signing. Signing data can have security implications.")
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
                
                Button("Sign Data") {
                    viewModel.approve()
                }
                .buttonStyle(TONLegacyButtonStyle(type: .primary))
            }
            .padding(AppSpacing.spacing(4.0))
        }
        .onReceive(viewModel.dismiss) { dismiss() }
    }
}
