import SwiftUI
import WebKit
import Network
import CoreMotion

struct RemoteScreenView: View {
    @StateObject private var remote = RemoteControlService()
    @State private var vrMode = false
    @State private var panoramicMode = false
    @State private var headMouse = false

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()
            if remote.isConnected {
                GeometryReader { geometry in
                    HStack(spacing: vrMode ? 8 : 0) {
                        RemoteStream(url: remote.streamURL)
                            .frame(width: vrMode ? geometry.size.width / 2 - 4 : geometry.size.width, height: geometry.size.height)
                        if vrMode {
                            RemoteStream(url: remote.streamURL)
                                .frame(width: geometry.size.width / 2 - 4, height: geometry.size.height)
                        }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .scaleEffect(panoramicMode ? 1.25 : 1)
                    .offset(panoramicMode ? remote.panoramaOffset : .zero)
                    .clipped()
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
                Button(panoramicMode ? "Panoramique actif" : "Panoramique") {
                    panoramicMode.toggle()
                    remote.setPanoramicEnabled(panoramicMode)
                }
                    .buttonStyle(.bordered)
                Button(headMouse ? "Gyro actif" : "Souris gyro") {
                    headMouse.toggle()
                    remote.setHeadMouseEnabled(headMouse)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(12)
        .foregroundStyle(.white)
        .opacity(remote.isConnected ? 0.9 : 0)
    }
}

struct RemoteStream: UIViewRepresentable {
    let url: URL?
    final class Coordinator {
        var loadedURL: URL?
    }

    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero)
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        return webView
    }
    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let url else { return }
        guard context.coordinator.loadedURL != url else { return }
        let escapedURL = url.absoluteString.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "\"", with: "&quot;")
        let html = """
        <html><head><meta name=\"viewport\" content=\"width=device-width,initial-scale=1\"></head>
        <body style=\"margin:0;background:#000;overflow:hidden\"><img src=\"\(escapedURL)\" style=\"display:block;width:100vw;height:100vh;object-fit:cover\"></body></html>
        """
        context.coordinator.loadedURL = url
        webView.loadHTMLString(html, baseURL: nil)
    }
}

@MainActor
final class RemoteControlService: ObservableObject {
    @Published var host = ""
    @Published private(set) var isConnected = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var panoramaOffset = CGSize.zero
    private var connection: NWConnection?
    private var lastPoint = CGPoint.zero
    private let motionManager = CMMotionManager()
    private let motionQueue = OperationQueue()
    private var referenceAttitude: CMAttitude?
    private var previousYaw: Double?
    private var previousPitch: Double?

    var streamURL: URL? { URL(string: "http://\(host):8080/stream") }

    func toggle() { isConnected ? stop() : start() }
    func start() {
        guard !host.isEmpty, let port = NWEndpoint.Port(rawValue: 45454) else { errorMessage = "Enter the PC IP address."; return }
        connection = NWConnection(host: NWEndpoint.Host(host), port: port, using: .udp)
        connection?.start(queue: .global(qos: .userInteractive))
        isConnected = true
        errorMessage = nil
    }
    func setHeadMouseEnabled(_ enabled: Bool) {
        guard enabled else {
            motionManager.stopDeviceMotionUpdates()
            referenceAttitude = nil
            previousYaw = nil
            previousPitch = nil
            return
        }
        guard motionManager.isDeviceMotionAvailable else { errorMessage = "Gyroscope unavailable."; return }
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        referenceAttitude = nil
        previousYaw = nil
        previousPitch = nil
        motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: motionQueue) { [weak self] motion, _ in
            guard let motion, let self else { return }
            let reference = self.referenceAttitude ?? motion.attitude
            if self.referenceAttitude == nil { self.referenceAttitude = reference }
            let relative = motion.attitude.copy() as! CMAttitude
            relative.multiply(byInverseOf: reference)
            let yaw = relative.yaw
            let pitch = relative.pitch
            let lastYaw = self.previousYaw ?? yaw
            let lastPitch = self.previousPitch ?? pitch
            let yawDelta = Self.shortestAngle(yaw - lastYaw)
            let pitchDelta = Self.shortestAngle(pitch - lastPitch)
            self.previousYaw = yaw
            self.previousPitch = pitch
            let dx = abs(yawDelta) > 0.001 ? yawDelta * 950 : 0
            let dy = abs(pitchDelta) > 0.001 ? -pitchDelta * 950 : 0
            Task { @MainActor in
                self.send(MousePacket(type: "move", dx: Double(dx), dy: Double(dy)))
                self.panoramaOffset = CGSize(width: max(-180, min(180, self.panoramaOffset.width - CGFloat(yawDelta * 260))), height: max(-110, min(110, self.panoramaOffset.height + CGFloat(pitchDelta * 260))))
            }
        }
    }
    private static func shortestAngle(_ angle: Double) -> Double {
        atan2(sin(angle), cos(angle))
    }
    func setPanoramicEnabled(_ enabled: Bool) { if !enabled { panoramaOffset = .zero } }
    func move(dx: CGFloat, dy: CGFloat) {
        let deltaX = dx - lastPoint.x
        let deltaY = dy - lastPoint.y
        lastPoint = CGPoint(x: dx, y: dy)
        send(MousePacket(type: "move", dx: Double(deltaX), dy: Double(deltaY)))
    }
    func click() { lastPoint = .zero; send(MousePacket(type: "click", dx: 0, dy: 0)) }
    func stop() { motionManager.stopDeviceMotionUpdates(); connection?.cancel(); connection = nil; isConnected = false; lastPoint = .zero; panoramaOffset = .zero; referenceAttitude = nil; previousYaw = nil; previousPitch = nil }
    private func send(_ packet: MousePacket) {
        guard let data = try? JSONEncoder().encode(packet) else { return }
        connection?.send(content: data, completion: .contentProcessed { _ in })
    }
}

private struct MousePacket: Codable { let type: String; let dx: Double; let dy: Double }
