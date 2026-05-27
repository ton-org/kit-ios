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
import Combine
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
            apiClients: "api"
        )

        let initCalls = mock.callRecords.filter { $0.path == "initWalletKit" }
        #expect(initCalls.count == 1)

        let args = try #require(initCalls.first?.args)
        #expect(args.count == 5)
        #expect(args[0] as? String == "config")
        #expect(args[1] as? String == "storage")
        #expect(args[2] is JSValue)
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
                apiClients: "api"
            )
        }
    }

    @Test("bridgeTransport argument is callable from JS during initializeWalletKit")
    func bridgeTransportCallableFromJS() async throws {
        let context = JSContext()!
        context.evaluateScript("""
            globalThis.__bridgeTransportType = null;
            globalThis.__bridgeTransportCallCount = 0;
            function initWalletKit(configuration, storage, bridgeTransport, sessionManager, apiClients) {
                globalThis.__bridgeTransportType = typeof bridgeTransport;
                bridgeTransport({
                    sessionID: "session-1",
                    messageID: "msg-1",
                    message: { foo: "bar" }
                });
                globalThis.__bridgeTransportCallCount += 1;
            }
        """)
        let sut = JSWalletKitContext(context: context)

        var received: JSBridgeTransportResponse?
        let cancellable = sut.bridgeTransport.waitForResponse().sink(
            receiveCompletion: { _ in },
            receiveValue: { received = $0 }
        )
        defer { cancellable.cancel() }

        try await sut.initializeWalletKit(
            configuration: "config",
            storage: "storage",
            sessionManager: "session",
            apiClients: "api"
        )

        let typeofResult = context.evaluateScript("globalThis.__bridgeTransportType")?.toString()
        let callCount = context.evaluateScript("globalThis.__bridgeTransportCallCount")?.toInt32()

        #expect(typeofResult == "function", "JS must see bridgeTransport as a callable function, got: \(typeofResult ?? "nil")")
        #expect(callCount == 1, "JS should have invoked bridgeTransport exactly once")
        #expect(received?.sessionID == "session-1")
        #expect(received?.messageID == "msg-1")
    }

    @Test("events callback argument is callable from JS during add(eventsHandler:)")
    func eventsCallbackCallableFromJS() throws {
        let context = JSContext()!
        context.evaluateScript("""
            globalThis.__eventsCallbackType = null;
            globalThis.__eventsCallbackCallCount = 0;
            var walletKit = {
                setEventsListeners: function(callback) {
                    globalThis.__eventsCallbackType = typeof callback;
                    callback("connectRequest", { foo: "bar" });
                    globalThis.__eventsCallbackCallCount += 1;
                }
            };
        """)
        let sut = JSWalletKitContext(context: context)
        let handler = MockJSBridgeEventsHandler()

        try sut.add(eventsHandler: handler)

        let typeofResult = context.evaluateScript("globalThis.__eventsCallbackType")?.toString()
        let callCount = context.evaluateScript("globalThis.__eventsCallbackCallCount")?.toInt32()

        #expect(typeofResult == "function", "JS must see events callback as a callable function, got: \(typeofResult ?? "nil")")
        #expect(callCount == 1, "JS should have invoked the events callback exactly once")
        #expect(handler.handledEvents.count == 1)
        #expect(handler.handledEvents.first?.type == .connectRequest)
    }
}
