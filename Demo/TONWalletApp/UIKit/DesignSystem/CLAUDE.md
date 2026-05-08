# Design System Rule (TONWalletApp demo)

All UI in this demo MUST consume the design system at this folder. This rule applies to every new screen, component, and modification of existing screens.

## Mandatory

- **Colors**: use semantic tokens (`Color.tonTextPrimary`, `Color.tonBgBrand`, …). Primitive tokens (`Color.tonAccentBlue`, `Color.tonRed`, …) are allowed only inside `Tokens/TONColors+Semantic.swift`.
- **Typography**: use `.textStyle(.headline)`, `.textStyle(.bodySemibold)`, etc. The full set lives in `Tokens/TONTypography.swift`.
- **Icons**: use `TONIcon.<case>.image`. Add new icons by extending the enum in `Icons/TONIcon.swift`.
- **Buttons**: rectangular → `.buttonStyle(.ton(...))`; circular → `.buttonStyle(.tonAction(...))`. Use the fluent `.primary.medium.leftIcon(...)` config builder.
- **Other controls**: `TONSegmentedControl`, `TONTab`, `TONBadge`, `Toggle(...).toggleStyle(.tonSwitch)`.
- **New components**: add a new folder under `Components/`, prefix the type with `TON`, follow the `Config` builder pattern from `TONButtonStyle.swift`.

## Forbidden

- Hardcoded hex strings (`Color(hex: "#…")`) outside `Tokens/TONColors.swift`.
- `Color.TON.*` palette from `Legacy/Theme.swift`.
- SwiftUI system colors (`.gray`, `.blue`, `.secondary`, …) for UI chrome.
- `.font(.system(...))`, `.font(.title)`, `.font(.headline)`, etc. — always go through `.textStyle(_:)`.
- `Image(systemName:)` outside `Icons/TONIcon.swift`'s SF Symbol fallback table.
- One-off `ButtonStyle` / `ToggleStyle` implementations in feature folders.

## Legacy

`Legacy/` contains pre-design-system code (kept only so existing screens compile). Do not add to it. When you touch a legacy screen, prefer migrating its UI to the new system.

## Icons & Figma

`TONIcon.image` currently returns SF Symbols as placeholders. The real Figma exports should be dropped into `Demo/TONWalletApp/Assets.xcassets/DesignSystem/` (Tabbar, Icons24, Icons40, IconsBadge groups) and `TONIcon.image` updated to prefer the named asset with the SF Symbol as last-resort fallback.
