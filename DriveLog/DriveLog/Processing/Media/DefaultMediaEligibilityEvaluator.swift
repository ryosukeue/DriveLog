struct DefaultMediaEligibilityEvaluator: MediaEligibilityEvaluating, Sendable {
    func evaluate(_ media: MediaAssetReference) -> MediaEligibility {
        guard media.creationDate != nil,
              media.isScreenshot == false,
              media.isScreenRecording == false
        else { return .ineligible }
        return .eligible
    }
}
