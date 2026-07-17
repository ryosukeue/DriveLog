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
        let totalMinutes = max(0, Int(stays.reduce(0) { $0 + $1.durationSeconds }) / 60)
        let duration = totalMinutes >= 60
            ? "\(totalMinutes / 60)時間\(totalMinutes % 60)分"
            : "\(totalMinutes)分"
        return stays.count == 1 ? "滞在 \(duration)" : "滞在\(stays.count)回・計\(duration)"
    }

    private var placeGroupingDistance: CLLocationDistance {
        ProcessingConfiguration.mvp.stay.stayRadius
    }
}
