import Foundation
import Network

class PointerWebSocketServer {
    private var listener: NWListener?
    private var connections: [NWConnection] = []

    func start() {
        let params = NWParameters.tcp
        params.allowLocalEndpointReuse = true
        listener = try? NWListener(using: params, on: 0) // dynamic port
        listener?.newConnectionHandler = { [weak self] connection in
            self?.connections.append(connection)
            connection.start(queue: .main)
        }
        listener?.start(queue: .main)
        if let port = listener?.port?.rawValue {
            print("WebSocket server on port \(port)")
        }
    }

    func sendMouseMove(dx: Float, dy: Float) {
        send("{\"type\":\"move\",\"dx\":\(dx),\"dy\":\(dy)}")
    }

    func sendMouseButton(button: Int, pressed: Bool) {
        send("{\"type\":\"button\",\"button\":\(button),\"pressed\":\(pressed)}")
    }

    func sendKey(code: Int, pressed: Bool) {
        send("{\"type\":\"key\",\"code\":\(code),\"pressed\":\(pressed)}")
    }

    private func send(_ string: String) {
        guard let data = string.data(using: .utf8) else { return }
        for conn in connections {
            conn.send(content: data, completion: .contentProcessed({ _ in }))
        }
    }
}