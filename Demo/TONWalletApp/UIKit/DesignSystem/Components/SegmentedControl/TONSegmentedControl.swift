import SwiftUI

private enum Layout {
    static let height: CGFloat = 36
    static let trackVerticalPadding: CGFloat = 2
    static let trackHorizontalPadding: CGFloat = 3
    static let trackCornerRadius: CGFloat = 18
    static let tabCornerRadius: CGFloat = 16
    static let tabHeight: CGFloat = 32
}

struct TONSegmentedControl<Item: Hashable>: View {
    @Binding var selection: Item
    let items: [Item]
    let title: (Item) -> String
    @Namespace private var pillNamespace

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                let isSelected = item == selection
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selection = item
                    }
                } label: {
                    Text(title(item))
                        .textStyle(.subheadline2Semibold)
                        .foregroundStyle(Color.tonTextPrimary)
                        .frame(maxWidth: .infinity, minHeight: Layout.tabHeight)
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: Layout.tabCornerRadius, style: .continuous)
                                    .fill(Color.tonBgPrimary)
                                    .matchedGeometryEffect(id: "pill", in: pillNamespace)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, Layout.trackVerticalPadding)
        .padding(.horizontal, Layout.trackHorizontalPadding)
        .frame(height: Layout.height)
        .background(
            RoundedRectangle(cornerRadius: Layout.trackCornerRadius, style: .continuous)
                .fill(Color.tonBgFillQuaternary)
        )
    }
}

#Preview { StatefulPreview() }
private struct StatefulPreview: View {
    @State private var selection = "1D"
    var body: some View {
        TONSegmentedControl(
            selection: $selection,
            items: ["1H", "1D", "1W", "1M", "ALL"],
            title: { $0 }
        ).padding()
    }
}
