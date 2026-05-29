import SwiftUI

// Spec: rounded-6, padding (top=2, bottom=1, h=4), font Footnote/CAPS (uppercase 12pt semibold).
// Filled: bg accent blue + text white. Gray: bg light gray + text dark gray.
struct TONBadge: View {
    enum Style {
        case filled, gray

        var background: Color {
            switch self {
            case .filled: return .tonBgBrand
            case .gray:   return .tonBgLightGray
            }
        }

        var foreground: Color {
            switch self {
            case .filled: return .tonTextOnBrand
            case .gray:   return .tonTextSecondary
            }
        }
    }

    let title: String
    let style: Style
    let uppercase: Bool

    init(_ title: String, style: Style = .filled, uppercase: Bool = true) {
        self.title = title
        self.style = style
        self.uppercase = uppercase
    }

    var body: some View {
        Text(title)
            .textStyle(uppercase ? .footnoteCaps : .footnote)
            .foregroundStyle(style.foreground)
            .padding(.horizontal, 4)
            .padding(.top, 2)
            .padding(.bottom, 1)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(style.background)
            )
    }
}

#Preview {
    HStack {
        TONBadge("NEW", style: .filled)
        TONBadge("PRO", style: .gray)
    }.padding()
}
