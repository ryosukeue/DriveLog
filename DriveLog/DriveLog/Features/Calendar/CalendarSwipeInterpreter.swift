import CoreGraphics

nonisolated enum CalendarSwipeDirection: Sendable, Equatable {
    case previousMonth
    case nextMonth
}

nonisolated struct CalendarSwipeInterpreter: Sendable {
    private let minimumHorizontalDistance: CGFloat

    init(minimumHorizontalDistance: CGFloat = 50) {
        self.minimumHorizontalDistance = minimumHorizontalDistance
    }

    func direction(translation: CGSize) -> CalendarSwipeDirection? {
        guard abs(translation.width) >= minimumHorizontalDistance,
              abs(translation.width) > abs(translation.height)
        else {
            return nil
        }
        return translation.width < 0 ? .nextMonth : .previousMonth
    }
}
