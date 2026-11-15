(function() {
    'use strict';

    // ---- Minimal desktop UA spoof ----
    // Only override what's needed to hide the "Add to Home Screen" prompt.
    // Do NOT touch maxTouchPoints, userAgentData, or matchMedia —
    // those break touch handling and event wiring on the page.
    const spoof = (obj, key, val) => {
        try { Object.defineProperty(obj, key, { value: val, configurable: true }); } catch (e) {}
    };

    spoof(navigator, "userAgent",
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15");
    spoof(navigator, "appVersion",
        "5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15");
    spoof(navigator, "platform", "MacIntel");
    spoof(navigator, "standalone", false);

    // ---- Diagnostic ----
    function sendDiag(msg) {
        try { window.webkit.messageHandlers.pointerLock.postMessage({ diagnostic: msg }); } catch (e) {}
        try {
            let el = document.getElementById('__hcg_diag');
            if (!el) {
                el = document.createElement('div');
                el.id = '__hcg_diag';
                el.style.cssText = 'position:fixed!important;top:0!important;left:0!important;' +
                    'z-index:2147483647!important;background:rgba(200,0,0,0.85)!important;color:white!important;' +
                    'padding:4px 6px!important;font-size:11px!important;font-family:monospace!important;' +
                    'max-width:100vw!important;overflow:hidden!important;pointer-events:none!important;';
                (document.documentElement || document.body).appendChild(el);
            }
            el.textContent = msg;
        } catch (e) {}
    }
    sendDiag('shim exec@' + location.href);

    // ---- mediaDevices polyfill ----
    if (!navigator.mediaDevices) navigator.mediaDevices = {};
    if (!navigator.mediaDevices.getUserMedia) {
        navigator.mediaDevices.getUserMedia = () => Promise.reject(new Error('getUserMedia not supported'));
    }

    // ---- Pointer lock override ----
    const wrapRequest = (prev) => function() {
        try { window.webkit.messageHandlers.pointerLock.postMessage({ locked: true }); } catch (e) {}
        if (typeof prev === 'function') return prev.apply(this, arguments);
    };
    Element.prototype.requestPointerLock = wrapRequest(Element.prototype.requestPointerLock);

    const wrapExit = (prev) => function() {
        try { window.webkit.messageHandlers.pointerLock.postMessage({ locked: false }); } catch (e) {}
        if (typeof prev === 'function') return prev.apply(this, arguments);
    };
    document.exitPointerLock = wrapExit(document.exitPointerLock);

    // ---- Reload fallback if BX hasn't loaded ----
    // Checks every 2s. Triggers one reload on any xbox.com host after ~16s if BX is missing.
    let checks = 0;
    const interval = setInterval(() => {
        if (window.BX_EXPOSED) {
            sendDiag('BX OK');
            clearInterval(interval);
            return;
        }
        checks++;
        if (checks > 30) { sendDiag('BX missing'); clearInterval(interval); return; }
        if (checks < 8) return;
        if (!location.hostname.includes('xbox.com')) { clearInterval(interval); return; }
        const lastReload = parseInt(sessionStorage.getItem('__hcg_reload_ts') || '0', 10);
        if (Date.now() - lastReload < 30000) return;
        sessionStorage.setItem('__hcg_reload_ts', String(Date.now()));
        clearInterval(interval);
        location.reload();
    }, 2000);
})();