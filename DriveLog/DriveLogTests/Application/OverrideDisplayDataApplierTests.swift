@testable import DriveLog
import Foundation
import Testing

@Suite("Override display data applier")
struct OverrideDisplayDataApplierTests {
    private let applier = OverrideDisplayDataApplier()

    @Test("applies user classification without changing automatic values")
    func classification() throws {
        let scene = makeScene()

        let result = applier.apply(
            to: scene,
            movements: [movementDisplay(classification: .train)],
            stays: [stayDisplay(action: nil, automaticVisibility: true)]
        )

        let label = try #require(result.movementLabels.first)
        #expect(label.userClassification == .train)
        #expect(label.automaticClassification == .automotiveLike)
        #expect(result.polylines == scene.polylines)
        #expect(result.mediaAnnotations == scene.mediaAnnotations)
        #expect(result.initialRegion == scene.initialRegion)
    }

    @Test("missing classification remains unset")
    func noClassification() throws {
        let result = applier.apply(
            to: makeScene(),
            movements: [movementDisplay(classification: nil)],
            stays: []
        )

        #expect(try #require(result.movementLabels.first).userClassification == nil)
    }

    @Test("stay visibility follows override action", arguments: [
        (StayOverrideAction.confirm, false, true),
        (.hide, true, false),
        (.automatic, true, true),
        (.automatic, false, false)
    ])
    func stayAction(
        action: StayOverrideAction,
        automaticVisibility: Bool,
        expectedVisibility: Bool
    ) {
        let result = applier.apply(
            to: makeScene(),
            movements: [],
            stays: [stayDisplay(
                action: action,
                automaticVisibility: automaticVisibility
            )]
        )

        #expect(result.stayAnnotations.isEmpty == !expectedVisibility)
        if expectedVisibility {
            #expect(
                result.stayAnnotations.first?.isVisibleByAutomaticRule == automaticVisibility
            )
        }
    }

    @Test("stay without override follows its automatic visibility", arguments: [true, false])
    func automaticStay(automaticVisibility: Bool) {
        let result = applier.apply(
            to: makeScene(),
            movements: [],
            stays: [stayDisplay(action: nil, automaticVisibility: automaticVisibility)]
        )

        #expect(result.stayAnnotations.isEmpty == !automaticVisibility)
    }

    @Test("unknown display identifiers do not change scene values")
    func unknown() {
        let scene = makeScene()
        let unknownMovement = movementDisplay(id: "unknown", classification: .bus)
        let unknownStay = stayDisplay(id: "unknown", action: .hide, automaticVisibility: true)

        let result = applier.apply(
            to: scene,
            movements: [unknownMovement],
            stays: [unknownStay]
        )

        #expect(result == scene)
    }

    private func makeScene() -> MapScene {
        let date = Date(timeIntervalSince1970: 0)
        return MapScene(
            polylines: [MapPolyline(
                segmentStableID: "movement",
                coordinates: [RouteCoordinate(latitude: 35, longitude: 139)]
            )],
            movementLabels: [MapMovementLabel(
                segmentStableID: "movement",
                coordinate: RouteCoordinate(latitude: 35, longitude: 139),
                text: "1分・0.1km",
                startDate: date,
                endDate: date.addingTimeInterval(60),
                durationSeconds: 60,
                distanceMeters: 100,
                averageSpeedMetersPerSecond: 2,
                automaticClassification: .automotiveLike,
                userClassification: nil
            )],
            stayAnnotations: [MapStayAnnotation(
                stayStableID: "stay",
                coordinate: RouteCoordinate(latitude: 35, longitude: 139),
                text: "1分",
                arrivalDate: date,
                departureDate: date.addingTimeInterval(60),
                durationSeconds: 60,
                confidence: .medium,
                isVisibleByAutomaticRule: true
            )],
            mediaAnnotations: [MapMediaAnnotation(
                localIdentifier: "media",
                mediaType: .photo,
                coordinate: RouteCoordinate(latitude: 35, longitude: 139)
            )],
            initialRegion: MapRegion(
                center: RouteCoordinate(latitude: 35, longitude: 139),
                latitudeDelta: 0.01,
                longitudeDelta: 0.01
            )
        )
    }

    private func movementDisplay(
        id: String = "movement",
        classification: UserMovementClassification?
    ) -> MovementDisplayData {
        let date = Date(timeIntervalSince1970: 0)
        return MovementDisplayData(
            segment: MovementSegmentData(
                stableID: id,
                localDateKey: "1970-01-01",
                startDate: date,
                endDate: date.addingTimeInterval(60),
                distanceMeters: 100,
                durationSeconds: 60,
                estimatedAverageSpeedMetersPerSecond: 2,
                automaticClassification: .automotiveLike,
                classificationConfidence: .high,
                route: [],
                labelCoordinate: nil,
                sourceRawRevision: 1,
                generatedAt: date
            ),
            userClassification: classification
        )
    }

    private func stayDisplay(
        id: String = "stay",
        action: StayOverrideAction?,
        automaticVisibility: Bool
    ) -> StayDisplayData {
        let date = Date(timeIntervalSince1970: 0)
        return StayDisplayData(
            segment: StaySegmentData(
                stableID: id,
                localDateKey: "1970-01-01",
                representativeCoordinate: RouteCoordinate(latitude: 35, longitude: 139),
                estimatedArrivalDate: date,
                estimatedDepartureDate: date.addingTimeInterval(60),
                durationSeconds: 60,
                confidence: .medium,
                source: .combined,
                isVisibleByAutomaticRule: automaticVisibility,
                sourceRawRevision: 1,
                generatedAt: date
            ),
            overrideAction: action
        )
    }
}
