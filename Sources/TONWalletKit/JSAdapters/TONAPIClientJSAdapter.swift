//
//  TONAPIClientJSAdapter.swift
//  TONWalletKit
//
//  Created by Nikita Rodionov on 20.01.2026.
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

import Foundation

class TONAPIClientJSAdapter: NSObject, JSAPIClient {
    private weak var context: JSContext?
    private let apiClient: any TONAPIClient

    init(
        context: JSContext,
        apiClient: any TONAPIClient
    ) {
        self.context = context
        self.apiClient = apiClient
    }

    @objc(getNetwork) func getNetwork() -> JSValue {
        guard let context else {
            return JSValue(undefinedIn: JSContext())
        }
        do {
            return JSValue(object: try apiClient.network().encode(in: context), in: context)
        } catch {
            return JSValue(undefinedIn: context)
        }
    }
    
    @objc(sendBoc:) func send(boc: JSValue) -> JSValue {
        guard let context else {
            return JSValue(
                newPromiseRejectedWithReason: "No context exists to perform \(#function)",
                in: JSContext()
            )
        }
        
        do {
            let boc: TONBase64 = try boc.decode()
            
            return JSValue(newPromiseIn: context) { [weak self] resolve, reject in
                Task {
                    guard let self else { return }
                    
                    do {
                        let result = try await self.apiClient.send(boc: boc)
                        resolve?.call(withArguments: [result])
                    } catch {
                        reject?.call(withArguments: [error.localizedDescription])
                    }
                }
            }
        } catch {
            return JSValue(newPromiseRejectedWithReason: error.localizedDescription, in: context)
        }
    }
    
    @objc(runGetMethod::::) func runGetMethod(
        address: JSValue,
        method: JSValue,
        stack: JSValue,
        seqno: JSValue
    ) -> JSValue {
        guard let context else {
            return JSValue(
                newPromiseRejectedWithReason: "No context exists to perform \(#function)",
                in: JSContext()
            )
        }
        
        do {
            let address: TONUserFriendlyAddress = try address.decode()
            let method: String = try method.decode()
            let stack: [TONRawStackItem]? = try stack.decode()
            let seqno: UInt? = try seqno.decode()
            
            return JSValue(newPromiseIn: context) { [weak self] resolve, reject in
                Task {
                    guard let self, let context = self.context else { return }
                    
                    do {
                        let result = try await self.apiClient.runGetMethod(
                            address: address,
                            method: method,
                            stack: stack,
                            seqno: seqno
                        )
                        let jsResult = try result.encode(in: context)
                        resolve?.call(withArguments: [jsResult])
                    } catch {
                        reject?.call(withArguments: [error.localizedDescription])
                    }
                }
            }
        } catch {
            return JSValue(newPromiseRejectedWithReason: error.localizedDescription, in: context)
        }
    }
    
    @objc(getMasterchainInfo) func masterchainInfo() -> JSValue {
        guard let context else {
            return JSValue(
                newPromiseRejectedWithReason: "No context exists to perform \(#function)",
                in: JSContext()
            )
        }
        
        return JSValue(newPromiseIn: context) { [weak self] resolve, reject in
            Task {
                guard let self else { return }
                
                do {
                    let result = try await self.apiClient.masterchainInfo()
                    let jsResult = try result.encode(in: context)
                    resolve?.call(withArguments: [jsResult])
                } catch {
                    reject?.call(withArguments: [error.localizedDescription])
                }
            }
        }
    }
}

extension TONAPIClientJSAdapter: JSValueEncodable {}
