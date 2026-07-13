import Foundation
import SwiftData

extension PersistenceActor {
    func saveLocationEvent(_ event: LocationEventData) throws -> RawEventSaveResult {
        let localDateKey = event.localDateKey
        let descriptor = FetchDescriptor<LocationEventModel>(
            predicate: #Predicate { $0.localDateKey == localDateKey }
        )
        let locations = try modelContext.fetch(descriptor)
        let duplicate = locations
            .filter { abs($0.timestamp.timeIntervalSince(event.timestamp)) <= 30 }
            .filter {
                Self.distanceMeters(
                    latitude: $0.latitude,
                    longitude: $0.longitude,
                    otherLatitude: event.latitude,
                    otherLongitude: event.longitude
                ) <= 10
            }
            .min { Self.precedes($0, $1) }

        if let duplicate {
            guard Self.shouldReplace(duplicate, with: event) else {
                return .duplicateIgnored
            }
            Self.update(duplicate, with: event)
            try incrementRawRevision(for: event.localDateKey, updatedAt: event.createdAt)
            try modelContext.save()
            return .updated
        }

        modelContext.insert(
            LocationEventModel(
                latitude: event.latitude, longitude: event.longitude,
                timestamp: event.timestamp, horizontalAccuracy: event.horizontalAccuracy,
                speedMetersPerSecond: event.speedMetersPerSecond, createdAt: event.createdAt,
                timeZoneIdentifier: event.timeZoneIdentifier,
                utcOffsetSeconds: event.utcOffsetSeconds, localDateKey: event.localDateKey,
                deduplicationKey: Self.deduplicationKey(for: event)
            )
        )
        try incrementRawRevision(for: event.localDateKey, updatedAt: event.createdAt)
        try modelContext.save()
        return .inserted
    }

    func locationEvents(for localDateKey: String) throws -> [LocationEventData] {
        let descriptor = FetchDescriptor<LocationEventModel>(
            predicate: #Predicate { $0.localDateKey == localDateKey },
            sortBy: [SortDescriptor(\LocationEventModel.timestamp)]
        )
        return try modelContext.fetch(descriptor).map {
            LocationEventData(
                latitude: $0.latitude, longitude: $0.longitude, timestamp: $0.timestamp,
                horizontalAccuracy: $0.horizontalAccuracy,
                speedMetersPerSecond: $0.speedMetersPerSecond, createdAt: $0.createdAt,
                timeZoneIdentifier: $0.timeZoneIdentifier,
                utcOffsetSeconds: $0.utcOffsetSeconds, localDateKey: $0.localDateKey
            )
        }
    }

    func incrementRawRevision(for localDateKey: String, updatedAt: Date) throws {
        var descriptor = FetchDescriptor<DayProcessingStateModel>(
            predicate: #Predicate { $0.localDateKey == localDateKey }
        )
        descriptor.fetchLimit = 1
        if let state = try modelContext.fetch(descriptor).first {
            state.rawRevision += 1
            state.statusRawValue = "pending"
            state.updatedAt = max(state.updatedAt, updatedAt)
        } else {
            modelContext.insert(
                DayProcessingStateModel(
                    localDateKey: localDateKey, rawRevision: 1, processedRevision: 0,
                    statusRawValue: "pending",
                    lastAttemptDate: nil, lastSuccessfulDate: nil, lastErrorCode: nil,
                    updatedAt: updatedAt
                )
            )
        }
    }

    private static func shouldReplace(
        _ existing: LocationEventModel,
        with incoming: LocationEventData
    ) -> Bool {
        if incoming.horizontalAccuracy != existing.horizontalAccuracy {
            return incoming.horizontalAccuracy < existing.horizontalAccuracy
        }
        if incoming.timestamp != existing.timestamp {
            return incoming.timestamp > existing.timestamp
        }
        return incoming.createdAt < existing.createdAt
    }

    private static func precedes(
        _ first: LocationEventModel,
        _ second: LocationEventModel
    ) -> Bool {
        if first.horizontalAccuracy != second.horizontalAccuracy {
            return first.horizontalAccuracy < second.horizontalAccuracy
        }
        if first.timestamp != second.timestamp {
            return first.timestamp > second.timestamp
        }
        return first.createdAt < second.createdAt
    }

    private static func update(
        _ model: LocationEventModel,
        with event: LocationEventData
    ) {
        model.latitude = event.latitude
        model.longitude = event.longitude
        model.timestamp = event.timestamp
        model.horizontalAccuracy = event.horizontalAccuracy
        model.speedMetersPerSecond = event.speedMetersPerSecond
        model.createdAt = event.createdAt
        model.timeZoneIdentifier = event.timeZoneIdentifier
        model.utcOffsetSeconds = event.utcOffsetSeconds
        model.localDateKey = event.localDateKey
        model.deduplicationKey = deduplicationKey(for: event)
    }

    private static func deduplicationKey(for event: LocationEventData) -> String {
        let timestampBucket = Int(floor(event.timestamp.timeIntervalSince1970 / 30))
        let latitudeBucket = Int((event.latitude * 10000).rounded())
        let longitudeBucket = Int((event.longitude * 10000).rounded())
        return "\(timestampBucket)|\(latitudeBucket)|\(longitudeBucket)"
    }

    static func distanceMeters(
        latitude: Double,
        longitude: Double,
        otherLatitude: Double,
        otherLongitude: Double
    ) -> Double {
        let latitudeDelta = (otherLatitude - latitude) * .pi / 180
        let longitudeDelta = (otherLongitude - longitude) * .pi / 180
        let firstLatitude = latitude * .pi / 180
        let secondLatitude = otherLatitude * .pi / 180
        let haversine = pow(sin(latitudeDelta / 2), 2)
            + cos(firstLatitude) * cos(secondLatitude) * pow(sin(longitudeDelta / 2), 2)
        return 6_371_000 * 2 * atan2(sqrt(haversine), sqrt(1 - haversine))
    }
}
