import Foundation

nonisolated struct MonthlyOverviewData: Sendable, Equatable {
    let month: LocalMonth
    let mapScene: MapScene
    let movements: [MovementSegmentData]
    let stays: [StaySegmentData]
    let media: [MediaAssetReference]

    var isEmpty: Bool {
        movements.isEmpty && stays.isEmpty && media.isEmpty
    }
}
