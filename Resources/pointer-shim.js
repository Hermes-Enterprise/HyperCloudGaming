(function() {
    'use strict';

    // ---- 1. Spoof navigator to desktop Edge to bypass PWA "Add to Home Screen" prompt ----
    function HookProperty(object, property, value) {
        try {
            Object.defineProperty(object, property, { value: value, configurable: true });
        } catch (e) { /* ignore if locked */ }
    }

    const fakeUAData = {
        brands: [
            { brand: "Microsoft Edge", version: "999" },
            { brand: "Chromium", version: "999" },
            { brand: "Not=A?Brand", version: "24" }
        ],
        mobile: false,
        platform: "Windows"
    };

    HookProperty(navigator, "userAgent",
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/999.0.0.0 Safari/537.36 Edg/999.0.0.0");
    HookProperty(navigator, "appVersion",
        "5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/999.0.0.0 Safari/537.36 Edg/999.0.0.0");
    HookProperty(navigator, "platform", "Win32");
    HookProperty(navigator, "appName", "Netscape");
    HookProperty(navigator, "appCodeName", "Mozilla");
    HookProperty(navigator, "product", "Gecko");
    HookProperty(navigator, "vendor", "Google Inc.");
    HookProperty(navigator, "vendorSub", "");
    HookProperty(navigator, "maxTouchPoints", undefined);
    HookProperty(navigator, "userAgentData", fakeUAData);

    // ---- 2. Diagnostic (so we can see the shim is running) ----
    function sendDiag(msg) {
        try {
            window.webkit.messageHandlers.pointerLock.postMessage({ diagnostic: msg });
        } catch (e) {}
        try {
            let el = document.getElementById('__hcg_diag');
            if (!el) {
                el = document.createElement('div');
                el.id = '__hcg_diag';
                el.style.cssText = 'position:fixed!important;top:0!important;left:0!important;' +
                    'z-index:2147483647!important;background:rgba(200,0,0,0.85)!important;color:white!important;' +
                    'padding:6px!important;font-size:12px!important;font-family:monospace!important;' +
                    'max-width:100vw!important;overflow:hidden!important;word-break:break-all!important;' +
                    'pointer-events:none!important;';
                (document.documentElement || document.body).appendChild(el);
            }
            el.textContent = msg;
        } catch (e) {}
    }

    sendDiag('shim exec@' + location.href + ' top=' + (window === window.top));

    // ---- 3. mediaDevices polyfill ----
    if (!navigator.mediaDevices) navigator.mediaDevices = {};
    if (!navigator.mediaDevices.getUserMedia) {
        navigator.mediaDevices.getUserMedia = function() {
            return Promise.reject(new Error('getUserMedia not supported'));
        };
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

    // ---- 5. Reload fallback if Better xCloud hasn't initialized on /play ----
    let checks = 0;
    const interval = setInterval(() => {
        checks++;
        if (window.BX_EXPOSED) {
            sendDiag('BX OK');
            clearInterval(interval);
            return;
        }
        if (checks > 20) {
            sendDiag('BX missing after 40s');
            clearInterval(interval);
            return;
        }
        if (checks < 5) return;
        const onPlayPage = location.hostname.includes('xbox.com') && location.pathname.includes('/play');
        if (!onPlayPage) return;
        const lastReload = parseInt(sessionStorage.getItem('__hcg_reload_ts') || '0', 10);
        if (Date.now() - lastReload < 60000) return;
        sessionStorage.setItem('__hcg_reload_ts', String(Date.now()));
        clearInterval(interval);
        location.reload();
    }, 2000);
})();