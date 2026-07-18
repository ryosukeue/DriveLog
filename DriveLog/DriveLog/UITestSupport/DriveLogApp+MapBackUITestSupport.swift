#if DEBUG
    import Foundation
    import SwiftData

    extension DriveLogApp {
        static func uiTestReferenceDate(defaultValue: Date, timeZone: TimeZone) -> Date {
            guard ProcessInfo.processInfo.arguments.contains("-ui-testing-july-17-map") else {
                return defaultValue
            }
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = timeZone
            return calendar.date(from: DateComponents(
                year: 2026,
                month: 7,
                day: 17,
                hour: 12
            )) ?? defaultValue
        }

        @MainActor
        static func seedRoute(
            context: ModelContext,
            localDateKey: String,
            startDate: Date,
            now: Date
        ) throws {
            let route = try PropertyListRouteEncoder().encode([
                RouteCoordinate(latitude: 37.330, longitude: -122.040),
                RouteCoordinate(latitude: 37.340, longitude: -122.020),
                RouteCoordinate(latitude: 37.350, longitude: -122.000)
            ])
            context.insert(MovementSegmentModel(
                stableID: "ui-movement",
                localDateKey: localDateKey,
                startDate: startDate,
                endDate: now,
                distanceMeters: 5200,
                durationSeconds: 3600,
                estimatedAverageSpeedMetersPerSecond: 5200 / 3600,
                automaticClassificationRawValue: "automotiveLike",
                classificationConfidenceRawValue: "high",
                encodedRouteData: route,
                labelLatitude: 37.340,
                labelLongitude: -122.020,
                sourceRawRevision: 1,
                generatedAt: now
            ))
            context.insert(StaySegmentModel(
                stableID: "ui-stay",
                localDateKey: localDateKey,
                representativeLatitude: 37.350,
                representativeLongitude: -122.000,
                estimatedArrivalDate: now.addingTimeInterval(-900),
                estimatedDepartureDate: now.addingTimeInterval(-300),
                durationSeconds: 600,
                confidenceRawValue: "high",
                sourceRawValue: "combined",
                isVisibleByAutomaticRule: true,
                sourceRawRevision: 1,
                generatedAt: now
            ))
        }

        @MainActor
        static func seedDenseMapExtras(
            context: ModelContext,
            localDateKey: String,
            startDate: Date,
            now: Date
        ) throws {
            for index in 1 ..< 7 {
                let offset = Double(index) * 0.002
                let route = try PropertyListRouteEncoder().encode([
                    RouteCoordinate(latitude: 37.330 + offset, longitude: -122.040 + offset),
                    RouteCoordinate(latitude: 37.340 + offset, longitude: -122.020 + offset),
                    RouteCoordinate(latitude: 37.350 + offset, longitude: -122.000 + offset)
                ])
                context.insert(MovementSegmentModel(
                    stableID: "ui-dense-movement-\(index)",
                    localDateKey: localDateKey,
                    startDate: startDate.addingTimeInterval(Double(index) * 60),
                    endDate: now.addingTimeInterval(Double(index) * -60),
                    distanceMeters: 5200,
                    durationSeconds: 3600,
                    estimatedAverageSpeedMetersPerSecond: 5200 / 3600,
                    automaticClassificationRawValue: "automotiveLike",
                    classificationConfidenceRawValue: "high",
                    encodedRouteData: route,
                    labelLatitude: 37.340 + offset,
                    labelLongitude: -122.020 + offset,
                    sourceRawRevision: 1,
                    generatedAt: now
                ))
            }
            for index in 1 ..< 18 {
                let offset = Double(index % 6) * 0.001
                context.insert(StaySegmentModel(
                    stableID: "ui-dense-stay-\(index)",
                    localDateKey: localDateKey,
                    representativeLatitude: 37.350 + offset,
                    representativeLongitude: -122.000 + offset,
                    estimatedArrivalDate: now.addingTimeInterval(Double(-1800 - index * 120)),
                    estimatedDepartureDate: now.addingTimeInterval(Double(-1200 - index * 120)),
                    durationSeconds: 600,
                    confidenceRawValue: "high",
                    sourceRawValue: "combined",
                    isVisibleByAutomaticRule: true,
                    sourceRawRevision: 1,
                    generatedAt: now
                ))
            }
        }
    }
#endif
