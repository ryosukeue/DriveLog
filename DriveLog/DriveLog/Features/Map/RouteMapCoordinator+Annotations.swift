import MapKit

extension RouteMapCoordinator {
    func mapView(_ mapView: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
        if let cluster = annotation as? MKClusterAnnotation {
            return mediaClusterView(for: cluster, in: mapView)
        }
        guard let annotation = annotation as? RouteMapPointAnnotation else { return nil }
        return switch annotation.kind {
        case .movementLabel:
            movementLabelView(for: annotation, in: mapView)
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
            mapView.showAnnotations(cluster.memberAnnotations, animated: true)
            mapView.deselectAnnotation(cluster, animated: false)
            return
        }
        guard let annotation = view.annotation as? RouteMapPointAnnotation else { return }
        switch annotation.kind {
        case .movementLabel:
            onSelectSegment(annotation.id)
        case .stay:
            onSelectStay(annotation.id)
        case .media:
            onSelectMedia(annotation.id)
        case .movementCallout, .stayCallout:
            return
        }
        mapView.deselectAnnotation(annotation, animated: false)
    }

    func addAnnotations(scene: MapScene, to mapView: MKMapView) {
        let labels = scene.movementLabels.map {
            RouteMapPointAnnotation(
                id: $0.segmentStableID,
                coordinate: $0.coordinate.mapCoordinate,
                kind: .movementLabel,
                labelText: $0.text
            )
        }
        let callouts = scene.movementLabels.compactMap { movement -> RouteMapPointAnnotation? in
            guard movement.segmentStableID == selectedSegmentID else { return nil }
            return RouteMapPointAnnotation(
                id: movement.segmentStableID,
                coordinate: movement.coordinate.mapCoordinate,
                kind: .movementCallout,
                movement: movement
            )
        }
        let stays = scene.stayAnnotations.map {
            RouteMapPointAnnotation(
                id: $0.stayStableID,
                coordinate: $0.coordinate.mapCoordinate,
                kind: .stay,
                labelText: $0.text
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
        let media = scene.mediaAnnotations.compactMap { annotation -> RouteMapPointAnnotation? in
            guard let asset = mediaByIdentifier[annotation.localIdentifier],
                  asset.location != nil
            else { return nil }
            return RouteMapPointAnnotation(
                id: annotation.localIdentifier,
                coordinate: annotation.coordinate.mapCoordinate,
                kind: .media,
                mediaType: asset.mediaType
            )
        }
        mapView.addAnnotations(labels + callouts + stays + stayCallouts + media)
    }

    func updateLabelSelection(in mapView: MKMapView) {
        for annotation in mapView.annotations {
            guard let value = annotation as? RouteMapPointAnnotation,
                  value.kind == .movementLabel,
                  let view = mapView.view(for: value) as? RouteMapLabelAnnotationView
            else { continue }
            view.configure(
                text: value.labelText ?? "",
                isSelected: value.id == selectedSegmentID
            )
        }
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
                coordinate: movement.coordinate.mapCoordinate,
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

    private func movementLabelView(
        for annotation: RouteMapPointAnnotation,
        in mapView: MKMapView
    ) -> MKAnnotationView {
        let identifier = "RouteMapLabelAnnotation"
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as?
            RouteMapLabelAnnotationView ?? RouteMapLabelAnnotationView(
                annotation: annotation,
                reuseIdentifier: identifier
            )
        view.annotation = annotation
        view.configure(
            text: annotation.labelText ?? "",
            isSelected: annotation.id == selectedSegmentID
        )
        return view
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
            thumbnailLoader: thumbnailLoader
        )
        view.clusteringIdentifier = "media"
        view.collisionMode = .rectangle
        view.displayPriority = .defaultHigh
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
        view.annotation = annotation
        view.configure(memberCount: annotation.memberAnnotations.count)
        return view
    }
}
