//
//  WalletWelcomeView.swift
//  TONWalletApp
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

struct WalletWelcomeView: View {
    let onCreateNew: () -> Void
    let onAddExisting: () -> Void

    @State private var selectedPage: Int = 0

    private let pages: [WalletWelcomePage.Content] = [
        .init(title: "Title", description: "Description"),
        .init(title: "Title", description: "Description"),
        .init(title: "Title", description: "Description"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $selectedPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, content in
                    WalletWelcomePage(content: content)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .never))

            VStack(spacing: 8) {
                Button("Create a new wallet") { onCreateNew() }
                    .buttonStyle(.ton(.primary))

                Button("Add an existing wallet") { onAddExisting() }
                    .buttonStyle(.ton(.secondary))

                termsFooter
                    .padding(.top, 4)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color.tonBgPrimary)
        .navigationBarBackButtonHidden(true)
    }

    private var termsFooter: some View {
        var attributed = AttributedString("By continuing, you agree to the ")
        attributed.foregroundColor = Color.tonTextSecondary

        var terms = AttributedString("Terms")
        terms.foregroundColor = Color.tonTextBrand

        var middle = AttributedString(" and ")
        middle.foregroundColor = Color.tonTextSecondary

        var privacy = AttributedString("Privacy Policy")
        privacy.foregroundColor = Color.tonTextBrand

        attributed.append(terms)
        attributed.append(middle)
        attributed.append(privacy)

        return Text(attributed)
            .textStyle(.caption1)
            .multilineTextAlignment(.center)
    }
}

private struct WalletWelcomePage: View {
    struct Content {
        let title: String
        let description: String
    }

    let content: Content

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.tonBgFillTertiary)
                .frame(width: 160, height: 160)

            VStack(spacing: 4) {
                Text(content.title)
                    .textStyle(.title2)
                    .foregroundStyle(Color.tonTextPrimary)
                Text(content.description)
                    .textStyle(.body)
                    .foregroundStyle(Color.tonTextSecondary)
            }
            .multilineTextAlignment(.center)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
    }
}
