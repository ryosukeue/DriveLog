@MainActor
protocol ObservePhotoLibraryChangesUseCase: Sendable {
    var changes: AsyncStream<PhotoLibraryChange> { get }
}

@MainActor
struct DefaultObservePhotoLibraryChangesUseCase: ObservePhotoLibraryChangesUseCase {
    let changes: AsyncStream<PhotoLibraryChange>

    init(photoLibrary: any PhotoLibraryProviding) {
        changes = photoLibrary.libraryChanges
    }
}
