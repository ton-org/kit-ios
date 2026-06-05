//
//  IframeSecurityLogger.swift
//  TONWalletApp
//
//  Created by Nikita Rodionov on 04.06.2026.
//
//  Copyright (c) 2026 TON Connect
//

import Foundation
import Combine

final class IframeSecurityLogger: ObservableObject {
    struct Entry: Identifiable, Equatable {
        let id = UUID()
        let timestamp: Date
        let frameLabel: String
        let action: String
        let claimedOrigin: String
        let actualFrameURL: String?
        let actualOrigin: String
        let isMainFrame: Bool
        let payload: String
        /// Set for entries that originate from the native SDK event stream
        /// (as opposed to a JS bridge postMessage from a frame).
        var isNative: Bool = false
    }

    @Published private(set) var entries: [Entry] = []

    func add(_ entry: Entry) {
        entries.append(entry)
    }

    /// Append an entry describing an event the native SDK actually received and
    /// surfaced — proof that the bridge accepted the request, plus the `domain`
    /// the SDK attributed to it.
    func addNative(action: String, domain: String, payload: String = "") {
        entries.append(
            Entry(
                timestamp: Date(),
                frameLabel: "SDK EVENT",
                action: action,
                claimedOrigin: domain,
                actualFrameURL: nil,
                actualOrigin: domain,
                isMainFrame: true,
                payload: payload,
                isNative: true
            )
        )
    }

    func clear() {
        entries.removeAll()
    }
}
