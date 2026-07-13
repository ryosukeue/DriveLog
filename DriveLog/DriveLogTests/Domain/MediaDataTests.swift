@testable import DriveLog
import Foundation
import Testing

@Suite("Media data")
struct MediaDataTests {
    @Test("Media enums expose designed cases")
    func mediaEnums() {
        #expect(MediaType.photo != .video)
        #expect(MediaEligibility.eligible != .ineligible)
        requireSendable(MediaType.photo)
        requireSendable(MediaEligibility.eligible)
    }

    @Test("Media reference preserves metadata and optional location")
    func mediaReferencePreservesValues() {
        let reference = makeReference(location: nil)

        #expect(reference.mediaType == .video)
        #expect(reference.location == nil)
        #expect(reference.durationSeconds == 15)
        #expect(reference.isScreenRecording)
        #expect(reference == makeReference(location: nil))
        #expect(reference != makeReference(location: coordinate))
        requireSendable(reference)
    }

    @Test("Media placement preserves coordinate and related stable ID")
    func mediaPlacementPreservesValues() {
        let placement = MediaPlacement(
            assetIdentifier: "asset-id",
            coordinate: coordinate,
            relatedMovementStableID: "movement-id"
        )

        #expect(placement.relatedMovementStableID == "movement-id")
        #expect(placement != MediaPlacement(
            assetIdentifier: "asset-id",
            coordinate: coordinate,
            relatedMovementStableID: nil
        ))
        requireSendable(placement)
    }

    private var coordinate: RouteCoordinate {
        RouteCoordinate(latitude: 35.0, longitude: 139.0)
    }

    private func makeReference(location: RouteCoordinate?) -> MediaAssetReference {
        MediaAssetReference(
            localIdentifier: "asset-id",
            mediaType: .video,
            creationDate: Date(timeIntervalSince1970: 1_700_000_000),
            location: location,
            durationSeconds: 15,
            isScreenshot: false,
            isScreenRecording: true
        )
    }

    private func requireSendable(_: some Sendable) {}
}
