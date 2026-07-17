import SwiftUI

private struct SelectedDay: Identifiable {
    let localDateKey: String

    var id: String {
        localDateKey
    }
}

private enum ContentRoute: Hashable {
    case fullMap(
        id: UUID,
        scene: MapScene,
        media: [MediaAssetReference],
        movements: [MovementDisplayData],
        stays: [StayDisplayData]
    )
    case mediaPreview(
        id: UUID,
        assets: [MediaAssetReference],
        selectedIdentifier: String
    )

    static func == (lhs: ContentRoute, rhs: ContentRoute) -> Bool {
        switch (lhs, rhs) {
        case let (.fullMap(lhsID, _, _, _, _), .fullMap(rhsID, _, _, _, _)):
            lhsID == rhsID
        case let (.mediaPreview(lhsID, _, _), .mediaPreview(rhsID, _, _)):
            lhsID == rhsID
        default:
            false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case let .fullMap(id, _, _, _, _):
            hasher.combine(0)
            hasher.combine(id)
        case let .mediaPreview(id, _, _):
            hasher.combine(1)
            hasher.combine(id)
        }
    }
}

struct ContentView: View {
    let calendarViewModel: CalendarViewModel
    let today: Date
    let makeDayDetailViewModel: (String) -> DayDetailViewModel
    let loadMediaThumbnail: any LoadMediaThumbnailUseCase
    let updateStayOverride: any UpdateStayOverrideUseCase
    let hapticFeedback: any HapticFeedbackProviding
    let makeMediaPreviewViewModel: (MediaAssetReference) -> MediaPreviewViewModel
    @State private var selectedDay: SelectedDay?
    @State private var detailPath: [ContentRoute] = []

    var body: some View {
        NavigationStack {
            CalendarView(
                viewModel: calendarViewModel,
                today: today,
                onSelectDate: {
                    detailPath.removeAll()
                    selectedDay = SelectedDay(localDateKey: $0)
                }
            )
        }
        .sheet(
            item: $selectedDay,
            onDismiss: {
                detailPath.removeAll()
            },
            content: { day in
                NavigationStack(path: $detailPath) {
                    DayDetailPagerView(
                        localDateKeys: calendarViewModel.validLocalDateKeys,
                        initialLocalDateKey: day.localDateKey,
                        makeViewModel: makeDayDetailViewModel,
                        onOpenMap: openMap,
                        onSelectMedia: openMedia,
                        onSelectDate: selectDisplayedDate,
                        onDeletionCompleted: completeDeletion
                    )
                    .navigationDestination(for: ContentRoute.self) { route in
                        destination(for: route)
                    }
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(24)
            }
        )
    }

    @ViewBuilder
    private func destination(for route: ContentRoute) -> some View {
        switch route {
        case let .fullMap(_, scene, media, movements, stays):
            FullRouteMapView(
                viewModel: RouteMapViewModel(
                    scene: scene,
                    media: media,
                    movements: movements,
                    stays: stays,
                    updateStayOverride: updateStayOverride,
                    hapticFeedback: hapticFeedback
                ),
                thumbnailLoader: loadMediaThumbnail,
                onSelectMedia: openMedia
            )
        case let .mediaPreview(_, assets, selectedIdentifier):
            MediaPreviewView(
                viewModels: assets.map(makeMediaPreviewViewModel),
                selectedIdentifier: selectedIdentifier
            )
        }
    }

    private func openMap(
        scene: MapScene,
        media: [MediaAssetReference],
        movements: [MovementDisplayData],
        stays: [StayDisplayData]
    ) {
        detailPath.append(.fullMap(
            id: UUID(),
            scene: scene,
            media: media,
            movements: movements,
            stays: stays
        ))
    }

    private func openMedia(
        asset: MediaAssetReference,
        assets: [MediaAssetReference]
    ) {
        detailPath.append(.mediaPreview(
            id: UUID(),
            assets: assets,
            selectedIdentifier: asset.localIdentifier
        ))
    }

    private func selectDisplayedDate(_ localDateKey: String) {
        calendarViewModel.select(localDateKey: localDateKey)
        calendarViewModel.consumeNavigation()
    }

    private func completeDeletion() {
        selectedDay = nil
        Task { @MainActor in
            await calendarViewModel.load()
        }
    }
}

private struct DayDetailPagerView: View {
    let localDateKeys: [String]
    let onOpenMap: (
        MapScene,
        [MediaAssetReference],
        [MovementDisplayData],
        [StayDisplayData]
    ) -> Void
    let onSelectMedia: (MediaAssetReference, [MediaAssetReference]) -> Void
    let onSelectDate: (String) -> Void
    let onDeletionCompleted: () -> Void
    @State private var selectedLocalDateKey: String
    @State private var viewModels: [String: DayDetailViewModel]

    init(
        localDateKeys: [String],
        initialLocalDateKey: String,
        makeViewModel: (String) -> DayDetailViewModel,
        onOpenMap: @escaping (
            MapScene,
            [MediaAssetReference],
            [MovementDisplayData],
            [StayDisplayData]
        ) -> Void,
        onSelectMedia: @escaping (MediaAssetReference, [MediaAssetReference]) -> Void,
        onSelectDate: @escaping (String) -> Void,
        onDeletionCompleted: @escaping () -> Void
    ) {
        let availableKeys = localDateKeys.contains(initialLocalDateKey)
            ? localDateKeys : [initialLocalDateKey]
        self.localDateKeys = availableKeys
        self.onOpenMap = onOpenMap
        self.onSelectMedia = onSelectMedia
        self.onSelectDate = onSelectDate
        self.onDeletionCompleted = onDeletionCompleted
        _selectedLocalDateKey = State(initialValue: initialLocalDateKey)
        _viewModels = State(initialValue: Dictionary(
            uniqueKeysWithValues: availableKeys.map { ($0, makeViewModel($0)) }
        ))
    }

    var body: some View {
        TabView(selection: $selectedLocalDateKey) {
            ForEach(localDateKeys, id: \.self) { localDateKey in
                if let viewModel = viewModels[localDateKey] {
                    DayDetailView(
                        viewModel: viewModel,
                        onOpenMap: onOpenMap,
                        onSelectMedia: onSelectMedia,
                        onDeletionCompleted: onDeletionCompleted
                    )
                    .tag(localDateKey)
                }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .accessibilityIdentifier("dayDetail.pager")
        .overlay(alignment: .topLeading) {
            Color.clear
                .frame(width: 1, height: 1)
                .accessibilityElement()
                .accessibilityLabel(selectedLocalDateKey)
                .accessibilityIdentifier("dayDetail.currentDate")
        }
        .onChange(of: selectedLocalDateKey) { _, localDateKey in
            onSelectDate(localDateKey)
        }
    }
}
