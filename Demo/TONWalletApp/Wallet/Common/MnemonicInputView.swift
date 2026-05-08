//
//  MnemonicInputView.swift
//  TONWalletApp
//
//  Created by Nikita Rodionov on 12.09.2025.
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
import SwiftUI
import TONWalletKit

struct MnemonicInputView: View {
    @Binding var mnemonic: TONMnemonic
    @FocusState private var focusedIndex: Int?

    private let total = TONMnemonicLength.max.rawValue
    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(0..<total, id: \.self) { index in
                TONSeedPhraseField(
                    index: index,
                    word: Binding(
                        get: { mnemonic.value[index] },
                        set: { mnemonic.update(word: $0, at: index) }
                    ),
                    isFocused: $focusedIndex,
                    onPaste: { handlePaste($0, at: index) }
                )
            }
        }
    }

    // Per spec: pasting into field N takes A = pasted.split(whitespace) and
    // fills fields[N..] with A[N..]. If A is shorter than N, nothing is written.
    private func handlePaste(_ pasted: String, at pasteIndex: Int) {
        let words = pasted
            .lowercased()
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)

        var lastFilled = pasteIndex - 1
        var offset = 0
        while pasteIndex + offset < total, pasteIndex + offset < words.count {
            let target = pasteIndex + offset
            let source = pasteIndex + offset
            mnemonic.update(word: words[source], at: target)
            lastFilled = target
            offset += 1
        }

        let next = lastFilled + 1
        focusedIndex = next < total ? next : nil
    }
}
