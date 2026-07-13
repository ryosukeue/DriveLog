import SwiftUI

struct DayMapPreview: View {
    let scene: MapScene
    let onOpenMap: () -> Void

    var body: some View {
        ZStack {
            RouteMapView(scene: scene, mode: .preview)
                .allowsHitTesting(false)
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.body.weight(.semibold))
                        .padding(10)
                        .background(.regularMaterial, in: Circle())
                        .padding(12)
                        .accessibilityHidden(true)
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))

            Button(action: onOpenMap) {
                Color.clear
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("全画面地図を開く")
            .accessibilityIdentifier("dayDetail.mapPreview")
        }
    }
}
