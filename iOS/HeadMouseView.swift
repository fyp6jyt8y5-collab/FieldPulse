import SwiftUI

struct HeadMouseView: View {
    @StateObject private var service = HeadMouseService()

    var body: some View {
        Form {
            Section("Windows PC") {
                TextField("IP address, e.g. 192.168.1.20", text: $service.host)
                    .keyboardType(.numbersAndPunctuation)
                TextField("UDP port", text: $service.port)
                    .keyboardType(.numberPad)
                Text("The PC agent must be running on the same Wi-Fi network.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("Control") {
                Toggle("Head tracking", isOn: Binding(get: { service.isRunning }, set: { _ in service.toggle() }))
                VStack(alignment: .leading) {
                    Text("Sensitivity: \(service.sensitivity, format: .number.precision(.fractionLength(1)))")
                    Slider(value: $service.sensitivity, in: 0.2...3.0)
                }
                VStack(alignment: .leading) {
                    Text("Dead zone: \(service.deadZone, format: .number.precision(.fractionLength(2)))")
                    Slider(value: $service.deadZone, in: 0...0.2)
                }
                Button("Recenter") { service.stop(); service.start() }
                    .disabled(!service.isRunning)
            }
            if let error = service.errorMessage {
                Section { Text(error).foregroundStyle(.red) }
            }
        }
        .navigationTitle("Head Mouse")
        .onDisappear { service.stop() }
    }
}
