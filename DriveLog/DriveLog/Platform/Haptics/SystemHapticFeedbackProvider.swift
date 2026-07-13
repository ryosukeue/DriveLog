import UIKit

struct SystemHapticFeedbackProvider: HapticFeedbackProviding {
    func performLightSuccess() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
