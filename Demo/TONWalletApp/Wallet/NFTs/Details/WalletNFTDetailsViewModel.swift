//
//  WalletNFTDetailsViewModel.swift
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

import Foundation
import Combine
import TONWalletKit

@MainActor
class WalletNFTDetailsViewModel: ObservableObject, Identifiable {
    let id = UUID()
    
    @Published private(set) var details: WalletNFTDetails
    @Published private(set) var isTransferring = false
    
    let onRemove: () -> Void
    
    private let wallet: TONWalletProtocol
    private let nft: TONNFT
    
    init(wallet: TONWalletProtocol, nft: TONNFT, onRemove: @escaping () -> Void) {
        self.wallet = wallet
        self.nft = nft
        self.details = .init(from: nft)
        self.onRemove = onRemove
    }
    
    func transfer(to address: String) {
        if isTransferring { return }
        
        let sameWalletTransfer = address == wallet.address.value
        
        isTransferring = true
        
        Task {
            do {
                let request = TONNFTTransferRequest(
                    nftAddress: nft.address,
                    transferAmount: TONTokenAmount(nanoUnits: 100000000),
                    recipientAddress: try TONUserFriendlyAddress(value: address)
                )

                let transactionRequest = try await wallet.transferNFTTransaction(request: request)
                _ = try await wallet.send(transactionRequest: transactionRequest)
            } catch {
                debugPrint("Failed to transfer NFT: \(error.localizedDescription)")
            }
            
            isTransferring = false
            
            if !sameWalletTransfer {
                onRemove()
            }
        }
    }
    
    func remove() {
        onRemove()
    }
}
