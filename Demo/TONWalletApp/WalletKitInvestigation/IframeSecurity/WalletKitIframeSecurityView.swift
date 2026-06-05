//
//  WalletKitIframeSecurityView.swift
//  TONWalletApp
//
//  Created by Nikita Rodionov on 04.06.2026.
//
//  Copyright (c) 2026 TON Connect
//

import SwiftUI

struct WalletKitIframeSecurityView: View {
    var body: some View {
        List {
            Section {
                ForEach(IframeSecurityCase.allCases) { testCase in
                    NavigationLink {
                        WalletKitIframeSecurityCaseView(testCase: testCase)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(testCase.title).font(.headline)
                            Text(testCase.summary)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(3)
                        }
                        .padding(.vertical, 2)
                    }
                }
            } footer: {
                Text("Each case loads a self-contained HTML page (parent baseURL = https://parent-dapp.test) with iframes that exercise a specific attack surface. A diagnostic bridge logs every postMessage with the real frame origin from WKFrameInfo.securityOrigin, so the claimed and actual origins can be compared side-by-side.")
                    .font(.caption)
            }
        }
        .navigationTitle("Iframe Security")
        .navigationBarTitleDisplayMode(.inline)
    }
}
