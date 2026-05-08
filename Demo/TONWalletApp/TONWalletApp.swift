//
//  TONWalletApp.swift
//  TONWalletApp
//
//  Created by Nikita Rodionov on 11.09.2025.
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
import SwiftUI
import TONWalletKit

@main
struct TONWalletApp: App {
    @State var initialized = false
    #if DEBUG
    @State private var showDebugMenu = false
    #endif

    var body: some Scene {
        WindowGroup {
            content
            #if DEBUG
                .onShake { showDebugMenu = true }
                .sheet(isPresented: $showDebugMenu) { DebugMenuView() }
            #endif
        }
    }

    @ViewBuilder
    private var content: some View {
        if initialized {
            TONWalletAppView()
        } else {
            ProgressView()
                .task { initialized = true }
        }
    }
}

extension TONWalletKit {
    
    private static var _shared: TONWalletKit?
    
    @discardableResult
    static func shared() async -> TONWalletKit {
        if let _shared {
            return _shared
        }
        if Env.toncenterAPIKey.isEmpty || Env.toncenterStreamingAPIKey.isEmpty {
            fatalError("API keys not configured. Fill in your keys in Demo/TONWalletApp/Env.swift")
        }
        let bridgeURL = "https://bridge.tonapi.io/bridge"
        let apiClientConfig = TONWalletKitConfiguration.APIClientConfiguration(key: Env.toncenterAPIKey)
        let testNetworkConfiguration = TONWalletKitConfiguration.NetworkConfiguration(
            network: .testnet,
            apiClient: .toncenter(apiClientConfig)
        )
        let mainNetworkConfiguration = TONWalletKitConfiguration.NetworkConfiguration(
            network: .mainnet,
            apiClientConfiguration: apiClientConfig
        )
        let tetraNetworkConfiguration = TONWalletKitConfiguration.NetworkConfiguration(
            network: .tetra,
            apiClient: .tonApi(.init(key: Env.tonApiTetraKey))
        )
        let configuration = TONWalletKitConfiguration(
            networkConfigurations: [testNetworkConfiguration, mainNetworkConfiguration, tetraNetworkConfiguration],
            walletManifest: TONWalletKitConfiguration.Manifest(
                name: "WalletKitDemoWallet",
                appName: "wallet_kit_demo_wallet",
                imageUrl: "https://example.com/image.png",
                aboutUrl: "https://example.com/about",
                universalLink: "https://example.com/universal-link",
                bridgeUrl: bridgeURL
            ),
            storage: .keychain,
            bridge: TONWalletKitConfiguration.Bridge(bridgeUrl: bridgeURL, webViewInjectionKey: "walletKitDemoWallet"),
            features: [
                TONSendTransactionFeature(maxMessages: 255),
                TONSignDataFeature(types: [.text, .binary, .cell]),
            ]
        )
        let kit = TONWalletKit(configuration: configuration)
        
        do {
            let toncenterStreaming = try await kit.streamingProvider(
                config: TONTonCenterStreamingProviderConfig(
                    network: .mainnet,
                    apiKey: Env.toncenterStreamingAPIKey
                )
            )
            
            try await kit.streaming().register(provider: toncenterStreaming)
        } catch {
            debugPrint("ERROR - \(error)")
        }
        
        _shared = kit
        return kit
    }
}
