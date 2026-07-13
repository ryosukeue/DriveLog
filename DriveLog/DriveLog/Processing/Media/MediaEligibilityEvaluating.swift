protocol MediaEligibilityEvaluating: Sendable {
    func evaluate(_ media: MediaAssetReference) -> MediaEligibility
}
