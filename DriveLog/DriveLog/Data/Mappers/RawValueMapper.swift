enum RawValueMapper {
    static func rawValue(for value: MotionConfidence) -> Int {
        switch value {
        case .low: 0
        case .medium: 1
        case .high: 2
        }
    }

    static func motionConfidence(from rawValue: Int) -> MotionConfidence {
        switch rawValue {
        case 1: .medium
        case 2: .high
        default: .low
        }
    }

    static func rawValue(for value: ProcessingStatus) -> String {
        switch value {
        case .pending: "pending"
        case .processing: "processing"
        case .completed: "completed"
        case .failed: "failed"
        }
    }

    static func processingStatus(from rawValue: String) -> ProcessingStatus {
        switch rawValue {
        case "processing": .processing
        case "completed": .completed
        case "failed": .failed
        default: .pending
        }
    }

    static func rawValue(for value: AutomaticMovementType) -> String {
        switch value {
        case .automotiveLike: "automotiveLike"
        case .walkingLike: "walkingLike"
        case .other: "other"
        }
    }

    static func automaticMovementType(from rawValue: String) -> AutomaticMovementType {
        switch rawValue {
        case "automotiveLike": .automotiveLike
        case "walkingLike": .walkingLike
        default: .other
        }
    }

    static func rawValue(for value: ClassificationConfidence) -> String {
        switch value {
        case .low: "low"
        case .medium: "medium"
        case .high: "high"
        }
    }

    static func classificationConfidence(from rawValue: String) -> ClassificationConfidence {
        switch rawValue {
        case "medium": .medium
        case "high": .high
        default: .low
        }
    }

    static func rawValue(for value: UserMovementClassification) -> String {
        switch value {
        case .automotive: "automotive"
        case .train: "train"
        case .bus: "bus"
        case .walking: "walking"
        case .other: "other"
        }
    }

    static func userClassification(from rawValue: String) -> UserMovementClassification {
        switch rawValue {
        case "automotive": .automotive
        case "train": .train
        case "bus": .bus
        case "walking": .walking
        default: .other
        }
    }

    static func rawValue(for value: StayConfidence) -> String {
        switch value {
        case .low: "low"
        case .medium: "medium"
        case .high: "high"
        }
    }

    static func stayConfidence(from rawValue: String) -> StayConfidence {
        switch rawValue {
        case "medium": .medium
        case "high": .high
        default: .low
        }
    }

    static func rawValue(for value: StayDetectionSource) -> String {
        switch value {
        case .visit: "visit"
        case .locationGap: "locationGap"
        case .motionTransition: "motionTransition"
        case .combined: "combined"
        }
    }

    static func staySource(from rawValue: String) -> StayDetectionSource {
        switch rawValue {
        case "visit": .visit
        case "motionTransition": .motionTransition
        case "combined": .combined
        default: .locationGap
        }
    }

    static func rawValue(for value: StayOverrideAction) -> String {
        switch value {
        case .confirm: "confirm"
        case .hide: "hide"
        case .automatic: "automatic"
        }
    }

    static func stayAction(from rawValue: String) -> StayOverrideAction {
        switch rawValue {
        case "confirm": .confirm
        case "hide": .hide
        default: .automatic
        }
    }

    static func rawValue(for value: MediaType) -> String {
        switch value {
        case .photo: "photo"
        case .video: "video"
        }
    }

    static func mediaType(from rawValue: String) -> MediaType {
        rawValue == "video" ? .video : .photo
    }

    static func rawValue(for value: MediaEligibility) -> String {
        switch value {
        case .eligible: "eligible"
        case .ineligible: "ineligible"
        }
    }

    static func mediaEligibility(from rawValue: String) -> MediaEligibility {
        rawValue == "eligible" ? .eligible : .ineligible
    }
}
