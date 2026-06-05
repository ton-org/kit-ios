//
//  RealBridgeIframeController.swift
//  TONWalletApp
//
//  Created by Nikita Rodionov on 05.06.2026.
//
//  Copyright (c) 2026 TON Connect
//

import Foundation
import Combine
import WebKit
import TONWalletKit

@MainActor
final class RealBridgeIframeController: ObservableObject {
    let logger = IframeSecurityLogger()

    weak var webView: WKWebView?

    private var subscribers = Set<AnyCancellable>()

    init() {
        subscribeToNativeEvents()

        // Nested ObservableObject changes don't bubble; relay the logger's
        // updates so views observing the controller re-render.
        logger.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &subscribers)
    }

    func run(_ testCase: RealBridgeIframeCase) {
        // Always emit a Swift-side entry so the panel confirms the tap landed,
        // independent of whether the injected frame can reach the bridge.
        logger.addNative(action: "▶ Inject: \(testCase.title)", domain: "(main frame)")
        guard let webView else {
            logger.addNative(action: "⚠️ WebView not ready", domain: "—")
            return
        }
        webView.evaluateJavaScript(testCase.spawnJS) { [weak self] _, error in
            if let error {
                self?.logger.addNative(
                    action: "JS error injecting \(testCase.shortTitle)",
                    domain: "(main frame)",
                    payload: error.localizedDescription
                )
            }
        }
    }

    func clearInjectedFrames() {
        webView?.evaluateJavaScript("window.__ifsecClear && window.__ifsecClear();")
    }

    func clearLog() {
        logger.clear()
    }

    /// Mirror every event the SDK actually surfaces into the log, with the
    /// `domain` the SDK attributed — the ground-truth origin the wallet trusts.
    private func subscribeToNativeEvents() {
        TONEventsHandler.shared.events
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.logNative(event)
            }
            .store(in: &subscribers)
    }

    private func logNative(_ event: TONWalletKitEvent) {
        let bridge = event.isJsBridge ? "jsBridge" : "remote"
        switch event {
        case .connectRequest(let request):
            logger.addNative(
                action: "→ SDK connectRequest (\(bridge))",
                domain: request.event.domain ?? request.event.dAppInfo?.url?.absoluteString ?? "(nil domain)",
                payload: request.event.dAppInfo?.name ?? ""
            )
        case .signDataRequest(let request):
            logger.addNative(
                action: "→ SDK signDataRequest (\(bridge)) — SHEET SHOULD APPEAR",
                domain: request.event.domain ?? "(nil domain)",
                payload: "from=\(request.event.from ?? "nil") tabId=\(request.event.tabId ?? "nil")"
            )
        case .signMessageRequest(let request):
            logger.addNative(
                action: "→ SDK signMessageRequest (\(bridge))",
                domain: request.event.domain ?? "(nil domain)",
                payload: "tabId=\(request.event.tabId ?? "nil")"
            )
        case .transactionRequest(let request):
            logger.addNative(
                action: "→ SDK transactionRequest (\(bridge))",
                domain: request.event.domain ?? "(nil domain)",
                payload: "tabId=\(request.event.tabId ?? "nil")"
            )
        case .disconnect:
            logger.addNative(action: "→ SDK disconnect", domain: "—")
        }
    }
}
