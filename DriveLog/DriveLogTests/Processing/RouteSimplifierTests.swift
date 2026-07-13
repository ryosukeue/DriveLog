@testable import DriveLog
import Testing

@Suite("Route simplifier")
struct RouteSimplifierTests {
    private let simplifier = RouteSimplifier(rules: ProcessingConfiguration.mvp.route)

    @Test("returns routes with fewer than ten points unchanged")
    func belowMinimumPointCount() {
        let empty: [RouteCoordinate] = []
        let single = [coordinate(eastMeters: 0, northMeters: 0)]
        let nine = straightRoute(count: 9)

        #expect(simplifier.simplify(empty) == empty)
        #expect(simplifier.simplify(single) == single)
        #expect(simplifier.simplify(nine) == nine)
    }

    @Test("simplifies a ten point straight route to its endpoints")
    func straightRoute() {
        let input = straightRoute(count: 10)
        let output = simplifier.simplify(input)

        #expect(output == [input[0], input[9]])
    }

    @Test("removes a point at the tolerance and keeps one above it")
    func toleranceBoundary() {
        let atTolerance = routeWithMiddleOffset(30)
        let aboveTolerance = routeWithMiddleOffset(30.1)

        #expect(simplifier.simplify(atTolerance).count == 2)
        #expect(simplifier.simplify(aboveTolerance).contains(aboveTolerance[5]))
    }

    @Test("preserves curved route shape and both endpoints")
    func curvedRoute() {
        let input = (0 ..< 10).map { index in
            coordinate(eastMeters: Double(index) * 100, northMeters: index == 5 ? 100 : 0)
        }
        let output = simplifier.simplify(input)

        #expect(output.first == input.first)
        #expect(output.last == input.last)
        #expect(output.contains(input[5]))
        #expect(output.count < input.count)
    }

    @Test("handles repeated coordinates without mutating the input")
    func repeatedCoordinatesAndInputImmutability() {
        let repeated = coordinate(eastMeters: 10, northMeters: 10)
        let input = Array(repeating: repeated, count: 10)
        let original = input
        let output = simplifier.simplify(input)

        #expect(output == [repeated, repeated])
        #expect(input == original)
    }

    private func straightRoute(count: Int) -> [RouteCoordinate] {
        (0 ..< count).map { coordinate(eastMeters: Double($0) * 100, northMeters: 0) }
    }

    private func routeWithMiddleOffset(_ offset: Double) -> [RouteCoordinate] {
        (0 ..< 10).map { index in
            coordinate(eastMeters: Double(index) * 100, northMeters: index == 5 ? offset : 0)
        }
    }

    private func coordinate(eastMeters: Double, northMeters: Double) -> RouteCoordinate {
        let earthRadius = 6_371_000.0
        return RouteCoordinate(
            latitude: northMeters / earthRadius * 180 / .pi,
            longitude: eastMeters / earthRadius * 180 / .pi
        )
    }
}
