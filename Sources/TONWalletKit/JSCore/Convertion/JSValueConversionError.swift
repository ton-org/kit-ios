//
//  JSValueConversionError.swift
//  TONWalletKit
//
//  Created by Nikita Rodionov on 22.10.2025.
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

enum JSValueConversionError: LocalizedError {
    case unableToConvertJSValue(type: Any.Type, description: String)
    case unableToConvertUndefinedJSValue(type: Any.Type)
    case unableToConvertNullJSValue(type: Any.Type)
    case unableToEncode(type: Any.Type)
    case decodingError(DecodingError)
    case encodingError(EncodingError)
    case unknown(message: String)

    var errorDescription: String? {
        switch self {
        case .unableToConvertJSValue(let type, let description):
            return "Unable to cast JS value \(description) to \(type)"
        case .unableToConvertUndefinedJSValue(let type):
            return "Unable to cast undefined JS value to \(type)"
        case .unableToConvertNullJSValue(let type):
            return "Unable to cast null JS value to \(type)"
        case .unableToEncode(let type):
            return "Unable to encode \(type) to JSValue"
        case .unknown(let message):
            return message
        case .decodingError(let error):
            return error.localizedDescription
        case .encodingError(let error):
            return error.localizedDescription
        }
    }
}
