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
    let onTapEmpty: () -> Void
}

struct RouteMapView: UIViewRepresentable {
    let scene: MapScene
    let mode: RouteMapDisplayMode
    let selectedSegmentID: String?
    let selectedStayID: String?
    let onSelectSegment: (String) -> Void
    let onSelectStay: (String) -> Void
    let onTapEmpty: () -> Void

    init(
        scene: MapScene,
        mode: RouteMapDisplayMode,
        selectedSegmentID: String? = nil,
        selectedStayID: String? = nil,
        onSelectSegment: @escaping (String) -> Void = { _ in },
        onSelectStay: @escaping (String) -> Void = { _ in },
        onTapEmpty: @escaping () -> Void = {}
    ) {
        self.scene = scene
        self.mode = mode
        self.selectedSegmentID = selectedSegmentID
        self.selectedStayID = selectedStayID
        self.onSelectSegment = onSelectSegment
        self.onSelectStay = onSelectStay
        self.onTapEmpty = onTapEmpty
    }

    func makeCoordinator() -> RouteMapCoordinator {
        RouteMapCoordinator()
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        configure(mapView)
        context.coordinator.configure(mapView: mapView, interaction: interaction)
        context.coordinator.update(scene: scene, in: mapView)
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        configure(mapView)
        context.coordinator.configure(mapView: mapView, interaction: interaction)
        context.coordinator.update(scene: scene, in: mapView)
    }

    private func configure(_ mapView: MKMapView) {
        let isFull = mode == .full
        mapView.isScrollEnabled = isFull
        mapView.isZoomEnabled = isFull
        mapView.isRotateEnabled = isFull
        mapView.isPitchEnabled = isFull
        mapView.showsCompass = isFull
        mapView.showsUserLocation = isFull
        mapView.pointOfInterestFilter = .excludingAll
        configureUserTrackingButton(in: mapView, isVisible: isFull)
    }

    private func configureUserTrackingButton(in mapView: MKMapView, isVisible: Bool) {
        let tag = 7005
        if isVisible, mapView.viewWithTag(tag) == nil {
            let button = MKUserTrackingButton(mapView: mapView)
            button.tag = tag
            button.translatesAutoresizingMaskIntoConstraints = false
            button.backgroundColor = .secondarySystemBackground
            button.layer.cornerRadius = 22
            button.accessibilityLabel = "現在地へ移動"
            button.accessibilityIdentifier = "map.currentLocation"
            mapView.addSubview(button)
            NSLayoutConstraint.activate([
                button.trailingAnchor.constraint(equalTo: mapView.safeAreaLayoutGuide.trailingAnchor, constant: -12),
                button.bottomAnchor.constraint(equalTo: mapView.safeAreaLayoutGuide.bottomAnchor, constant: -12),
                button.widthAnchor.constraint(greaterThanOrEqualToConstant: 44),
                button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
            ])
        } else if !isVisible {
            mapView.viewWithTag(tag)?.removeFromSuperview()
        }
    }

    private var interaction: RouteMapInteraction {
        RouteMapInteraction(
            mode: mode,
            selectedSegmentID: selectedSegmentID,
            selectedStayID: selectedStayID,
            onSelectSegment: onSelectSegment,
            onSelectStay: onSelectStay,
            onTapEmpty: onTapEmpty
        )
    }
}

final class RouteMapCoordinator: NSObject, MKMapViewDelegate {
    var renderedScene: MapScene?
    private weak var mapView: MKMapView?
    var selectedSegmentID: String?
    var selectedStayID: String?
    var onSelectSegment: (String) -> Void = { _ in }
    var onSelectStay: (String) -> Void = { _ in }
    private var onTapEmpty: () -> Void = {}
    private var tapRecognizer: UITapGestureRecognizer?

    func configure(
        mapView: MKMapView,
        interaction: RouteMapInteraction
    ) {
        self.mapView = mapView
        onSelectSegment = interaction.onSelectSegment
        onSelectStay = interaction.onSelectStay
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
