import MapKit

final class RouteMapPointAnnotation: NSObject, MKAnnotation {
    enum Kind {
        case movementLabel
        case movementCallout
        case stay
        case stayCallout
        case media
    }

    let id: String
    let coordinate: CLLocationCoordinate2D
    let kind: Kind
    let labelText: String?
    let movement: MapMovementLabel?
    let stay: MapStayAnnotation?

    init(
        id: String,
        coordinate: CLLocationCoordinate2D,
        kind: Kind,
        labelText: String? = nil,
        movement: MapMovementLabel? = nil,
        stay: MapStayAnnotation? = nil
    ) {
        self.id = id
        self.coordinate = coordinate
        self.kind = kind
        self.labelText = labelText
        self.movement = movement
        self.stay = stay
    }
}

final class RouteMapStayCalloutView: MKAnnotationView {
    private let label = UILabel()

    override init(annotation: (any MKAnnotation)?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .label
        label.backgroundColor = .secondarySystemBackground
        label.numberOfLines = 0
        label.layer.cornerRadius = 12
        label.layer.masksToBounds = true
        label.layer.borderColor = UIColor.systemRed.cgColor
        label.layer.borderWidth = 2
        addSubview(label)
        canShowCallout = false
        centerOffset = CGPoint(x: 0, y: -70)
        isAccessibilityElement = true
        accessibilityTraits = .button
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        nil
    }

    func configure(stay: MapStayAnnotation, formatter: DayDetailFormatter) {
        let values = [
            "到着 \(formatter.time(stay.arrivalDate))",
            "出発 \(formatter.time(stay.departureDate))",
            "滞在 \(formatter.duration(seconds: stay.durationSeconds))",
            "信頼度 \(formatter.stayConfidence(stay.confidence))",
            stay.isVisibleByAutomaticRule ? "自動判定 表示" : "自動判定 非表示"
        ]
        label.text = "  \(values.joined(separator: "\n"))  "
        frame.size = CGSize(width: 175, height: 125)
        label.frame = bounds
        accessibilityLabel = values.joined(separator: "、")
        accessibilityIdentifier = "map.stayCallout"
    }
}

final class RouteMapMovementCalloutView: MKAnnotationView {
    private let label = UILabel()

    override init(annotation: (any MKAnnotation)?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .label
        label.backgroundColor = .secondarySystemBackground
        label.numberOfLines = 0
        label.layer.cornerRadius = 12
        label.layer.masksToBounds = true
        label.layer.borderColor = UIColor.systemRed.cgColor
        label.layer.borderWidth = 2
        addSubview(label)
        canShowCallout = false
        centerOffset = CGPoint(x: 0, y: -85)
        isAccessibilityElement = true
        accessibilityTraits = .button
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        nil
    }

    func configure(movement: MapMovementLabel, formatter: DayDetailFormatter) {
        let timeRange = "\(formatter.time(movement.startDate))–\(formatter.time(movement.endDate))"
        let values = [
            timeRange,
            formatter.duration(seconds: movement.durationSeconds),
            formatter.distance(meters: movement.distanceMeters),
            "平均 \(formatter.averageSpeed(metersPerSecond: movement.averageSpeedMetersPerSecond))",
            formatter.classification(movement.automaticClassification),
            "ユーザー分類 \(formatter.classification(movement.userClassification))"
        ]
        label.text = "  \(values.joined(separator: "\n"))  "
        frame.size = CGSize(width: 190, height: 150)
        label.frame = bounds
        accessibilityLabel = values.joined(separator: "、")
        accessibilityIdentifier = "map.movementCallout"
    }
}

final class RouteMapLabelAnnotationView: MKAnnotationView {
    private let label = UILabel()

    override init(annotation: (any MKAnnotation)?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .label
        label.backgroundColor = .secondarySystemBackground
        label.textAlignment = .center
        label.layer.cornerRadius = 8
        label.layer.masksToBounds = true
        addSubview(label)
        canShowCallout = false
        isAccessibilityElement = true
        accessibilityTraits = .button
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        nil
    }

    func configure(text: String, isSelected: Bool) {
        label.text = "  \(text)  "
        label.sizeToFit()
        frame.size = CGSize(
            width: max(44, label.bounds.width),
            height: max(32, label.bounds.height + 8)
        )
        label.frame = bounds
        label.layer.borderColor = UIColor.systemRed.cgColor
        label.layer.borderWidth = isSelected ? 3 : 1
        accessibilityLabel = "移動区間 \(text)"
        accessibilityIdentifier = "map.movementLabel"
    }
}

final class RouteMapStayAnnotationView: MKAnnotationView {
    private let label = UILabel()

    override init(annotation: (any MKAnnotation)?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .white
        label.backgroundColor = .systemRed
        label.textAlignment = .center
        label.layer.cornerRadius = 22
        label.layer.masksToBounds = true
        addSubview(label)
        canShowCallout = false
        isAccessibilityElement = true
        accessibilityTraits = .button
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        nil
    }

    func configure(text: String, isSelected: Bool) {
        label.text = text
        let width = max(52, label.intrinsicContentSize.width + 16)
        frame.size = CGSize(width: width, height: 44)
        label.frame = bounds
        label.layer.borderColor = UIColor.label.cgColor
        label.layer.borderWidth = isSelected ? 4 : 1
        accessibilityLabel = "滞在 \(text)"
        accessibilityIdentifier = "map.stayAnnotation"
    }
}
