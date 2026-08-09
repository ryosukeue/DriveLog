import GoogleMobileAds
import SwiftUI

enum AdMobConfiguration {
    private static var hasStarted = false
    static var appID: String? { configuredValue(for: "GADApplicationIdentifier") }
    static var bannerUnitID: String? { configuredValue(for: "AdMobBannerUnitID") }

    static func startIfConfigured() {
        guard !hasStarted, appID != nil, bannerUnitID != nil else { return }
        hasStarted = true
        MobileAds.shared.start()
    }

    private static func configuredValue(for key: String) -> String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String,
              !value.isEmpty,
              !value.hasPrefix("YOUR_")
        else { return nil }
        return value
    }
}

struct AdMobBannerView: UIViewRepresentable {
    func makeUIView(context _: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = AdMobConfiguration.bannerUnitID
        banner.backgroundColor = .secondarySystemBackground
        banner.load(Request())
        return banner
    }

    func updateUIView(_: BannerView, context _: Context) {}
}

struct CalendarBannerAd: View {
    var body: some View {
        if AdMobConfiguration.bannerUnitID != nil {
            AdMobBannerView()
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .background(Color(uiColor: .secondarySystemBackground))
                .accessibilityIdentifier("calendar.bannerAd")
        }
    }
}
