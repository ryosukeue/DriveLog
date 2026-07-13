@testable import DriveLog
import Foundation
import Testing

@Suite("Day detail formatter")
struct DayDetailFormatterTests {
    private let formatter = DayDetailFormatter(
        timeZone: TimeZone(secondsFromGMT: 9 * 60 * 60) ?? .gmt,
        locale: Locale(identifier: "en_US")
    )

    @Test("formats distance")
    func distance() {
        #expect(formatter.distance(meters: 1250) == "1.2km")
        #expect(formatter.distance(meters: -.infinity) == "--")
    }

    @Test("formats duration without waiting")
    func duration() {
        #expect(formatter.duration(seconds: 59) == "0分")
        #expect(formatter.duration(seconds: 90) == "1分")
        #expect(formatter.duration(seconds: 3720) == "1時間 2分")
        #expect(formatter.duration(seconds: -.infinity) == "--")
    }

    @Test("formats optional time in the injected time zone")
    func time() {
        #expect(formatter.time(Date(timeIntervalSince1970: 0)) == "9:00")
        #expect(formatter.time(nil) == "--")
    }

    @Test("formats all automatic classifications")
    func classification() {
        #expect(formatter.classification(.automotiveLike) == "車っぽい移動")
        #expect(formatter.classification(.walkingLike) == "徒歩っぽい移動")
        #expect(formatter.classification(AutomaticMovementType.other) == "その他")
        #expect(formatter.classification(UserMovementClassification.automotive) == "車")
        #expect(formatter.classification(UserMovementClassification?.none) == "未設定")
    }

    @Test("formats segment average speed")
    func speed() {
        #expect(formatter.averageSpeed(metersPerSecond: 10) == "36.0km/h")
        #expect(formatter.averageSpeed(metersPerSecond: nil) == "--")
        #expect(formatter.averageSpeed(metersPerSecond: -.infinity) == "--")
    }

    @Test("formats all stay confidence values")
    func stayConfidence() {
        #expect(formatter.stayConfidence(.low) == "低")
        #expect(formatter.stayConfidence(.medium) == "中")
        #expect(formatter.stayConfidence(.high) == "高")
    }
}
