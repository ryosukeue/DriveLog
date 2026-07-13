import CoreGraphics
@testable import DriveLog
import Testing

@Suite("Calendar swipe interpreter")
struct CalendarSwipeInterpreterTests {
    private let interpreter = CalendarSwipeInterpreter()

    @Test("maps left and right horizontal drags")
    func directions() {
        #expect(interpreter.direction(translation: CGSize(width: -50, height: 5)) == .nextMonth)
        #expect(interpreter.direction(translation: CGSize(width: 80, height: -10)) == .previousMonth)
    }

    @Test("ignores short and vertical drags")
    func ignored() {
        #expect(interpreter.direction(translation: CGSize(width: 49, height: 0)) == nil)
        #expect(interpreter.direction(translation: CGSize(width: 60, height: 60)) == nil)
        #expect(interpreter.direction(translation: CGSize(width: 20, height: 100)) == nil)
    }
}
