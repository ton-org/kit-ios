//
//  IframeSecurityCase.swift
//  TONWalletApp
//
//  Created by Nikita Rodionov on 04.06.2026.
//
//  Copyright (c) 2026 TON Connect
//

import Foundation

enum IframeSecurityCase: String, CaseIterable, Identifiable {
    case baseline
    case sameOriginIframe
    case programmaticIframe
    case sameOriginViaScheme
    case suffixSpoofedSubdomain
    case crossOriginIframe
    case nestedIframe
    case siblingIframes
    case payloadOriginSpoof
    case raceCondition
    case sandboxedIframe

    var id: String { rawValue }

    enum LoadMode {
        case htmlString(html: String, baseURL: URL)
        case schemeRoutes(scheme: String, initial: URL, routes: [String: String])
    }

    var title: String {
        switch self {
        case .baseline:               return "1. Baseline (no iframe)"
        case .sameOriginIframe:       return "2. Same-origin iframe (srcdoc)"
        case .programmaticIframe:     return "2a. Programmatic iframe (no src)"
        case .sameOriginViaScheme:    return "2b. Same-origin via path (scheme handler)"
        case .suffixSpoofedSubdomain: return "2c. Suffix-spoofed subdomain"
        case .crossOriginIframe:      return "3. Cross-origin iframe (data:)"
        case .nestedIframe:           return "4. Nested iframes (3 levels)"
        case .siblingIframes:         return "5. Sibling iframes (cross-origin)"
        case .payloadOriginSpoof:     return "6. Payload origin spoofing"
        case .raceCondition:          return "7. Concurrent connect race"
        case .sandboxedIframe:        return "8. Sandboxed iframe"
        }
    }

    var summary: String {
        switch self {
        case .baseline:
            return "Sanity check. Parent page, no iframes. Verifies the diagnostic bridge logs main-frame events with the expected origin."
        case .sameOriginIframe:
            return "iframe via srcdoc inherits the parent's origin. A bridge keyed by origin alone cannot distinguish parent from iframe."
        case .programmaticIframe:
            return "Parent creates an iframe via document.createElement('iframe') without src or srcdoc. The about:blank initial document inherits the parent's origin. Common pattern for in-page widgets injected by parent JS."
        case .sameOriginViaScheme:
            return "Parent at tonkitdemo://parent-dapp.test/ embeds an iframe at .../widget on the same scheme + host. Different path doesn't break SOP — both frames share an origin. Models the dApp pattern of embedding a same-host widget."
        case .suffixSpoofedSubdomain:
            return "Parent at tonkitdemo://parent-dapp.test/. Iframe loaded from tonkitdemo://evil.parent-dapp.test/widget. A naive origin.endsWith(\"parent-dapp.test\") check would accept it; an exact-host match would reject."
        case .crossOriginIframe:
            return "iframe loaded via data: URL gets an opaque (\"null\") origin. If approval is tied to parent's origin, the iframe must be rejected."
        case .nestedIframe:
            return "Three-level: parent → iframe A (data:) → iframe B (data:). The deepest frame triggers a tx. The bridge should see B's origin, not the parent's."
        case .siblingIframes:
            return "Two opaque-origin siblings under one parent. One simulates a connect, the other a transaction. They must not share permission state."
        case .payloadOriginSpoof:
            return "iframe sends a payload that claims `origin: https://parent-dapp.test`. The bridge must trust WKFrameInfo.securityOrigin, never the payload."
        case .raceCondition:
            return "Parent and iframe both fire a connect request in the same task. Tests how the approval UI handles concurrent prompts from different origins."
        case .sandboxedIframe:
            return "iframe `sandbox=\"allow-scripts\"` (no allow-same-origin) gets a fresh opaque origin even when using srcdoc. Demonstrates sandbox-attribute effects."
        }
    }

    var vulnerabilityClass: String {
        switch self {
        case .baseline:
            return "(none) — reference baseline."
        case .sameOriginIframe:
            return "CWE-940. Origin-only permission model is bypassed by frames that inherit origin."
        case .programmaticIframe:
            return "Same as case 2 — origin-only permission. The iframe is fully scriptable from parent AND has its own webkit.messageHandlers access."
        case .sameOriginViaScheme:
            return "Origin-only permission. WKFrameInfo.securityOrigin is path-agnostic; per-path or per-document permissions would require explicit URL-level tracking."
        case .suffixSpoofedSubdomain:
            return "CWE-1390 / weak origin verification. Substring/suffix origin comparison + blanket subdomain trust + subdomain takeover."
        case .crossOriginIframe:
            return "CWE-346. Bridge must reject events whose securityOrigin differs from the granted origin."
        case .nestedIframe:
            return "Confused-deputy / nested-frame relay. Trust does not transit through intermediate frames."
        case .siblingIframes:
            return "Shared permission state. Per-tab/per-WebView permissions leak between unrelated iframes."
        case .payloadOriginSpoof:
            return "Self-reported origin. Bridge must use WKFrameInfo.securityOrigin, never trust origin claimed in the JS payload."
        case .raceCondition:
            return "Concurrent approval ambiguity. The UI flow must bind each prompt to the frame that actually triggered it."
        case .sandboxedIframe:
            return "Sandbox origin semantics. `allow-scripts` without `allow-same-origin` produces an opaque origin even with srcdoc."
        }
    }

    var observation: String {
        switch self {
        case .baseline:
            return "Real and claimed origin both = https://parent-dapp.test. isMainFrame = true."
        case .sameOriginIframe:
            return "iframe's real origin equals parent's origin (frame badge stays green) but isMainFrame = false. Origin alone is not enough — you also need the frame identity."
        case .programmaticIframe:
            return "After tapping Create, the iframe's real origin = https://parent-dapp.test (same as parent). isMainFrame = false. WKFrameInfo.request.url is about:blank."
        case .sameOriginViaScheme:
            return "Both frames report tonkitdemo://parent-dapp.test. The /widget path is visible in WKFrameInfo.request.url, but NOT in securityOrigin — so path-level enforcement requires explicit URL tracking."
        case .suffixSpoofedSubdomain:
            return "iframe origin = tonkitdemo://evil.parent-dapp.test (different host) while parent's host is parent-dapp.test. Hosts differ; a bridge MUST exact-match host, not check for substring/suffix."
        case .crossOriginIframe:
            return "iframe's real origin is logged as opaque (empty / data). isMainFrame = false."
        case .nestedIframe:
            return "The button inside iframe B logs B's own opaque origin. Parent never appears in the log for that event."
        case .siblingIframes:
            return "Each sibling reports a distinct opaque origin. There is no shared identity between them."
        case .payloadOriginSpoof:
            return "Claimed origin (in red) = parent-dapp.test, but the frame's real origin is opaque. The mismatch is the entire vulnerability — a naive bridge would trust the claim."
        case .raceCondition:
            return "Two log entries arrive a few ms apart with different frame origins. The diagnostic bridge keeps them separate; what matters is whether the upstream approval UI does too."
        case .sandboxedIframe:
            return "Origin is opaque even though srcdoc would normally inherit. Sandbox strips same-origin."
        }
    }

    var loadMode: LoadMode {
        switch self {
        case .baseline:
            return .htmlString(html: Self.doc("""
            <div class="frame parent">
              <div class="label">PARENT</div>
              <div class="origin">origin: <span id="op"></span></div>
              <button onclick="send('PARENT','connect-request')">Connect (parent)</button>
              <button onclick="send('PARENT','send-tx',{to:'EQA',amount:'0.1'})">Send TX (parent)</button>
            </div>
            <script>showOrigin('op');</script>
            """), baseURL: Self.httpsBaseURL)

        case .sameOriginIframe:
            let inner = Self.doc("""
            <div class="frame iframe">
              <div class="label">SRCDOC IFRAME — inherits parent origin</div>
              <div class="origin">origin: <span id="oi"></span></div>
              <button class="danger" onclick="send('IFRAME-SRCDOC','send-tx',{to:'EQA',amount:'0.5',note:'No own connect'})">Send TX with no own connect</button>
              <script>showOrigin('oi');</script>
            </div>
            """)
            return .htmlString(html: Self.doc("""
            <div class="frame parent">
              <div class="label">PARENT</div>
              <div class="origin">origin: <span id="op"></span></div>
              <button onclick="send('PARENT','connect-request')">Connect (parent)</button>
            </div>
            <iframe srcdoc="\(Self.srcdocEscape(inner))"></iframe>
            <script>showOrigin('op');</script>
            """), baseURL: Self.httpsBaseURL)

        case .programmaticIframe:
            return .htmlString(html: Self.doc("""
            <div class="frame parent">
              <div class="label">PARENT</div>
              <div class="origin">origin: <span id="op"></span></div>
              <button onclick="send('PARENT','connect-request')">Connect (parent)</button>
              <button onclick="createIframe()">Create programmatic iframe (no src)</button>
            </div>
            <div id="host"></div>
            <script>
              showOrigin('op');
              function createIframe() {
                var host = document.getElementById('host');
                if (host.firstChild) return;
                var iframe = document.createElement('iframe');
                iframe.style.cssText = 'width:100%;min-height:160px;border:0;background:#fff;border-radius:8px;margin-top:8px';
                host.appendChild(iframe);
                var w = iframe.contentWindow;
                var d = iframe.contentDocument;
                w.tonSend = function(label, action, payload) {
                  w.webkit.messageHandlers.iframeSecLog.postMessage({
                    frameLabel: label,
                    action: action,
                    payload: payload || {},
                    claimedOrigin: w.location.origin || 'null',
                    ts: Date.now()
                  });
                };
                d.body.innerHTML =
                  '<div style="font-family:-apple-system;padding:10px;background:#ffe5cf;border:2px solid #ff9b5b;border-radius:10px;margin:8px;font-size:13px">' +
                  '<div style="font-weight:700;font-size:12px;margin-bottom:4px">PROGRAMMATIC IFRAME (no src)</div>' +
                  '<div style="font-family:monospace;font-size:11px;color:#444;margin-bottom:8px">origin: ' + (w.location.origin || 'null') + '</div>' +
                  '<button onclick="tonSend(&quot;IFRAME-PROG&quot;,&quot;send-tx&quot;,{to:&quot;EQA&quot;,amount:&quot;1.0&quot;})" ' +
                  'style="padding:6px 10px;border:0;border-radius:6px;background:#ff3b30;color:#fff;font-size:12px">Send TX (no own connect)</button>' +
                  '</div>';
              }
            </script>
            """), baseURL: Self.httpsBaseURL)

        case .sameOriginViaScheme:
            let parent = Self.doc("""
            <div class="frame parent">
              <div class="label">PARENT (\(Self.customScheme)://parent-dapp.test/)</div>
              <div class="origin">origin: <span id="op"></span></div>
              <button onclick="send('PARENT','connect-request')">Connect (parent)</button>
            </div>
            <iframe src="\(Self.customScheme)://parent-dapp.test/widget"></iframe>
            <script>showOrigin('op');</script>
            """)
            let widget = Self.doc("""
            <div class="frame iframe">
              <div class="label">SAME-ORIGIN WIDGET (/widget path)</div>
              <div class="origin">origin: <span id="oi"></span></div>
              <button class="danger" onclick="send('IFRAME-WIDGET','send-tx',{to:'EQA',amount:'1.0',note:'same origin, different path'})">Send TX without own connect</button>
              <script>showOrigin('oi');</script>
            </div>
            """)
            return .schemeRoutes(
                scheme: Self.customScheme,
                initial: URL(string: "\(Self.customScheme)://parent-dapp.test/")!,
                routes: [
                    "\(Self.customScheme)://parent-dapp.test/": parent,
                    "\(Self.customScheme)://parent-dapp.test/widget": widget
                ]
            )

        case .suffixSpoofedSubdomain:
            let parent = Self.doc("""
            <div class="frame parent">
              <div class="label">PARENT (\(Self.customScheme)://parent-dapp.test/)</div>
              <div class="origin">origin: <span id="op"></span></div>
              <button onclick="send('PARENT','connect-request')">Connect (parent)</button>
            </div>
            <iframe src="\(Self.customScheme)://evil.parent-dapp.test/widget"></iframe>
            <script>showOrigin('op');</script>
            """)
            let evilWidget = Self.doc("""
            <div class="frame deep">
              <div class="label">SUFFIX-SPOOFED WIDGET (evil.parent-dapp.test)</div>
              <div class="origin">origin: <span id="oi"></span></div>
              <button class="danger" onclick="send('IFRAME-EVIL-SUBDOMAIN','send-tx',{to:'EQA',amount:'99.0',note:'host endsWith parent-dapp.test BUT host is NOT parent-dapp.test'})">Send TX</button>
              <script>showOrigin('oi');</script>
            </div>
            """)
            return .schemeRoutes(
                scheme: Self.customScheme,
                initial: URL(string: "\(Self.customScheme)://parent-dapp.test/")!,
                routes: [
                    "\(Self.customScheme)://parent-dapp.test/": parent,
                    "\(Self.customScheme)://evil.parent-dapp.test/widget": evilWidget
                ]
            )

        case .crossOriginIframe:
            let inner = Self.doc("""
            <div class="frame iframe">
              <div class="label">DATA: IFRAME — opaque origin</div>
              <div class="origin">origin: <span id="oi"></span></div>
              <button class="danger" onclick="send('IFRAME-DATA','send-tx',{to:'EQA',amount:'0.5',note:'No own connect'})">Send TX with no own connect</button>
              <script>showOrigin('oi');</script>
            </div>
            """)
            return .htmlString(html: Self.doc("""
            <div class="frame parent">
              <div class="label">PARENT</div>
              <div class="origin">origin: <span id="op"></span></div>
              <button onclick="send('PARENT','connect-request')">Connect (parent)</button>
            </div>
            <iframe src="\(Self.dataURL(inner))"></iframe>
            <script>showOrigin('op');</script>
            """), baseURL: Self.httpsBaseURL)

        case .nestedIframe:
            let innerB = Self.doc("""
            <div class="frame deep">
              <div class="label">IFRAME B — deepest (data:)</div>
              <div class="origin">origin: <span id="ob"></span></div>
              <button class="danger" onclick="send('IFRAME-B','send-tx',{to:'EQA',amount:'9.99'})">Send TX from depth 2</button>
              <script>showOrigin('ob');</script>
            </div>
            """)
            let innerA = Self.doc("""
            <div class="frame iframe">
              <div class="label">IFRAME A — middle (data:)</div>
              <div class="origin">origin: <span id="oa"></span></div>
              <iframe src="\(Self.dataURL(innerB))" style="min-height:170px"></iframe>
              <script>showOrigin('oa');</script>
            </div>
            """)
            return .htmlString(html: Self.doc("""
            <div class="frame parent">
              <div class="label">PARENT</div>
              <div class="origin">origin: <span id="op"></span></div>
              <button onclick="send('PARENT','connect-request')">Connect (parent)</button>
            </div>
            <iframe src="\(Self.dataURL(innerA))" style="min-height:300px"></iframe>
            <script>showOrigin('op');</script>
            """), baseURL: Self.httpsBaseURL)

        case .siblingIframes:
            let innerA = Self.doc("""
            <div class="frame iframe">
              <div class="label">SIBLING A (data:)</div>
              <div class="origin">origin: <span id="oa"></span></div>
              <button onclick="send('SIBLING-A','connect-request')">Connect from sibling A</button>
              <script>showOrigin('oa');</script>
            </div>
            """)
            let innerB = Self.doc("""
            <div class="frame iframe" style="background:#dfffdf;border-color:#5bcc5b">
              <div class="label">SIBLING B (data:)</div>
              <div class="origin">origin: <span id="ob"></span></div>
              <button class="danger" onclick="send('SIBLING-B','send-tx',{to:'EQA',amount:'5.0',note:'Did not connect — leveraging A approval'})">Send TX from sibling B</button>
              <script>showOrigin('ob');</script>
            </div>
            """)
            return .htmlString(html: Self.doc("""
            <div class="frame parent">
              <div class="label">PARENT</div>
              <div class="origin">origin: <span id="op"></span></div>
            </div>
            <iframe src="\(Self.dataURL(innerA))"></iframe>
            <iframe src="\(Self.dataURL(innerB))"></iframe>
            <script>showOrigin('op');</script>
            """), baseURL: Self.httpsBaseURL)

        case .payloadOriginSpoof:
            let inner = Self.doc("""
            <div class="frame iframe">
              <div class="label">DATA: IFRAME — lies in payload</div>
              <div class="origin">real origin: <span id="oi"></span></div>
              <button class="danger" onclick="send('IFRAME-SPOOF','send-tx',{to:'EQA',amount:'42.0',claimedFrom:'parent-dapp.test'},'https://parent-dapp.test')">Send TX claiming origin = parent-dapp.test</button>
              <script>showOrigin('oi');</script>
            </div>
            """)
            return .htmlString(html: Self.doc("""
            <div class="frame parent">
              <div class="label">PARENT</div>
              <div class="origin">origin: <span id="op"></span></div>
            </div>
            <iframe src="\(Self.dataURL(inner))"></iframe>
            <script>showOrigin('op');</script>
            """), baseURL: Self.httpsBaseURL)

        case .raceCondition:
            let inner = Self.doc("""
            <div class="frame iframe">
              <div class="label">DATA: IFRAME — race target</div>
              <div class="origin">origin: <span id="oi"></span></div>
              <script>
                showOrigin('oi');
                window.addEventListener('message', function(e) {
                  if (e.data === 'fire-connect') {
                    send('IFRAME-RACE','connect-request',{triggeredBy:'parent-postMessage'});
                  }
                });
              </script>
            </div>
            """)
            return .htmlString(html: Self.doc("""
            <div class="frame parent">
              <div class="label">PARENT</div>
              <div class="origin">origin: <span id="op"></span></div>
              <button class="danger" onclick="fireRace()">Fire connect from BOTH (same tick)</button>
              <script>
                showOrigin('op');
                function fireRace() {
                  const f = document.querySelector('iframe');
                  f.contentWindow.postMessage('fire-connect','*');
                  send('PARENT','connect-request',{triggeredBy:'button'});
                }
              </script>
            </div>
            <iframe src="\(Self.dataURL(inner))"></iframe>
            """), baseURL: Self.httpsBaseURL)

        case .sandboxedIframe:
            let inner = Self.doc("""
            <div class="frame iframe">
              <div class="label">SANDBOXED SRCDOC (allow-scripts only)</div>
              <div class="origin">origin: <span id="oi"></span></div>
              <button class="danger" onclick="send('IFRAME-SANDBOX','send-tx',{to:'EQA',amount:'0.5'})">Send TX from sandboxed</button>
              <script>showOrigin('oi');</script>
            </div>
            """)
            return .htmlString(html: Self.doc("""
            <div class="frame parent">
              <div class="label">PARENT</div>
              <div class="origin">origin: <span id="op"></span></div>
            </div>
            <iframe sandbox="allow-scripts" srcdoc="\(Self.srcdocEscape(inner))"></iframe>
            <script>showOrigin('op');</script>
            """), baseURL: Self.httpsBaseURL)
        }
    }

    // MARK: - HTML helpers

    private static let httpsBaseURL = URL(string: "https://parent-dapp.test")!
    private static let customScheme = "tonkitdemo"

    private static let htmlHead = """
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <style>
      *{box-sizing:border-box}
      body{font-family:-apple-system;margin:0;padding:10px;background:#f5f5f7;color:#1d1d1f;font-size:13px}
      .frame{padding:10px;border-radius:10px;margin-bottom:8px}
      .frame.parent{background:#cfe4ff;border:2px solid #5b9bff}
      .frame.iframe{background:#ffe5cf;border:2px solid #ff9b5b}
      .frame.deep{background:#ffcfcf;border:2px solid #ff5b5b}
      .label{font-size:12px;font-weight:700;margin-bottom:4px;letter-spacing:.5px}
      .origin{font-family:ui-monospace,monospace;font-size:11px;color:#444;margin-bottom:8px;word-break:break-all}
      button{display:inline-block;padding:6px 10px;margin:2px 2px 0 0;border-radius:6px;border:0;background:#007aff;color:#fff;font-size:12px}
      button.danger{background:#ff3b30}
      iframe{width:100%;border:0;min-height:130px;background:#fff;border-radius:8px}
    </style>
    <script>
      function send(frameLabel, action, payload, claimedOrigin) {
        var claimed = (claimedOrigin !== undefined) ? claimedOrigin : (location.origin || 'null');
        try {
          window.webkit.messageHandlers.iframeSecLog.postMessage({
            frameLabel: frameLabel,
            action: action,
            payload: payload || {},
            claimedOrigin: claimed,
            ts: Date.now()
          });
        } catch (e) { console.error('Bridge unavailable:', String(e)); }
      }
      function showOrigin(id) {
        var el = document.getElementById(id);
        if (el) el.textContent = location.origin || 'null';
      }
    </script>
    """

    private static func doc(_ body: String) -> String {
        "<!doctype html><html><head>\(htmlHead)</head><body>\(body)</body></html>"
    }

    private static func dataURL(_ html: String) -> String {
        let b64 = Data(html.utf8).base64EncodedString()
        return "data:text/html;charset=utf-8;base64,\(b64)"
    }

    private static func srcdocEscape(_ html: String) -> String {
        html
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
