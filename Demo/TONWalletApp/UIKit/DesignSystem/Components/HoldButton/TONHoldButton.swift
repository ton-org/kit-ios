//
//  TONHoldButton.swift
//  TONWalletApp
//
//  Created by Nikita Rodionov on 29.05.2026.
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

import SwiftUI

struct TONHoldButton: View {
    let title: String
    let icon: Image?
    let duration: TimeInterval
    let onComplete: () -> Void

    @State private var progress: CGFloat = 0
    @State private var isHolding: Bool = false
    @State private var holdTask: Task<Void, Never>?

    private let cornerRadius: CGFloat = 12
    private let height: CGFloat = 50
    private let horizontalPadding: CGFloat = 24
    private let iconLabelSpacing: CGFloat = 8
    private let iconSize: CGFloat = 20

    init(
        title: String,
        icon: Image? = nil,
        duration: TimeInterval = 3,
        onComplete: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.duration = duration
        self.onComplete = onComplete
    }

    var body: some View {
        ZStack {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Color.tonBgBrand
                    Color.tonBgScrim
                        .frame(width: geo.size.width * progress)
                }
            }

            HStack(spacing: iconLabelSpacing) {
                icon?
                    .resizable()
                    .scaledToFit()
                    .frame(width: iconSize, height: iconSize)
                    .foregroundStyle(Color.tonTextOnBrand)
                Text(title)
                    .textStyle(.bodySemibold)
                    .foregroundStyle(Color.tonTextOnBrand)
            }
            .padding(.horizontal, horizontalPadding)
        }
        .frame(maxWidth: .infinity, minHeight: height, maxHeight: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .contentShape(.rect)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !isHolding else { return }
                    isHolding = true
                    startHold()
                }
                .onEnded { _ in
                    isHolding = false
                    cancelHold()
                }
        )
    }

    private func startHold() {
        holdTask?.cancel()
        withAnimation(.linear(duration: duration)) {
            progress = 1.0
        }
        holdTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            onComplete()
            holdTask = nil
            progress = 0
        }
    }

    private func cancelHold() {
        holdTask?.cancel()
        holdTask = nil
        withAnimation(.easeOut(duration: 0.2)) {
            progress = 0
        }
    }
}
