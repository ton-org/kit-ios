//
//  FeeAsset.swift
//  TONWalletApp
//
//  Created by Nikita Rodionov on 16.06.2026.
//
//  Copyright (c) 2026 TON Connect
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

/// A jetton the relayer accepts as a gasless fee payment, resolved to display metadata.
struct FeeAsset: Identifiable, Equatable {
    let address: TONUserFriendlyAddress
    let symbol: String
    let decimals: Int
    let iconURL: URL?

    var id: String { address.value }

    static func == (lhs: FeeAsset, rhs: FeeAsset) -> Bool {
        lhs.address.value == rhs.address.value
    }
}
