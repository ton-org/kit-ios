import SwiftUI

// Wallet "action" button — vertical icon (24px) over a short caption.
// Primary:   bg = accent blue,      text/icon = white.
// Secondary: bg = 10% accent blue,  text/icon = brand.   (both: gap 2, radius 12, Caption 2 Medium)
// Tertiary:  bg = secondary gray,   icon = brand, label = primary.
//            Home Send/Swap/Stake tiles — gap 8, radius 24, Subheadline 2 Semibold (14),
//            vertical padding 12 → 74pt height.
struct TONActionButton: View {
    enum Style {
        case primary, secondary, tertiary

        var background: Color {
            switch self {
            case .primary:   return .tonBgBrand
            case .secondary: return .tonBgBrandFillSubtle
            case .tertiary:  return .tonBgSecondary
            }
        }

        // Icon tint.
        var foreground: Color {
            switch self {
            case .primary:              return .tonTextOnBrand
            case .secondary, .tertiary: return .tonTextBrand
            }
        }

        // Caption tint (matches the icon except on the neutral `tertiary` style).
        var labelForeground: Color {
            switch self {
            case .primary:    return .tonTextOnBrand
            case .secondary:  return .tonTextBrand
            case .tertiary:   return .tonTextPrimary
            }
        }

        // Vertical inset. `primary`/`secondary` mirror the Android component (≈7/8).
        // `tertiary` (home Send/Swap/Stake tiles): 12 → total height 74 (24 icon + 8 gap + 18
        // label line + 24 padding).
        var verticalInset: CGFloat {
            switch self {
            case .primary, .secondary: return 8
            case .tertiary:            return 12
            }
        }

        // Gap between the icon and the caption.
        var iconLabelSpacing: CGFloat {
            switch self {
            case .primary, .secondary: return 2
            case .tertiary:            return 8
            }
        }

        var labelStyle: TONTypography.TextStyle {
            switch self {
            case .primary, .secondary: return .caption2Medium
            case .tertiary:            return .subheadline2Semibold
            }
        }

        var cornerRadius: CGFloat {
            switch self {
            case .primary, .secondary: return 12
            case .tertiary:            return 24
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
            VStack(spacing: style.iconLabelSpacing) {
                icon.image
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .size(24)
                    .foregroundStyle(style.foreground)
                Text(title)
                    .textStyle(style.labelStyle)
                    .foregroundStyle(style.labelForeground)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, style.verticalInset)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous)
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
