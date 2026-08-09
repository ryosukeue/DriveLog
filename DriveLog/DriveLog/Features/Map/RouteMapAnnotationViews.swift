import MapKit

final class RouteMapPointAnnotation: NSObject, MKAnnotation {
    enum Kind {
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
    let mediaType: MediaType?
    let relatedStays: [MapStayAnnotation]

    init(
        id: String,
        coordinate: CLLocationCoordinate2D,
        kind: Kind,
        labelText: String? = nil,
        movement: MapMovementLabel? = nil,
        stay: MapStayAnnotation? = nil,
        mediaType: MediaType? = nil,
        relatedStays: [MapStayAnnotation] = []
    ) {
        self.id = id
        self.coordinate = coordinate
        self.kind = kind
        self.labelText = labelText
        self.movement = movement
        self.stay = stay
        self.mediaType = mediaType
        self.relatedStays = relatedStays
    }
}

class RouteMapMediaAnnotationView: MKAnnotationView {
    private let imageView = UIImageView()
    private let videoBadge = UIImageView(image: UIImage(systemName: "play.fill"))
    private let countLabel = UILabel()
    private let stayLabel = UILabel()
    private var representedIdentifier: String?
    private var accessibilityBaseLabel = "写真"
    private var thumbnailTask: Task<Void, Never>?
    private(set) var displayedCountText: String?
    private(set) var displayedStayText: String?
    private(set) var isStayEmphasized = true

    override init(annotation: (any MKAnnotation)?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        frame.size = CGSize(width: 104, height: 92)
        centerOffset = CGPoint(x: 0, y: -46)
        backgroundColor = .clear
        clipsToBounds = false

        imageView.frame = CGRect(x: 26, y: 0, width: 52, height: 52)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 9
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.borderWidth = 2
        imageView.layer.shadowColor = UIColor.black.cgColor
        imageView.layer.shadowOpacity = 0.25
        imageView.layer.shadowRadius = 3
        imageView.layer.shadowOffset = CGSize(width: 0, height: 2)
        addSubview(imageView)

        videoBadge.tintColor = .white
        videoBadge.backgroundColor = UIColor.black.withAlphaComponent(0.65)
        videoBadge.contentMode = .center
        videoBadge.layer.cornerRadius = 11
        videoBadge.frame = CGRect(x: 53, y: 27, width: 22, height: 22)
        addSubview(videoBadge)

        configurePill(countLabel, backgroundColor: .systemRed, textColor: .white)
        configurePill(
            stayLabel, backgroundColor: .secondarySystemBackground, textColor: .label
        )

        canShowCallout = false
        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityIdentifier = "map.mediaAnnotation"
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        nil
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailTask?.cancel()
        thumbnailTask = nil
        representedIdentifier = nil
        imageView.image = nil
        displayedCountText = nil
        displayedStayText = nil
        accessibilityBaseLabel = "写真"
        setStayEmphasized(true)
    }

    func configure(
        localIdentifier: String,
        mediaType: MediaType,
        memberCount: Int = 1,
        staySummary: String? = nil,
        thumbnailLoader: (any LoadMediaThumbnailUseCase)?
    ) {
        thumbnailTask?.cancel()
        representedIdentifier = localIdentifier
        imageView.image = UIImage(systemName: "photo")
        imageView.tintColor = .secondaryLabel
        videoBadge.isHidden = mediaType != .video
        displayedCountText = memberCount > 1 ? "\(memberCount)枚" : nil
        countLabel.text = displayedCountText
        countLabel.isHidden = displayedCountText == nil
        let kind = mediaType == .video ? "動画" : "写真"
        let countDescription = memberCount > 1 ? "、\(memberCount)件" : ""
        accessibilityBaseLabel = kind + countDescription
        setStaySummary(staySummary)
        guard let thumbnailLoader else { return }
        thumbnailTask = Task { @MainActor [weak self] in
            do {
                let image = try await thumbnailLoader.execute(
                    localIdentifier: localIdentifier,
                    targetSize: CGSize(width: 156, height: 156)
                )
                guard !Task.isCancelled,
                      self?.representedIdentifier == localIdentifier
                else { return }
                self?.imageView.image = image
            } catch is CancellationError {
                return
            } catch {
                guard self?.representedIdentifier == localIdentifier else { return }
                self?.imageView.image = UIImage(systemName: "photo.badge.exclamationmark")
            }
        }
    }

    func setStayEmphasized(_ isEmphasized: Bool) {
        isStayEmphasized = isEmphasized
        stayLabel.alpha = isEmphasized ? 1 : 0.22
    }

    func setStaySummary(_ summary: String?) {
        displayedStayText = summary
        stayLabel.text = summary
        stayLabel.isHidden = summary == nil
        setStayEmphasized(isStayEmphasized)
        layoutPills()
        accessibilityLabel = accessibilityBaseLabel + (summary.map { "、\($0)" } ?? "")
    }

    func setAccessibilityBaseLabel(_ label: String) {
        accessibilityBaseLabel = label
        setStaySummary(displayedStayText)
    }

    private func configurePill(
        _ label: UILabel,
        backgroundColor: UIColor,
        textColor: UIColor
    ) {
        label.font = .preferredFont(forTextStyle: .caption2)
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.textColor = textColor
        label.backgroundColor = backgroundColor
        label.layer.cornerRadius = 8
        label.layer.masksToBounds = true
        label.isHidden = true
        addSubview(label)
    }

    private func layoutPills() {
        var nextY: CGFloat = 54
        if !countLabel.isHidden {
            countLabel.frame = CGRect(x: 26, y: nextY, width: 52, height: 17)
            nextY += 19
        }
        if !stayLabel.isHidden {
            stayLabel.frame = CGRect(x: 2, y: nextY, width: 100, height: 18)
        }
    }
}

final class RouteMapMediaClusterAnnotationView: RouteMapMediaAnnotationView {
    override init(annotation: (any MKAnnotation)?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        canShowCallout = false
        displayPriority = .required
        collisionMode = .rectangle
        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityIdentifier = "map.mediaCluster"
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        nil
    }
}

class RouteMapStayAnnotationView: MKAnnotationView {
    private let label = UILabel()
    private(set) var displayedText: String?
    private(set) var isStayEmphasized = true

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
        displayedText = text
        label.text = text
        let width = max(52, label.intrinsicContentSize.width + 16)
        frame.size = CGSize(width: width, height: 44)
        label.frame = bounds
        updateBorderColor()
        label.layer.borderWidth = isSelected ? 4 : 1
        accessibilityLabel = text.hasPrefix("滞在") ? text : "滞在 \(text)"
        accessibilityIdentifier = "map.stayAnnotation"
    }

    func setStayEmphasized(_ isEmphasized: Bool) {
        isStayEmphasized = isEmphasized
        alpha = isEmphasized ? 1 : 0.22
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else {
            return
        }
        updateBorderColor()
    }

    private func updateBorderColor() {
        label.layer.borderColor = UIColor.label.resolvedColor(with: traitCollection).cgColor
    }
}

final class RouteMapStayClusterAnnotationView: RouteMapStayAnnotationView {
    override init(annotation: (any MKAnnotation)?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        displayPriority = .required
        collisionMode = .rectangle
        accessibilityIdentifier = "map.stayCluster"
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        nil
    }
}
