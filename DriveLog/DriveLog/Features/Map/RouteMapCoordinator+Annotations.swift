import MapKit

extension RouteMapCoordinator {
    func mapView(_ mapView: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
        if let cluster = annotation as? MKClusterAnnotation {
            let members = cluster.memberAnnotations.compactMap {
                $0 as? RouteMapPointAnnotation
            }
            return members.contains(where: { $0.kind == .media })
                ? mediaClusterView(for: cluster, in: mapView)
                : stayClusterView(for: cluster, in: mapView)
        }
        guard let annotation = annotation as? RouteMapPointAnnotation else { return nil }
        return switch annotation.kind {
        case .movementCallout:
            movementCalloutView(for: annotation, in: mapView)
        case .stay:
            stayView(for: annotation, in: mapView)
        case .stayCallout:
            stayCalloutView(for: annotation, in: mapView)
        case .media:
            mediaView(for: annotation, in: mapView)
        }
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let cluster = view.annotation as? MKClusterAnnotation {
            let members = cluster.memberAnnotations.compactMap { $0 as? RouteMapPointAnnotation }
            onSelectPlace(MapPlaceSelection(
                mediaIdentifiers: members.filter { $0.kind == .media }.map(\.id).sorted(),
                stayStableIDs: uniqueStayIDs(in: members)
            ))
            mapView.deselectAnnotation(cluster, animated: false)
            return
        }
        guard let annotation = view.annotation as? RouteMapPointAnnotation else { return }
        switch annotation.kind {
        case .stay:
            onSelectPlace(MapPlaceSelection(
                mediaIdentifiers: [],
                stayStableIDs: annotation.relatedStays.map(\.stayStableID)
            ))
        case .media:
            onSelectPlace(MapPlaceSelection(
                mediaIdentifiers: [annotation.id],
                stayStableIDs: annotation.relatedStays.map(\.stayStableID)
            ))
        case .movementCallout, .stayCallout:
            return
        }
        mapView.deselectAnnotation(annotation, animated: false)
    }

    func addAnnotations(scene: MapScene, to mapView: MKMapView) {
        let callouts = scene.movementLabels.compactMap { movement -> RouteMapPointAnnotation? in
            guard movement.segmentStableID == selectedSegmentID else { return nil }
            return RouteMapPointAnnotation(
                id: movement.segmentStableID,
                coordinate: movementCalloutCoordinate(for: movement),
                kind: .movementCallout,
                movement: movement
            )
        }
        let stayAssignments = assignStaysToMedia(scene: scene)
        let stays = groupedStays(
            unassignedStays(in: scene, assignments: stayAssignments)
        ).compactMap { group -> RouteMapPointAnnotation? in
            guard let representative = group.first else { return nil }
            return RouteMapPointAnnotation(
                id: representative.stayStableID,
                coordinate: representative.coordinate.mapCoordinate,
                kind: .stay,
                labelText: staySummary(group),
                stay: group.count == 1 ? representative : nil,
                relatedStays: group
            )
        }
        let stayCallouts = scene.stayAnnotations.compactMap { stay -> RouteMapPointAnnotation? in
            guard stay.stayStableID == selectedStayID else { return nil }
            return RouteMapPointAnnotation(
                id: stay.stayStableID,
                coordinate: stay.coordinate.mapCoordinate,
                kind: .stayCallout,
                stay: stay
            )
        }
        let media = scene.mediaAnnotations.map { annotation in
            RouteMapPointAnnotation(
                id: annotation.localIdentifier,
                coordinate: annotation.coordinate.mapCoordinate,
                kind: .media,
                mediaType: annotation.mediaType,
                relatedStays: stayAssignments[annotation.localIdentifier] ?? []
            )
        }
        mapView.addAnnotations(callouts + stays + stayCallouts + media)
    }

    func updateStaySelection(in mapView: MKMapView) {
        for annotation in mapView.annotations {
            guard let value = annotation as? RouteMapPointAnnotation,
                  value.kind == .stay,
                  let view = mapView.view(for: value) as? RouteMapStayAnnotationView
            else { continue }
            view.configure(
                text: value.labelText ?? "",
                isSelected: value.id == selectedStayID
            )
        }
    }

    func updateMovementCallout(in mapView: MKMapView) {
        let existing = mapView.annotations.compactMap { annotation -> RouteMapPointAnnotation? in
            guard let value = annotation as? RouteMapPointAnnotation,
                  value.kind == .movementCallout
            else { return nil }
            return value
        }
        mapView.removeAnnotations(existing)
        guard let selectedSegmentID,
              let movement = renderedScene?.movementLabels.first(where: {
                  $0.segmentStableID == selectedSegmentID
              })
        else { return }
        mapView.addAnnotation(
            RouteMapPointAnnotation(
                id: movement.segmentStableID,
                coordinate: movementCalloutCoordinate(for: movement),
                kind: .movementCallout,
                movement: movement
            )
        )
    }

    func updateStayCallout(in mapView: MKMapView) {
        let existing = mapView.annotations.compactMap { annotation -> RouteMapPointAnnotation? in
            guard let value = annotation as? RouteMapPointAnnotation,
                  value.kind == .stayCallout
            else { return nil }
            return value
        }
        mapView.removeAnnotations(existing)
        guard let selectedStayID,
              let stay = renderedScene?.stayAnnotations.first(where: {
                  $0.stayStableID == selectedStayID
              })
        else { return }
        mapView.addAnnotation(
            RouteMapPointAnnotation(
                id: stay.stayStableID,
                coordinate: stay.coordinate.mapCoordinate,
                kind: .stayCallout,
                stay: stay
            )
        )
    }

    private func movementCalloutView(
        for annotation: RouteMapPointAnnotation,
        in mapView: MKMapView
    ) -> MKAnnotationView {
        let identifier = "RouteMapMovementCallout"
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as?
            RouteMapMovementCalloutView ?? RouteMapMovementCalloutView(
                annotation: annotation,
                reuseIdentifier: identifier
            )
        view.annotation = annotation
        if let movement = annotation.movement {
            view.configure(
                movement: movement,
                formatter: DayDetailFormatter(timeZone: SystemTimeZoneProvider().current)
            )
        }
        return view
    }

    func updateMovementCalloutConfiguration(in mapView: MKMapView) {
        for annotation in mapView.annotations {
            guard let value = annotation as? RouteMapPointAnnotation,
                  value.kind == .movementCallout,
                  let movement = value.movement,
                  let view = mapView.view(for: value) as? RouteMapMovementCalloutView
            else { continue }
            view.configure(
                movement: movement,
                formatter: DayDetailFormatter(timeZone: SystemTimeZoneProvider().current)
            )
        }
    }

    private func stayView(
        for annotation: RouteMapPointAnnotation,
        in mapView: MKMapView
    ) -> MKAnnotationView {
        let identifier = "RouteMapStayAnnotation"
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as?
            RouteMapStayAnnotationView ?? RouteMapStayAnnotationView(
                annotation: annotation,
                reuseIdentifier: identifier
            )
        view.annotation = annotation
        view.configure(
            text: annotation.labelText ?? "",
            isSelected: annotation.id == selectedStayID
        )
        view.setStayEmphasized(isStayEmphasized(annotation.relatedStays))
        view.clusteringIdentifier = "stay"
        view.collisionMode = .rectangle
        view.displayPriority = .defaultHigh
        return view
    }

    private func stayCalloutView(
        for annotation: RouteMapPointAnnotation,
        in mapView: MKMapView
    ) -> MKAnnotationView {
        let identifier = "RouteMapStayCallout"
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as?
            RouteMapStayCalloutView ?? RouteMapStayCalloutView(
                annotation: annotation,
                reuseIdentifier: identifier
            )
        view.annotation = annotation
        if let stay = annotation.stay {
            view.configure(
                stay: stay,
                formatter: DayDetailFormatter(timeZone: SystemTimeZoneProvider().current)
            )
        }
        return view
    }

    func updateStayCalloutConfiguration(in mapView: MKMapView) {
        for annotation in mapView.annotations {
            guard let value = annotation as? RouteMapPointAnnotation,
                  value.kind == .stayCallout,
                  let stay = value.stay,
                  let view = mapView.view(for: value) as? RouteMapStayCalloutView
            else { continue }
            view.configure(
                stay: stay,
                formatter: DayDetailFormatter(timeZone: SystemTimeZoneProvider().current)
            )
        }
    }

    private func mediaView(
        for annotation: RouteMapPointAnnotation,
        in mapView: MKMapView
    ) -> MKAnnotationView {
        let identifier = "RouteMapMediaAnnotation"
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as?
            RouteMapMediaAnnotationView ?? RouteMapMediaAnnotationView(
                annotation: annotation,
                reuseIdentifier: identifier
            )
        view.annotation = annotation
        view.configure(
            localIdentifier: annotation.id,
            mediaType: annotation.mediaType ?? .photo,
            staySummary: staySummary(annotation.relatedStays),
            thumbnailLoader: thumbnailLoader
        )
        view.setStayEmphasized(isStayEmphasized(annotation.relatedStays))
        view.clusteringIdentifier = "media"
        view.collisionMode = .rectangle
        view.displayPriority = .required
        return view
    }

    private func mediaClusterView(
        for annotation: MKClusterAnnotation,
        in mapView: MKMapView
    ) -> MKAnnotationView {
        let identifier = "RouteMapMediaCluster"
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as?
            RouteMapMediaClusterAnnotationView ?? RouteMapMediaClusterAnnotationView(
                annotation: annotation,
                reuseIdentifier: identifier
            )
        let members = annotation.memberAnnotations.compactMap { $0 as? RouteMapPointAnnotation }
        let representative = representativeMedia(in: members)
        view.annotation = annotation
        view.configure(
            localIdentifier: representative?.id ?? "",
            mediaType: representative?.mediaType ?? .photo,
            memberCount: members.count,
            staySummary: staySummary(uniqueStays(in: members)),
            thumbnailLoader: thumbnailLoader
        )
        view.setStayEmphasized(isStayEmphasized(uniqueStays(in: members)))
        view.accessibilityLabel = "\(members.count)件の写真と動画" +
            (staySummary(uniqueStays(in: members)).map { "、\($0)" } ?? "")
        return view
    }

    private func stayClusterView(
        for annotation: MKClusterAnnotation,
        in mapView: MKMapView
    ) -> MKAnnotationView {
        let identifier = "RouteMapStayCluster"
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as?
            RouteMapStayClusterAnnotationView ?? RouteMapStayClusterAnnotationView(
                annotation: annotation,
                reuseIdentifier: identifier
            )
        let members = annotation.memberAnnotations.compactMap {
            $0 as? RouteMapPointAnnotation
        }
        view.annotation = annotation
        view.configure(
            text: staySummary(uniqueStays(in: members)) ?? "滞在",
            isSelected: false
        )
        view.setStayEmphasized(isStayEmphasized(uniqueStays(in: members)))
        view.accessibilityIdentifier = "map.stayCluster"
        return view
    }

    func isStayEmphasized(_ stays: [MapStayAnnotation]) -> Bool {
        guard !stays.isEmpty,
              let selectedSegmentID,
              let movement = renderedScene?.movementLabels.first(where: {
                  $0.segmentStableID == selectedSegmentID
              })
        else { return true }
        let tolerance = ProcessingConfiguration.mvp.stay.automaticStayDuration
        let relatedInterval = DateInterval(
            start: movement.startDate.addingTimeInterval(-tolerance),
            end: movement.endDate.addingTimeInterval(tolerance)
        )
        return stays.contains { stay in
            stay.departureDate >= relatedInterval.start &&
                stay.arrivalDate <= relatedInterval.end
        }
    }

    func updateStayEmphasis(in mapView: MKMapView) {
        for annotation in mapView.annotations {
            if let point = annotation as? RouteMapPointAnnotation {
                updateStayEmphasis(for: point, in: mapView)
            } else if let cluster = annotation as? MKClusterAnnotation {
                updateStayEmphasis(for: cluster, in: mapView)
            }
        }
    }

    private func updateStayEmphasis(
        for annotation: RouteMapPointAnnotation,
        in mapView: MKMapView
    ) {
        let isEmphasized = isStayEmphasized(annotation.relatedStays)
        switch mapView.view(for: annotation) {
        case let view as RouteMapStayAnnotationView:
            view.setStayEmphasized(isEmphasized)
        case let view as RouteMapMediaAnnotationView:
            view.setStayEmphasized(isEmphasized)
        default:
            break
        }
    }

    private func updateStayEmphasis(
        for annotation: MKClusterAnnotation,
        in mapView: MKMapView
    ) {
        let members = annotation.memberAnnotations.compactMap {
            $0 as? RouteMapPointAnnotation
        }
        let isEmphasized = isStayEmphasized(uniqueStays(in: members))
        switch mapView.view(for: annotation) {
        case let view as RouteMapStayAnnotationView:
            view.setStayEmphasized(isEmphasized)
        case let view as RouteMapMediaAnnotationView:
            view.setStayEmphasized(isEmphasized)
        default:
            break
        }
    }
}
