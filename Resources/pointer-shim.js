(function() {
    'use strict';

    // ---- 1. Desktop UA + standalone spoof ----
    const fakeUAData = {
        brands: [{ brand: "Microsoft Edge", version: "999" }, { brand: "Chromium", version: "999" }, { brand: "Not=A?Brand", version: "24" }],
        mobile: false, platform: "Windows"
    };

    const spoof = (obj, key, val) => { try { Object.defineProperty(obj, key, { value: val, configurable: true }); } catch (e) {} };

    spoof(navigator, "userAgent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/999.0.0.0 Safari/537.36 Edg/999.0.0.0");
    spoof(navigator, "appVersion", "5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/999.0.0.0 Safari/537.36 Edg/999.0.0.0");
    spoof(navigator, "platform", "Win32");
    spoof(navigator, "appName", "Netscape");
    spoof(navigator, "appCodeName", "Mozilla");
    spoof(navigator, "product", "Gecko");
    spoof(navigator, "vendor", "Google Inc.");
    spoof(navigator, "vendorSub", "");
    spoof(navigator, "maxTouchPoints", undefined);
    spoof(navigator, "userAgentData", fakeUAData);
    spoof(navigator, "standalone", false);

    const origMatchMedia = window.matchMedia;
    window.matchMedia = function(q) {
        if (q.includes('standalone')) return { matches: false, addListener: () => {}, removeListener: () => {} };
        return origMatchMedia.call(window, q);
    };

    // ---- 2. Diagnostic ----
    function sendDiag(msg) {
        try { window.webkit.messageHandlers.pointerLock.postMessage({ diagnostic: msg }); } catch (e) {}
        try {
            let el = document.getElementById('__hcg_diag');
            if (!el) {
                el = document.createElement('div');
                el.id = '__hcg_diag';
                el.style.cssText = 'position:fixed!important;top:0!important;left:0!important;z-index:2147483647!important;background:rgba(200,0,0,0.85)!important;color:white!important;padding:4px 6px!important;font-size:11px!important;font-family:monospace!important;max-width:100vw!important;overflow:hidden!important;pointer-events:none!important;';
                (document.documentElement || document.body).appendChild(el);
            }
            el.textContent = msg;
        } catch (e) {}
    }
    sendDiag('shim exec@' + location.href);

    // ---- 3. mediaDevices polyfill ----
    if (!navigator.mediaDevices) navigator.mediaDevices = {};
    if (!navigator.mediaDevices.getUserMedia) {
        navigator.mediaDevices.getUserMedia = () => Promise.reject(new Error('getUserMedia not supported'));
    }

    // ---- 4. Pointer lock override ----
    const prevRequest = Element.prototype.requestPointerLock;
    Element.prototype.requestPointerLock = function() {
        try { window.webkit.messageHandlers.pointerLock.postMessage({ locked: true }); } catch (e) {}
        if (typeof prevRequest === 'function') return prevRequest.apply(this, arguments);
    };
    const prevExit = document.exitPointerLock;
    document.exitPointerLock = function() {
        try { window.webkit.messageHandlers.pointerLock.postMessage({ locked: false }); } catch (e) {}
        if (typeof prevExit === 'function') return prevExit.apply(this, arguments);
    };

    // ---- 5. Reload fallback ----
    let checks = 0;
    setInterval(() => {
        if (window.BX_EXPOSED) { sendDiag('BX OK'); return; }
        checks++;
        if (checks < 5) return;
        const onPlay = location.hostname.includes('xbox.com') && location.pathname.includes('/play');
        if (!onPlay) return;
        const last = parseInt(sessionStorage.getItem('__hcg_reload_ts') || '0', 10);
        if (Date.now() - last < 60000) return;
        sessionStorage.setItem('__hcg_reload_ts', String(Date.now()));
        location.reload();
    }, 2000);
})();