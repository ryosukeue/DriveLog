@testable import DriveLog
import Foundation
import Testing

@Suite("Media eligibility evaluator")
struct MediaEligibilityEvaluatorTests {
    private let evaluator = DefaultMediaEligibilityEvaluator()

    @Test("accepts ordinary photos and videos", arguments: [MediaType.photo, .video])
    func acceptsOrdinaryMedia(mediaType: MediaType) {
        #expect(evaluator.evaluate(media(mediaType: mediaType)) == .eligible)
    }

    @Test("rejects screenshots")
    func rejectsScreenshot() {
        #expect(evaluator.evaluate(media(isScreenshot: true)) == .ineligible)
    }

    @Test("rejects screen recordings")
    func rejectsScreenRecording() {
        #expect(evaluator.evaluate(media(mediaType: .video, isScreenRecording: true)) == .ineligible)
    }

    @Test("rejects media without a creation date")
    func rejectsMissingCreationDate() {
        #expect(evaluator.evaluate(media(creationDate: nil)) == .ineligible)
    }

    @Test("any definite exclusion wins")
    func definiteExclusionWins() {
        #expect(evaluator.evaluate(media(
            creationDate: nil,
            isScreenshot: true,
            isScreenRecording: true
        )) == .ineligible)
    }

    private func media(
        mediaType: MediaType = .photo,
        creationDate: Date? = Date(timeIntervalSince1970: 1_700_000_000),
        isScreenshot: Bool = false,
        isScreenRecording: Bool = false
    ) -> MediaAssetReference {
        MediaAssetReference(
            localIdentifier: "origin-is-not-inferred",
            mediaType: mediaType,
            creationDate: creationDate,
            location: nil,
            durationSeconds: mediaType == .video ? 10 : nil,
            isScreenshot: isScreenshot,
            isScreenRecording: isScreenRecording
        )
    }
}
