(function() {
    'use strict';
    if (window.GM_getValue) return; // already installed

    const PREFIX = '__bx_';

    window.GM_getValue = function(key, defaultValue) {
        const raw = localStorage.getItem(PREFIX + key);
        if (raw === null) return defaultValue;
        try { return JSON.parse(raw); } catch (e) { return raw; }
    };

    window.GM_setValue = function(key, value) {
        try { localStorage.setItem(PREFIX + key, JSON.stringify(value)); }
        catch (e) { localStorage.setItem(PREFIX + key, String(value)); }
    };

    window.GM_deleteValue = function(key) {
        localStorage.removeItem(PREFIX + key);
    };

    window.GM_listValues = function() {
        const out = [];
        for (let i = 0; i < localStorage.length; i++) {
            const k = localStorage.key(i);
            if (k && k.startsWith(PREFIX)) out.push(k.substring(PREFIX.length));
        }
        return out;
    };

    window.GM_addStyle = function(css) {
        const style = document.createElement('style');
        style.textContent = css;
        (document.head || document.documentElement).appendChild(style);
        return style;
    };

    window.GM_xmlhttpRequest = function(opts) {
        const init = {
            method: opts.method || 'GET',
            headers: opts.headers || {},
            credentials: opts.withCredentials ? 'include' : 'same-origin'
        };
        if (opts.data) init.body = opts.data;

        fetch(opts.url, init)
            .then(res => res.text().then(text => ({ res, text })))
            .then(({ res, text }) => {
                if (opts.onload) opts.onload({
                    status: res.status,
                    statusText: res.statusText,
                    responseText: text,
                    responseHeaders: Array.from(res.headers).map(([k, v]) => `${k}: ${v}`).join('\r\n'),
                    finalUrl: res.url
                });
            })
            .catch(err => {
                if (opts.onerror) opts.onerror(err);
            });
    };

    window.GM_info = {
        script: { version: '6.7.13', name: 'Better xCloud' },
        scriptHandler: 'HyperCloud',
        version: '6.7.13'
    };

    window.unsafeWindow = window;

    console.log('[HyperCloud] GM_* shims installed');
})();