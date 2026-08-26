import Foundation
import Combine
#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

@MainActor
final class ConnectivityService: NSObject, ObservableObject {
    @Published private(set) var data = AppData.empty
    @Published private(set) var isReachable = false

    override init() {
        super.init()
#if canImport(WatchConnectivity)
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
        isReachable = WCSession.default.isReachable
#endif
    }

    func send(_ data: AppData) {
        self.data = data
        SharedDataStore.save(data)
#if canImport(WatchConnectivity)
        guard WCSession.default.activationState == .activated else { return }
        try? WCSession.default.updateApplicationContext(["data": data.encoded])
        WCSession.default.transferUserInfo(["data": data.encoded])
#endif
    }

#if canImport(WatchConnectivity)
    private func apply(_ dictionary: [String: Any]) {
        guard let value = dictionary["data"] as? Data, let decoded = try? JSONDecoder().decode(AppData.self, from: value) else { return }
        data = decoded
        SharedDataStore.save(decoded)
    }
#endif
}

private extension AppData { var encoded: Data { (try? JSONEncoder().encode(self)) ?? Data() } }

#if canImport(WatchConnectivity)
extension ConnectivityService: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) { Task { @MainActor in self.isReachable = session.isReachable } }
    nonisolated func sessionReachabilityDidChange(_ session: WCSession) { Task { @MainActor in self.isReachable = session.isReachable } }
    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) { Task { @MainActor in self.apply(applicationContext) } }
    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) { Task { @MainActor in self.apply(userInfo) } }
#if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }
#endif
}
#endif
