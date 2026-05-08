//
//  WalletConnectionRequestView.swift
//  TONWalletApp
//
//  Created by Nikita Rodionov on 03.10.2025.
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

struct WalletConnectionRequestView: View {
    @StateObject var viewModel: WalletConnectionRequestViewModel
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: AppSpacing.spacing(4.0)) {
            VStack(spacing: AppSpacing.spacing(2.0)) {
                Text("Connect Request")
                    .textXL(weight: .bold)
                    .foregroundColor(Color.TON.gray900)
                
                Text("A dApp wants to connect to your wallet")
                    .textSM()
                    .foregroundColor(Color.TON.gray600)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            if let dAppInfo = viewModel.dAppInfo {
                DAppView(dAppInfo: dAppInfo)
            }
            
            if !viewModel.permissions.isEmpty {
                VStack(alignment: .leading, spacing: 8.0) {
                    Text("Requested Permissions:")
                        .textLG(weight: .medium)
                        .foregroundColor(Color.TON.gray900)
                    
                    ForEach(0..<viewModel.permissions.count, id: \.self) { index in
                        let permission = viewModel.permissions[index]
                        
                        VStack(alignment: .leading, spacing: AppSpacing.spacing(2.0)) {
                            Text(permission.title ?? "")
                                .textSM(weight: .medium)
                                .foregroundColor(Color.TON.gray900)
                                .fixedSize(horizontal: false, vertical: true)
                                .multilineTextAlignment(.leading)
                            
                            Text(permission.description ?? "")
                                .textXS()
                                .foregroundColor(Color.TON.gray600)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .widget(style: .block(.regular))
                    }
                }
            }
            
            // Wallets Selection Section
            VStack(alignment: .leading, spacing: AppSpacing.spacing(2.0)) {
                Text("Select Wallet")
                    .textLG(weight: .medium)
                    .foregroundColor(Color.TON.gray900)
                
                ScrollView {
                    VStack(spacing: AppSpacing.spacing(2.0)) {
                        ForEach(viewModel.wallets) { wallet in
                            WalletSelectionRow(
                                wallet: wallet,
                                isSelected: viewModel.selectedWallet?.id == wallet.id,
                                onTap: {
                                    viewModel.selectedWallet = wallet
                                }
                            )
                        }
                    }
                    .padding(.vertical, AppSpacing.spacing(1.0))
                }
                .frame(maxHeight: 200)
            }
            
            Text("Only connect to trusted applications. This will give the dApp access to your wallet address and allow it to request transactions.")
                .textSM()
                .foregroundColor(Color.TON.yellow800)
                .multilineTextAlignment(.leading)
                .widget(style: .block(.warning))
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
            
            HStack(spacing: AppSpacing.spacing(2.0)) {
                Button("Reject") {
                    viewModel.reject()
                }
                .buttonStyle(TONLegacyButtonStyle(type: .secondary))
                
                Button("Connect") {
                    viewModel.approve()
                }
                .buttonStyle(TONLegacyButtonStyle(type: .primary))
            }
        }
        .padding(AppSpacing.spacing(4.0))
        .onReceive(viewModel.dismiss) { dismiss() }
    }
}

struct WalletSelectionRow: View {
    let wallet: WalletConnectionRequestViewModel.SelectableWallet
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.spacing(3.0)) {
                // Wallet Icon/Initial
                Circle()
                    .fill(Color.TON.blue500)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(wallet.address.prefix(2)))
                            .textSM(weight: .bold)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: AppSpacing.spacing(0.5)) {
                    Text("Wallet")
                        .textBase(weight: .medium)
                        .foregroundColor(Color.TON.gray900)
                        .lineLimit(1)
                    
                    Text(formatAddress(wallet.address))
                        .textSM()
                        .foregroundColor(Color.TON.gray500)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Selection Indicator
                Circle()
                    .stroke(isSelected ? Color.TON.blue500 : Color.TON.gray300, lineWidth: 2)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .fill(Color.TON.blue500)
                            .frame(width: 12, height: 12)
                            .opacity(isSelected ? 1 : 0)
                    )
            }
            .padding(AppSpacing.spacing(3.0))
            .background(isSelected ? Color.TON.blue50 : Color.TON.white)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.standard)
                    .stroke(isSelected ? Color.TON.blue500 : Color.TON.gray200, lineWidth: 1)
            )
            .cornerRadius(AppRadius.standard)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatAddress(_ address: String) -> String {
        guard address.count > 8 else { return address }
        let start = String(address.prefix(4))
        let end = String(address.suffix(4))
        return "\(start)...\(end)"
    }
}
