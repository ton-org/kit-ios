//
//  SendTokensView.swift
//  TONWalletApp
//
//  Created by Nikita Rodionov on 01.11.2025.
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

struct SendTokensView: View {
    @StateObject var viewModel: SendTokensViewModel
    
    @State private var showTokenSelection = false
    @State private var recipientAddress = ""
    @State private var amount = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Scrollable Content
            ScrollView {
                VStack(spacing: AppSpacing.spacing(6)) {
                    // Token Selection Section
                    VStack(alignment: .leading, spacing: AppSpacing.spacing(3)) {
                        Button(action: {
                            showTokenSelection.toggle()
                        }) {
                            HStack(spacing: AppSpacing.spacing(3)) {
                                SendableTokenInitialsView(initials: viewModel.selectedToken.initials)
                                
                                VStack(alignment: .leading, spacing: AppSpacing.spacing(0.5)) {
                                    Text(viewModel.selectedToken.name)
                                        .textBase(weight: .medium)
                                        .foregroundColor(Color.TON.gray900)
                                        .lineLimit(1)
                                    
                                    Text("Balance: \(viewModel.selectedToken.balance)")
                                        .textSM()
                                        .foregroundColor(Color.TON.gray500)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.down")
                                    .foregroundColor(Color.TON.gray400)
                                    .textSM()
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if showTokenSelection {
                            SendableTokenSelectionView(
                                tokens: viewModel.availableTokens,
                                onTokenSelected: { token in
                                    recipientAddress = ""
                                    amount = ""
                                    viewModel.select(token: token)
                                    showTokenSelection = false
                                }
                            )
                        }
                    }
                    .widget()
                    
                    VStack(spacing: AppSpacing.spacing(2)) {
                        Text("Available Balance")
                            .textSM()
                            .foregroundColor(Color.TON.gray500)
                        
                        Text("\(viewModel.selectedToken.balance) \(viewModel.selectedToken.symbol)")
                            .text2XL(weight: .bold)
                            .foregroundColor(Color.TON.gray900)
                    }
                    .frame(maxWidth: .infinity)
                    .widget()
                    
                    VStack(alignment: .leading, spacing: AppSpacing.spacing(3)) {
                        Text("Recipient Address")
                            .textLG(weight: .medium)
                            .foregroundColor(Color.TON.gray900)
                        
                        ZStack(alignment: .trailing) {
                            TextField("EQxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx", text: $recipientAddress)
                                .textFieldStyle(TONTextFieldStyle())
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .keyboardType(.asciiCapable)
                        }
                        
                        Text("Enter the recipient's TON address")
                            .textSM()
                            .foregroundColor(Color.TON.gray500)
                    }
                    .widget()
                    
                    VStack(alignment: .leading, spacing: AppSpacing.spacing(3)) {
                        Text("Amount (\(viewModel.selectedToken.symbol))")
                            .textLG(weight: .medium)
                            .foregroundColor(Color.TON.gray900)
                        
                        TextField("0.0000", text: $amount)
                            .textFieldStyle(TONTextFieldStyle())
                            .keyboardType(.decimalPad)
                        
                        HStack {
                            Text(viewModel.selectedToken.requiredAmountInfo)
                                .textSM()
                                .foregroundColor(Color.TON.gray500)
                            
                            Spacer()
                            
                            Button("Use Max") {
                                amount = viewModel.selectedToken.balance
                            }
                            .textSM(weight: .medium)
                            .foregroundColor(Color.TON.blue500)
                            .padding(.horizontal, AppSpacing.spacing(3))
                            .padding(.vertical, AppSpacing.spacing(2))
                            .background(Color.TON.gray100)
                            .cornerRadius(AppRadius.standard / 2)
                        }
                    }
                    .widget()
                }
                .padding(AppSpacing.spacing(4))
            }
            
            // Fixed Send Button at Bottom
            VStack {
                Divider()
                
                Button("Send \(viewModel.selectedToken.symbol)") {
                    viewModel.send(
                        amount: amount,
                        address: recipientAddress
                    )
                }
                .buttonStyle(TONLegacyButtonStyle(
                    type: .primary,
                    isLoading: viewModel.isSending
                ))
                .disabled(!canSend)
                .padding(.horizontal, AppSpacing.spacing(4))
                .padding(.bottom, AppSpacing.spacing(4))
            }
            .background(Color.TON.white)
        }
        .background(Color.TON.gray100)
        .navigationTitle("Send \(viewModel.selectedToken.symbol)")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var canSend: Bool {
        !recipientAddress.isEmpty && 
        !amount.isEmpty &&
        !viewModel.isSending
    }
}

