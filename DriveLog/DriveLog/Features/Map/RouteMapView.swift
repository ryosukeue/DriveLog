import MapKit
import SwiftUI

nonisolated enum RouteMapDisplayMode: Sendable, Equatable {
    case preview
    case full
}

nonisolated struct MapPlaceSelection: Identifiable, Sendable, Equatable {
    let mediaIdentifiers: [String]
    let stayStableIDs: [String]

    var id: String {
        (mediaIdentifiers + ["|"] + stayStableIDs).joined(separator: ",")
    }
}

struct RouteMapInteraction {
    let mode: RouteMapDisplayMode
    let selectedSegmentID: String?
    let selectedStayID: String?
    let onSelectSegment: (String) -> Void
    let onSelectStay: (String) -> Void
    let staySavingSegmentID: String?
    let onUpdateStay: (String, StayOverrideAction) -> Void
    let media: [MediaAssetReference]
    let thumbnailLoader: (any LoadMediaThumbnailUseCase)?
    let onSelectMedia: (String) -> Void
    let onSelectPlace: (MapPlaceSelection) -> Void
    let onTapEmpty: () -> Void
}

struct RouteMapView: UIViewRepresentable {
    let scene: MapScene
    let mode: RouteMapDisplayMode
    let selectedSegmentID: String?
    let selectedStayID: String?
    let onSelectSegment: (String) -> Void
    let onSelectStay: (String) -> Void
    let staySavingSegmentID: String?
    let onUpdateStay: (String, StayOverrideAction) -> Void
    let media: [MediaAssetReference]
    let thumbnailLoader: (any LoadMediaThumbnailUseCase)?
    let onSelectMedia: (String) -> Void
    let onSelectPlace: (MapPlaceSelection) -> Void
    let onTapEmpty: () -> Void
    let userTrackingRequestID: Int

    init(
        scene: MapScene,
        mode: RouteMapDisplayMode,
        selectedSegmentID: String? = nil,
        selectedStayID: String? = nil,
        onSelectSegment: @escaping (String) -> Void = { _ in },
        onSelectStay: @escaping (String) -> Void = { _ in },
        staySavingSegmentID: String? = nil,
        onUpdateStay: @escaping (String, StayOverrideAction) -> Void = { _, _ in },
        media: [MediaAssetReference] = [],
        thumbnailLoader: (any LoadMediaThumbnailUseCase)? = nil,
        onSelectMedia: @escaping (String) -> Void = { _ in },
        onSelectPlace: @escaping (MapPlaceSelection) -> Void = { _ in },
        onTapEmpty: @escaping () -> Void = {},
        userTrackingRequestID: Int = 0
    ) {
        self.scene = scene
        self.mode = mode
        self.selectedSegmentID = selectedSegmentID
        self.selectedStayID = selectedStayID
        self.onSelectSegment = onSelectSegment
        self.onSelectStay = onSelectStay
        self.staySavingSegmentID = staySavingSegmentID
        self.onUpdateStay = onUpdateStay
        self.media = media
        self.thumbnailLoader = thumbnailLoader
        self.onSelectMedia = onSelectMedia
        self.onSelectPlace = onSelectPlace
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
        container.accessibilityIdentifier = isFull ? "map.route" : "map.preview"
        mapView.accessibilityIdentifier = container.accessibilityIdentifier
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
            staySavingSegmentID: staySavingSegmentID,
            onUpdateStay: onUpdateStay,
            media: media,
            thumbnailLoader: thumbnailLoader,
            onSelectMedia: onSelectMedia,
            onSelectPlace: onSelectPlace,
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

final class RouteMapCoordinator: NSObject, MKMapViewDelegate, UIGestureRecognizerDelegate {
    var renderedScene: MapScene?
    weak var mapView: MKMapView?
    var selectedSegmentID: String?
    var selectedStayID: String?
    var onSelectSegment: (String) -> Void = { _ in }
    var onSelectStay: (String) -> Void = { _ in }
    var staySavingSegmentID: String?
    var onUpdateStay: (String, StayOverrideAction) -> Void = { _, _ in }
    var onSelectMedia: (String) -> Void = { _ in }
    var onSelectPlace: (MapPlaceSelection) -> Void = { _ in }
    var mediaByIdentifier: [String: MediaAssetReference] = [:]
    var thumbnailLoader: (any LoadMediaThumbnailUseCase)?

    var onTapEmpty: () -> Void = {}
    var tapRecognizer: UITapGestureRecognizer?
    var navigationGestureRecognizerIDs: Set<ObjectIdentifier> = []
    var suppressesSelectionDuringNavigation = false
    var selectedSegmentAnchor: (id: String, coordinate: CLLocationCoordinate2D)?

    func configure(
        mapView: MKMapView,
        interaction: RouteMapInteraction
    ) {
        self.mapView = mapView
        onSelectSegment = interaction.onSelectSegment
        onSelectStay = interaction.onSelectStay
        staySavingSegmentID = interaction.staySavingSegmentID
        onUpdateStay = interaction.onUpdateStay
        onSelectMedia = interaction.onSelectMedia
        onSelectPlace = interaction.onSelectPlace
        mediaByIdentifier = Dictionary(
            interaction.media.map { ($0.localIdentifier, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        thumbnailLoader = interaction.thumbnailLoader
        onTapEmpty = interaction.onTapEmpty
        if selectedSegmentID != interaction.selectedSegmentID {
            if selectedSegmentAnchor?.id != interaction.selectedSegmentID {
                selectedSegmentAnchor = nil
            }
            selectedSegmentID = interaction.selectedSegmentID
            updatePolylineSelection(in: mapView)
            updateMovementCallout(in: mapView)
            updateStayEmphasis(in: mapView)
        }
        if selectedStayID != interaction.selectedStayID {
            selectedStayID = interaction.selectedStayID
            updateStaySelection(in: mapView)
            updateStayCallout(in: mapView)
        }
        if interaction.mode == .full, tapRecognizer == nil {
            let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
            recognizer.cancelsTouchesInView = false
            recognizer.delegate = self
            mapView.addGestureRecognizer(recognizer)
            prioritizeMapNavigationGestures(over: recognizer, in: mapView)
            tapRecognizer = recognizer
        } else if interaction.mode == .preview, let tapRecognizer {
            stopObservingMapNavigationGestures(in: mapView)
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
