import MapKit
import SwiftUI

nonisolated enum RouteMapDisplayMode: Sendable, Equatable {
    case preview
    case full
}

struct RouteMapInteraction {
    let mode: RouteMapDisplayMode
    let selectedSegmentID: String?
    let selectedStayID: String?
    let onSelectSegment: (String) -> Void
    let onSelectStay: (String) -> Void
    let classificationSavingSegmentID: String?
    let onUpdateClassification: (String, UserMovementClassification) -> Void
    let staySavingSegmentID: String?
    let onUpdateStay: (String, StayOverrideAction) -> Void
    let media: [MediaAssetReference]
    let thumbnailLoader: (any LoadMediaThumbnailUseCase)?
    let onSelectMedia: (String) -> Void
    let onTapEmpty: () -> Void
}

struct RouteMapView: UIViewRepresentable {
    let scene: MapScene
    let mode: RouteMapDisplayMode
    let selectedSegmentID: String?
    let selectedStayID: String?
    let onSelectSegment: (String) -> Void
    let onSelectStay: (String) -> Void
    let classificationSavingSegmentID: String?
    let onUpdateClassification: (String, UserMovementClassification) -> Void
    let staySavingSegmentID: String?
    let onUpdateStay: (String, StayOverrideAction) -> Void
    let media: [MediaAssetReference]
    let thumbnailLoader: (any LoadMediaThumbnailUseCase)?
    let onSelectMedia: (String) -> Void
    let onTapEmpty: () -> Void
    let userTrackingRequestID: Int

    init(
        scene: MapScene,
        mode: RouteMapDisplayMode,
        selectedSegmentID: String? = nil,
        selectedStayID: String? = nil,
        onSelectSegment: @escaping (String) -> Void = { _ in },
        onSelectStay: @escaping (String) -> Void = { _ in },
        classificationSavingSegmentID: String? = nil,
        onUpdateClassification: @escaping (String, UserMovementClassification) -> Void = { _, _ in },
        staySavingSegmentID: String? = nil,
        onUpdateStay: @escaping (String, StayOverrideAction) -> Void = { _, _ in },
        media: [MediaAssetReference] = [],
        thumbnailLoader: (any LoadMediaThumbnailUseCase)? = nil,
        onSelectMedia: @escaping (String) -> Void = { _ in },
        onTapEmpty: @escaping () -> Void = {},
        userTrackingRequestID: Int = 0
    ) {
        self.scene = scene
        self.mode = mode
        self.selectedSegmentID = selectedSegmentID
        self.selectedStayID = selectedStayID
        self.onSelectSegment = onSelectSegment
        self.onSelectStay = onSelectStay
        self.classificationSavingSegmentID = classificationSavingSegmentID
        self.onUpdateClassification = onUpdateClassification
        self.staySavingSegmentID = staySavingSegmentID
        self.onUpdateStay = onUpdateStay
        self.media = media
        self.thumbnailLoader = thumbnailLoader
        self.onSelectMedia = onSelectMedia
        self.onTapEmpty = onTapEmpty
        self.userTrackingRequestID = userTrackingRequestID
    }

    func makeCoordinator() -> RouteMapCoordinator {
        RouteMapCoordinator()
    }

    func makeUIView(context: Context) -> RouteMapContainerView {
        let container = RouteMapContainerView()
        let mapView = container.mapView
        mapView.delegate = context.coordinator
        configure(container)
        context.coordinator.configure(mapView: mapView, interaction: interaction)
        context.coordinator.update(scene: scene, in: mapView)
        container.applyUserTrackingRequest(userTrackingRequestID)
        return container
    }

    func updateUIView(_ container: RouteMapContainerView, context: Context) {
        let mapView = container.mapView
        configure(container)
        context.coordinator.configure(mapView: mapView, interaction: interaction)
        context.coordinator.update(scene: scene, in: mapView)
        container.applyUserTrackingRequest(userTrackingRequestID)
    }

    private func configure(_ container: RouteMapContainerView) {
        let mapView = container.mapView
        let isFull = mode == .full
        mapView.isAccessibilityElement = false
        mapView.accessibilityElementsHidden = false
        mapView.isScrollEnabled = isFull
        mapView.isZoomEnabled = isFull
        mapView.isRotateEnabled = isFull
        mapView.isPitchEnabled = isFull
        mapView.showsCompass = isFull
        mapView.showsUserLocation = isFull
        mapView.pointOfInterestFilter = .excludingAll
        container.setUserTrackingButtonVisible(isFull)
    }

    private var interaction: RouteMapInteraction {
        RouteMapInteraction(
            mode: mode,
            selectedSegmentID: selectedSegmentID,
            selectedStayID: selectedStayID,
            onSelectSegment: onSelectSegment,
            onSelectStay: onSelectStay,
            classificationSavingSegmentID: classificationSavingSegmentID,
            onUpdateClassification: onUpdateClassification,
            staySavingSegmentID: staySavingSegmentID,
            onUpdateStay: onUpdateStay,
            media: media,
            thumbnailLoader: thumbnailLoader,
            onSelectMedia: onSelectMedia,
            onTapEmpty: onTapEmpty
        )
    }
}

final class RouteMapContainerView: UIView {
    let mapView = MKMapView()
    private var userTrackingButton: MKUserTrackingButton?
    private var appliedUserTrackingRequestID = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        isAccessibilityElement = false
        mapView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(mapView)
        NSLayoutConstraint.activate([
            mapView.leadingAnchor.constraint(equalTo: leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: trailingAnchor),
            mapView.topAnchor.constraint(equalTo: topAnchor),
            mapView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        nil
    }

    func setUserTrackingButtonVisible(_ isVisible: Bool) {
        if isVisible, userTrackingButton == nil {
            let button = MKUserTrackingButton(mapView: mapView)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.backgroundColor = .secondarySystemBackground
            button.layer.cornerRadius = 22
            button.isAccessibilityElement = true
            button.accessibilityLabel = "現在地へ移動"
            button.accessibilityIdentifier = "map.currentLocation"
            addSubview(button)
            NSLayoutConstraint.activate([
                button.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -12),
                button.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -12),
                button.widthAnchor.constraint(greaterThanOrEqualToConstant: 44),
                button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
            ])
            userTrackingButton = button
        } else if !isVisible {
            userTrackingButton?.removeFromSuperview()
            userTrackingButton = nil
        }
    }

    func applyUserTrackingRequest(_ requestID: Int) {
        guard requestID != appliedUserTrackingRequestID else { return }
        appliedUserTrackingRequestID = requestID
        mapView.setUserTrackingMode(.follow, animated: true)
    }

    override func accessibilityElementCount() -> Int {
        accessibilityChildren.count
    }

    override func accessibilityElement(at index: Int) -> Any? {
        guard accessibilityChildren.indices.contains(index) else { return nil }
        return accessibilityChildren[index]
    }

    override func index(ofAccessibilityElement element: Any) -> Int {
        accessibilityChildren.firstIndex { ($0 as AnyObject) === (element as AnyObject) } ?? NSNotFound
    }

    private var accessibilityChildren: [UIView] {
        let annotationViews = mapView.annotations.compactMap { mapView.view(for: $0) }
        return [userTrackingButton].compactMap(\.self) + annotationViews
    }
}

final class RouteMapCoordinator: NSObject, MKMapViewDelegate {
    var renderedScene: MapScene?
    private weak var mapView: MKMapView?
    var selectedSegmentID: String?
    var selectedStayID: String?
    var onSelectSegment: (String) -> Void = { _ in }
    var onSelectStay: (String) -> Void = { _ in }
    var classificationSavingSegmentID: String?
    var onUpdateClassification: (String, UserMovementClassification) -> Void = { _, _ in }
    var staySavingSegmentID: String?
    var onUpdateStay: (String, StayOverrideAction) -> Void = { _, _ in }
    var onSelectMedia: (String) -> Void = { _ in }
    var mediaByIdentifier: [String: MediaAssetReference] = [:]
    var thumbnailLoader: (any LoadMediaThumbnailUseCase)?

    private var onTapEmpty: () -> Void = {}
    private var tapRecognizer: UITapGestureRecognizer?

    func configure(
        mapView: MKMapView,
        interaction: RouteMapInteraction
    ) {
        self.mapView = mapView
        onSelectSegment = interaction.onSelectSegment
        onSelectStay = interaction.onSelectStay
        classificationSavingSegmentID = interaction.classificationSavingSegmentID
        onUpdateClassification = interaction.onUpdateClassification
        staySavingSegmentID = interaction.staySavingSegmentID
        onUpdateStay = interaction.onUpdateStay
        onSelectMedia = interaction.onSelectMedia
        mediaByIdentifier = Dictionary(
            interaction.media.map { ($0.localIdentifier, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        thumbnailLoader = interaction.thumbnailLoader
        onTapEmpty = interaction.onTapEmpty
        if selectedSegmentID != interaction.selectedSegmentID {
            selectedSegmentID = interaction.selectedSegmentID
            mapView.overlays.forEach { mapView.renderer(for: $0)?.setNeedsDisplay() }
            updateLabelSelection(in: mapView)
            updateMovementCallout(in: mapView)
        }
        if selectedStayID != interaction.selectedStayID {
            selectedStayID = interaction.selectedStayID
            updateStaySelection(in: mapView)
            updateStayCallout(in: mapView)
        }
        if interaction.mode == .full, tapRecognizer == nil {
            let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
            recognizer.cancelsTouchesInView = false
            mapView.addGestureRecognizer(recognizer)
            tapRecognizer = recognizer
        } else if interaction.mode == .preview, let tapRecognizer {
            mapView.removeGestureRecognizer(tapRecognizer)
            self.tapRecognizer = nil
        }
        updateMovementCalloutConfiguration(in: mapView)
        updateStayCalloutConfiguration(in: mapView)
    }

    func update(scene: MapScene, in mapView: MKMapView) {
        guard renderedScene != scene else { return }
        renderedScene = scene
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)
        addPolylines(scene.polylines, to: mapView)
        addAnnotations(scene: scene, to: mapView)
        if let region = scene.initialRegion {
            mapView.setRegion(region.mapRegion, animated: false)
        }
    }

    func mapView(
        _: MKMapView,
        rendererFor overlay: any MKOverlay
    ) -> MKOverlayRenderer {
        guard let polyline = overlay as? MKPolyline else {
            return MKOverlayRenderer(overlay: overlay)
        }
        let renderer = MKPolylineRenderer(polyline: polyline)
        renderer.strokeColor = .systemRed
        renderer.lineWidth = polyline.title == selectedSegmentID ? 7 : 4
        renderer.lineJoin = .round
        renderer.lineCap = .round
        return renderer
    }

    @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
        guard let mapView else { return }
        let tapPoint = recognizer.location(in: mapView)
        let coordinate = mapView.convert(tapPoint, toCoordinateFrom: mapView)
        let mapPoint = MKMapPoint(coordinate)
        for overlay in mapView.overlays.reversed() {
            guard let polyline = overlay as? MKPolyline,
                  let renderer = mapView.renderer(for: polyline) as? MKPolylineRenderer
            else { continue }
            renderer.createPath()
            let rendererPoint = renderer.point(for: mapPoint)
            let hitPath = renderer.path?.copy(
                strokingWithWidth: 22,
                lineCap: .round,
                lineJoin: .round,
                miterLimit: 0
            )
            guard hitPath?.contains(rendererPoint) == true,
                  let stableID = polyline.title
            else { continue }
            onSelectSegment(stableID)
            return
        }
        onTapEmpty()
    }

    private func addPolylines(_ polylines: [MapPolyline], to mapView: MKMapView) {
        for value in polylines where value.coordinates.count >= 2 {
            let coordinates = value.coordinates.map(\.mapCoordinate)
            let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
            polyline.title = value.segmentStableID
            mapView.addOverlay(polyline)
        }
    }
}

extension RouteCoordinate {
    var mapCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

private extension MapRegion {
    var mapRegion: MKCoordinateRegion {
        MKCoordinateRegion(
            center: center.mapCoordinate,
            span: MKCoordinateSpan(
                latitudeDelta: latitudeDelta,
                longitudeDelta: longitudeDelta
            )
        )
    }
}
