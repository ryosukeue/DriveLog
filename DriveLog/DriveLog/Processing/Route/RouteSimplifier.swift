import Foundation

nonisolated protocol RouteSimplifying: Sendable {
    func simplify(_ coordinates: [RouteCoordinate]) -> [RouteCoordinate]
}

nonisolated struct RouteSimplifier: RouteSimplifying {
    private let rules: RouteRules

    init(rules: RouteRules) {
        self.rules = rules
    }

    func simplify(_ coordinates: [RouteCoordinate]) -> [RouteCoordinate] {
        guard coordinates.count >= rules.minimumPointCountForSimplification else {
            return coordinates
        }
        return douglasPeucker(coordinates)
    }

    private func douglasPeucker(_ coordinates: [RouteCoordinate]) -> [RouteCoordinate] {
        guard coordinates.count > 2,
              let first = coordinates.first,
              let last = coordinates.last
        else {
            return coordinates
        }

        var maximumDistance = 0.0
        var maximumIndex: Int?
        for index in 1 ..< coordinates.count - 1 {
            let distance = perpendicularDistance(
                from: coordinates[index],
                toSegmentFrom: first,
                to: last
            )
            if distance > maximumDistance {
                maximumDistance = distance
                maximumIndex = index
            }
        }

        guard maximumDistance > rules.simplificationTolerance,
              let maximumIndex
        else {
            return [first, last]
        }

        let leading = douglasPeucker(Array(coordinates[...maximumIndex]))
        let trailing = douglasPeucker(Array(coordinates[maximumIndex...]))
        return leading.dropLast() + trailing
    }

    private func perpendicularDistance(
        from point: RouteCoordinate,
        toSegmentFrom start: RouteCoordinate,
        to end: RouteCoordinate
    ) -> Double {
        let endPoint = projected(end, relativeTo: start)
        let point = projected(point, relativeTo: start)
        let squaredLength = endPoint.x * endPoint.x + endPoint.y * endPoint.y
        guard squaredLength > 0 else {
            return hypot(point.x, point.y)
        }

        let position = max(0, min(1, (point.x * endPoint.x + point.y * endPoint.y) / squaredLength))
        return hypot(point.x - position * endPoint.x, point.y - position * endPoint.y)
    }

    private func projected(
        _ coordinate: RouteCoordinate,
        relativeTo origin: RouteCoordinate
    ) -> (x: Double, y: Double) {
        let earthRadius = 6_371_000.0
        let latitudeDelta = radians(coordinate.latitude - origin.latitude)
        let longitudeDelta = normalizedLongitudeDelta(coordinate.longitude - origin.longitude)
        let meanLatitude = radians((coordinate.latitude + origin.latitude) / 2)
        return (
            x: earthRadius * radians(longitudeDelta) * cos(meanLatitude),
            y: earthRadius * latitudeDelta
        )
    }

    private func normalizedLongitudeDelta(_ degrees: Double) -> Double {
        var result = degrees.truncatingRemainder(dividingBy: 360)
        if result > 180 {
            result -= 360
        } else if result < -180 {
            result += 360
        }
        return result
    }

    private func radians(_ degrees: Double) -> Double {
        degrees * .pi / 180
    }
}
