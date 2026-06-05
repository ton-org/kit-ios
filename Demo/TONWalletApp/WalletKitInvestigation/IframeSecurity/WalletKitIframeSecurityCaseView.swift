//
//  WalletKitIframeSecurityCaseView.swift
//  TONWalletApp
//
//  Created by Nikita Rodionov on 04.06.2026.
//
//  Copyright (c) 2026 TON Connect
//

import SwiftUI

struct WalletKitIframeSecurityCaseView: View {
    let testCase: IframeSecurityCase
    @StateObject private var logger = IframeSecurityLogger()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    var body: some View {
        VStack(spacing: 0) {
            descriptionPanel
            IframeSecurityWebView(
                loadMode: testCase.loadMode,
                logger: logger
            )
            Divider()
            logPanel
        }
        .navigationTitle(testCase.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Clear") { logger.clear() }
                    .disabled(logger.entries.isEmpty)
            }
        }
    }

    @ViewBuilder
    private var descriptionPanel: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 8) {
                fieldRow(title: "Summary", body: testCase.summary)
                fieldRow(title: "Class", body: testCase.vulnerabilityClass)
                fieldRow(title: "What to watch", body: testCase.observation)
            }
            .padding(.top, 8)
        } label: {
            Text(testCase.title).font(.subheadline.bold())
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
    }

    private func fieldRow(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption.bold())
            Text(body).font(.caption).foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var logPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Bridge log (\(logger.entries.count))")
                    .font(.caption.bold())
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(.systemGray6))

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        if logger.entries.isEmpty {
                            Text("No bridge messages yet. Tap a button inside the WebView above.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.top, 12)
                        } else {
                            ForEach(logger.entries) { entry in
                                entryRow(entry).id(entry.id)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                }
                .onChange(of: logger.entries.count) { _ in
                    if let last = logger.entries.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }
        }
        .frame(maxHeight: 240)
    }

    @ViewBuilder
    private func entryRow(_ entry: IframeSecurityLogger.Entry) -> some View {
        let claimedMatches = entry.claimedOrigin == entry.actualOrigin
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Text(entry.frameLabel)
                    .font(.caption2.bold())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(claimedMatches ? Color.green.opacity(0.18) : Color.red.opacity(0.18))
                    .foregroundStyle(claimedMatches ? Color.green : Color.red)
                    .cornerRadius(4)

                Text(entry.action)
                    .font(.caption2.monospaced())

                if !entry.isMainFrame {
                    Text("iframe")
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.orange.opacity(0.2))
                        .foregroundStyle(.orange)
                        .cornerRadius(3)
                }

                Spacer()

                Text(Self.timeFormatter.string(from: entry.timestamp))
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .top, spacing: 4) {
                Text("real:")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(entry.actualOrigin)
                    .font(.caption2.monospaced())
            }

            HStack(alignment: .top, spacing: 4) {
                Text("claimed:")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(entry.claimedOrigin)
                    .font(.caption2.monospaced())
                    .foregroundStyle(claimedMatches ? Color.primary : Color.red)
            }

            if let url = entry.actualFrameURL {
                HStack(alignment: .top, spacing: 4) {
                    Text("url:")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(String(url.prefix(120)))
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            if !entry.payload.isEmpty && entry.payload != "{}" {
                Text(entry.payload)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .padding(.top, 2)
            }
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(.systemGray4), lineWidth: 0.5)
        )
    }
}
