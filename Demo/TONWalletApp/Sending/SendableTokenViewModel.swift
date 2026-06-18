//
//  SendableTokenViewModel.swift
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
import Combine
import TONWalletKit

protocol SendableTokenViewModel: AnyObject {
    var name: String { get }
    var symbol: String { get }
    var balance: String { get }
    var decimals: Int { get }
    var requiredAmountInfo: String { get }
    var balanceChanges: AnyPublisher<Void, Never> { get }

    /// The wallet that owns this asset — used to build/sign transactions.
    var wallet: any TONWalletProtocol { get }
    /// Jetton master address, or `nil` for native TON. Used to gate gasless.
    var jettonAddress: TONUserFriendlyAddress? { get }
    /// Remote icon for the asset, when available.
    var iconURL: URL? { get }

    func send(amount: String, address: String) async throws
    func updateBalance() async throws
}

extension SendableTokenViewModel {

    /// Gasless is only available for jettons (native TON already pays its own gas).
    var isNativeTON: Bool { jettonAddress == nil }
}

extension SendableTokenViewModel {
    
    var initials: String {
        let components = name.components(separatedBy: " ")
        let initials = components.compactMap { $0.first }.prefix(2)
        return String(initials).uppercased()
    }
}
