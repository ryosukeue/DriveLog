import MapKit
import UIKit

final class RouteMapStayCalloutView: MKAnnotationView {
    private let metricsView = RouteMapMetricsView()

    private(set) var displayedItems: [String] = []

    override init(annotation: (any MKAnnotation)?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        frame.size = CGSize(width: 300, height: RouteMapMetricsView.preferredHeight)
        centerOffset = CGPoint(x: 0, y: -58)
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.16
        layer.shadowRadius = 10
        layer.shadowOffset = CGSize(width: 0, height: 4)

        metricsView.frame = CGRect(
            x: 0, y: 0, width: bounds.width, height: RouteMapMetricsView.preferredHeight
        )
        metricsView.autoresizingMask = [.flexibleWidth]
        metricsView.isAccessibilityElement = true
        metricsView.accessibilityTraits = .staticText
        metricsView.accessibilityIdentifier = "map.stayCallout"
        addSubview(metricsView)

        canShowCallout = false
        displayPriority = .required
        zPriority = .max
        collisionMode = .rectangle
        isAccessibilityElement = false
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        nil
    }

    func configure(
        stay: MapStayAnnotation,
        formatter: DayDetailFormatter
    ) {
        let values = [
            formatter.duration(seconds: stay.durationSeconds),
            formatter.time(stay.arrivalDate),
            formatter.time(stay.departureDate)
        ]
        displayedItems = [
            "滞在時間 \(values[0])",
            "到着 \(values[1])",
            "出発 \(values[2])"
        ]
        metricsView.configure(items: [
            ("滞在時間", values[0]),
            ("到着", values[1]),
            ("出発", values[2])
        ])
    }
}
