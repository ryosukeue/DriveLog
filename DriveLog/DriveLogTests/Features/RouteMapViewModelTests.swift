@testable import DriveLog
import Foundation
import Testing

@MainActor
@Suite("Route map view model")
struct RouteMapViewModelTests {
    @Test("selects movement and stay exclusively")
    func exclusiveSelection() {
        let viewModel = RouteMapViewModel(scene: makeScene())

        viewModel.selectSegment(stableID: "movement")
        #expect(viewModel.selectedSegmentID == "movement")
        #expect(viewModel.selectedStayID == nil)

        viewModel.selectStay(stableID: "stay")
        #expect(viewModel.selectedSegmentID == nil)
        #expect(viewModel.selectedStayID == "stay")
    }

    @Test("ignores unknown identifiers")
    func unknown() {
        let viewModel = RouteMapViewModel(scene: makeScene())

        viewModel.selectSegment(stableID: "unknown")
        viewModel.selectStay(stableID: "unknown")

        #expect(viewModel.selectedSegmentID == nil)
        #expect(viewModel.selectedStayID == nil)
    }

    @Test("clears every selection on an empty map tap")
    func clear() {
        let viewModel = RouteMapViewModel(scene: makeScene())
        viewModel.selectSegment(stableID: "movement")

        viewModel.clearSelection()

        #expect(viewModel.selectedSegmentID == nil)
        #expect(viewModel.selectedStayID == nil)
    }

    @Test("resolves only located media represented by the scene")
    func visibleMedia() {
        let photo = makeMedia(id: "photo", type: .photo, hasLocation: true)
        let video = makeMedia(id: "video", type: .video, hasLocation: true)
        let locationless = makeMedia(id: "locationless", type: .photo, hasLocation: false)
        let unknown = makeMedia(id: "unknown", type: .photo, hasLocation: true)
        let viewModel = RouteMapViewModel(
            scene: makeScene(mediaIdentifiers: ["photo", "video", "locationless"]),
            media: [photo, video, locationless, unknown]
        )

        #expect(viewModel.visibleMedia == [photo, video])
        #expect(viewModel.media(localIdentifier: "photo") == photo)
        #expect(viewModel.media(localIdentifier: "video") == video)
        #expect(viewModel.media(localIdentifier: "locationless") == nil)
        #expect(viewModel.media(localIdentifier: "unknown") == nil)
    }
}

private func makeScene(mediaIdentifiers: [String] = []) -> MapScene {
    let date = Date(timeIntervalSince1970: 0)
    return MapScene(
        polylines: [],
        movementLabels: [
            MapMovementLabel(
                segmentStableID: "movement",
                coordinate: RouteCoordinate(latitude: 35, longitude: 139),
                text: "1分・0.1km",
                startDate: date,
                endDate: date.addingTimeInterval(60),
                durationSeconds: 60,
                distanceMeters: 100,
                averageSpeedMetersPerSecond: nil,
                automaticClassification: .other,
                userClassification: nil
            )
        ],
        stayAnnotations: [
            MapStayAnnotation(
                stayStableID: "stay",
                coordinate: RouteCoordinate(latitude: 35, longitude: 139),
                text: "1分",
                arrivalDate: date,
                departureDate: date.addingTimeInterval(60),
                durationSeconds: 60,
                confidence: .medium,
                isVisibleByAutomaticRule: true
            )
        ],
        mediaAnnotations: mediaIdentifiers.enumerated().map { index, identifier in
            MapMediaAnnotation(
                localIdentifier: identifier,
                coordinate: RouteCoordinate(latitude: 35 + Double(index), longitude: 139)
            )
        },
        initialRegion: nil
    )
}

@MainActor
private func makeMedia(id: String, type: MediaType, hasLocation: Bool) -> MediaAssetReference {
    MediaAssetReference(
        localIdentifier: id,
        mediaType: type,
        creationDate: Date(timeIntervalSince1970: 0),
        location: hasLocation ? RouteCoordinate(latitude: 35, longitude: 139) : nil,
        durationSeconds: type == .video ? 10 : nil,
        isScreenshot: false,
        isScreenRecording: false
    )
}
