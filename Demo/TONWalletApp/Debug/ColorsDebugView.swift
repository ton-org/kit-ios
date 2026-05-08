#if DEBUG
import SwiftUI

struct ColorsDebugView: View {
    private struct Swatch: Identifiable {
        let id = UUID()
        let name: String
        let hex: String
        let color: Color
    }

    private let textAndIcon: [Swatch] = [
        .init(name: "tonBlack",      hex: "#000000", color: .tonBlack),
        .init(name: "tonGray",       hex: "#93939D", color: .tonGray),
        .init(name: "tonDarkGray",   hex: "#787881", color: .tonDarkGray),
        .init(name: "tonAccentBlue", hex: "#007AFF", color: .tonAccentBlue),
        .init(name: "tonGreen",      hex: "#2ABD4F", color: .tonGreen),
        .init(name: "tonRed",        hex: "#FF3B30", color: .tonRed),
        .init(name: "tonWhite",      hex: "#FFFFFF", color: .tonWhite),
    ]

    private let backgrounds: [Swatch] = [
        .init(name: "tonBgWhite",              hex: "#FFFFFF", color: .tonBgWhite),
        .init(name: "tonBgLightGray",          hex: "#EDEDF3", color: .tonBgLightGray),
        .init(name: "tonBgTertiaryFill",       hex: "#7474801F", color: .tonBgTertiaryFill),
        .init(name: "tonBgQuaternaryFill",     hex: "#74748014", color: .tonBgQuaternaryFill),
        .init(name: "tonBgBlack",              hex: "#000000", color: .tonBgBlack),
        .init(name: "tonBgSuperLightGray",     hex: "#F7F8FA", color: .tonBgSuperLightGray),
        .init(name: "tonBgLightBlue",          hex: "#ECF1FF", color: .tonBgLightBlue),
        .init(name: "tonBgLightBlueSecondary", hex: "#D4E5FF", color: .tonBgLightBlueSecondary),
    ]

    private let semantic: [Swatch] = [
        .init(name: "tonTextPrimary",   hex: "—", color: .tonTextPrimary),
        .init(name: "tonTextSecondary", hex: "—", color: .tonTextSecondary),
        .init(name: "tonTextTertiary",  hex: "—", color: .tonTextTertiary),
        .init(name: "tonTextBrand",     hex: "—", color: .tonTextBrand),
        .init(name: "tonTextSuccess",   hex: "—", color: .tonTextSuccess),
        .init(name: "tonTextError",     hex: "—", color: .tonTextError),
        .init(name: "tonBgPrimary",     hex: "—", color: .tonBgPrimary),
        .init(name: "tonBgSecondary",   hex: "—", color: .tonBgSecondary),
        .init(name: "tonBgBrand",       hex: "—", color: .tonBgBrand),
        .init(name: "tonBgBrandSubtle", hex: "—", color: .tonBgBrandSubtle),
        .init(name: "tonBgBrandActive", hex: "—", color: .tonBgBrandActive),
        .init(name: "tonBgDisabled",    hex: "—", color: .tonBgDisabled),
        .init(name: "tonBgOverlay",     hex: "—", color: .tonBgOverlay),
    ]

    var body: some View {
        List {
            section("Text & Icon", swatches: textAndIcon)
            section("Background", swatches: backgrounds)
            section("Semantic (light/dark aware)", swatches: semantic)
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Colors")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func section(_ title: String, swatches: [Swatch]) -> some View {
        Section(title) {
            ForEach(swatches) { swatch in
                HStack(spacing: 12) {
                    Circle()
                        .fill(swatch.color)
                        .overlay(Circle().stroke(Color.tonBgLightGray, lineWidth: 1))
                        .size(40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(swatch.name).textStyle(.bodySemibold).foregroundStyle(Color.tonTextPrimary)
                        Text(swatch.hex).textStyle(.caption1).foregroundStyle(Color.tonTextSecondary)
                    }
                }
            }
        }
    }
}

#Preview { NavigationStack { ColorsDebugView() } }
#endif
