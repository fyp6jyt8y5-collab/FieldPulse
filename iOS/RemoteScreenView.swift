import SwiftUI
import WebKit
import Network

struct RemoteScreenView: View {
    @StateObject private var remote = RemoteControlService()
    @State private var vrMode = false

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()
            if remote.isConnected {
                GeometryReader { geometry in
                    HStack(spacing: vrMode ? 2 : 0) {
                        RemoteStream(url: remote.streamURL)
                        if vrMode { RemoteStream(url: remote.streamURL) }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .overlay {
                        Color.clear
                            .contentShape(Rectangle())
                            .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                                remote.move(dx: value.translation.width, dy: value.translation.height)
                            }.onEnded { _ in remote.click() })
                    }
                }
            } else {
                setupView
            }
            controls
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .ignoresSafeArea()
        .onDisappear { remote.stop() }
    }

    private var setupView: some View {
        VStack(spacing: 16) {
            Image(systemName: "desktopcomputer").font(.system(size: 48)).foregroundStyle(.white)
            TextField("IP du PC, ex. 192.168.1.20", text: $remote.host)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numbersAndPunctuation)
                .frame(maxWidth: 320)
            Button("Connecter") { remote.start() }.buttonStyle(.borderedProminent)
            if let error = remote.errorMessage { Text(error).foregroundStyle(.red) }
        }
    }

    private var controls: some View {
        HStack {
            if remote.isConnected {
                Button("Deconnecter") { remote.stop() }.buttonStyle(.bordered)
                Button(vrMode ? "Ecran unique" : "Mode casque VR") { vrMode.toggle() }.buttonStyle(.bordered)
            }
        }
        .padding(12)
        .foregroundStyle(.white)
        .opacity(remote.isConnected ? 0.9 : 0)
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
