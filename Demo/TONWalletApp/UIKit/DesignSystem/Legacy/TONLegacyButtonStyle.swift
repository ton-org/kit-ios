//
//  TONButtonStyle.swift
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

import SwiftUI

struct TONLegacyButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    let type: TONLegacyButtonType
    let isLoading: Bool

    init(type: TONLegacyButtonType, isLoading: Bool = false) {
        self.type = type
        self.isLoading = isLoading
    }

    public func makeBody(configuration: Configuration) -> some View {
        return ZStack(alignment: .center) {
            if isLoading {
                ProgressView()
            } else {
                configuration.label
                    .font(.headline)
                    .foregroundColor(type.textColor)
            }
        }
        .frame(
            maxWidth: .infinity,
            minHeight: 50.0,
            maxHeight: 50.0
        )
        .contentShape(.rect)
        .padding(.horizontal, 16.0)
        .background(configuration.isPressed ? type.highlightColor : type.backgroundColor)
        .cornerRadius(AppRadius.standard)
        .opacity(isEnabled ? 1.0 : 0.5)
        .allowsHitTesting(!isLoading)
    }
}

enum TONLegacyButtonType {
    case primary
    case secondary
    
    var textColor: Color {
        switch self {
        case .primary: .TON.white
        case .secondary: .TON.gray900
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .primary: .TON.blue500
        case .secondary: .TON.gray200
        }
    }
    
    var highlightColor: Color {
        switch self {
        case .primary: .TON.blue700
        case .secondary: .TON.gray300
        }
    }
}
