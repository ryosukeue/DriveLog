import SwiftUI

struct MediaGridColumnPolicy {
    func columnCount(for dynamicTypeSize: DynamicTypeSize) -> Int {
        dynamicTypeSize.isAccessibilitySize ? 2 : 4
    }
}

struct MediaGridSection: View {
    let media: [MediaAssetReference]
    let loadThumbnail: @MainActor @Sendable (String, CGSize) async throws -> UIImage
    let onSelect: (MediaAssetReference) -> Void
    private let title: String
    private let emptyMessage: String
    private let gridIdentifier: String

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private let spacing: CGFloat = 6

    init(
        media: [MediaAssetReference],
        loadThumbnail: @escaping @MainActor @Sendable (String, CGSize) async throws -> UIImage,
        onSelect: @escaping (MediaAssetReference) -> Void,
        title: String = "写真・動画",
        emptyMessage: String = "この日の写真・動画はありません",
        gridIdentifier: String = "dayDetail.media.grid"
    ) {
        self.media = media
        self.loadThumbnail = loadThumbnail
        self.onSelect = onSelect
        self.title = title
        self.emptyMessage = emptyMessage
        self.gridIdentifier = gridIdentifier
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            if media.isEmpty {
                Label(emptyMessage, systemImage: "photo.on.rectangle.angled")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 88)
                    .accessibilityIdentifier("dayDetail.media.empty")
            } else {
                LazyVGrid(columns: columns, spacing: spacing) {
                    ForEach(media, id: \.localIdentifier) { asset in
                        MediaThumbnailCell(
                            asset: asset,
                            loadThumbnail: { localIdentifier, targetSize in
                                try await loadThumbnail(localIdentifier, targetSize)
                            },
                            onSelect: onSelect
                        )
                    }
                }
                .accessibilityIdentifier(gridIdentifier)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var columns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: spacing),
            count: MediaGridColumnPolicy().columnCount(for: dynamicTypeSize)
        )
    }
}

private struct MediaThumbnailCell: View {
    let asset: MediaAssetReference
    let loadThumbnail: @MainActor @Sendable (String, CGSize) async throws -> UIImage
    let onSelect: (MediaAssetReference) -> Void

    @State private var image: UIImage?
    @State private var didFail = false

    var body: some View {
        Button {
            onSelect(asset)
        } label: {
            ZStack {
                Color(.secondarySystemBackground)
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else if didFail {
                    Image(systemName: "photo.badge.exclamationmark")
                        .foregroundStyle(.secondary)
                } else {
                    ProgressView()
                }
                if asset.mediaType == .video {
                    Image(systemName: "play.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(7)
                        .background(.black.opacity(0.65), in: Circle())
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(asset.mediaType == .video ? "動画" : "写真")
        .accessibilityIdentifier("dayDetail.media.cell")
        .task(id: asset.localIdentifier) {
            await load()
        }
    }

    @MainActor
    private func load() async {
        do {
            image = try await loadThumbnail(
                asset.localIdentifier,
                CGSize(width: 180, height: 180)
            )
            didFail = false
        } catch is CancellationError {
            return
        } catch {
            didFail = true
        }
    }
}
