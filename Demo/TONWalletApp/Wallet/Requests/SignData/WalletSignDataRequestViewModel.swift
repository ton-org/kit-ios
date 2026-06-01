//
//  WalletSignDataRequestViewModel.swift
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

import Foundation
import Combine
import TONWalletKit

@MainActor
class WalletSignDataRequestViewModel: ObservableObject {
    private let request: TONWalletSignDataRequest
    
    var dAppInfo: TONDAppInfo? { request.event.preview.dAppInfo }
    var walletAddress: String? { request.event.walletAddress?.value }
    var signData: TONSignData { request.event.payload.data }
    
    let dismiss = PassthroughSubject<Void, Never>()
    
    init(request: TONWalletSignDataRequest) {
        self.request = request
    }
    
    func approve() {
        Task {
            do {
                _ = try await request.approve()
                dismiss.send()
            } catch {
                debugPrint("Error approving sign data request: \(error.localizedDescription)")
            }
        }
    }
    
    func reject() {
        Task {
            do {
                try await request.reject(reason: "User rejected sign data request")
                dismiss.send()
            } catch {
                debugPrint("Error rejecting sign data request: \(error.localizedDescription)")
            }
        }
    }
}
