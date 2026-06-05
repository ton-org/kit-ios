//
//  RealBridgeIframeWebView.swift
//  TONWalletApp
//
//  Created by Nikita Rodionov on 05.06.2026.
//
//  Copyright (c) 2026 TON Connect
//

import SwiftUI
import WebKit
import TONWalletKit

struct RealBridgeIframeWebView: UIViewRepresentable {
    let walletKit: TONWalletKit
    let url: URL
    let controller: RealBridgeIframeController

    func makeCoordinator() -> Coordinator {
        Coordinator(logger: controller.logger)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        if #available(iOS 16.4, *) { webView.isInspectable = true }

        // Real WalletKit injection: registers `walletKitInjectionBridge` and the
        // all-frames provider injection (window.ton.tonconnect etc.).
        try? webView.inject(walletKit: walletKit)

        // Parallel diagnostic handler so injected frames can report their claimed
        // origin while the native side records the real WKFrameInfo.securityOrigin.
        webView.configuration.userContentController.add(context.coordinator, name: "iframeSecLog")

        controller.webView = webView
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKScriptMessageHandler {
        weak var logger: IframeSecurityLogger?

        init(logger: IframeSecurityLogger) {
            self.logger = logger
        }

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            let frameInfo = message.frameInfo
            let body = message.body as? [String: Any] ?? [:]

            let secOrigin = frameInfo.securityOrigin
            let scheme = secOrigin.`protocol`
            let host = secOrigin.host
            let port = secOrigin.port

            let actualOrigin: String
            if scheme.isEmpty && host.isEmpty {
                actualOrigin = "null (opaque)"
            } else if scheme == "data" {
                actualOrigin = "data: (opaque)"
            } else if port == 0 {
                actualOrigin = "\(scheme)://\(host)"
            } else {
                actualOrigin = "\(scheme)://\(host):\(port)"
            }

            let entry = IframeSecurityLogger.Entry(
                timestamp: Date(),
                frameLabel: body["frameLabel"] as? String ?? "?",
                action: body["action"] as? String ?? "?",
                claimedOrigin: body["claimedOrigin"] as? String ?? "?",
                actualFrameURL: frameInfo.request.url?.absoluteString,
                actualOrigin: actualOrigin,
                isMainFrame: frameInfo.isMainFrame,
                payload: body["payload"] as? String ?? ""
            )

            // Mirror to the Xcode console too, so messages are visible even if the
            // in-app panel is obscured.
            debugPrint("[iframeSecLog] \(entry.frameLabel) | \(entry.action) | real=\(entry.actualOrigin) claimed=\(entry.claimedOrigin) \(entry.payload)")

            DispatchQueue.main.async { [weak self] in
                self?.logger?.add(entry)
            }
        }
    }
}
