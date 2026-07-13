import SwiftUI

private enum ContentRoute: Hashable {
    case dayDetail(String)
    case fullMap(id: UUID, scene: MapScene, media: [MediaAssetReference])
    case mediaPreview(id: UUID, asset: MediaAssetReference)

    static func == (lhs: ContentRoute, rhs: ContentRoute) -> Bool {
        switch (lhs, rhs) {
        case let (.dayDetail(lhsKey), .dayDetail(rhsKey)):
            lhsKey == rhsKey
        case let (.fullMap(lhsID, _, _), .fullMap(rhsID, _, _)):
            lhsID == rhsID
        case let (.mediaPreview(lhsID, _), .mediaPreview(rhsID, _)):
            lhsID == rhsID
        default:
            false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case let .dayDetail(localDateKey):
            hasher.combine(0)
            hasher.combine(localDateKey)
        case let .fullMap(id, _, _):
            hasher.combine(1)
            hasher.combine(id)
        case let .mediaPreview(id, _):
            hasher.combine(2)
            hasher.combine(id)
        }
    }
}

struct ContentView: View {
    let calendarViewModel: CalendarViewModel
    let today: Date
    let makeDayDetailViewModel: (String) -> DayDetailViewModel
    let loadMediaThumbnail: any LoadMediaThumbnailUseCase
    let makeMediaPreviewViewModel: (MediaAssetReference) -> MediaPreviewViewModel
    @State private var path: [ContentRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            CalendarView(
                viewModel: calendarViewModel,
                today: today,
                onSelectDate: { path.append(.dayDetail($0)) }
            )
            .navigationDestination(for: ContentRoute.self) { route in
                switch route {
                case let .dayDetail(localDateKey):
                    DayDetailView(
                        viewModel: makeDayDetailViewModel(localDateKey),
                        onOpenMap: { scene, media in
                            path.append(.fullMap(id: UUID(), scene: scene, media: media))
                        },
                        onSelectMedia: { asset in
                            path.append(.mediaPreview(id: UUID(), asset: asset))
                        }
                    )
                case let .fullMap(_, scene, media):
                    FullRouteMapView(
                        viewModel: RouteMapViewModel(scene: scene, media: media),
                        thumbnailLoader: loadMediaThumbnail,
                        onSelectMedia: { asset in
                            path.append(.mediaPreview(id: UUID(), asset: asset))
                        }
                    )
                case let .mediaPreview(_, asset):
                    MediaPreviewView(viewModel: makeMediaPreviewViewModel(asset))
                }
            }
        }
    }
}
