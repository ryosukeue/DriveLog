import Foundation
import SwiftData

extension PersistenceActor {
    func saveOrUpdateVisitEvent(
        _ event: VisitEventData,
        savedAt: Date
    ) throws -> RawEventSaveResult {
        let localDateKey = event.localDateKey
        let descriptor = FetchDescriptor<VisitEventModel>(
            predicate: #Predicate { $0.localDateKey == localDateKey }
        )
        let candidate = try modelContext.fetch(descriptor).first {
            Self.isSameVisit($0, as: event)
        }

        if let candidate {
            guard Self.update(candidate, with: event, updatedAt: savedAt) else {
                return .duplicateIgnored
            }
            try incrementRawRevision(for: event.localDateKey, updatedAt: savedAt)
            try modelContext.save()
            return .updated
        }

        modelContext.insert(
            VisitEventModel(
                latitude: event.latitude, longitude: event.longitude,
                arrivalDate: event.arrivalDate, departureDate: event.departureDate,
                horizontalAccuracy: event.horizontalAccuracy,
                createdAt: savedAt, updatedAt: savedAt,
                timeZoneIdentifier: event.timeZoneIdentifier,
                utcOffsetSeconds: event.utcOffsetSeconds, localDateKey: event.localDateKey,
                visitMatchKey: Self.visitMatchKey(for: event)
            )
        )
        try incrementRawRevision(for: event.localDateKey, updatedAt: savedAt)
        try modelContext.save()
        return .inserted
    }

    func rawEvents(for localDateKey: String) throws -> RawDayEvents {
        try RawDayEvents(
            locations: locationEvents(for: localDateKey),
            motions: motionEvents(for: localDateKey),
            visits: visitEvents(for: localDateKey),
            classificationOverrides: [], stayOverrides: []
        )
    }

    func deleteRawEvents(for localDateKey: String) throws {
        let locations = try modelContext.fetch(
            FetchDescriptor<LocationEventModel>(
                predicate: #Predicate { $0.localDateKey == localDateKey }
            )
        )
        let motions = try modelContext.fetch(
            FetchDescriptor<MotionEventModel>(
                predicate: #Predicate { $0.localDateKey == localDateKey }
            )
        )
        let visits = try modelContext.fetch(
            FetchDescriptor<VisitEventModel>(
                predicate: #Predicate { $0.localDateKey == localDateKey }
            )
        )
        locations.forEach(modelContext.delete)
        motions.forEach(modelContext.delete)
        visits.forEach(modelContext.delete)
        try modelContext.save()
    }

    private func visitEvents(for localDateKey: String) throws -> [VisitEventData] {
        let descriptor = FetchDescriptor<VisitEventModel>(
            predicate: #Predicate { $0.localDateKey == localDateKey },
            sortBy: [SortDescriptor(\VisitEventModel.arrivalDate)]
        )
        return try modelContext.fetch(descriptor).map {
            VisitEventData(
                latitude: $0.latitude, longitude: $0.longitude,
                arrivalDate: $0.arrivalDate, departureDate: $0.departureDate,
                horizontalAccuracy: $0.horizontalAccuracy,
                timeZoneIdentifier: $0.timeZoneIdentifier,
                utcOffsetSeconds: $0.utcOffsetSeconds, localDateKey: $0.localDateKey
            )
        }
    }

    private static func isSameVisit(
        _ existing: VisitEventModel,
        as incoming: VisitEventData
    ) -> Bool {
        guard let existingArrival = existing.arrivalDate,
              let incomingArrival = incoming.arrivalDate,
              abs(existingArrival.timeIntervalSince(incomingArrival)) <= 60
        else { return false }
        let accuracyRadius = max(
            10,
            max(existing.horizontalAccuracy, incoming.horizontalAccuracy)
        )
        return distanceMeters(
            latitude: existing.latitude, longitude: existing.longitude,
            otherLatitude: incoming.latitude, otherLongitude: incoming.longitude
        ) <= accuracyRadius
    }

    private static func update(
        _ model: VisitEventModel,
        with event: VisitEventData,
        updatedAt: Date
    ) -> Bool {
        let hasNewDeparture = event.departureDate != nil
            && event.departureDate != model.departureDate
        let hasBetterLocation = event.horizontalAccuracy < model.horizontalAccuracy
        guard hasNewDeparture || hasBetterLocation else { return false }

        if hasNewDeparture {
            model.departureDate = event.departureDate
        }
        if hasBetterLocation {
            model.latitude = event.latitude
            model.longitude = event.longitude
            model.horizontalAccuracy = event.horizontalAccuracy
        }
        model.updatedAt = updatedAt
        model.timeZoneIdentifier = event.timeZoneIdentifier
        model.utcOffsetSeconds = event.utcOffsetSeconds
        model.visitMatchKey = visitMatchKey(for: event)
        return true
    }

    private static func visitMatchKey(for event: VisitEventData) -> String {
        let arrivalBucket = Int(floor((event.arrivalDate?.timeIntervalSince1970 ?? 0) / 3600))
        let latitudeBucket = Int((event.latitude * 10000).rounded())
        let longitudeBucket = Int((event.longitude * 10000).rounded())
        return "\(arrivalBucket)|\(latitudeBucket)|\(longitudeBucket)"
    }
}
