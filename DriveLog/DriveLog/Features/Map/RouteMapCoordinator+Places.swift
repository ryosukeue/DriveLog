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
                let maximumDistance = isTemporallyRelated(media, to: stay)
                    ? temporallyRelatedPlaceGroupingDistance
                    : placeGroupingDistance
                guard distance <= maximumDistance else { return nil }
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
        let staysByID = Dictionary(
            stays.map { ($0.stayStableID, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        return displayStayGroups(for: stays).map { group in
            group.memberStableIDs.compactMap { staysByID[$0] }
        }
    }

    func staySummary(_ stays: [MapStayAnnotation]) -> String? {
        guard !stays.isEmpty else { return nil }
        let displayGroups = displayStayGroups(for: stays)
        guard let movement = selectedMovement else {
            guard displayGroups.count == 1, let group = displayGroups.first else {
                return "滞在"
            }
            return "滞在 \(durationText(seconds: group.durationSeconds))"
        }
        let endpoints = endpointStays(in: stays, for: movement)
        let precedingText = endpoints.preceding.map { stay in
            let duration = displayGroup(containing: stay, in: displayGroups)?.durationSeconds
                ?? stay.durationSeconds
            return "前 \(durationText(seconds: duration))"
        }
        let followingText = endpoints.following.map { stay in
            let duration = displayGroup(containing: stay, in: displayGroups)?.durationSeconds
                ?? stay.durationSeconds
            return "後 \(durationText(seconds: duration))"
        }
        let components = [precedingText, followingText].compactMap(\.self)
        return components.isEmpty ? "滞在" : components.joined(separator: "・")
    }

    private func displayStayGroups(
        for stays: [MapStayAnnotation]
    ) -> [StayDisplayGroup] {
        StayDisplayGrouping().groups(
            stays: stays,
            movements: renderedScene?.movementLabels ?? []
        )
    }

    private func displayGroup(
        containing stay: MapStayAnnotation,
        in groups: [StayDisplayGroup]
    ) -> StayDisplayGroup? {
        groups.first { $0.memberStableIDs.contains(stay.stayStableID) }
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

    private func durationText(seconds: TimeInterval) -> String {
        let totalMinutes = max(0, Int(seconds) / 60)
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

    private var temporallyRelatedPlaceGroupingDistance: CLLocationDistance {
        ProcessingConfiguration.mvp.overrideMatching.stayOverrideCoordinateTolerance
    }

    private var placeGroupingTimeTolerance: TimeInterval {
        ProcessingConfiguration.mvp.overrideMatching.stayOverrideArrivalTolerance
    }

    private func isTemporallyRelated(
        _ media: MapMediaAnnotation,
        to stay: MapStayAnnotation
    ) -> Bool {
        guard let creationDate = mediaByIdentifier[media.localIdentifier]?.creationDate else {
            return false
        }
        let lowerBound = stay.arrivalDate.addingTimeInterval(-placeGroupingTimeTolerance)
        let upperBound = stay.departureDate.addingTimeInterval(placeGroupingTimeTolerance)
        return lowerBound ... upperBound ~= creationDate
    }
}
