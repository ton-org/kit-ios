//
//  SendableJettonViewModel.swift
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
import TONWalletKit

final class SendableJettonViewModel: SendableTokenViewModel {
    var name: String { jetton.info.name ?? "Unknown Jetton" }
    var symbol: String {  jetton.info.symbol ?? "UNKNOWN" }
    var decimals: Int { jetton.decimalsNumber ?? 9 }
    var requiredAmountInfo: String { "Enter amount in \(symbol) units" }
    var balance: String { jettonBalance.flatMap { formatter.string(from: $0) } ?? "Unknown Balance" }
    
    private lazy var formatter: TONBalanceFormatter = {
        let formatter = TONBalanceFormatter()
        formatter.nanoUnitDecimalsNumber = decimals
        return formatter
    }()
    
    let jetton: TONJetton
    let wallet: any TONWalletProtocol
    private(set) var jettonBalance: TONBalance?
    
    init(jetton: TONJetton, wallet: any TONWalletProtocol) {
        self.jetton = jetton
        self.jettonBalance = jetton.balance
        self.wallet = wallet
    }
    
    func send(amount: String, address: String) async throws {
        guard let amount = formatter.amount(from: amount) else {
            return
        }
        
        let request = TONJettonsTransferRequest(
            jettonAddress: jetton.address,
            transferAmount: amount,
            recipientAddress: try TONUserFriendlyAddress(value: address),
        )

        let transactionRequest = try await wallet.transferJettonTransaction(request: request)
        _ = try await wallet.send(transactionRequest: transactionRequest)
    }
    
    func updateBalance() async throws {
        self.jettonBalance = try await wallet.jettonBalance(jettonAddress: jetton.address)
    }
    
}
