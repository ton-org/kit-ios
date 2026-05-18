//
//  TONAPIClientJSAdapterTests.swift
//  TONWalletKit
//
//  Created by Nikita Rodionov on 08.02.2026.
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

import Testing
import JavaScriptCore
@testable import TONWalletKit

@Suite("TONAPIClientJSAdapter Tests")
struct TONAPIClientJSAdapterTests {

    private let context = JSContext()!

    private func makeSUT(
        client: MockAPIClient = MockAPIClient(),
        network: TONNetwork = .mainnet
    ) -> (sut: TONAPIClientJSAdapter, client: MockAPIClient) {
        client.stubbedNetwork = network
        let sut = TONAPIClientJSAdapter(
            context: context,
            apiClient: client
        )
        return (sut, client)
    }

    @Test("getNetwork returns mainnet chainId")
    func getNetworkReturnsMainnetChainId() throws {
        let (sut, _) = makeSUT(network: .mainnet)

        let result: TONNetwork = try sut.getNetwork().decode()

        #expect(result == TONNetwork.mainnet)
    }

    @Test("getNetwork returns testnet chainId")
    func getNetworkReturnsTestnetChainId() throws {
        let (sut, _) = makeSUT(network: .testnet)

        let result: TONNetwork = try sut.getNetwork().decode()

        #expect(result == TONNetwork.testnet)
    }

    @Test("getNetwork returns custom chainId from client")
    func getNetworkReturnsCustomChainId() throws {
        let custom = TONNetwork(chainId: "123456")
        let (sut, _) = makeSUT(network: custom)

        let result: TONNetwork = try sut.getNetwork().decode()

        #expect(result == custom)
    }

    @Test("getNetwork reflects updates to the client's network after init")
    func getNetworkReflectsUpdatedNetwork() throws {
        let (sut, client) = makeSUT(network: .mainnet)

        let initial: TONNetwork = try sut.getNetwork().decode()
        #expect(initial == .mainnet)

        client.stubbedNetwork = .testnet
        let updated: TONNetwork = try sut.getNetwork().decode()
        #expect(updated == .testnet)
    }

    @Test("getNetwork throws when context is deallocated")
    func getNetworkThrowsWhenDeallocated() {
        let client = MockAPIClient()
        var jsContext: JSContext? = JSContext()!
        let sut = TONAPIClientJSAdapter(
            context: jsContext!,
            apiClient: client
        )
        jsContext = nil

        #expect(throws: (any Error).self) {
            let _: TONNetwork = try sut.getNetwork().decode()
        }
    }

    @Test("Send resolves with result from API client")
    func sendResolvesWithResult() async throws {
        let (sut, _) = makeSUT()
        let boc = JSValue(object: "dGVzdA==", in: context)!

        let result = sut.send(boc: boc)
        let resolved = try await result.then()

        #expect(resolved.toString() == "ok")
    }

    @Test("Send rejects promise for invalid boc")
    func sendRejectsPromiseForInvalidBoc() async {
        let (sut, _) = makeSUT()
        let boc = JSValue(undefinedIn: context)!

        let result = sut.send(boc: boc)

        await #expect(throws: (any Error).self) {
            try await result.then()
        }
    }

    @Test("Send rejects when API client throws")
    func sendRejectsWhenAPIClientThrows() async {
        let client = MockAPIClient()
        client.shouldThrow = true
        let (sut, _) = makeSUT(client: client)
        let boc = JSValue(object: "dGVzdA==", in: context)!

        let result = sut.send(boc: boc)

        await #expect(throws: (any Error).self) {
            try await result.then()
        }
    }

    @Test("send rejects when context is deallocated")
    func sendRejectsWhenDeallocated() async {
        let client = MockAPIClient()
        var jsContext: JSContext? = JSContext()!
        let sut = TONAPIClientJSAdapter(context: jsContext!, apiClient: client)
        let boc = JSValue(object: "dGVzdA==", in: context)!
        jsContext = nil

        let result = sut.send(boc: boc)

        await #expect(throws: (any Error).self) {
            try await result.then()
        }
    }

    @Test("runGetMethod rejects when context is deallocated")
    func runGetMethodRejectsWhenDeallocated() async {
        let client = MockAPIClient()
        var jsContext: JSContext? = JSContext()!
        let sut = TONAPIClientJSAdapter(context: jsContext!, apiClient: client)
        let address = JSValue(undefinedIn: context)!
        let method = JSValue(undefinedIn: context)!
        let stack = JSValue(undefinedIn: context)!
        let seqno = JSValue(undefinedIn: context)!
        jsContext = nil

        let result = sut.runGetMethod(address: address, method: method, stack: stack, seqno: seqno)

        await #expect(throws: (any Error).self) {
            try await result.then()
        }
    }

    @Test("runGetMethod rejects promise for invalid input")
    func runGetMethodRejectsPromiseForInvalidInput() async {
        let (sut, _) = makeSUT()
        let address = JSValue(undefinedIn: context)!
        let method = JSValue(undefinedIn: context)!
        let stack = JSValue(undefinedIn: context)!
        let seqno = JSValue(undefinedIn: context)!

        let result = sut.runGetMethod(
            address: address,
            method: method,
            stack: stack,
            seqno: seqno
        )

        await #expect(throws: (any Error).self) {
            try await result.then()
        }
    }

    @Test("masterchainInfo resolves with result from API client")
    func masterchainInfoResolvesWithResult() async throws {
        let (sut, _) = makeSUT()

        let result = sut.masterchainInfo()
        let resolved = try await result.then()
        let decoded: TONMasterchainInfo = try resolved.decode()

        #expect(decoded.seqno == 12345)
        #expect(decoded.shard == "8000000000000000")
        #expect(decoded.workchain == -1)
    }

    @Test("masterchainInfo rejects when API client throws")
    func masterchainInfoRejectsWhenAPIClientThrows() async {
        let client = MockAPIClient()
        client.shouldThrow = true
        let (sut, _) = makeSUT(client: client)

        let result = sut.masterchainInfo()

        await #expect(throws: (any Error).self) {
            try await result.then()
        }
    }

    @Test("masterchainInfo rejects when context is deallocated")
    func masterchainInfoRejectsWhenDeallocated() async {
        let client = MockAPIClient()
        var jsContext: JSContext? = JSContext()!
        let sut = TONAPIClientJSAdapter(context: jsContext!, apiClient: client)
        jsContext = nil

        let result = sut.masterchainInfo()

        await #expect(throws: (any Error).self) {
            try await result.then()
        }
    }

    @Test("getNetwork is callable from JS")
    func getNetworkCallableFromJS() throws {
        let (sut, _) = makeSUT(network: .mainnet)
        context.evaluateScript("function callGetNetwork(client) { return client.getNetwork(); }")

        let result: JSValue = try context.callGetNetwork(sut)

        #expect(result.forProperty("chainId")?.toString() == "-239")
    }

    @Test("getNetwork from JS returns testnet chainId")
    func getNetworkFromJSReturnsTestnetChainId() throws {
        let (sut, _) = makeSUT(network: .testnet)
        context.evaluateScript("function callGetNetwork(client) { return client.getNetwork(); }")

        let result: JSValue = try context.callGetNetwork(sut)

        #expect(result.forProperty("chainId")?.toString() == "-3")
    }

    @Test("getNetwork from JS returns a plain object, not a Promise")
    func getNetworkFromJSIsSynchronous() throws {
        let (sut, _) = makeSUT(network: .mainnet)
        context.evaluateScript(
            "function isPromiseFromGetNetwork(client) { return client.getNetwork() instanceof Promise; }"
        )

        let isPromise: Bool = try context.isPromiseFromGetNetwork(sut)

        #expect(isPromise == false)
    }

    @Test("masterchainInfo resolves from JS call")
    func masterchainInfoResolvesFromJS() async throws {
        let (sut, _) = makeSUT()
        context.evaluateScript("function callMasterchainInfo(client) { return client.getMasterchainInfo(); }")

        let result: TONMasterchainInfo = try await context.callMasterchainInfo(sut)

        #expect(result.seqno == 12345)
    }
}
