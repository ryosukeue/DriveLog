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

    @Test("classification update persists and updates only the user value")
    func classificationSuccess() async throws {
        let useCase = ClassificationUseCaseSpy()
        let movement = makeMovementDisplay()
        let viewModel = RouteMapViewModel(
            scene: makeScene(),
            movements: [movement],
            updateClassification: useCase
        )

        await viewModel.updateClassification(stableID: "movement", classification: .train)

        let call = try #require(await useCase.calls.first)
        #expect(call.stableID == "movement")
        #expect(call.classification == .train)
        let label = try #require(viewModel.scene.movementLabels.first)
        #expect(label.userClassification == .train)
        #expect(label.automaticClassification == .other)
        #expect(viewModel.classificationSavingSegmentID == nil)
        #expect(viewModel.classificationUpdateFailed == false)
    }

    @Test("classification failure keeps the display and exposes dismissible error")
    func classificationFailure() async throws {
        let useCase = ClassificationUseCaseSpy(error: .persistenceFailure(code: "update"))
        let viewModel = RouteMapViewModel(
            scene: makeScene(),
            movements: [makeMovementDisplay()],
            updateClassification: useCase
        )

        await viewModel.updateClassification(stableID: "movement", classification: .bus)

        #expect(try #require(viewModel.scene.movementLabels.first).userClassification == nil)
        #expect(viewModel.classificationUpdateFailed)
        viewModel.dismissClassificationError()
        #expect(viewModel.classificationUpdateFailed == false)
    }

    @Test("classification ignores an unknown segment")
    func classificationUnknown() async {
        let useCase = ClassificationUseCaseSpy()
        let viewModel = RouteMapViewModel(
            scene: makeScene(),
            movements: [makeMovementDisplay()],
            updateClassification: useCase
        )

        await viewModel.updateClassification(stableID: "unknown", classification: .other)

        #expect(await useCase.calls.isEmpty)
    }

    @Test("classification ignores repeated input while saving")
    func classificationDuplicate() async {
        let useCase = SuspendedClassificationUseCase()
        let viewModel = RouteMapViewModel(
            scene: makeScene(),
            movements: [makeMovementDisplay()],
            updateClassification: useCase
        )
        let firstUpdate = Task {
            await viewModel.updateClassification(stableID: "movement", classification: .train)
        }
        while await useCase.isSuspended == false {
            await Task.yield()
        }

        #expect(viewModel.classificationSavingSegmentID == "movement")
        await viewModel.updateClassification(stableID: "movement", classification: .bus)
        #expect(await useCase.callCount == 1)

        await useCase.resume()
        await firstUpdate.value
        #expect(viewModel.classificationSavingSegmentID == nil)
        #expect(viewModel.scene.movementLabels.first?.userClassification == .train)
    }

    @Test("stay confirm persists and remains visible")
    func stayConfirm() async throws {
        let useCase = StayUseCaseSpy()
        let viewModel = makeStayViewModel(useCase: useCase, automaticVisibility: false)
        viewModel.selectStay(stableID: "stay")

        await viewModel.updateStay(stableID: "stay", action: .confirm)

        let call = try #require(await useCase.calls.first)
        #expect(call.stableID == "stay")
        #expect(call.action == .confirm)
        #expect(viewModel.scene.stayAnnotations.map(\.stayStableID) == ["stay"])
        #expect(viewModel.scene.stayAnnotations.first?.isVisibleByAutomaticRule == false)
        #expect(viewModel.selectedStayID == "stay")
    }

    @Test("stay hide removes the annotation and closes selection")
    func stayHide() async {
        let useCase = StayUseCaseSpy()
        let viewModel = makeStayViewModel(useCase: useCase)
        viewModel.selectStay(stableID: "stay")

        await viewModel.updateStay(stableID: "stay", action: .hide)

        #expect(viewModel.scene.stayAnnotations.isEmpty)
        #expect(viewModel.selectedStayID == nil)
    }

    @Test("stay automatic restores its original visibility", arguments: [true, false])
    func stayAutomatic(automaticVisibility: Bool) async {
        let useCase = StayUseCaseSpy()
        let viewModel = makeStayViewModel(
            useCase: useCase,
            automaticVisibility: automaticVisibility
        )
        viewModel.selectStay(stableID: "stay")

        await viewModel.updateStay(stableID: "stay", action: .automatic)

        #expect(viewModel.scene.stayAnnotations.isEmpty == !automaticVisibility)
        #expect((viewModel.selectedStayID != nil) == automaticVisibility)
    }

    @Test("stay failure keeps the annotation and exposes dismissible error")
    func stayFailure() async {
        let useCase = StayUseCaseSpy(error: .persistenceFailure(code: "update"))
        let viewModel = makeStayViewModel(useCase: useCase)
        viewModel.selectStay(stableID: "stay")

        await viewModel.updateStay(stableID: "stay", action: .hide)

        #expect(viewModel.scene.stayAnnotations.count == 1)
        #expect(viewModel.selectedStayID == "stay")
        #expect(viewModel.stayUpdateFailed)
        viewModel.dismissStayError()
        #expect(viewModel.stayUpdateFailed == false)
    }

    @Test("stay ignores repeated input while saving")
    func stayDuplicate() async {
        let useCase = SuspendedStayUseCase()
        let viewModel = makeStayViewModel(useCase: useCase)
        let firstUpdate = Task {
            await viewModel.updateStay(stableID: "stay", action: .confirm)
        }
        while await useCase.isSuspended == false {
            await Task.yield()
        }

        #expect(viewModel.staySavingSegmentID == "stay")
        await viewModel.updateStay(stableID: "stay", action: .hide)
        #expect(await useCase.callCount == 1)

        await useCase.resume()
        await firstUpdate.value
        #expect(viewModel.staySavingSegmentID == nil)
        #expect(viewModel.scene.stayAnnotations.count == 1)
    }

    private func makeStayViewModel(
        useCase: any UpdateStayOverrideUseCase,
        automaticVisibility: Bool = true
    ) -> RouteMapViewModel {
        RouteMapViewModel(
            scene: makeScene(),
            stays: [makeStayDisplay(automaticVisibility: automaticVisibility)],
            updateStayOverride: useCase
        )
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

private func makeMovementDisplay() -> MovementDisplayData {
    let date = Date(timeIntervalSince1970: 0)
    return MovementDisplayData(
        segment: MovementSegmentData(
            stableID: "movement",
            localDateKey: "1970-01-01",
            startDate: date,
            endDate: date.addingTimeInterval(60),
            distanceMeters: 100,
            durationSeconds: 60,
            estimatedAverageSpeedMetersPerSecond: nil,
            automaticClassification: .other,
            classificationConfidence: .low,
            route: [],
            labelCoordinate: nil,
            sourceRawRevision: 1,
            generatedAt: date
        ),
        userClassification: nil
    )
}

private func makeStayDisplay(automaticVisibility: Bool) -> StayDisplayData {
    let date = Date(timeIntervalSince1970: 0)
    return StayDisplayData(
        segment: StaySegmentData(
            stableID: "stay",
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
        overrideAction: automaticVisibility ? nil : .confirm
    )
}

private actor ClassificationUseCaseSpy: UpdateClassificationUseCase {
    struct Call: Sendable {
        let stableID: String
        let classification: UserMovementClassification
    }

    private(set) var calls: [Call] = []
    private let error: DriveLogError?

    init(error: DriveLogError? = nil) {
        self.error = error
    }

    func execute(
        segment: MovementSegmentData,
        classification: UserMovementClassification
    ) throws {
        calls.append(Call(stableID: segment.stableID, classification: classification))
        if let error {
            throw error
        }
    }
}

private actor SuspendedClassificationUseCase: UpdateClassificationUseCase {
    private(set) var callCount = 0
    private(set) var isSuspended = false
    private var continuation: CheckedContinuation<Void, Never>?

    func execute(
        segment _: MovementSegmentData,
        classification _: UserMovementClassification
    ) async {
        callCount += 1
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            isSuspended = true
        }
    }

    func resume() {
        continuation?.resume()
        continuation = nil
        isSuspended = false
    }
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
