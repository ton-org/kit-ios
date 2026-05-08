import SwiftUI

private enum Layout {
    static let cornerRadius: CGFloat = 12
    static let horizontalPadding: CGFloat = 24
    static let iconLabelSpacing: CGFloat = 8
}

struct TONButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    let config: Config

    init(config: Config) {
        self.config = config
    }

    func makeBody(configuration: Configuration) -> some View {
        let state: Config.Style.State = isEnabled
            ? (configuration.isPressed ? .pressed : .default)
            : .disabled
        let properties = config.style.properties(state: state)

        return ZStack {
            if config.isLoading {
                TONLoader()
                    .foregroundStyle(properties.loaderColor)
                    .size(config.size.iconSize)
            } else {
                HStack(spacing: Layout.iconLabelSpacing) {
                    config.leftIcon?
                        .resizable()
                        .scaledToFit()
                        .size(config.size.iconSize)
                        .foregroundStyle(properties.iconColor)

                    configuration.label
                        .textStyle(.bodySemibold)
                        .foregroundStyle(properties.labelColor)

                    config.rightIcon?
                        .resizable()
                        .scaledToFit()
                        .size(config.size.iconSize)
                        .foregroundStyle(properties.iconColor)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: config.size.height, maxHeight: config.size.height)
        .contentShape(.rect)
        .padding(.horizontal, Layout.horizontalPadding)
        .background(properties.backgroundColor)
        .cornerRadius(Layout.cornerRadius)
        .allowsHitTesting(!config.isLoading)
    }
}

extension ButtonStyle where Self == TONButtonStyle {
    static var ton: TONButtonStyle { ton(.primary) }
    static func ton(_ config: TONButtonStyle.Config) -> TONButtonStyle { TONButtonStyle(config: config) }
}

// MARK: - Config

extension TONButtonStyle {
    struct Config {
        public private(set) var style: Style
        public private(set) var size: Size
        public private(set) var leftIcon: Image?
        public private(set) var rightIcon: Image?
        public private(set) var isLoading: Bool

        init(style: Style, size: Size = .default) {
            self.style = style
            self.size = size
            self.isLoading = false
        }

        static var primary:   Self { Config(style: .primary) }
        static var secondary: Self { Config(style: .secondary) }
        static var tertiary:  Self { Config(style: .tertiary) }
        static var text:      Self { Config(style: .text) }

        var small:   Self { update(\.size, to: .small) }
        var medium:  Self { update(\.size, to: .medium) }
        var `default`: Self { update(\.size, to: .default) }

        func leftIcon(_ image: Image) -> Self  { update(\.leftIcon, to: image) }
        func rightIcon(_ image: Image) -> Self { update(\.rightIcon, to: image) }
        func isLoading(_ loading: Bool) -> Self { update(\.isLoading, to: loading) }

        private func update<T>(_ keyPath: WritableKeyPath<Self, T>, to value: T) -> Self {
            var copy = self
            copy[keyPath: keyPath] = value
            return copy
        }
    }
}

// MARK: - Style & Size

extension TONButtonStyle.Config {
    enum Style {
        case primary, secondary, tertiary, text

        func properties(state: State) -> Properties {
            switch self {
            case .primary:   return PrimaryProperties.state(state)
            case .secondary: return SecondaryProperties.state(state)
            case .tertiary:  return TertiaryProperties.state(state)
            case .text:      return TextProperties.state(state)
            }
        }
    }

    enum Size: CGFloat {
        case small = 36, medium = 44, `default` = 50
        var height: CGFloat { rawValue }
        var iconSize: CGFloat { self == .small ? 16 : 20 }
    }
}

extension TONButtonStyle.Config.Style {
    enum State { case `default`, disabled, pressed }

    protocol Properties {
        var iconColor: Color { get }
        var backgroundColor: Color { get }
        var labelColor: Color { get }
        var loaderColor: Color { get }
        static func state(_ state: State) -> Self
    }

    struct PrimaryProperties: Properties {
        let iconColor: Color = .tonTextOnBrand
        let backgroundColor: Color
        let labelColor: Color
        let loaderColor: Color = .tonTextOnBrand

        init(backgroundColor: Color, labelColor: Color = .tonTextOnBrand) {
            self.backgroundColor = backgroundColor
            self.labelColor = labelColor
        }

        static func state(_ state: State) -> Self {
            switch state {
            case .default:  return PrimaryProperties(backgroundColor: .tonBgBrand)
            case .pressed:  return PrimaryProperties(backgroundColor: .tonBgBrandActive)
            case .disabled: return PrimaryProperties(backgroundColor: .tonBgDisabled, labelColor: .tonTextTertiary)
            }
        }
    }

    struct SecondaryProperties: Properties {
        let iconColor: Color
        let backgroundColor: Color
        let labelColor: Color
        let loaderColor: Color = .tonTextBrand

        init(iconColor: Color = .tonTextBrand, backgroundColor: Color, labelColor: Color = .tonTextBrand) {
            self.iconColor = iconColor
            self.backgroundColor = backgroundColor
            self.labelColor = labelColor
        }

        static func state(_ state: State) -> Self {
            switch state {
            case .default:  return SecondaryProperties(backgroundColor: .tonBgBrandSubtle)
            case .pressed:  return SecondaryProperties(backgroundColor: .tonBgBrandActive)
            case .disabled: return SecondaryProperties(iconColor: .tonTextTertiary, backgroundColor: .tonBgDisabled, labelColor: .tonTextTertiary)
            }
        }
    }

    struct TertiaryProperties: Properties {
        let iconColor: Color
        let backgroundColor: Color
        let labelColor: Color
        let loaderColor: Color = .tonTextBrand

        init(iconColor: Color = .tonTextPrimary, backgroundColor: Color, labelColor: Color = .tonTextPrimary) {
            self.iconColor = iconColor
            self.backgroundColor = backgroundColor
            self.labelColor = labelColor
        }

        static func state(_ state: State) -> Self {
            switch state {
            case .default:  return TertiaryProperties(backgroundColor: .tonBgSecondary)
            case .pressed:  return TertiaryProperties(iconColor: .tonTextBrand, backgroundColor: .tonBgSecondary, labelColor: .tonTextBrand)
            case .disabled: return TertiaryProperties(iconColor: .tonTextTertiary, backgroundColor: .tonBgDisabled, labelColor: .tonTextTertiary)
            }
        }
    }

    struct TextProperties: Properties {
        let iconColor: Color
        let backgroundColor: Color = .clear
        let labelColor: Color
        let loaderColor: Color = .tonTextBrand

        init(iconColor: Color = .tonTextBrand, labelColor: Color = .tonTextBrand) {
            self.iconColor = iconColor
            self.labelColor = labelColor
        }

        static func state(_ state: State) -> Self {
            switch state {
            case .default:  return TextProperties()
            case .pressed:  return TextProperties(iconColor: .tonTextBrand.opacity(0.6), labelColor: .tonTextBrand.opacity(0.6))
            case .disabled: return TextProperties(iconColor: .tonTextTertiary, labelColor: .tonTextTertiary)
            }
        }
    }
}

// MARK: - Previews

#Preview("Primary default") {
    Button("Continue") {}.buttonStyle(.ton(.primary)).padding()
}

#Preview("All sizes") {
    VStack(spacing: 12) {
        Button("Default 56") {}.buttonStyle(.ton(.primary))
        Button("Medium 48") {}.buttonStyle(.ton(.primary.medium))
        Button("Small 36") {}.buttonStyle(.ton(.primary.small))
    }.padding()
}
