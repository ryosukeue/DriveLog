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

private enum RootTab: Hashable {
    case calendar
    case analytics
    case friends
    case vehicles
    case premium
}

struct ContentView: View {
    let calendarViewModel: CalendarViewModel
    let monthlySummaryViewModel: MonthlySummaryViewModel
    let monthlyOverviewViewModel: MonthlyOverviewViewModel
    let analyticsViewModel: AnalyticsViewModel
    let friendsViewModel: FriendsViewModel
    let iCloudSetupViewModel: ICloudSetupViewModel
    let vehiclesViewModel: VehiclesViewModel
    let plusPlanStore: PlusPlanStore
    let today: Date
    let makeDayDetailViewModel: (String) -> DayDetailViewModel
    let loadMediaThumbnail: any LoadMediaThumbnailUseCase
    let updateStayOverride: any UpdateStayOverrideUseCase
    let hapticFeedback: any HapticFeedbackProviding
    let makeMediaPreviewViewModel: (MediaAssetReference) -> MediaPreviewViewModel
    @State private var selectedDay: SelectedDay?
    @State private var detailPath: [ContentRoute] = []
    @State private var selectedTab: RootTab = .calendar

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                CalendarView(
                    viewModel: calendarViewModel,
                    monthlySummaryViewModel: monthlySummaryViewModel,
                    monthlyOverviewViewModel: monthlyOverviewViewModel,
                    today: today,
                    onSelectDate: {
                        detailPath.removeAll()
                        selectedDay = SelectedDay(localDateKey: $0)
                    },
                    thumbnailLoader: loadMediaThumbnail,
                    updateStayOverride: updateStayOverride,
                    hapticFeedback: hapticFeedback,
                    makeMediaPreviewViewModel: makeMediaPreviewViewModel,
                    showsAds: plusPlanStore.hasResolvedEntitlement && !plusPlanStore.isPlus
                )
            }
            .tabItem {
                Label("カレンダー", systemImage: "calendar")
            }
            .accessibilityIdentifier("tab.calendar")
            .tag(RootTab.calendar)

            NavigationStack {
                AnalyticsView(
                    viewModel: analyticsViewModel,
                    isPlusEnabled: plusPlanStore.isPlus,
                    onShowPremium: { selectedTab = .premium }
                )
            }
            .tabItem {
                Label("アナリティクス", systemImage: "chart.bar.xaxis")
            }
            .accessibilityIdentifier("tab.analytics")
            .tag(RootTab.analytics)

            NavigationStack {
                FriendsView(
                    viewModel: friendsViewModel,
                    iCloudSetupViewModel: iCloudSetupViewModel
                )
            }
            .tabItem {
                Label("友達", systemImage: "person.2.fill")
            }
            .accessibilityIdentifier("tab.friends")
            .tag(RootTab.friends)

            NavigationStack {
                VehiclesView(
                    viewModel: vehiclesViewModel,
                    onShowPremium: { selectedTab = .premium }
                )
            }
            .tabItem {
                Label("車種登録", systemImage: "car.fill")
            }
            .accessibilityIdentifier("tab.vehicles")
            .tag(RootTab.vehicles)

            NavigationStack {
                PremiumView(plusPlanStore: plusPlanStore)
            }
            .tabItem {
                Label("Premium", systemImage: "crown.fill")
            }
            .accessibilityIdentifier("tab.premium")
            .tag(RootTab.premium)
        }
        .onOpenURL { url in
            Task { await friendsViewModel.acceptInvitation(url) }
        }
        .task {
            #if DEBUG
                if ProcessInfo.processInfo.arguments.contains("-ui-testing-fuel-review") {
                    selectedTab = .analytics
                }
            #endif
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
                onSelectMedia: openMedia,
                onBack: closeTopDestination
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

    private func closeTopDestination() {
        guard !detailPath.isEmpty else { return }
        detailPath.removeLast()
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
    @State private var deletionLocalDateKey: String?
    @State private var isShowingDeletionConfirmation = false

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
                        onSelectMedia: onSelectMedia
                    )
                    .tag(localDateKey)
                }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("この日の記録を削除", role: .destructive) {
                        deletionLocalDateKey = selectedLocalDateKey
                        isShowingDeletionConfirmation = true
                    }
                    .accessibilityIdentifier("dayDetail.delete")
                } label: {
                    Label("その他の操作", systemImage: "ellipsis.circle")
                }
                .accessibilityIdentifier("dayDetail.menu")
                .disabled(selectedViewModel?.isDeleting ?? true)
            }
        }
        .confirmationDialog(
            "この日の記録を削除しますか？",
            isPresented: $isShowingDeletionConfirmation,
            titleVisibility: .visible
        ) {
            Button("削除", role: .destructive) {
                deleteConfirmedDay()
            }
            .accessibilityIdentifier("dayDetail.delete.confirm")
            Button("キャンセル", role: .cancel) {}
                .accessibilityIdentifier("dayDetail.delete.cancel")
        } message: {
            Text("""
            位置情報、移動区間、滞在地点、分類修正が削除されます。
            写真アプリ内の写真や動画は削除されません。
            この操作は取り消せません。
            """)
        }
        .alert("削除できませんでした", isPresented: deletionErrorBinding) {
            Button("OK") {
                deletionViewModel?.dismissDeletionError()
            }
        } message: {
            Text("時間をおいて、もう一度お試しください")
        }
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

    private var selectedViewModel: DayDetailViewModel? {
        viewModels[selectedLocalDateKey]
    }

    private var deletionViewModel: DayDetailViewModel? {
        guard let deletionLocalDateKey else { return nil }
        return viewModels[deletionLocalDateKey]
    }

    private var navigationTitle: String {
        let components = selectedLocalDateKey.split(separator: "-")
        guard components.count == 3,
              let month = Int(components[1]),
              let day = Int(components[2])
        else { return selectedLocalDateKey }
        return "\(month)月\(day)日"
    }

    private var deletionErrorBinding: Binding<Bool> {
        Binding(
            get: { deletionViewModel?.deletionFailed ?? false },
            set: { isPresented in
                if !isPresented {
                    deletionViewModel?.dismissDeletionError()
                }
            }
        )
    }

    private func deleteConfirmedDay() {
        guard let deletionViewModel else { return }
        Task { @MainActor in
            if await deletionViewModel.deleteDay() {
                onDeletionCompleted()
            }
        }
    }
}
