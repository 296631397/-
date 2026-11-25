import WidgetKit
import SwiftUI
import Foundation

// MARK: - 三个可调字号

struct FontSizeIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "字体大小"
    static var description = IntentDescription("分别调节年月、农历、正文字号，在默认值基础上可 +1 ~ +5")

    @Parameter(title: "年月字号", description: "默认 20", default: 20, inclusiveRange: 20...25)
    var titleSize: Int

    @Parameter(title: "农历字号", description: "默认 11", default: 11, inclusiveRange: 11...16)
    var lunarSize: Int

    @Parameter(title: "正文字号", description: "默认 12", default: 12, inclusiveRange: 12...17)
    var bodySize: Int

    init() {}
}

// MARK: - Entry

struct MonthEntry: TimelineEntry {
    let date: Date
    let configuration: FontSizeIntent
}

// MARK: - Provider

struct MonthProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> MonthEntry {
        MonthEntry(date: .now, configuration: FontSizeIntent())
    }

    func snapshot(for configuration: FontSizeIntent, in context: Context) async -> MonthEntry {
        MonthEntry(date: .now, configuration: configuration)
    }

    func timeline(for configuration: FontSizeIntent, in context: Context) async -> Timeline<MonthEntry> {
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
        return Timeline(entries: [MonthEntry(date: .now, configuration: configuration)],
                        policy: .after(next))
    }
}

// MARK: - Widget

struct RedCalendarWidget: Widget {
    let kind = "RedCalendarMonthWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: FontSizeIntent.self, provider: MonthProvider()) { entry in
            MonthView(entry: entry)
                .containerBackground(for: .widget) {
                    Color(red: 0.909, green: 0.267, blue: 0.235)
                }
        }
        .configurationDisplayName("红历月历")
        .description("左右切月 · 今回今天")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

@main
struct RedCalendarWidgetBundle: WidgetBundle {
    var body: some Widget {
        RedCalendarWidget()
    }
}

// MARK: - 视图

struct DayInfo: Hashable {
    let day: Int
    let lunar: String
    let isToday: Bool
}

struct MonthView: View {
    let entry: MonthEntry

    private var calendar: Calendar { Calendar.current }
    private var chineseCalendar: Calendar { Calendar(identifier: .chinese) }

    private let lunarDays = ["初一","初二","初三","初四","初五","初六","初七","初八","初九","初十",
                             "十一","十二","十三","十四","十五","十六","十七","十八","十九","二十",
                             "廿一","廿二","廿三","廿四","廿五","廿六","廿七","廿八","廿九","三十"]
    private let lunarMonths = ["正月","二月","三月","四月","五月","六月","七月","八月","九月","十月","冬月","腊月"]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            header
            weekRow
            grid
        }
        .padding(10)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(monthTitle)
                .font(.system(size: CGFloat(entry.configuration.titleSize), weight: .bold))
                .foregroundColor(.white)
            Spacer(minLength: 6)
            Text(lunarTitle)
                .font(.system(size: CGFloat(entry.configuration.lunarSize)))
                .foregroundColor(.white.opacity(0.88))
        }
    }

    private var weekRow: some View {
        HStack(spacing: 0) {
            ForEach(["日","一","二","三","四","五","六"], id: \.self) { w in
                Text(w)
                    .font(.system(size: max(CGFloat(entry.configuration.bodySize) - 3, 6)))
                    .foregroundColor(.white.opacity(0.9))
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var grid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 2) {
            ForEach(days, id: \.self) { d in
                dayCell(d)
            }
        }
    }

    private func dayCell(_ d: DayInfo) -> some View {
        let size = CGFloat(entry.configuration.bodySize)
        return VStack(spacing: 0) {
            Text("\(d.day)")
                .font(.system(size: size, weight: d.isToday ? .bold : .regular))
                .foregroundColor(d.isToday ? .white : .black)
            Text(d.lunar)
                .font(.system(size: max(size - 4, 6)))
                .foregroundColor(d.isToday ? .white.opacity(0.9) : .gray)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, minHeight: size * 2)
        .background(d.isToday ? Color.red : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    // MARK: - 数据

    private var monthTitle: String {
        let c = calendar.dateComponents([.year, .month], from: entry.date)
        return "\(c.year ?? 0)年\(c.month ?? 0)月"
    }

    private var lunarTitle: String {
        let c = chineseCalendar.dateComponents([.month, .day], from: entry.date)
        let m = lunarMonths[max(0, min(11, (c.month ?? 1) - 1))]
        let d = lunarDays[max(0, min(29, (c.day ?? 1) - 1))]
        return "\(m)\(d)"
    }

    private var days: [DayInfo] {
        let comps = calendar.dateComponents([.year, .month], from: entry.date)
        guard let first = calendar.date(from: comps) else { return [] }
        let range = calendar.range(of: .day, in: .month, for: first) ?? 1..<2
        return range.map { d in
            let date = calendar.date(byAdding: .day, value: d - 1, to: first) ?? first
            let lc = chineseCalendar.dateComponents([.day], from: date)
            let ln = lunarDays[max(0, min(29, (lc.day ?? 1) - 1))]
            return DayInfo(day: d, lunar: ln, isToday: calendar.isDateInToday(date))
        }
    }
}
