import SwiftUI

// Wallet "action" button — vertical icon (24px) over short caption.
// Spec: padding (top 7, bottom 8, h 24), gap 2, rounded-12, label SF Pro Medium 11 (Caption 2 Medium).
// Primary: bg = accent blue, text/icon = white.
// Secondary: bg = 10% accent blue, text/icon = brand.
struct TONActionButton: View {
    enum Style {
        case primary, secondary

        var background: Color {
            switch self {
            case .primary:   return .tonBgBrand
            case .secondary: return .tonBgBrandFillSubtle
            }
        }

        var foreground: Color {
            switch self {
            case .primary:   return .tonTextOnBrand
            case .secondary: return .tonTextBrand
            }
        }
    }

    let icon: TONIcon
    let title: String
    let style: Style
    let action: () -> Void

    init(icon: TONIcon, title: String, style: Style = .primary, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.style = style
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                icon.image
                    .resizable()
                    .scaledToFit()
                    .size(24)
                Text(title)
                    .textStyle(.caption2Medium)
            }
            .foregroundStyle(style.foreground)
            .frame(maxWidth: .infinity)
            .padding(.top, 7)
            .padding(.bottom, 8)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(style.background)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HStack(spacing: 8) {
        TONActionButton(icon: .arrowUpCircle,    title: "Send",    style: .primary)   {}
        TONActionButton(icon: .arrowDownCircle,  title: "Receive", style: .secondary) {}
        TONActionButton(icon: .switchVertical24, title: "Swap",    style: .secondary) {}
    }.padding()
}
