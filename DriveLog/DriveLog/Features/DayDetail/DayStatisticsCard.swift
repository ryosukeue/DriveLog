import SwiftUI

struct DayStatisticsCard: View {
    let aggregate: DayAggregateData
    let formatter: DayDetailFormatter

    private let columns = [GridItem(.adaptive(minimum: 130), spacing: 12)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("詳細統計")
                .font(.headline)
            LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                statistic(title: "移動区間数", value: "\(aggregate.movementSegmentCount)件")
                statistic(title: "滞在地点数", value: "\(aggregate.staySegmentCount)件")
                statistic(
                    title: "総滞在時間",
                    value: formatter.duration(seconds: aggregate.totalStayDurationSeconds)
                )
                statistic(title: "記録点数", value: "\(aggregate.locationRecordCount)件")
                statistic(title: "除外位置点数", value: "\(aggregate.rejectedLocationCount)件")
                statistic(
                    title: "車っぽい移動時間",
                    value: formatter.duration(seconds: aggregate.automotiveDurationSeconds)
                )
                statistic(
                    title: "徒歩っぽい移動時間",
                    value: formatter.duration(seconds: aggregate.walkingDurationSeconds)
                )
            }
        }
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityIdentifier("dayDetail.statistics")
    }

    private func statistic(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
