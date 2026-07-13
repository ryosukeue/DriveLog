import Foundation

@MainActor
protocol SharePresenting: AnyObject {
    func presentShareSheet(resource: ShareableMediaResource) async throws
}
