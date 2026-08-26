import WidgetKit
import SwiftUI

struct PulseEntry: TimelineEntry {
    let date: Date
    let data: AppData
}

struct PulseProvider: TimelineProvider {
    func placeholder(in context: Context) -> PulseEntry { PulseEntry(date: .now, data: .empty) }
    func getSnapshot(in context: Context, completion: @escaping (PulseEntry) -> Void) { completion(PulseEntry(date: .now, data: storedData())) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<PulseEntry>) -> Void) {
        let entry = PulseEntry(date: .now, data: storedData())
        completion(Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(900))))
    }
    private func storedData() -> AppData {
        return SharedDataStore.load()
    }
}

struct FieldPulseWidgetView: View {
    let entry: PulseEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Label(entry.data.city ?? "FieldPulse", systemImage: "location.fill").font(.caption2)
            if let temperature = entry.data.temperature { Text(temperature.formatted(.number.precision(.fractionLength(0))) + "°").font(.title2.bold()) }
            Text(entry.data.condition ?? "No weather data").font(.caption2).lineLimit(1)
            if family == .accessoryRectangular { Text(Date.now, format: .dateTime.hour().minute()).font(.caption2) }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct FieldPulseWidget: Widget {
    let kind = "FieldPulseWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PulseProvider()) { entry in FieldPulseWidgetView(entry: entry) }
            .configurationDisplayName("FieldPulse")
            .description("Current time, weather, location and battery.")
            .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline, .systemSmall, .systemMedium])
    }
}

@main
struct FieldPulseWidgetBundle: WidgetBundle { var body: some Widget { FieldPulseWidget() } }
