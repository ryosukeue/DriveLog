import MapKit
import SwiftUI

struct DayMapPreview: View {
    let scene: MapScene
    let onOpenMap: () -> Void

    var body: some View {
        Button(action: onOpenMap) {
            Map(initialPosition: cameraPosition, interactionModes: []) {
                ForEach(scene.polylines, id: \.segmentStableID) { polyline in
                    MapKit.MapPolyline(coordinates: polyline.coordinates.map(\.mapCoordinate))
                        .stroke(Color.accentColor, lineWidth: 4)
                }
                ForEach(scene.stayAnnotations, id: \.stayStableID) { stay in
                    Marker("滞在", coordinate: stay.coordinate.mapCoordinate)
                        .tint(.red)
                }
            }
            .allowsHitTesting(false)
            .overlay(alignment: .bottomTrailing) {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.body.weight(.semibold))
                    .padding(10)
                    .background(.regularMaterial, in: Circle())
                    .padding(12)
                    .accessibilityHidden(true)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("全画面地図を開く")
        .accessibilityIdentifier("dayDetail.mapPreview")
    }

    private var cameraPosition: MapCameraPosition {
        guard let region = scene.initialRegion else { return .automatic }
        return .region(
            MKCoordinateRegion(
                center: region.center.mapCoordinate,
                span: MKCoordinateSpan(
                    latitudeDelta: region.latitudeDelta,
                    longitudeDelta: region.longitudeDelta
                )
            )
        )
    }
}

private extension RouteCoordinate {
    var mapCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
