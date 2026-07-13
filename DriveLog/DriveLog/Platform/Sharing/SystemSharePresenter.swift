import UIKit

@MainActor
final class SystemSharePresenter: SharePresenting {
    func presentShareSheet(resource: ShareableMediaResource) async throws {
        guard let presenter = activePresenter() else {
            throw DriveLogError.mediaUnavailable
        }
        try await withCheckedThrowingContinuation { continuation in
            let controller = UIActivityViewController(
                activityItems: [resource.fileURL],
                applicationActivities: nil
            )
            controller.completionWithItemsHandler = { _, _, _, error in
                if error == nil {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: DriveLogError.mediaUnavailable)
                }
            }
            controller.popoverPresentationController?.sourceView = presenter.view
            controller.popoverPresentationController?.sourceRect = CGRect(
                x: presenter.view.bounds.midX,
                y: presenter.view.bounds.midY,
                width: 0,
                height: 0
            )
            presenter.present(controller, animated: true)
        }
    }

    private func activePresenter() -> UIViewController? {
        let root = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }?
            .windows
            .first { $0.isKeyWindow }?
            .rootViewController
        var presenter = root
        while let presented = presenter?.presentedViewController {
            presenter = presented
        }
        return presenter
    }
}
