import MapKit

extension RouteMapCoordinator {
    func mapView(
        _: MKMapView,
        rendererFor overlay: any MKOverlay
    ) -> MKOverlayRenderer {
        guard let polyline = overlay as? MKPolyline else {
            return MKOverlayRenderer(overlay: overlay)
        }
        let renderer = MKPolylineRenderer(polyline: polyline)
        applyPolylineStyle(to: renderer, stableID: polyline.title)
        renderer.lineJoin = .round
        renderer.lineCap = .round
        return renderer
    }

    func applyPolylineStyle(to renderer: MKPolylineRenderer, stableID: String?) {
        let isSelected = stableID == selectedSegmentID
        let isSelectionActive = selectedSegmentID != nil
        renderer.strokeColor = UIColor.systemRed.withAlphaComponent(
            isSelectionActive && !isSelected ? 0.45 : 1
        )
        renderer.lineWidth = isSelected ? 8 : (isSelectionActive ? 3 : 4)
    }

    func updatePolylineSelection(in mapView: MKMapView) {
        for overlay in mapView.overlays {
            guard let polyline = overlay as? MKPolyline,
                  let renderer = mapView.renderer(for: polyline) as? MKPolylineRenderer
            else { continue }
            applyPolylineStyle(to: renderer, stableID: polyline.title)
            renderer.setNeedsDisplay()
        }
    }

    @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
        guard let mapView else { return }
        let tapPoint = recognizer.location(in: mapView)
        if selectPolyline(at: tapPoint, in: mapView) {
            return
        }
        selectedSegmentAnchor = nil
        selectedSegmentID = nil
        selectedStayID = nil
        updatePolylineSelection(in: mapView)
        updateMovementCallout(in: mapView)
        updateStaySelection(in: mapView)
        updateStayCallout(in: mapView)
        onTapEmpty()
    }

    @discardableResult
    func selectPolyline(at tapPoint: CGPoint, in mapView: MKMapView) -> Bool {
        let coordinate = mapView.convert(tapPoint, toCoordinateFrom: mapView)
        for overlay in mapView.overlays.reversed() {
            guard let polyline = overlay as? MKPolyline,
                  isTap(tapPoint, near: polyline, in: mapView),
                  let stableID = polyline.title
            else { continue }
            selectedSegmentAnchor = (stableID, coordinate)
            selectedSegmentID = stableID
            updatePolylineSelection(in: mapView)
            updateMovementCallout(in: mapView)
            onSelectSegment(stableID)
            return true
        }
        return false
    }

    func isTap(_ tapPoint: CGPoint, near polyline: MKPolyline, in mapView: MKMapView) -> Bool {
        guard polyline.pointCount >= 2 else { return false }
        let points = polyline.points()
        var start = mapView.convert(points[0].coordinate, toPointTo: mapView)
        for index in 1 ..< polyline.pointCount {
            let end = mapView.convert(points[index].coordinate, toPointTo: mapView)
            if distance(from: tapPoint, toSegmentFrom: start, to: end) <= 22 {
                return true
            }
            start = end
        }
        return false
    }

    func gestureRecognizer(_: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        var touchedView = touch.view
        while let view = touchedView {
            if view is MKAnnotationView || view is UIControl {
                return false
            }
            touchedView = view.superview
        }
        return true
    }

    func gestureRecognizer(
        _: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith _: UIGestureRecognizer
    ) -> Bool {
        true
    }

    func movementCalloutCoordinate(for movement: MapMovementLabel) -> CLLocationCoordinate2D {
        guard selectedSegmentAnchor?.id == movement.segmentStableID,
              let coordinate = selectedSegmentAnchor?.coordinate
        else { return movement.coordinate.mapCoordinate }
        return coordinate
    }

    func addPolylines(_ polylines: [MapPolyline], to mapView: MKMapView) {
        for value in polylines where value.coordinates.count >= 2 {
            let coordinates = value.coordinates.map(\.mapCoordinate)
            let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
            polyline.title = value.segmentStableID
            mapView.addOverlay(polyline)
        }
    }

    private func distance(
        from point: CGPoint,
        toSegmentFrom start: CGPoint,
        to end: CGPoint
    ) -> CGFloat {
        let deltaX = end.x - start.x
        let deltaY = end.y - start.y
        let squaredLength = deltaX * deltaX + deltaY * deltaY
        guard squaredLength > 0 else {
            return hypot(point.x - start.x, point.y - start.y)
        }
        let projection = max(0, min(
            1,
            ((point.x - start.x) * deltaX + (point.y - start.y) * deltaY) / squaredLength
        ))
        let closest = CGPoint(
            x: start.x + projection * deltaX,
            y: start.y + projection * deltaY
        )
        return hypot(point.x - closest.x, point.y - closest.y)
    }
}
