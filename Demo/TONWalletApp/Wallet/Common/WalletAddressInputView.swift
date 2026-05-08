//
//  WalletAddressInputView.swift
//  TONWalletApp
//
//  Created by Nikita Rodionov on 29.10.2025.
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
import TONWalletKit

struct WalletAddressInputView: View {
    @State private var addressInput: String = ""
    @State private var isValidAddress: Bool = false
    
    let title: String
    let placeholder: String
    let buttonTitle: String
    let onAddressSelected: (String) -> Void
    
    init(
        title: String = "Enter Wallet Address",
        placeholder: String = "Enter TON wallet address",
        buttonTitle: String = "Continue",
        onAddressSelected: @escaping (String) -> Void
    ) {
        self.title = title
        self.placeholder = placeholder
        self.buttonTitle = buttonTitle
        self.onAddressSelected = onAddressSelected
    }
    
    var body: some View {
        VStack(spacing: AppSpacing.spacing(6)) {
            // Title
            if !title.isEmpty {
                Text(title)
                    .textXL(weight: .bold)
                    .foregroundColor(Color.TON.gray900)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Address Input Field
            VStack(alignment: .leading, spacing: AppSpacing.spacing(2)) {
                ZStack(alignment: .trailing) {
                    TextField(placeholder, text: $addressInput)
                        .textFieldStyle(TONTextFieldStyle())
                        .onChange(of: addressInput) { newValue in
                            validateAddress(newValue)
                        }
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .keyboardType(.default)
                    
                    // Paste Button
                    if addressInput.isEmpty {
                        Button("Paste") {
                            pasteFromClipboard()
                        }
                        .textSM(weight: .medium)
                        .foregroundColor(Color.TON.blue500)
                        .padding(.trailing, AppSpacing.spacing(4))
                    }
                }
                
                Text("Please enter a valid TON wallet address")
                    .textSM()
                    .foregroundColor(Color.TON.red500)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .opacity(!addressInput.isEmpty && !isValidAddress ? 1 : 0)
            }

            // Continue Button
            Button(buttonTitle) {
                if isValidAddress {
                    onAddressSelected(addressInput.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            }
            .buttonStyle(TONLegacyButtonStyle(type: .primary))
            .disabled(!isValidAddress)
        }
        .padding(AppSpacing.spacing(4))
    }
    
    /// Validates if the input string is a valid TON wallet address
    private func validateAddress(_ address: String) {
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        isValidAddress = isValidTONAddress(trimmedAddress)
    }
    
    /// Pastes text from clipboard into the address input field
    private func pasteFromClipboard() {
        if let clipboardString = UIPasteboard.general.string {
            addressInput = clipboardString
            validateAddress(clipboardString)
        }
    }
    
    private func isValidTONAddress(_ address: String) -> Bool {
        (try? TONUserFriendlyAddress(value: address)) != nil
    }
}
