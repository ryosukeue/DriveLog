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
            LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                summaryItem(
                    title: "総移動距離",
                    value: formatter.distance(meters: aggregate.totalDistanceMeters),
                    emphasized: true
                )
                summaryItem(
                    title: "総移動時間",
                    value: formatter.duration(seconds: aggregate.totalMovementDurationSeconds),
                    emphasized: true
                )
                summaryItem(title: "開始", value: formatter.time(aggregate.startDate))
                summaryItem(title: "終了", value: formatter.time(aggregate.endDate))
                summaryItem(title: "写真・動画", value: "\(aggregate.mediaCountCache)件")
            }
            if !vehicleDistances.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(vehicleDistances) { value in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(Color(hex: value.vehicle.colorHex))
                                .frame(width: 10, height: 10)
                            Text(value.vehicle.name)
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text(formatter.distance(meters: value.distanceMeters))
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .accessibilityIdentifier("dayDetail.summary.vehicles")
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
