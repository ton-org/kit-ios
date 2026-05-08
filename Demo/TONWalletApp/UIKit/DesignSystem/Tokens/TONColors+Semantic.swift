import SwiftUI

extension Color {
    // MARK: Text & Icon
    static var tonTextPrimary:   Color { Color(light: .tonBlack,      dark: .tonBlack) }
    static var tonTextSecondary: Color { Color(light: .tonDarkGray,   dark: .tonDarkGray) }
    static var tonTextTertiary:  Color { Color(light: .tonGray,       dark: .tonGray) }
    static var tonTextBrand:     Color { Color(light: .tonAccentBlue, dark: .tonAccentBlue) }
    static var tonTextSuccess:   Color { Color(light: .tonGreen,      dark: .tonGreen) }
    static var tonTextError:     Color { Color(light: .tonRed,        dark: .tonRed) }
    static var tonTextOnBrand:   Color { Color(light: .tonWhite,      dark: .tonWhite) }

    // MARK: Background
    static var tonBgPrimary:     Color { Color(light: .tonBgWhite,              dark: .tonBgBlack) }
    static var tonBgSecondary:   Color { Color(light: .tonBgSuperLightGray,     dark: .tonBgSuperLightGray) }
    static var tonBgBrand:       Color { Color(light: .tonAccentBlue,           dark: .tonAccentBlue) }
    static var tonBgBrandSubtle: Color { Color(light: .tonBgLightBlue,          dark: .tonBgLightBlue) }
    static var tonBgBrandActive: Color { Color(light: .tonBgLightBlueSecondary, dark: .tonBgLightBlueSecondary) }
    static var tonBgDisabled:    Color { Color(light: .tonBgLightGray,          dark: .tonBgLightGray) }
    static var tonBgOverlay:     Color { Color(light: .tonBgTertiaryFill,       dark: .tonBgTertiaryFill) }
    static var tonBgFillTertiary:   Color { Color(light: .tonBgTertiaryFill,    dark: .tonBgTertiaryFill) }
    static var tonBgFillQuaternary: Color { Color(light: .tonBgQuaternaryFill,  dark: .tonBgQuaternaryFill) }
}
