import Foundation

nonisolated struct StayDisplayGroup: Sendable, Equatable, Identifiable {
    let memberStableIDs: [String]
    let localDateKey: String?
    let coordinate: RouteCoordinate
    let arrivalDate: Date
    let departureDate: Date

    var id: String {
        memberStableIDs.joined(separator: "|")
    }

    var durationSeconds: TimeInterval {
        max(0, departureDate.timeIntervalSince(arrivalDate))
    }
}

nonisolated struct StayDisplayGrouping: Sendable {
    private let maximumDistanceMeters: Double
    private let maximumTemporalGap: TimeInterval
    private let distanceCalculator: GeodesicDistanceCalculator

    init(
        maximumDistanceMeters: Double = ProcessingConfiguration.mvp.stay.stayRadius,
        maximumTemporalGap: TimeInterval =
            ProcessingConfiguration.mvp.stay.automaticStayDuration,
        distanceCalculator: GeodesicDistanceCalculator = GeodesicDistanceCalculator()
    ) {
        self.maximumDistanceMeters = maximumDistanceMeters
        self.maximumTemporalGap = maximumTemporalGap
        self.distanceCalculator = distanceCalculator
    }

    func groups(
        stays: [MapStayAnnotation],
        movements: [MapMovementLabel]
    ) -> [StayDisplayGroup] {
        makeGroups(
            candidates: stays.map { stay in
                Candidate(
                    stableID: stay.stayStableID,
                    // MapScene is built for one local day, so the scene itself
                    // supplies the localDateKey that is present on persisted data.
                    localDateKey: "scene",
                    coordinate: stay.coordinate,
                    arrivalDate: stay.arrivalDate,
                    departureDate: stay.departureDate
                )
            },
            movements: movements
        )
    }

    func groups(
        stays: [StayDisplayData],
        movements: [MapMovementLabel]
    ) -> [StayDisplayGroup] {
        makeGroups(
            candidates: stays.map { stay in
                Candidate(
                    stableID: stay.segment.stableID,
                    localDateKey: stay.segment.localDateKey,
                    coordinate: stay.segment.representativeCoordinate,
                    arrivalDate: stay.segment.estimatedArrivalDate,
                    departureDate: stay.segment.estimatedDepartureDate
                )
            },
            movements: movements
        )
    }

    private func makeGroups(
        candidates: [Candidate],
        movements: [MapMovementLabel]
    ) -> [StayDisplayGroup] {
        let sorted = candidates.sorted {
            if $0.arrivalDate == $1.arrivalDate {
                return $0.stableID < $1.stableID
            }
            return $0.arrivalDate < $1.arrivalDate
        }
        var groups: [[Candidate]] = []
        for candidate in sorted {
            guard let lastGroup = groups.indices.last,
                  canAppend(candidate, to: groups[lastGroup], movements: movements)
            else {
                groups.append([candidate])
                continue
            }
            groups[lastGroup].append(candidate)
        }
        return groups.map(makeGroup)
    }

    private func canAppend(
        _ candidate: Candidate,
        to group: [Candidate],
        movements: [MapMovementLabel]
    ) -> Bool {
        guard let representative = group.first,
              let previous = group.last,
              previous.localDateKey == candidate.localDateKey,
              abs(candidate.arrivalDate.timeIntervalSince(previous.departureDate)) <=
              maximumTemporalGap,
              distance(from: representative.coordinate, to: candidate.coordinate) <=
              maximumDistanceMeters
        else {
            return false
        }
        let startDate = group.map(\.arrivalDate).min() ?? previous.arrivalDate
        let endDate = max(
            candidate.departureDate,
            group.map(\.departureDate).max() ?? previous.departureDate
        )
        return !movements.contains {
            $0.startDate < endDate && $0.endDate > startDate
        }
    }

    private func makeGroup(_ candidates: [Candidate]) -> StayDisplayGroup {
        let first = candidates[0]
        return StayDisplayGroup(
            memberStableIDs: candidates.map(\.stableID),
            localDateKey: first.localDateKey,
            coordinate: first.coordinate,
            arrivalDate: candidates.map(\.arrivalDate).min() ?? first.arrivalDate,
            departureDate: candidates.map(\.departureDate).max() ?? first.departureDate
        )
    }

    private func distance(from start: RouteCoordinate, to end: RouteCoordinate) -> Double {
        distanceCalculator.meters(
            fromLatitude: start.latitude,
            longitude: start.longitude,
            toLatitude: end.latitude,
            longitude: end.longitude
        )
    }
}

private nonisolated struct Candidate: Sendable {
    let stableID: String
    let localDateKey: String?
    let coordinate: RouteCoordinate
    let arrivalDate: Date
    let departureDate: Date
}
