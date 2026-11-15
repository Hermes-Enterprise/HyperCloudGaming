(function() {
    'use strict';

    // Override pointer lock
    const originalRequest = Element.prototype.requestPointerLock;
    Element.prototype.requestPointerLock = function() {
        window.webkit.messageHandlers.pointerLock.postMessage({ locked: true });
    };
    const originalExit = document.exitPointerLock;
    document.exitPointerLock = function() {
        window.webkit.messageHandlers.pointerLock.postMessage({ locked: false });
    };

    // Listen for WebSocket data from Swift
    let ws;
    function connect() {
        // PORT_PLACEHOLDER will be replaced at build time
        ws = new WebSocket('ws://localhost:PORT_PLACEHOLDER');
        ws.onmessage = (event) => {
            const data = JSON.parse(event.data);
            if (data.type === 'move') {
                if (window.BX_EXPOSED && window.BX_EXPOSED.inputChannel) {
                    window.BX_EXPOSED.inputChannel.queueMouseInput({
                        X: data.dx, Y: data.dy, Buttons: 0, WheelX: 0, WheelY: 0
                    });
                }
            }
            // buttons and keys handled similarly
        };
    }
    connect();
})();