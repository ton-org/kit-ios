//
//  JSWalletKitContextTests.swift
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
@_private(sourceFile: "JSWalletKitContext.swift")
@testable import TONWalletKit

@Suite("JSWalletKitContext Tests")
struct JSWalletKitContextTests {

    private func makeSUT(
        mockContext: MockJSDynamicObject? = nil
    ) -> (sut: JSWalletKitContext, mock: MockJSDynamicObject) {
        let mock = mockContext ?? MockJSDynamicObject()
        let sut = JSWalletKitContext(context: mock)
        return (sut, mock)
    }

    @Test("jsContext delegates to injected context")
    func jsContextDelegation() {
        let (sut, mock) = makeSUT()
        #expect(sut.jsContext === mock.jsContext)
    }

    @Test("Load evaluates script code on jsContext")
    func loadEvaluatesScript() async throws {
        let (sut, mock) = makeSUT()
        let script = MockJSScript(code: "var __testMarker = 42;")

        try await sut.load(script: script)

        let marker = mock.jsContext.evaluateScript("__testMarker")
        #expect(marker?.toInt32() == 42)
    }

    @Test("Load throws when script fails to load")
    func loadThrowsOnScriptFailure() async {
        let (sut, _) = makeSUT()
        let script = MockFailingJSScript()

        await #expect(throws: (any Error).self) {
            try await sut.load(script: script)
        }
    }
    
    @Test("Add first handler creates bridgeEventHandlers and calls setEventsListeners")
    func addFirstHandler() throws {
        let (sut, mock) = makeSUT()
        let handler = MockJSBridgeEventsHandler()

        try sut.add(eventsHandler: handler)

        #expect(sut.bridgeEventHandlers != nil)
        let setListenerCalls = mock.callRecords.filter { $0.path == "walletKit.setEventsListeners" }
        #expect(setListenerCalls.count == 1)
    }

    @Test("Add second handler reuses existing bridgeEventHandlers without calling setEventsListeners again")
    func addSecondHandler() throws {
        let (sut, mock) = makeSUT()
        let handler1 = MockJSBridgeEventsHandler()
        let handler2 = MockJSBridgeEventsHandler()

        try sut.add(eventsHandler: handler1)
        try sut.add(eventsHandler: handler2)

        let setListenerCalls = mock.callRecords.filter { $0.path == "walletKit.setEventsListeners" }
        #expect(setListenerCalls.count == 1)
    }

    @Test("Add handler throws when setEventsListeners fails")
    func addHandlerThrowsOnListenerSetupFailure() {
        let mock = MockJSDynamicObject()
        mock.shouldThrowOnCall = true
        let (sut, _) = makeSUT(mockContext: mock)
        let handler = MockJSBridgeEventsHandler()

        #expect(throws: (any Error).self) {
            try sut.add(eventsHandler: handler)
        }
    }

    @Test("Remove last handler calls removeEventListeners")
    func removeLastHandler() throws {
        let (sut, mock) = makeSUT()
        let handler = MockJSBridgeEventsHandler()

        try sut.add(eventsHandler: handler)
        mock.callRecords.removeAll()

        try sut.remove(eventsHandler: handler)

        let removeCalls = mock.callRecords.filter { $0.path == "walletKit.removeEventListeners" }
        #expect(removeCalls.count == 1)
    }

    @Test("Remove non-last handler does not call removeEventListeners")
    func removeNonLastHandler() throws {
        let (sut, mock) = makeSUT()
        let handler1 = MockJSBridgeEventsHandler()
        let handler2 = MockJSBridgeEventsHandler()

        try sut.add(eventsHandler: handler1)
        try sut.add(eventsHandler: handler2)
        mock.callRecords.removeAll()

        try sut.remove(eventsHandler: handler1)

        let removeCalls = mock.callRecords.filter { $0.path == "walletKit.removeEventListeners" }
        #expect(removeCalls.isEmpty)
    }

    @Test("Remove when no handlers were added calls removeEventListeners")
    func removeWithNoBridgeHandlers() throws {
        let (sut, mock) = makeSUT()
        let handler = MockJSBridgeEventsHandler()

        try sut.remove(eventsHandler: handler)

        let removeCalls = mock.callRecords.filter { $0.path == "walletKit.removeEventListeners" }
        #expect(removeCalls.count == 1)
    }

    @Test("Remove throws when removeEventListeners fails")
    func removeThrowsOnFailure() throws {
        let (sut, mock) = makeSUT()
        let handler = MockJSBridgeEventsHandler()

        try sut.add(eventsHandler: handler)
        mock.shouldThrowOnCall = true

        #expect(throws: (any Error).self) {
            try sut.remove(eventsHandler: handler)
        }
    }

    @Test("Subscript dynamicMember forwards to context")
    func dynamicMemberForwarding() {
        let mock = MockJSDynamicObject()
        mock.jsContext.evaluateScript("var testProp = 'hello';")
        let sut = JSWalletKitContext(context: mock)

        let member: any JSDynamicObjectMember = sut[dynamicMember: "testProp"]
        #expect(member.jsContext === mock.jsContext)
    }

    @Test("InitializeWalletKit calls initWalletKit on context")
    func initializeWalletKit() async throws {
        let (sut, mock) = makeSUT()

        try await sut.initializeWalletKit(
            configuration: "config",
            storage: "storage",
            sessionManager: "session",
            apiClients: "api",
            fetchManifest: nil
        )

        let initCalls = mock.callRecords.filter { $0.path == "initWalletKit" }
        #expect(initCalls.count == 1)

        let args = try #require(initCalls.first?.args)
        #expect(args.count == 6)
        #expect(args[0] as? String == "config")
        #expect(args[1] as? String == "storage")
        #expect(args[2] is AnyJSValueEncodable)
        #expect(args[3] as? String == "session")
        #expect(args[4] as? String == "api")
    }

    @Test("InitializeWalletKit throws when JS call fails")
    func initializeWalletKitThrows() async {
        let mock = MockJSDynamicObject()
        mock.shouldThrowOnCall = true
        let sut = JSWalletKitContext(context: mock)

        await #expect(throws: (any Error).self) {
            try await sut.initializeWalletKit(
                configuration: "config",
                storage: "storage",
                sessionManager: "session",
                apiClients: "api",
                fetchManifest: nil
            )
        }
    }

    // MARK: - fetchManifest

    @Test("InitializeWalletKit with fetchManifest=nil passes a JS-null sixth arg")
    func initializeForwardsNilFetchManifest() async throws {
        let (sut, mock) = makeSUT()

        try await sut.initializeWalletKit(
            configuration: "config",
            storage: "storage",
            sessionManager: "session",
            apiClients: "api",
            fetchManifest: nil
        )

        let args = try #require(mock.callRecords.first(where: { $0.path == "initWalletKit" })?.args)
        let sixth = try #require(args[5] as? (any JSValueEncodable))
        let encoded = try sixth.encode(in: mock.jsContext)
        let jsValue = try #require(encoded as? JSValue)
        #expect(jsValue.isNull, "Expected a JS null for nil fetchManifest, got \(jsValue)")
    }

    @Test("InitializeWalletKit with fetchManifest closure passes an AnyJSValueEncodable wrapping a callable block")
    func initializeForwardsFetchManifestBlock() async throws {
        let (sut, mock) = makeSUT()
        let closure: TONWalletKitConfiguration.FetchManifest = { _ in
            TONManifestFetchResult(manifest: AnyCodable([:] as [String: AnyCodable]))
        }

        try await sut.initializeWalletKit(
            configuration: "config",
            storage: "storage",
            sessionManager: "session",
            apiClients: "api",
            fetchManifest: closure
        )

        let args = try #require(mock.callRecords.first(where: { $0.path == "initWalletKit" })?.args)
        let wrapper = try #require(args[5] as? AnyJSValueEncodable)

        // The wrapped value must be the Swift block — installable as a JS function.
        let context = mock.jsContext
        let encoded = try wrapper.encode(in: context)
        context.setObject(encoded, forKeyedSubscript: "swiftFetchManifest" as NSString)
        #expect(context.evaluateScript("typeof swiftFetchManifest")?.toString() == "function")
    }

    @Test("fetchManifest block forwards URL and resolves JS Promise with the encoded result")
    func fetchManifestBlockResolves() async throws {
        let (sut, mock) = makeSUT()
        // Use a plain [String: Any]-shaped dict so the decoded side (which
        // unwraps via mapValues { $0.value }) compares equal via the
        // [String: Any] / NSDictionary branch of AnyCodable.==.
        let manifestPayload = AnyCodable([
            "name": "Test App",
            "url": "https://example.com",
        ] as [String: String])
        let urlBox = URLBox()
        let closure: TONWalletKitConfiguration.FetchManifest = { url in
            await urlBox.set(url)
            return TONManifestFetchResult(
                manifest: manifestPayload,
                manifestFetchErrorCode: .manifestContentError
            )
        }

        try await sut.initializeWalletKit(
            configuration: "config",
            storage: "storage",
            sessionManager: "session",
            apiClients: "api",
            fetchManifest: closure
        )

        let promise = try invokeFetchManifest(
            from: mock,
            withURL: "https://example.com/manifest.json"
        )
        let resolved = try await promise.then()
        let decoded: TONManifestFetchResult = try resolved.decode()

        let captured = await urlBox.get()
        #expect(captured == "https://example.com/manifest.json")
        #expect(decoded.manifestFetchErrorCode == .manifestContentError)

        // Verify the manifest payload survives the JS round-trip intact.
        #expect(decoded.manifest == manifestPayload)
        let decodedDict = try #require(decoded.manifest?.value as? [String: Any])
        #expect(decodedDict["name"] as? String == "Test App")
        #expect(decodedDict["url"] as? String == "https://example.com")
        #expect(decodedDict.count == 2)
    }

    @Test("fetchManifest block rejects JS Promise when the closure throws")
    func fetchManifestBlockRejects() async throws {
        let (sut, mock) = makeSUT()
        let closure: TONWalletKitConfiguration.FetchManifest = { _ in
            throw NSError(
                domain: "test",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "fetch failed"]
            )
        }

        try await sut.initializeWalletKit(
            configuration: "config",
            storage: "storage",
            sessionManager: "session",
            apiClients: "api",
            fetchManifest: closure
        )

        let promise = try invokeFetchManifest(from: mock, withURL: "https://example.com/m.json")
        await #expect(throws: (any Error).self) {
            _ = try await promise.then()
        }
    }

    @Test("fetchManifest block returns a rejected Promise once the context is deallocated")
    func fetchManifestBlockRejectsAfterDeallocation() async throws {
        // Build the SUT, capture the wrapper, then drop the SUT so its weak
        // reference inside the block becomes nil before invocation.
        let mock = MockJSDynamicObject()
        var sutOptional: JSWalletKitContext? = JSWalletKitContext(context: mock)
        let closure: TONWalletKitConfiguration.FetchManifest = { _ in
            TONManifestFetchResult(manifest: AnyCodable([:] as [String: AnyCodable]))
        }
        try await sutOptional!.initializeWalletKit(
            configuration: "config",
            storage: "storage",
            sessionManager: "session",
            apiClients: "api",
            fetchManifest: closure
        )

        let args = try #require(mock.callRecords.first(where: { $0.path == "initWalletKit" })?.args)
        let wrapper = try #require(args[5] as? AnyJSValueEncodable)
        let encoded = try wrapper.encode(in: mock.jsContext)

        sutOptional = nil

        let context = mock.jsContext
        context.setObject(encoded, forKeyedSubscript: "swiftFetchManifest" as NSString)
        let promise = try #require(context.evaluateScript("swiftFetchManifest('https://example.com/m.json')"))

        await #expect(throws: (any Error).self) {
            _ = try await promise.then()
        }
    }

    private func invokeFetchManifest(
        from mock: MockJSDynamicObject,
        withURL url: String
    ) throws -> JSValue {
        let args = try #require(mock.callRecords.first(where: { $0.path == "initWalletKit" })?.args)
        let wrapper = try #require(args[5] as? AnyJSValueEncodable)
        let encoded = try wrapper.encode(in: mock.jsContext)
        mock.jsContext.setObject(encoded, forKeyedSubscript: "swiftFetchManifest" as NSString)
        return try #require(
            mock.jsContext.evaluateScript("swiftFetchManifest('\(url)')")
        )
    }
}

private actor URLBox {
    private var value: String?
    func set(_ url: String) { value = url }
    func get() -> String? { value }
}
