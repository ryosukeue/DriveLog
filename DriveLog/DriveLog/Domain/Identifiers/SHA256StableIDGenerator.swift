import CryptoKit
import Foundation

struct SHA256StableIDGenerator: StableIDGenerating {
    func movementSegmentID(
        localDateKey: String,
        startDate: Date,
        endDate: Date
    ) -> String {
        hash([
            localDateKey,
            String(roundedMinute(startDate)),
            String(roundedMinute(endDate))
        ].joined(separator: "|"))
    }

    func staySegmentID(
        localDateKey: String,
        arrivalDate: Date,
        departureDate: Date,
        latitude: Double,
        longitude: Double
    ) -> String {
        hash([
            localDateKey,
            String(roundedMinute(arrivalDate)),
            String(roundedMinute(departureDate)),
            coordinateString(latitude),
            coordinateString(longitude)
        ].joined(separator: "|"))
    }

    private func roundedMinute(_ date: Date) -> Int64 {
        Int64((date.timeIntervalSince1970 / 60).rounded()) * 60
    }

    private func coordinateString(_ coordinate: Double) -> String {
        let rounded = (coordinate * 10000).rounded() / 10000
        let normalized = rounded == 0 ? 0 : rounded
        return String(format: "%.4f", locale: Locale(identifier: "en_US_POSIX"), normalized)
    }

    private func hash(_ seed: String) -> String {
        SHA256.hash(data: Data(seed.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
