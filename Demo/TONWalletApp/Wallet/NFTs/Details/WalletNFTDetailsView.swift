//
//  WalletNFTDetailsView.swift
//  TONWalletApp
//
//  Created by Nikita Rodionov on 29.10.2025.
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

struct WalletNFTDetailsView: View {
    @StateObject var viewModel: WalletNFTDetailsViewModel
    @State private var isWalletAddressInputPresented = false
    
    var nftDetails: WalletNFTDetails { viewModel.details }

    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: AppSpacing.spacing(6)) {
            ScrollView {
                VStack(spacing: AppSpacing.spacing(6)) {

                    Text(nftDetails.name)
                        .textXL(weight: .bold)
                        .foregroundColor(Color.TON.gray900)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    let placeholder = Rectangle()
                        .fill(Color.TON.gray100)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundColor(Color.TON.gray400)
                        }
                    
                    if let imageURL = nftDetails.imageURL {
                        AsyncImage(url: imageURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            placeholder
                        }
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.standard))
                    } else {
                        placeholder
                    }
                    
                    VStack(spacing: AppSpacing.spacing(6)) {
                        // Description Section
                        VStack(alignment: .leading, spacing: AppSpacing.spacing(2)) {
                            Text("Description")
                                .textLG(weight: .medium)
                                .foregroundColor(Color.TON.gray900)
                            
                            Text(nftDetails.description)
                                .textBase()
                                .foregroundColor(Color.TON.gray600)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Collection Section
                        VStack(alignment: .leading, spacing: AppSpacing.spacing(2)) {
                            Text("Collection")
                                .textLG(weight: .medium)
                                .foregroundColor(Color.TON.gray900)
                            
                            Text(nftDetails.collectionName)
                                .textBase()
                                .foregroundColor(Color.TON.gray600)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Index and Status Row
                        HStack(spacing: AppSpacing.spacing(8)) {
                            // Index
                            VStack(alignment: .leading, spacing: AppSpacing.spacing(2)) {
                                Text("Index")
                                    .textLG(weight: .medium)
                                    .foregroundColor(Color.TON.gray900)
                                
                                Text(nftDetails.index)
                                    .textBase()
                                    .foregroundColor(Color.TON.gray600)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // Status
                            VStack(alignment: .leading, spacing: AppSpacing.spacing(2)) {
                                Text("Status")
                                    .textLG(weight: .medium)
                                    .foregroundColor(Color.TON.gray900)
                                
                                Text(nftDetails.status)
                                    .textBase()
                                    .foregroundColor(Color.TON.gray600)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        // Contract Address Section
                        VStack(alignment: .leading, spacing: AppSpacing.spacing(2)) {
                            Text("Contract Address")
                                .textLG(weight: .medium)
                                .foregroundColor(Color.TON.gray900)
                            
                            Text(nftDetails.contractAddress)
                                .textBase()
                                .foregroundColor(Color.TON.gray600)
                                .fixedSize(horizontal: false, vertical: true)
                                .textSelection(.enabled)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(alignment: .leading, spacing: AppSpacing.spacing(2)) {
                            Text("Owner")
                                .textLG(weight: .medium)
                                .foregroundColor(Color.TON.gray900)
                            
                            Text(nftDetails.ownerAddress)
                                .textBase()
                                .foregroundColor(Color.TON.gray600)
                                .fixedSize(horizontal: false, vertical: true)
                                .textSelection(.enabled)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(AppSpacing.spacing(4))
            }
            
            HStack(spacing: AppSpacing.spacing(3)) {
                Button("Transfer") {
                    isWalletAddressInputPresented = true
                }
                .buttonStyle(TONLegacyButtonStyle(type: .primary, isLoading: viewModel.isTransferring))
                .disabled(!nftDetails.canTransfer)
                
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(TONLegacyButtonStyle(type: .secondary))
            }
            .padding(AppSpacing.spacing(4.0))
        }
        .background(Color.TON.white)
        .sheet(isPresented: $isWalletAddressInputPresented) {
            WalletAddressInputView(title: "Transfer NFT", buttonTitle: "Transfer") { address in
                isWalletAddressInputPresented = false
                viewModel.transfer(to: address)
            }
            .automaticHeightPresentationDetents()
            .presentationDragIndicator(.visible)
        }
    }
}

