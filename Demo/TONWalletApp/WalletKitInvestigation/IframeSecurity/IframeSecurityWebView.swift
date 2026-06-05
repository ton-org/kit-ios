//
//  IframeSecurityWebView.swift
//  TONWalletApp
//
//  Created by Nikita Rodionov on 04.06.2026.
//
//  Copyright (c) 2026 TON Connect
//

import SwiftUI
import WebKit

struct IframeSecurityWebView: UIViewRepresentable {
    let loadMode: IframeSecurityCase.LoadMode
    let logger: IframeSecurityLogger

    func makeCoordinator() -> Coordinator {
        Coordinator(logger: logger)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.userContentController.add(context.coordinator, name: "iframeSecLog")

        if case .schemeRoutes(let scheme, _, let routes) = loadMode {
            let handler = IframeSecuritySchemeHandler(routes: routes)
            config.setURLSchemeHandler(handler, forURLScheme: scheme)
            context.coordinator.schemeHandler = handler
        }

        let webView = WKWebView(frame: .zero, configuration: config)
        if #available(iOS 16.4, *) { webView.isInspectable = true }

        switch loadMode {
        case .htmlString(let html, let baseURL):
            webView.loadHTMLString(html, baseURL: baseURL)
        case .schemeRoutes(_, let initial, _):
            webView.load(URLRequest(url: initial))
        }

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKScriptMessageHandler {
        weak var logger: IframeSecurityLogger?
        var schemeHandler: IframeSecuritySchemeHandler?

        init(logger: IframeSecurityLogger) {
            self.logger = logger
        }

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            let frameInfo = message.frameInfo
            let body = message.body as? [String: Any] ?? [:]

            let frameURL = frameInfo.request.url?.absoluteString
            let isMain = frameInfo.isMainFrame

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

            let frameLabel = body["frameLabel"] as? String ?? "?"
            let action = body["action"] as? String ?? "?"
            let claimedOrigin = body["claimedOrigin"] as? String ?? "?"

            var payloadString = ""
            if let payload = body["payload"] {
                if JSONSerialization.isValidJSONObject(payload),
                   let data = try? JSONSerialization.data(withJSONObject: payload),
                   let str = String(data: data, encoding: .utf8) {
                    payloadString = str
                } else {
                    payloadString = String(describing: payload)
                }
            }

            let entry = IframeSecurityLogger.Entry(
                timestamp: Date(),
                frameLabel: frameLabel,
                action: action,
                claimedOrigin: claimedOrigin,
                actualFrameURL: frameURL,
                actualOrigin: actualOrigin,
                isMainFrame: isMain,
                payload: payloadString
            )

            DispatchQueue.main.async { [weak self] in
                self?.logger?.add(entry)
            }
        }
    }
}
