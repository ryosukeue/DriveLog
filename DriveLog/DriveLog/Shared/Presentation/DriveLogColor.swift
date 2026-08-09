import SwiftUI
import UIKit

extension Color {
    init(hex: String) {
        self.init(uiColor: UIColor(driveLogHex: hex) ?? .systemBlue)
    }
}

extension UIColor {
    convenience init?(driveLogHex: String) {
        let value = driveLogHex
            .trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
            .uppercased()
        guard value.count == 6, let number = UInt64(value, radix: 16) else {
            return nil
        }

        if let systemColor = Self.driveLogSystemColor(for: value) {
            self.init { traits in
                systemColor.resolvedColor(with: traits)
            }
            return
        }

        let red = CGFloat((number >> 16) & 0xFF) / 255
        let green = CGFloat((number >> 8) & 0xFF) / 255
        let blue = CGFloat(number & 0xFF) / 255
        let lightColor = UIColor(red: red, green: green, blue: blue, alpha: 1)
        let darkColor = UIColor(
            red: red + (1 - red) * 0.18,
            green: green + (1 - green) * 0.18,
            blue: blue + (1 - blue) * 0.18,
            alpha: 1
        )
        self.init { traits in
            traits.userInterfaceStyle == .dark ? darkColor : lightColor
        }
    }

    private static func driveLogSystemColor(for hex: String) -> UIColor? {
        switch hex {
        case "007AFF": .systemBlue
        case "34C759": .systemGreen
        case "AF52DE": .systemPurple
        case "FF9500": .systemOrange
        case "00C7BE": .systemTeal
        case "5856D6": .systemIndigo
        default: nil
        }
    }
}
