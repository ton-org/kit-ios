import SwiftUI

// Spec: bg light-gray, label text-black SF Pro Semibold 16-17 (figma uses Inter Body/Semibold 16),
// padding (8v, 12h), corner radius 12. Designed to be used in a row with flex-1 sizing.
struct TONPercentageButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .textStyle(.bodySemibold)
                .foregroundStyle(isSelected ? Color.tonTextOnBrand : Color.tonTextPrimary)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isSelected ? Color.tonBgBrand : Color.tonBgLightGray)
                )
        }
        .buttonStyle(.plain)
    }
}

// Convenience row with figma-spec gap of 8.
struct TONPercentageButtonRow: View {
    @Binding var selection: String?
    let items: [String]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(items, id: \.self) { item in
                TONPercentageButton(title: item, isSelected: selection == item) {
                    selection = item
                }
            }
        }
    }
}

#Preview { StatefulPreview() }
private struct StatefulPreview: View {
    @State private var selected: String? = "50%"
    var body: some View {
        TONPercentageButtonRow(selection: $selected, items: ["25%", "50%", "75%", "MAX"])
            .padding()
    }
}
