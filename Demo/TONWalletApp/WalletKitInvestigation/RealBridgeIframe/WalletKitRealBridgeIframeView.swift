//
//  WalletKitRealBridgeIframeView.swift
//  TONWalletApp
//
//  Created by Nikita Rodionov on 05.06.2026.
//
//  Copyright (c) 2026 TON Connect
//

import SwiftUI
import TONWalletKit

struct WalletKitRealBridgeIframeView: View {
    @StateObject private var controller = RealBridgeIframeController()

    @State private var walletKit: TONWalletKit?
    @State private var selectedCase: RealBridgeIframeCase = .sameOriginNavigated
    @State private var showInfo = false

    private static let dappURL = URL(string: "https://tonconnect-sdk-demo-dapp.vercel.app/")!

    private var logger: IframeSecurityLogger { controller.logger }

    var body: some View {
        VStack(spacing: 0) {
            instructions
            caseBar
            Divider()
            webViewArea
            Divider()
            logPanel
        }
        .navigationTitle("Real Bridge")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    controller.clearInjectedFrames()
                    controller.clearLog()
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .task {
            if walletKit == nil {
                walletKit = await TONWalletKit.shared()
                controller.logger.addNative(
                    action: "Ready — connect in the dApp, then pick a case and tap Inject",
                    domain: "—"
                )
            }
        }
    }

    @ViewBuilder
    private var instructions: some View {
        DisclosureGroup(isExpanded: $showInfo) {
            VStack(alignment: .leading, spacing: 6) {
                Text(selectedCase.title).font(.subheadline.bold())
                Text(selectedCase.summary).font(.caption).foregroundStyle(.secondary)
                Text(selectedCase.expectation)
                    .font(.caption.bold())
                    .foregroundStyle(selectedCase.expectsSheet ? Color.red : Color.green)
                Divider()
                stepText("1.", "Connect a wallet using the dApp below (real connect, origin = the dApp).")
                stepText("2.", "Pick a case and tap “Inject”. A frame is added in a panel inside the page.")
                stepText("3.", "Tap “Send REAL signData” inside the injected frame.")
                stepText("4.", "Watch the log + whether the real wallet sign-data sheet appears for a frame that never connected.")
            }
            .padding(.top, 6)
        } label: {
            Label("How this works — \(selectedCase.shortTitle)", systemImage: "info.circle")
                .font(.caption.bold())
        }
        .padding(10)
        .background(Color(.secondarySystemBackground))
    }

    private func stepText(_ n: String, _ s: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text(n).font(.caption.bold())
            Text(s).font(.caption).foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var caseBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(RealBridgeIframeCase.allCases) { testCase in
                    Button {
                        selectedCase = testCase
                    } label: {
                        Text(testCase.shortTitle)
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(selectedCase == testCase ? Color.accentColor : Color(.systemGray5))
                            .foregroundStyle(selectedCase == testCase ? Color.white : Color.primary)
                            .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .overlay(alignment: .trailing) {
            Button("Inject") {
                controller.run(selectedCase)
                showInfo = false
            }
            .font(.caption.bold())
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.red)
            .foregroundStyle(.white)
            .cornerRadius(8)
            .padding(.trailing, 8)
            .disabled(walletKit == nil)
        }
    }

    @ViewBuilder
    private var webViewArea: some View {
        if let walletKit {
            RealBridgeIframeWebView(
                walletKit: walletKit,
                url: Self.dappURL,
                controller: controller
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack { Spacer(); ProgressView("Loading WalletKit…"); Spacer() }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private var logPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Log (\(logger.entries.count))").font(.caption.bold())
                Spacer()
                Text("orange = injected frame · blue = SDK event")
                    .font(.caption2).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(Color(.systemGray6))

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        if logger.entries.isEmpty {
                            Text("No events yet. Connect, inject a case, then send.")
                                .font(.caption).foregroundStyle(.secondary).padding(.top, 12)
                        } else {
                            ForEach(logger.entries) { entry in
                                RealBridgeLogRow(entry: entry).id(entry.id)
                            }
                        }
                    }
                    .padding(.horizontal, 12).padding(.vertical, 6)
                }
                .onChange(of: logger.entries.count) { _ in
                    if let last = logger.entries.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }
        }
        .frame(height: 260)
        .background(Color(.systemBackground))
    }
}

private struct RealBridgeLogRow: View {
    let entry: IframeSecurityLogger.Entry

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f
    }()

    var body: some View {
        let claimedMatches = entry.claimedOrigin == entry.actualOrigin
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Text(entry.frameLabel)
                    .font(.caption2.bold())
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(labelBackground(claimedMatches))
                    .foregroundStyle(labelForeground(claimedMatches))
                    .cornerRadius(4)

                Text(entry.action).font(.caption2.monospaced()).lineLimit(2)

                Spacer()

                Text(Self.timeFormatter.string(from: entry.timestamp))
                    .font(.caption2.monospaced()).foregroundStyle(.secondary)
            }

            originRow("real:", entry.actualOrigin, color: .primary)
            if !entry.isNative {
                originRow("claimed:", entry.claimedOrigin, color: claimedMatches ? .primary : .red)
            }

            if !entry.payload.isEmpty {
                Text(entry.payload)
                    .font(.caption2.monospaced()).foregroundStyle(.secondary)
                    .lineLimit(3).padding(.top, 2)
            }
        }
        .padding(8)
        .background(entry.isNative ? Color.blue.opacity(0.08) : Color(.systemBackground))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(entry.isNative ? Color.blue.opacity(0.4) : Color(.systemGray4), lineWidth: 0.5)
        )
    }

    private func originRow(_ title: String, _ value: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 4) {
            Text(title).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.caption2.monospaced()).foregroundStyle(color)
        }
    }

    private func labelBackground(_ matches: Bool) -> Color {
        if entry.isNative { return Color.blue.opacity(0.18) }
        return matches ? Color.green.opacity(0.18) : Color.red.opacity(0.18)
    }

    private func labelForeground(_ matches: Bool) -> Color {
        if entry.isNative { return .blue }
        return matches ? .green : .red
    }
}
