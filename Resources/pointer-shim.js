(function() {
    'use strict';

    const where = 'exec@' + location.href + ' top=' + (window === window.top);

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
                    'z-index:2147483647!important;background:red!important;color:white!important;' +
                    'padding:8px!important;font-size:14px!important;font-family:monospace!important;' +
                    'max-width:100vw!important;overflow:hidden!important;word-break:break-all!important;';
                (document.documentElement || document.body).appendChild(el);
            }
            el.textContent = msg;
        } catch (e) {}
    }

    sendDiag('shim ' + where);

    // MediaDevices polyfill
    if (!navigator.mediaDevices) navigator.mediaDevices = {};
    if (!navigator.mediaDevices.getUserMedia) {
        navigator.mediaDevices.getUserMedia = function() {
            return Promise.reject(new Error('getUserMedia not supported'));
        };
    }

    // Pointer lock override
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

    // If we end up on the /play page and BX_EXPOSED never appears, reload once
    let checks = 0;
    const interval = setInterval(() => {
        checks++;
        if (window.BX_EXPOSED) { sendDiag('BX OK ' + where); clearInterval(interval); return; }
        if (checks > 20) { sendDiag('BX missing after 40s ' + where); clearInterval(interval); return; }
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