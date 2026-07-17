import MapKit
import UIKit

final class RouteMapMovementCalloutView: MKAnnotationView {
    private let metricsView = RouteMapMetricsView()

    private(set) var displayedItems: [String] = []

    override init(annotation: (any MKAnnotation)?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        frame.size = CGSize(width: 344, height: RouteMapMetricsView.preferredHeight)
        centerOffset = CGPoint(x: 0, y: -58)
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.16
        layer.shadowRadius = 10
        layer.shadowOffset = CGSize(width: 0, height: 4)

        metricsView.frame = bounds
        metricsView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(metricsView)

        canShowCallout = false
        displayPriority = .required
        zPriority = .max
        collisionMode = .rectangle
        isAccessibilityElement = true
        accessibilityTraits = .staticText
        accessibilityIdentifier = "map.movementCallout"
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        nil
    }

    func configure(
        movement: MapMovementLabel,
        formatter: DayDetailFormatter
    ) {
        let values = [
            formatter.duration(seconds: movement.durationSeconds),
            formatter.time(movement.startDate),
            formatter.time(movement.endDate),
            formatter.averageSpeed(metersPerSecond: movement.averageSpeedMetersPerSecond)
        ]
        displayedItems = [
            "所要時間 \(values[0])",
            "開始 \(values[1])",
            "終了 \(values[2])",
            "平均速度 \(values[3])"
        ]
        metricsView.configure(items: [
            ("所要時間", values[0]),
            ("開始", values[1]),
            ("終了", values[2]),
            ("平均速度", values[3])
        ])
        accessibilityLabel = displayedItems.joined(separator: "、")
    }
}
