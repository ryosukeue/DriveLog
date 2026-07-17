import UIKit

final class RouteMapMetricsView: UIVisualEffectView {
    static let preferredHeight: CGFloat = 82

    private let rowsStack = UIStackView()
    private let titleRow = UIStackView()
    private let valueRow = UIStackView()

    init() {
        super.init(effect: UIBlurEffect(style: .systemMaterial))
        layer.cornerRadius = 16
        layer.masksToBounds = true

        configure(row: titleRow)
        configure(row: valueRow)

        rowsStack.addArrangedSubview(titleRow)
        rowsStack.addArrangedSubview(valueRow)
        rowsStack.axis = .vertical
        rowsStack.alignment = .fill
        rowsStack.distribution = .fillEqually
        rowsStack.spacing = 2
        rowsStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(rowsStack)
        NSLayoutConstraint.activate([
            rowsStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            rowsStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            rowsStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            rowsStack.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 9),
            rowsStack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -9)
        ])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        nil
    }

    func configure(items: [(title: String, value: String)]) {
        removeArrangedSubviews(from: titleRow)
        removeArrangedSubviews(from: valueRow)

        for item in items {
            titleRow.addArrangedSubview(titleLabel(text: item.title))
            valueRow.addArrangedSubview(valueLabel(text: item.value))
        }
        accessibilityLabel = items
            .map { "\($0.title) \($0.value)" }
            .joined(separator: "、")
    }

    private func configure(row: UIStackView) {
        row.axis = .horizontal
        row.alignment = .fill
        row.distribution = .fillEqually
        row.spacing = 6
        row.isAccessibilityElement = false
    }

    private func removeArrangedSubviews(from stack: UIStackView) {
        for view in stack.arrangedSubviews {
            stack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
    }

    private func titleLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .preferredFont(forTextStyle: .caption1)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 1
        label.accessibilityIdentifier = "map.metric.title"
        return label
    }

    private func valueLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .preferredFont(forTextStyle: .title3)
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.6
        label.baselineAdjustment = .alignCenters
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 1
        label.accessibilityIdentifier = "map.metric.value"
        return label
    }
}
