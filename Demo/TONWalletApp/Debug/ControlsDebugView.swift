#if DEBUG
import SwiftUI

struct ControlsDebugView: View {
    @State private var segmented: String = "1D"
    @State private var tab: String = "Tokens"
    @State private var quickFilter: String = "Trending"
    @State private var percentage: String? = "50%"
    @State private var switchOn = true
    @State private var switchOff = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                buttonsSection
                actionButtonsSection
                segmentedSection
                tabsSection
                quickFiltersSection
                percentageSection
                navbarSection
                adjustSection
                togglesSection
                badgesSection
            }
            .padding(20)
        }
        .background(Color.tonBgPrimary)
        .navigationTitle("Controls")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .textStyle(.footnoteCaps)
            .foregroundStyle(Color.tonTextTertiary)
    }

    private var buttonsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Buttons — primary")
            Button("Default") {}.buttonStyle(.ton(.primary))
            Button("Medium")  {}.buttonStyle(.ton(.primary.medium))
            Button("Small")   {}.buttonStyle(.ton(.primary.small))
            Button("Loading") {}.buttonStyle(.ton(.primary.isLoading(true)))
            Button("Disabled") {}.buttonStyle(.ton(.primary)).disabled(true)

            sectionTitle("Buttons — secondary")
            Button("Secondary") {}.buttonStyle(.ton(.secondary))
            Button("Disabled")  {}.buttonStyle(.ton(.secondary)).disabled(true)

            sectionTitle("Buttons — tertiary")
            Button("Tertiary") {}.buttonStyle(.ton(.tertiary))

            sectionTitle("Buttons — text")
            Button("Text only") {}.buttonStyle(.ton(.text))
        }
    }

    private var actionButtonsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Action buttons — primary")
            HStack(spacing: 8) {
                TONActionButton(icon: .arrowUpCircle,    title: "Send",    style: .primary) {}
                TONActionButton(icon: .arrowDownCircle,  title: "Receive", style: .primary) {}
                TONActionButton(icon: .switchVertical24, title: "Swap",    style: .primary) {}
                TONActionButton(icon: .arrowRightUpCircle, title: "Earn",  style: .primary) {}
            }
            sectionTitle("Action buttons — secondary")
            HStack(spacing: 8) {
                TONActionButton(icon: .arrowUpCircle,    title: "Send",    style: .secondary) {}
                TONActionButton(icon: .arrowDownCircle,  title: "Receive", style: .secondary) {}
                TONActionButton(icon: .switchVertical24, title: "Swap",    style: .secondary) {}
                TONActionButton(icon: .arrowRightUpCircle, title: "Earn",  style: .secondary) {}
            }
        }
    }

    private var segmentedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Segmented control — selected: \(segmented)")
            TONSegmentedControl(
                selection: $segmented,
                items: ["1H", "1D", "1W", "1M", "1Y"],
                title: { $0 }
            )
        }
    }

    private var tabsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Tabs — selected: \(tab)")
            HStack(spacing: 8) {
                ForEach(["Tokens", "NFTs", "History"], id: \.self) { item in
                    TONTab(title: item, isActive: tab == item) { tab = item }
                }
            }
        }
    }

    private var quickFiltersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Quick filters — selected: \(quickFilter)")
            TONQuickFilters(
                selection: $quickFilter,
                items: [
                    TONQuickFilter("Trending", title: "Trending", icon: .trend),
                    TONQuickFilter("Top",      title: "Top",      icon: .hot),
                    TONQuickFilter("Active",   title: "Active"),
                    TONQuickFilter("New",      title: "New",      icon: .new),
                ]
            )
        }
    }

    private var percentageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Percentage buttons — selected: \(percentage ?? "none")")
            TONPercentageButtonRow(
                selection: $percentage,
                items: ["25%", "50%", "75%", "MAX"]
            )
        }
    }

    private var navbarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Navbar action buttons (44×44)")
            HStack(spacing: 12) {
                TONNavbarActionButton(icon: .headerArrowShare) {}
                TONNavbarActionButton(icon: .headerStar)       {}
                TONNavbarActionButton(icon: .headerStarOutline) {}
                TONNavbarActionButton(icon: .filter)           {}
            }
        }
    }

    private var adjustSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Adjust buttons (50×50)")
            HStack(spacing: 12) {
                TONAdjustButton(icon: .filter)   {}
                TONAdjustButton(icon: .calendar) {}
                TONAdjustButton(icon: .gas)      {}
            }
        }
    }

    private var togglesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Toggle switch")
            Toggle("On",  isOn: $switchOn).toggleStyle(.tonSwitch)
            Toggle("Off", isOn: $switchOff).toggleStyle(.tonSwitch)
        }
    }

    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Badges")
            HStack(spacing: 8) {
                TONBadge("NEW", style: .filled)
                TONBadge("PRO", style: .gray)
            }
        }
    }
}

#Preview { NavigationStack { ControlsDebugView() } }
#endif
