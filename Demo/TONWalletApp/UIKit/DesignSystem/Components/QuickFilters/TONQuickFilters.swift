import SwiftUI

// Quick filters row = horizontal scroll of TONTab pills (active=black, inactive=light-gray).
struct TONQuickFilter<Item: Hashable> {
    let item: Item
    let title: String
    let icon: TONIcon?

    init(_ item: Item, title: String, icon: TONIcon? = nil) {
        self.item = item
        self.title = title
        self.icon = icon
    }
}

struct TONQuickFilters<Item: Hashable>: View {
    @Binding var selection: Item
    let items: [TONQuickFilter<Item>]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, filter in
                    TONTab(title: filter.title, icon: filter.icon, isActive: filter.item == selection) {
                        selection = filter.item
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

#Preview { StatefulPreview() }
private struct StatefulPreview: View {
    @State private var selected = "Trending"
    var body: some View {
        TONQuickFilters(
            selection: $selected,
            items: [
                TONQuickFilter("Trending", title: "Trending", icon: .trend),
                TONQuickFilter("Top",      title: "Top",      icon: .hot),
                TONQuickFilter("Active",   title: "Active"),
                TONQuickFilter("New",      title: "New",      icon: .new),
            ]
        )
    }
}
