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
}

private func makeScene() -> MapScene {
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
        mediaAnnotations: [],
        initialRegion: nil
    )
}
