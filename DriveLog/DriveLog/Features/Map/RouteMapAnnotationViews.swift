import MapKit

final class RouteMapPointAnnotation: NSObject, MKAnnotation {
    enum Kind {
        case movementLabel
        case stay
        case media
    }

    let id: String
    let coordinate: CLLocationCoordinate2D
    let kind: Kind
    let labelText: String?

    init(
        id: String,
        coordinate: CLLocationCoordinate2D,
        kind: Kind,
        labelText: String? = nil
    ) {
        self.id = id
        self.coordinate = coordinate
        self.kind = kind
        self.labelText = labelText
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
