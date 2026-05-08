#if DEBUG
import SwiftUI

struct IconsDebugView: View {
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ForEach(TONIcon.Category.allCases, id: \.self) { category in
                    categorySection(category)
                }
                footer
            }
            .padding(20)
        }
        .background(Color.tonBgPrimary)
        .navigationTitle("Icons")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func categorySection(_ category: TONIcon.Category) -> some View {
        let icons = TONIcon.allCases.filter { $0.category == category }
        VStack(alignment: .leading, spacing: 12) {
            Text(category.rawValue)
                .textStyle(.footnoteCaps)
                .foregroundStyle(Color.tonTextTertiary)
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(icons, id: \.self) { icon in
                    iconCell(icon)
                }
            }
        }
    }

    private func iconCell(_ icon: TONIcon) -> some View {
        VStack(spacing: 6) {
            icon.image
                .resizable()
                .scaledToFit()
                .size(24)
                .foregroundStyle(Color.tonTextPrimary)
            Text(icon.rawValue)
                .textStyle(.caption2Semibold)
                .foregroundStyle(Color.tonTextSecondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
    }

    private var footer: some View {
        Text("89 icons imported from Demo App UI Kit, organized by intrinsic size.")
            .textStyle(.caption1)
            .foregroundStyle(Color.tonTextTertiary)
            .padding(.top, 8)
    }
}

#Preview { NavigationStack { IconsDebugView() } }
#endif
