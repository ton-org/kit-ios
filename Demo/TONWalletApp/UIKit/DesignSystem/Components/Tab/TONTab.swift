import SwiftUI

// Pill tab. Active = bg-black + text-white. Inactive = bg-light-gray + text-black.
// Spec: padding (7v, 12h), gap 4 between optional icon and label, capsule radius.
struct TONTab: View {
    let title: String
    let icon: TONIcon?
    let isActive: Bool
    let action: () -> Void

    init(title: String, icon: TONIcon? = nil, isActive: Bool, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isActive = isActive
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                icon?.image
                    .resizable()
                    .scaledToFit()
                    .size(16)
                    .foregroundStyle(textColor)
                Text(title)
                    .textStyle(.subheadline2Medium)
                    .foregroundStyle(textColor)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Capsule().fill(backgroundColor))
        }
        .buttonStyle(.plain)
    }

    private var backgroundColor: Color { isActive ? .tonBlack : .tonBgLightGray }
    private var textColor: Color       { isActive ? .tonWhite : .tonTextPrimary }
}

#Preview {
    HStack(spacing: 8) {
        TONTab(title: "Trending", isActive: true) {}
        TONTab(title: "Top",      isActive: false) {}
        TONTab(title: "Active",   isActive: false) {}
    }.padding()
}
