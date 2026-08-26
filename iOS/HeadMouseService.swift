import CoreMotion
import Combine
import Foundation
import Network

@MainActor
final class HeadMouseService: ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var errorMessage: String?
    @Published var host = ""
    @Published var port = "45454"
    @Published var sensitivity = 1.0
    @Published var deadZone = 0.04

    private let motionManager = CMMotionManager()
    private var connection: NWConnection?
    private let motionQueue = OperationQueue()

    func toggle() {
        if isRunning { stop() } else { start() }
    }

    func start() {
        guard !host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { errorMessage = "Enter the Windows PC IP address."; return }
        guard let portValue = UInt16(port), let networkPort = NWEndpoint.Port(rawValue: portValue) else { errorMessage = "Enter a valid UDP port."; return }
        guard motionManager.isDeviceMotionAvailable else { errorMessage = "This iPhone has no compatible motion sensor."; return }
        errorMessage = nil
        connection = NWConnection(host: NWEndpoint.Host(host), port: networkPort, using: .udp)
        connection?.start(queue: .global(qos: .userInteractive))
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        let zone = deadZone
        motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: motionQueue) { [weak self] motion, _ in
            guard let motion else { return }
            let yaw = abs(motion.rotationRate.y) > zone ? motion.rotationRate.y : 0
            let pitch = abs(motion.rotationRate.x) > zone ? motion.rotationRate.x : 0
            let packet = MotionPacket(x: pitch, y: -yaw, sensitivity: self?.sensitivity ?? 1.0)
            guard let encoded = try? JSONEncoder().encode(packet) else { return }
            self?.connection?.send(content: encoded, completion: .contentProcessed { _ in })
        }
        isRunning = true
    }

    func stop() {
        motionManager.stopDeviceMotionUpdates()
        connection?.cancel()
        connection = nil
        isRunning = false
    }

    deinit { motionManager.stopDeviceMotionUpdates(); connection?.cancel() }
}

private struct MotionPacket: Codable {
    let x: Double
    let y: Double
    let sensitivity: Double
}
