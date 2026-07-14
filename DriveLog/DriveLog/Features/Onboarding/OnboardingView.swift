import SwiftUI

struct OnboardingView: View {
    let onStart: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("DriveLog")
                        .font(.largeTitle.bold())
                    Text("移動した日を、地図と写真で振り返るための記録アプリです。")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                permissionRow(
                    title: "位置情報",
                    description: "大きな移動をバックグラウンドで記録するために使用します。",
                    systemImage: "location.fill"
                )
                permissionRow(
                    title: "モーション",
                    description: "徒歩や車など、移動方法を端末上で推定するために使用します。",
                    systemImage: "figure.walk.motion"
                )
                permissionRow(
                    title: "写真と動画",
                    description: "移動した日に撮影した写真や動画を振り返るために使用します。",
                    systemImage: "photo.on.rectangle"
                )
                Label {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("プライバシー")
                            .font(.headline)
                        Text("データは端末内で処理され、外部サーバーへ送信されません。")
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "lock.shield.fill")
                        .foregroundStyle(.accent)
                }
                .accessibilityElement(children: .combine)
                Button("権限設定を始める") {
                    onStart()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("onboarding.start")
            }
            .frame(maxWidth: 560, alignment: .leading)
            .padding(24)
        }
        .accessibilityIdentifier("onboarding.root")
    }

    private func permissionRow(
        title: String,
        description: String,
        systemImage: String
    ) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(.accent)
                .frame(width: 36)
        }
        .accessibilityElement(children: .combine)
    }
}
