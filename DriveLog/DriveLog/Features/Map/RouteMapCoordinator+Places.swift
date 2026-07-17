import MapKit

extension RouteMapCoordinator {
    func representativeMedia(
        in members: [RouteMapPointAnnotation]
    ) -> RouteMapPointAnnotation? {
        members.sorted { first, second in
            let firstDate = mediaByIdentifier[first.id]?.creationDate ?? .distantPast
            let secondDate = mediaByIdentifier[second.id]?.creationDate ?? .distantPast
            return firstDate == secondDate ? first.id < second.id : firstDate > secondDate
        }.first
    }

    func uniqueStays(
        in members: [RouteMapPointAnnotation]
    ) -> [MapStayAnnotation] {
        var seen = Set<String>()
        return members.flatMap(\.relatedStays).filter { seen.insert($0.stayStableID).inserted }
    }

    func uniqueStayIDs(in members: [RouteMapPointAnnotation]) -> [String] {
        uniqueStays(in: members).map(\.stayStableID)
    }

    func assignStaysToMedia(
        scene: MapScene
    ) -> [String: [MapStayAnnotation]] {
        var assignments: [String: [MapStayAnnotation]] = [:]
        for stay in scene.stayAnnotations {
            let stayPoint = MKMapPoint(stay.coordinate.mapCoordinate)
            let closest = scene.mediaAnnotations.compactMap { media -> (String, CLLocationDistance)? in
                let distance = stayPoint.distance(to: MKMapPoint(media.coordinate.mapCoordinate))
                guard distance <= placeGroupingDistance else { return nil }
                return (media.localIdentifier, distance)
            }.min { first, second in
                first.1 == second.1 ? first.0 < second.0 : first.1 < second.1
            }
            guard let closest else { continue }
            assignments[closest.0, default: []].append(stay)
        }
        return assignments
    }

    func unassignedStays(
        in scene: MapScene,
        assignments: [String: [MapStayAnnotation]]
    ) -> [MapStayAnnotation] {
        let assignedIDs = Set(assignments.values.flatMap { $0.map(\.stayStableID) })
        return scene.stayAnnotations.filter { !assignedIDs.contains($0.stayStableID) }
    }

    func groupedStays(_ stays: [MapStayAnnotation]) -> [[MapStayAnnotation]] {
        var groups: [[MapStayAnnotation]] = []
        for stay in stays {
            let point = MKMapPoint(stay.coordinate.mapCoordinate)
            if let index = groups.firstIndex(where: { group in
                guard let representative = group.first else { return false }
                return point.distance(to: MKMapPoint(representative.coordinate.mapCoordinate)) <=
                    placeGroupingDistance
            }) {
                groups[index].append(stay)
            } else {
                groups.append([stay])
            }
        }
        return groups
    }

    func staySummary(_ stays: [MapStayAnnotation]) -> String? {
        guard !stays.isEmpty else { return nil }
        guard let movement = selectedMovement else {
            return stays.count == 1 ? "滞在 \(durationText(for: stays[0]))" : "滞在"
        }
        let endpoints = endpointStays(in: stays, for: movement)
        let precedingText = endpoints.preceding.map { "前 \(durationText(for: $0))" }
        let followingText = endpoints.following.map { "後 \(durationText(for: $0))" }
        let components = [precedingText, followingText].compactMap(\.self)
        return components.isEmpty ? "滞在" : components.joined(separator: "・")
    }

    func endpointStays(
        in stays: [MapStayAnnotation],
        for movement: MapMovementLabel
    ) -> (preceding: MapStayAnnotation?, following: MapStayAnnotation?) {
        let tolerance = ProcessingConfiguration.mvp.stay.automaticStayDuration
        var preceding = stays
            .filter {
                abs($0.departureDate.timeIntervalSince(movement.startDate)) <= tolerance
            }
            .min { first, second in
                isCloser(
                    first,
                    than: second,
                    date: \.departureDate,
                    referenceDate: movement.startDate
                )
            }
        var following = stays
            .filter {
                abs($0.arrivalDate.timeIntervalSince(movement.endDate)) <= tolerance
            }
            .min { first, second in
                isCloser(
                    first,
                    than: second,
                    date: \.arrivalDate,
                    referenceDate: movement.endDate
                )
            }
        if let sharedStay = preceding, sharedStay.stayStableID == following?.stayStableID {
            let precedingDifference = abs(
                sharedStay.departureDate.timeIntervalSince(movement.startDate)
            )
            let followingDifference = abs(
                sharedStay.arrivalDate.timeIntervalSince(movement.endDate)
            )
            if precedingDifference <= followingDifference {
                following = nil
            } else {
                preceding = nil
            }
        }
        return (preceding, following)
    }

    var selectedMovement: MapMovementLabel? {
        guard let selectedSegmentID else { return nil }
        return renderedScene?.movementLabels.first {
            $0.segmentStableID == selectedSegmentID
        }
    }

    private func durationText(for stay: MapStayAnnotation) -> String {
        let totalMinutes = max(0, Int(stay.durationSeconds) / 60)
        return totalMinutes >= 60
            ? "\(totalMinutes / 60)時間\(totalMinutes % 60)分"
            : "\(totalMinutes)分"
    }

    private func isCloser(
        _ first: MapStayAnnotation,
        than second: MapStayAnnotation,
        date: KeyPath<MapStayAnnotation, Date>,
        referenceDate: Date
    ) -> Bool {
        let firstDifference = abs(first[keyPath: date].timeIntervalSince(referenceDate))
        let secondDifference = abs(second[keyPath: date].timeIntervalSince(referenceDate))
        return firstDifference == secondDifference
            ? first.stayStableID < second.stayStableID
            : firstDifference < secondDifference
    }

    private var placeGroupingDistance: CLLocationDistance {
        ProcessingConfiguration.mvp.stay.stayRadius
    }
}
