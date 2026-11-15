import Foundation
import GameController
import WebKit

class GameControllerBridge: NSObject, ObservableObject, WKScriptMessageHandler {
    private var mouse: GCMouse?
    private var keyboard: GCKeyboard?
    private var pointerLocked = false
    private let wsServer = PointerWebSocketServer()

    func start() {
        wsServer.start()
        NotificationCenter.default.addObserver(self, selector: #selector(mouseConnected), name: .GCMouseDidConnect, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardConnected), name: .GCKeyboardDidConnect, object: nil)
        if let mouse = GCMouse.current { setupMouse(mouse) }
        if let keyboard = GCKeyboard.coalesced { setupKeyboard(keyboard) }
    }

    @objc private func mouseConnected(_ note: Notification) {
        if let mouse = note.object as? GCMouse { setupMouse(mouse) }
    }

    @objc private func keyboardConnected(_ note: Notification) {
        if let keyboard = note.object as? GCKeyboard { setupKeyboard(keyboard) }
    }

    private func setupMouse(_ mouse: GCMouse) {
        self.mouse = mouse
        mouse.mouseInput?.mouseMovedHandler = { [weak self] _, dx, dy in
            guard let self = self, self.pointerLocked else { return }
            self.wsServer.sendMouseMove(dx: dx, dy: dy)
        }
        mouse.mouseInput?.leftButton.pressedChangedHandler = { [weak self] _, _, pressed in
            self?.wsServer.sendMouseButton(button: 0, pressed: pressed)
        }
        mouse.mouseInput?.rightButton?.pressedChangedHandler = { [weak self] _, _, pressed in
            self?.wsServer.sendMouseButton(button: 1, pressed: pressed)
        }
        mouse.mouseInput?.middleButton?.pressedChangedHandler = { [weak self] _, _, pressed in
            self?.wsServer.sendMouseButton(button: 2, pressed: pressed)
        }
    }

    private func setupKeyboard(_ keyboard: GCKeyboard) {
        self.keyboard = keyboard
        keyboard.keyboardInput?.keyChangedHandler = { [weak self] _, _, keyCode, pressed in
            self?.wsServer.sendKey(code: Int(keyCode.rawValue), pressed: pressed)
        }
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "pointerLock", let body = message.body as? [String: Any] {
            if let locked = body["locked"] as? Bool { pointerLocked = locked }
        }
    }
}