import Foundation

@MainActor
protocol ShareMediaUseCase: AnyObject {
    func execute(localIdentifier: String) async throws
}

@MainActor
final class DefaultShareMediaUseCase: ShareMediaUseCase {
    private let photoLibrary: any PhotoLibraryProviding
    private let presenter: any SharePresenting
    private let fileManager: FileManager

    init(
        photoLibrary: any PhotoLibraryProviding,
        presenter: any SharePresenting,
        fileManager: FileManager = .default
    ) {
        self.photoLibrary = photoLibrary
        self.presenter = presenter
        self.fileManager = fileManager
    }

    func execute(localIdentifier: String) async throws {
        guard localIdentifier.isEmpty == false else { throw DriveLogError.invalidData }
        let resource = try await photoLibrary.requestShareableResource(
            localIdentifier: localIdentifier
        )
        do {
            try await presenter.presentShareSheet(resource: resource)
        } catch {
            try? remove(resource.fileURL)
            throw error
        }
        do {
            try remove(resource.fileURL)
        } catch {
            throw DriveLogError.unknown(code: "share_cleanup")
        }
    }

    private func remove(_ fileURL: URL) throws {
        guard fileManager.fileExists(atPath: fileURL.path) else { return }
        try fileManager.removeItem(at: fileURL)
    }
}
