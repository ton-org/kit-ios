import SwiftUI
import UIKit

// All 23 SF Pro styles enumerated from the Figma "Typography" section via MCP.
// Names mirror Apple HIG (Title 1/2/3, Body, Callout, Subheadline 1/2, Footnote, Caption 1/2)
// plus the three SF Pro Rounded Bold "Price" sizes (40 / 44 / 64) used for amounts.
enum TONTypography {
    struct TextStyle: Hashable {
        let name: String
        let font: Font
        let uiFont: UIFont
        let lineHeight: CGFloat
        let letterSpacing: CGFloat
        let textCase: Text.Case?

        var lineSpacing: CGFloat { max(0, lineHeight - uiFont.lineHeight) }

        // MARK: - Price (SF Pro Rounded Bold)
        static let price64 = TextStyle(
            name: "Price 64 — SF Pro Rounded Bold",
            font: .system(size: 64, weight: .bold, design: .rounded),
            uiFont: .systemFont(ofSize: 64, weight: .bold),
            lineHeight: 82, letterSpacing: -0.64, textCase: nil
        )
        static let price44 = TextStyle(
            name: "Price 44 — SF Pro Rounded Bold",
            font: .system(size: 44, weight: .bold, design: .rounded),
            uiFont: .systemFont(ofSize: 44, weight: .bold),
            lineHeight: 46, letterSpacing: -1.32, textCase: nil
        )
        static let price40 = TextStyle(
            name: "Price 40 — SF Pro Rounded Bold",
            font: .system(size: 40, weight: .bold, design: .rounded),
            uiFont: .systemFont(ofSize: 40, weight: .bold),
            lineHeight: 46, letterSpacing: -0.5, textCase: nil
        )

        // MARK: - Titles
        static let title1 = TextStyle(
            name: "Title 1 — SF Pro Bold 28",
            font: .system(size: 28, weight: .bold),
            uiFont: .systemFont(ofSize: 28, weight: .bold),
            lineHeight: 34, letterSpacing: 0.38, textCase: nil
        )
        static let title2 = TextStyle(
            name: "Title 2 — SF Pro Semibold 22",
            font: .system(size: 22, weight: .semibold),
            uiFont: .systemFont(ofSize: 22, weight: .semibold),
            lineHeight: 28, letterSpacing: -0.264, textCase: nil
        )
        static let title3Bold = TextStyle(
            name: "Title 3 Bold — SF Pro Bold 20",
            font: .system(size: 20, weight: .bold),
            uiFont: .systemFont(ofSize: 20, weight: .bold),
            lineHeight: 24, letterSpacing: -0.45, textCase: nil
        )
        static let title3Semibold = TextStyle(
            name: "Title 3 Semibold — SF Pro Semibold 20",
            font: .system(size: 20, weight: .semibold),
            uiFont: .systemFont(ofSize: 20, weight: .semibold),
            lineHeight: 24, letterSpacing: -0.45, textCase: nil
        )

        // MARK: - Title 3 Regular Rounded (20)
        static let title3RoundedRegular = TextStyle(
            name: "Title 3 Regular Rounded — SF Pro Rounded Regular 20",
            font: .system(size: 20, weight: .regular, design: .rounded),
            uiFont: .systemFont(ofSize: 20, weight: .regular),
            lineHeight: 24, letterSpacing: -0.45, textCase: nil
        )

        // MARK: - Body (17)
        static let body = TextStyle(
            name: "Body — SF Pro Regular 17",
            font: .system(size: 17, weight: .regular),
            uiFont: .systemFont(ofSize: 17, weight: .regular),
            lineHeight: 22, letterSpacing: -0.43, textCase: nil
        )
        static let bodyMedium = TextStyle(
            name: "Body Medium — SF Pro Medium 17",
            font: .system(size: 17, weight: .medium),
            uiFont: .systemFont(ofSize: 17, weight: .medium),
            lineHeight: 22, letterSpacing: -0.43, textCase: nil
        )
        static let bodySemibold = TextStyle(
            name: "Body Semibold — SF Pro Semibold 17",
            font: .system(size: 17, weight: .semibold),
            uiFont: .systemFont(ofSize: 17, weight: .semibold),
            lineHeight: 22, letterSpacing: -0.43, textCase: nil
        )
        static let bodyRoundedSemibold = TextStyle(
            name: "Body Rounded Semibold — SF Pro Rounded Semibold 17",
            font: .system(size: 17, weight: .semibold, design: .rounded),
            uiFont: .systemFont(ofSize: 17, weight: .semibold),
            lineHeight: 22, letterSpacing: -0.12, textCase: nil
        )

        // MARK: - Callout (16)
        static let callout = TextStyle(
            name: "Callout — SF Pro Regular 16",
            font: .system(size: 16, weight: .regular),
            uiFont: .systemFont(ofSize: 16, weight: .regular),
            lineHeight: 22, letterSpacing: -0.31, textCase: nil
        )
        static let calloutMedium = TextStyle(
            name: "Callout Medium — SF Pro Medium 16",
            font: .system(size: 16, weight: .medium),
            uiFont: .systemFont(ofSize: 16, weight: .medium),
            lineHeight: 22, letterSpacing: -0.31, textCase: nil
        )

        // MARK: - Subheadline 1 (15 Rounded)
        static let subheadline1 = TextStyle(
            name: "Subheadline 1 — SF Pro Rounded Semibold 15",
            font: .system(size: 15, weight: .semibold, design: .rounded),
            uiFont: .systemFont(ofSize: 15, weight: .semibold),
            lineHeight: 20, letterSpacing: 0.44, textCase: nil
        )

        // MARK: - Subheadline 2 (14)
        static let subheadline2 = TextStyle(
            name: "Subheadline 2 — SF Pro Regular 14",
            font: .system(size: 14, weight: .regular),
            uiFont: .systemFont(ofSize: 14, weight: .regular),
            lineHeight: 18, letterSpacing: -0.154, textCase: nil
        )
        static let subheadline2Medium = TextStyle(
            name: "Subheadline 2 Medium — SF Pro Medium 14",
            font: .system(size: 14, weight: .medium),
            uiFont: .systemFont(ofSize: 14, weight: .medium),
            lineHeight: 18, letterSpacing: -0.154, textCase: nil
        )
        static let subheadline2Semibold = TextStyle(
            name: "Subheadline 2 Semibold — SF Pro Semibold 14",
            font: .system(size: 14, weight: .semibold),
            uiFont: .systemFont(ofSize: 14, weight: .semibold),
            lineHeight: 18, letterSpacing: -0.154, textCase: nil
        )

        // MARK: - Footnote (13)
        static let footnote = TextStyle(
            name: "Footnote — SF Pro Regular 13",
            font: .system(size: 13, weight: .regular),
            uiFont: .systemFont(ofSize: 13, weight: .regular),
            lineHeight: 18, letterSpacing: -0.078, textCase: nil
        )
        static let footnoteSemibold = TextStyle(
            name: "Footnote Semibold — SF Pro Semibold 13",
            font: .system(size: 13, weight: .semibold),
            uiFont: .systemFont(ofSize: 13, weight: .semibold),
            lineHeight: 18, letterSpacing: -0.08, textCase: nil
        )
        static let footnoteCaps = TextStyle(
            name: "Footnote Caps — SF Pro Regular 13 / UPPER",
            font: .system(size: 13, weight: .regular),
            uiFont: .systemFont(ofSize: 13, weight: .regular),
            lineHeight: 18, letterSpacing: -0.078, textCase: .uppercase
        )

        // MARK: - Caption 1 (12)
        static let caption1 = TextStyle(
            name: "Caption 1 — SF Pro Regular 12",
            font: .system(size: 12, weight: .regular),
            uiFont: .systemFont(ofSize: 12, weight: .regular),
            lineHeight: 16, letterSpacing: 0, textCase: nil
        )

        // MARK: - Caption 2 (11)
        static let caption2Medium = TextStyle(
            name: "Caption 2 Medium — SF Pro Medium 11",
            font: .system(size: 11, weight: .medium),
            uiFont: .systemFont(ofSize: 11, weight: .medium),
            lineHeight: 13, letterSpacing: 0.06, textCase: nil
        )
        static let caption2Semibold = TextStyle(
            name: "Caption 2 Semibold — SF Pro Semibold 11",
            font: .system(size: 11, weight: .semibold),
            uiFont: .systemFont(ofSize: 11, weight: .semibold),
            lineHeight: 12, letterSpacing: -0.11, textCase: nil
        )
        static let caption2MediumCaps = TextStyle(
            name: "Caption 2 Medium Caps — SF Pro Medium 11 / UPPER",
            font: .system(size: 11, weight: .medium),
            uiFont: .systemFont(ofSize: 11, weight: .medium),
            lineHeight: 13, letterSpacing: 0.06, textCase: .uppercase
        )

        static let allStyles: [TextStyle] = [
            .price64, .price44, .price40,
            .title1, .title2, .title3Bold, .title3Semibold, .title3RoundedRegular,
            .body, .bodyMedium, .bodySemibold, .bodyRoundedSemibold,
            .callout, .calloutMedium,
            .subheadline1,
            .subheadline2, .subheadline2Medium, .subheadline2Semibold,
            .footnote, .footnoteSemibold, .footnoteCaps,
            .caption1,
            .caption2Medium, .caption2Semibold, .caption2MediumCaps,
        ]
    }
}

extension View {
    func textStyle(_ style: TONTypography.TextStyle) -> some View {
        modifier(TONTextStyleModifier(style: style))
    }
}

private struct TONTextStyleModifier: ViewModifier {
    let style: TONTypography.TextStyle

    func body(content: Content) -> some View {
        content
            .font(style.font)
            .lineSpacing(style.lineSpacing)
            .padding(.vertical, style.lineSpacing.rounded() / 2)
            .kerning(style.letterSpacing)
            .textCase(style.textCase)
    }
}
