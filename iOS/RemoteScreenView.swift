import SwiftUI
import WebKit
import Network

struct RemoteScreenView: View {
    @StateObject private var remote = RemoteControlService()

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                TextField("IP du PC", text: $remote.host)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numbersAndPunctuation)
                Button(remote.isConnected ? "Stop" : "Connect") { remote.toggle() }
                    .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)
            if remote.isConnected {
                RemoteStream(url: remote.streamURL)
                    .overlay {
                        Color.clear
                            .contentShape(Rectangle())
                            .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                                remote.move(dx: value.translation.width, dy: value.translation.height)
                            }.onEnded { _ in remote.click() })
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal)
            } else {
                ContentUnavailableView("PC disconnected", systemImage: "desktopcomputer")
            }
            if let error = remote.errorMessage { Text(error).font(.caption).foregroundStyle(.red) }
        }
        .navigationTitle("Remote Screen")
        .onDisappear { remote.stop() }
    }
}

struct RemoteStream: UIViewRepresentable {
    let url: URL?
    func makeUIView(context: Context) -> WKWebView { WKWebView(frame: .zero) }
    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let url else { return }
        webView.load(URLRequest(url: url))
    }
}

@MainActor
final class RemoteControlService: ObservableObject {
    @Published var host = ""
    @Published private(set) var isConnected = false
    @Published private(set) var errorMessage: String?
    private var connection: NWConnection?
    private var lastPoint = CGPoint.zero

    var streamURL: URL? { URL(string: "http://\(host):8080/stream") }

    func toggle() { isConnected ? stop() : start() }
    func start() {
        guard !host.isEmpty, let port = NWEndpoint.Port(rawValue: 45454) else { errorMessage = "Enter the PC IP address."; return }
        connection = NWConnection(host: NWEndpoint.Host(host), port: port, using: .udp)
        connection?.start(queue: .global(qos: .userInteractive))
        isConnected = true
        errorMessage = nil
    }
    func move(dx: CGFloat, dy: CGFloat) {
        let deltaX = dx - lastPoint.x
        let deltaY = dy - lastPoint.y
        lastPoint = CGPoint(x: dx, y: dy)
        send(MousePacket(type: "move", dx: Double(deltaX), dy: Double(deltaY)))
    }
    func click() { lastPoint = .zero; send(MousePacket(type: "click", dx: 0, dy: 0)) }
    func stop() { connection?.cancel(); connection = nil; isConnected = false; lastPoint = .zero }
    private func send(_ packet: MousePacket) {
        guard let data = try? JSONEncoder().encode(packet) else { return }
        connection?.send(content: data, completion: .contentProcessed { _ in })
    }
}

private struct MousePacket: Codable { let type: String; let dx: Double; let dy: Double }
