(function() {
    'use strict';

    // ---- Diagnostics (remove after first successful test) ----
    console.log('[HyperCloud] pointer-shim loaded at', location.href);
    if (document.body) document.body.style.border = '5px solid red';
    else document.addEventListener('DOMContentLoaded', () => {
        document.body.style.border = '5px solid red';
    });

    // ---- Polyfill mediaDevices (xCloud crashes without it on WebKit) ----
    if (!navigator.mediaDevices) navigator.mediaDevices = {};
    if (!navigator.mediaDevices.getUserMedia) {
        navigator.mediaDevices.getUserMedia = function() {
            return Promise.reject(new Error('getUserMedia not supported'));
        };
    }

    // ---- Pointer lock override (notifies Swift, preserves any previous override) ----
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

    // ---- Reload fallback: if on /play but BX_EXPOSED never appears, reload once per minute ----
    let checks = 0;
    const interval = setInterval(() => {
        checks++;
        if (window.BX_EXPOSED) { clearInterval(interval); return; }
        if (checks > 15) { clearInterval(interval); return; }
        if (checks < 5) return;

        const onPlayPage = location.hostname.includes('xbox.com') && location.pathname.includes('/play');
        if (!onPlayPage) return;

        const lastReload = parseInt(sessionStorage.getItem('__hcg_reload_ts') || '0', 10);
        if (Date.now() - lastReload < 60000) return;

        sessionStorage.setItem('__hcg_reload_ts', String(Date.now()));
        clearInterval(interval);
        console.log('[HyperCloud] Better xCloud not detected after 10s, reloading once');
        location.reload();
    }, 2000);

    // ---- WebSocket hookup (placeholder — we wire this up in Phase 2) ----
    // const ws = new WebSocket('ws://localhost:PORT_PLACEHOLDER');
    // ws.onmessage = ...
})();