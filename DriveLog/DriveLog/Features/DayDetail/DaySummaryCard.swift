import SwiftUI

struct DaySummaryCard: View {
    let aggregate: DayAggregateData
    let vehicleDistances: [VehicleDistanceSummary]
    let formatter: DayDetailFormatter

    private let columns = [GridItem(.adaptive(minimum: 130), spacing: 12)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("移動")
                .font(.headline)
            summaryItem(
                title: "総移動距離",
                value: formatter.distance(meters: aggregate.totalDistanceMeters),
                emphasized: true
            )
            if !vehicleDistances.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(vehicleDistances) { value in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color(hex: value.vehicle.colorHex))
                                    .frame(width: 12, height: 12)
                                Text(value.vehicle.name)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Text(formatter.distance(meters: value.distanceMeters))
                                .font(.title2.bold().monospacedDigit())
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityElement(children: .combine)
                    }
                }
                .accessibilityIdentifier("dayDetail.summary.vehicles")
            }
            LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                summaryItem(
                    title: "総移動時間",
                    value: formatter.duration(seconds: aggregate.totalMovementDurationSeconds),
                    emphasized: true
                )
                summaryItem(title: "開始", value: formatter.time(aggregate.startDate))
                summaryItem(title: "終了", value: formatter.time(aggregate.endDate))
                summaryItem(title: "写真・動画", value: "\(aggregate.mediaCountCache)件")
            }
        }
        .accessibilityIdentifier("dayDetail.summary")
    }

    private func summaryItem(title: String, value: String, emphasized: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(emphasized ? .title2.bold() : .body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
