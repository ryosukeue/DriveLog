nonisolated protocol LocalDayBoundarySplitting: Sendable {
    func split(rawEvents: RawDayEvents) -> [String: RawDayEvents]
}

nonisolated struct LocalDayBoundarySplitter: LocalDayBoundarySplitting {
    func split(rawEvents: RawDayEvents) -> [String: RawDayEvents] {
        var buckets: [String: DayBucket] = [:]

        for location in rawEvents.locations {
            buckets[location.localDateKey, default: DayBucket()].locations.append(location)
        }
        for motion in rawEvents.motions {
            buckets[motion.localDateKey, default: DayBucket()].motions.append(motion)
        }
        for visit in rawEvents.visits {
            buckets[visit.localDateKey, default: DayBucket()].visits.append(visit)
        }
        for classificationOverride in rawEvents.classificationOverrides {
            buckets[classificationOverride.localDateKey, default: DayBucket()]
                .classificationOverrides.append(classificationOverride)
        }
        for stayOverride in rawEvents.stayOverrides {
            buckets[stayOverride.localDateKey, default: DayBucket()].stayOverrides.append(stayOverride)
        }

        return buckets.mapValues(\.rawEvents)
    }
}

private nonisolated struct DayBucket {
    var locations: [LocationEventData] = []
    var motions: [MotionEventData] = []
    var visits: [VisitEventData] = []
    var classificationOverrides: [ClassificationOverrideData] = []
    var stayOverrides: [StayOverrideData] = []

    var rawEvents: RawDayEvents {
        RawDayEvents(
            locations: locations,
            motions: motions,
            visits: visits,
            classificationOverrides: classificationOverrides,
            stayOverrides: stayOverrides
        )
    }
}
