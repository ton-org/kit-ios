import SwiftUI

// Spec: padding 10 around 24x24 icon → 44x44 box; rounded-12 (NOT capsule);
// background: tertiary fill (light-gray-transparent at 12%).
struct TONNavbarActionButton: View {
    let icon: TONIcon
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            icon.image
                .resizable()
                .scaledToFit()
                .size(24)
                .foregroundStyle(Color.tonTextPrimary)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.tonBgFillTertiary)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HStack(spacing: 12) {
        TONNavbarActionButton(icon: .headerArrowShare) {}
        TONNavbarActionButton(icon: .headerStar) {}
        TONNavbarActionButton(icon: .filter) {}
    }.padding()
}
