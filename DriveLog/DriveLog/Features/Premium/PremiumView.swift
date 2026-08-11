import SwiftUI

struct PremiumView: View {
    @State private var plusPlanStore: PlusPlanStore

    init(plusPlanStore: PlusPlanStore) {
        _plusPlanStore = State(initialValue: plusPlanStore)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header
                comparisonTable
                purchaseSection
            }
            .padding()
        }
        .navigationTitle("Premium")
        .task {
            await plusPlanStore.load()
        }
        .alert(
            alertTitle,
            isPresented: Binding(
                get: { showsAlert },
                set: { if !$0 { plusPlanStore.dismissMessage() } }
            )
        ) {
            Button("OK") { plusPlanStore.dismissMessage() }
        } message: {
            Text(alertMessage)
        }
        .accessibilityIdentifier("premium.root")
    }

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: plusPlanStore.isPlus ? "crown.fill" : "sparkles")
                .font(.system(size: 54, weight: .bold))
                .foregroundStyle(.yellow, .orange)
                .accessibilityHidden(true)
            Text("DriveLog Plus")
                .font(.largeTitle.bold())
            Text(
                plusPlanStore.isPlus
                    ? "Plusプランをご利用中です"
                    : plusPlanStore.isEligibleForSevenDayTrial
                        ? "最初の7日間は無料です"
                        : "車との毎日を、もっと詳しく記録"
            )
            .font(.headline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    private var comparisonTable: some View {
        Grid(horizontalSpacing: 12, verticalSpacing: 0) {
            GridRow {
                Text("機能")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("無料")
                Text("Plus")
                    .foregroundStyle(.orange)
            }
            .font(.headline)
            .padding(.vertical, 12)

            Divider().gridCellColumns(3)
            comparisonRow("登録できる車", free: "1台", plus: "無制限")
            Divider().gridCellColumns(3)
            comparisonRow("燃費記録・グラフ", free: "—", plus: "✓")
            Divider().gridCellColumns(3)
            comparisonRow("オイル交換管理", free: "—", plus: "✓")
            Divider().gridCellColumns(3)
            comparisonRow("広告", free: "表示", plus: "なし")
        }
        .padding(.horizontal)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 18))
        .accessibilityIdentifier("premium.comparison")
    }

    private func comparisonRow(_ title: String, free: String, plus: String) -> some View {
        GridRow {
            Text(title)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(free)
                .foregroundStyle(.secondary)
            Text(plus)
                .fontWeight(.semibold)
                .foregroundStyle(.orange)
        }
        .padding(.vertical, 14)
    }

    @ViewBuilder
    private var purchaseSection: some View {
        if plusPlanStore.isPlus {
            VStack(spacing: 12) {
                Label("Plusプランは有効です", systemImage: "checkmark.seal.fill")
                    .font(.headline)
                    .foregroundStyle(.green)
                Link(
                    "サブスクリプションを管理",
                    destination: URL(string: "https://apps.apple.com/account/subscriptions")!
                )
            }
        } else {
            VStack(spacing: 12) {
                Button {
                    Task { await plusPlanStore.purchase() }
                } label: {
                    Group {
                        if plusPlanStore.state == .purchasing {
                            ProgressView()
                        } else if plusPlanStore.isEligibleForSevenDayTrial {
                            Text("7日間無料で試す")
                        } else if let price = plusPlanStore.displayPrice {
                            Text("Plusを始める  \(price)/月")
                        } else {
                            Text("Plusを始める")
                        }
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .disabled(
                    plusPlanStore.product == nil ||
                        plusPlanStore.state == .loading ||
                        plusPlanStore.state == .purchasing
                )

                if plusPlanStore.canUnlockForTestFlight {
                    Button {
                        plusPlanStore.unlockForTestFlight()
                    } label: {
                        Label("テスト用にPlusを解放", systemImage: "hammer.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Text("TestFlightでPlus機能を確認するためのボタンです。料金は発生しません。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                if plusPlanStore.state == .unavailable {
                    Text("現在Plusプランの価格情報を取得できません")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Button("購入を復元") {
                    Task { await plusPlanStore.restorePurchases() }
                }
                .disabled(plusPlanStore.state == .loading)

                if plusPlanStore.isEligibleForSevenDayTrial,
                   let price = plusPlanStore.displayPrice
                {
                    Text("7日間無料、その後は\(price)/月")
                        .font(.subheadline.weight(.semibold))
                }

                Text(
                    (plusPlanStore.isEligibleForSevenDayTrial
                        ? "無料期間終了後は月額の自動更新サブスクリプションとして、"
                        : "月額の自動更新サブスクリプションとして、") +
                        "解約するまで毎月更新されます。" +
                        "購入後はApple Accountのサブスクリプション設定からいつでも解約できます。"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

                HStack(spacing: 12) {
                    Link(
                        "利用規約",
                        destination: URL(
                            string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
                        )!
                    )
                    NavigationLink("プライバシーポリシー") {
                        PrivacyPolicyView()
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
    }

    private var showsAlert: Bool {
        switch plusPlanStore.state {
        case .failed, .pending, .purchased:
            true
        case .idle, .loading, .purchasing, .unavailable:
            false
        }
    }

    private var alertTitle: String {
        switch plusPlanStore.state {
        case .purchased:
            "Plusプランへようこそ！"
        case .pending:
            "購入手続き中です"
        case .failed:
            "Plusプラン"
        case .idle, .loading, .purchasing, .unavailable:
            ""
        }
    }

    private var alertMessage: String {
        switch plusPlanStore.state {
        case let .failed(message):
            message
        case .pending:
            "承認後にPlus機能が自動で有効になります。"
        case .purchased:
            "すべてのPlus機能が利用できるようになりました。"
        case .idle, .loading, .purchasing, .unavailable:
            ""
        }
    }
}
