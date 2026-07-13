import MapKit
import SwiftUI

nonisolated enum RouteMapDisplayMode: Sendable, Equatable {
    case preview
    case full
}

struct RouteMapView: UIViewRepresentable {
    let scene: MapScene
    let mode: RouteMapDisplayMode
    let selectedSegmentID: String?
    let onSelectSegment: (String) -> Void
    let onTapEmpty: () -> Void

    init(
        scene: MapScene,
        mode: RouteMapDisplayMode,
        selectedSegmentID: String? = nil,
        onSelectSegment: @escaping (String) -> Void = { _ in },
        onTapEmpty: @escaping () -> Void = {}
    ) {
        self.scene = scene
        self.mode = mode
        self.selectedSegmentID = selectedSegmentID
        self.onSelectSegment = onSelectSegment
        self.onTapEmpty = onTapEmpty
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        configure(mapView)
        context.coordinator.configure(
            mapView: mapView,
            mode: mode,
            selectedSegmentID: selectedSegmentID,
            onSelectSegment: onSelectSegment,
            onTapEmpty: onTapEmpty
        )
        context.coordinator.update(scene: scene, in: mapView)
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        configure(mapView)
        context.coordinator.configure(
            mapView: mapView,
            mode: mode,
            selectedSegmentID: selectedSegmentID,
            onSelectSegment: onSelectSegment,
            onTapEmpty: onTapEmpty
        )
        context.coordinator.update(scene: scene, in: mapView)
    }

    private func configure(_ mapView: MKMapView) {
        let isFull = mode == .full
        mapView.isScrollEnabled = isFull
        mapView.isZoomEnabled = isFull
        mapView.isRotateEnabled = isFull
        mapView.isPitchEnabled = isFull
        mapView.showsCompass = false
        mapView.pointOfInterestFilter = .excludingAll
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        private var renderedScene: MapScene?
        private weak var mapView: MKMapView?
        private var selectedSegmentID: String?
        private var onSelectSegment: (String) -> Void = { _ in }
        private var onTapEmpty: () -> Void = {}
        private var tapRecognizer: UITapGestureRecognizer?

        func configure(
            mapView: MKMapView,
            mode: RouteMapDisplayMode,
            selectedSegmentID: String?,
            onSelectSegment: @escaping (String) -> Void,
            onTapEmpty: @escaping () -> Void
        ) {
            self.mapView = mapView
            self.onSelectSegment = onSelectSegment
            self.onTapEmpty = onTapEmpty
            if self.selectedSegmentID != selectedSegmentID {
                self.selectedSegmentID = selectedSegmentID
                mapView.overlays.forEach { mapView.renderer(for: $0)?.setNeedsDisplay() }
            }
            if mode == .full, tapRecognizer == nil {
                let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
                recognizer.cancelsTouchesInView = false
                mapView.addGestureRecognizer(recognizer)
                tapRecognizer = recognizer
            } else if mode == .preview, let tapRecognizer {
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

        func mapView(_ mapView: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
            guard let annotation = annotation as? RouteMapPointAnnotation else { return nil }
            let identifier = "RouteMapPointAnnotation"
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) ??
                MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.annotation = annotation
            view.canShowCallout = false
            if let marker = view as? MKMarkerAnnotationView {
                marker.markerTintColor = annotation.kind == .stay ? .systemRed : .systemBlue
                marker.glyphImage = UIImage(
                    systemName: annotation.kind == .stay ? "mappin" : "photo"
                )
            }
            return view
        }

        private func addPolylines(_ polylines: [MapPolyline], to mapView: MKMapView) {
            for value in polylines where value.coordinates.count >= 2 {
                let coordinates = value.coordinates.map(\.mapCoordinate)
                let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
                polyline.title = value.segmentStableID
                mapView.addOverlay(polyline)
            }
        }

        private func addAnnotations(scene: MapScene, to mapView: MKMapView) {
            let stays = scene.stayAnnotations.map {
                RouteMapPointAnnotation(
                    id: $0.stayStableID,
                    coordinate: $0.coordinate.mapCoordinate,
                    kind: .stay
                )
            }
            let media = scene.mediaAnnotations.map {
                RouteMapPointAnnotation(
                    id: $0.localIdentifier,
                    coordinate: $0.coordinate.mapCoordinate,
                    kind: .media
                )
            }
            mapView.addAnnotations(stays + media)
        }
    }
}

private final class RouteMapPointAnnotation: NSObject, MKAnnotation {
    enum Kind {
        case stay
        case media
    }

    let id: String
    let coordinate: CLLocationCoordinate2D
    let kind: Kind

    init(id: String, coordinate: CLLocationCoordinate2D, kind: Kind) {
        self.id = id
        self.coordinate = coordinate
        self.kind = kind
    }
}

private extension RouteCoordinate {
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
