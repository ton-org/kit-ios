//
//  FeeAssetViewModel.swift
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
import Combine
import TONWalletKit

/// One row of the gasless fee-asset list. Each instance resolves its own jetton metadata
/// (symbol / decimals / icon) from the master address via `TONJettonsManager` — the list shows
/// addresses first and each turns into a ticker as it loads, mirroring the JS demo.
@MainActor
final class FeeAssetViewModel: ObservableObject, Identifiable {

    let id: String
    let address: TONUserFriendlyAddress
    private let network: TONNetwork

    /// Resolved ticker once metadata loads; the short address until then.
    @Published private(set) var title: String
    /// Always the short master address (secondary line).
    @Published private(set) var subtitle: String
    @Published private(set) var iconURL: URL?
    @Published private(set) var decimals: Int
    @Published private(set) var isLoading = false

    private var didLoad = false

    init(address: TONUserFriendlyAddress, network: TONNetwork) {
        self.id = address.value
        self.address = address
        self.network = network
        let short = Self.shortAddress(address.value)
        self.title = short
        self.subtitle = short
        self.decimals = 9
    }

    /// Resolve metadata via `TONJettonsManager.jettonInfo`. Idempotent.
    func load() async {
        guard !didLoad, !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let manager = try await TONWalletKit.shared().jettons()
            guard let info = try await manager.jettonInfo(address: address, network: network) else {
                didLoad = true
                return
            }
            if !info.symbol.isEmpty {
                title = info.symbol
            } else if !info.name.isEmpty {
                title = info.name
            }
            if let decimals = info.decimals {
                self.decimals = decimals
            }
            if let image = info.image, let url = URL(string: image) {
                self.iconURL = url
            }
            didLoad = true
        } catch {
            debugPrint("Failed to load jetton info for \(address.value): \(error)")
        }
    }

    private static func shortAddress(_ address: String) -> String {
        guard address.count > 8 else { return address }
        return "\(address.prefix(4))…\(address.suffix(4))"
    }
}
