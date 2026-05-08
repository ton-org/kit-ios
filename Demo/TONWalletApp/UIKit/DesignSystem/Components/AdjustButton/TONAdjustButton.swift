import SwiftUI

// Spec: h=50, px=13 around 24x24 icon → 50x50 box; rounded-12; tertiary fill background.
struct TONAdjustButton: View {
    let icon: TONIcon
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            icon.image
                .resizable()
                .scaledToFit()
                .size(24)
                .foregroundStyle(Color.tonTextPrimary)
                .frame(height: 50)
                .padding(.horizontal, 13)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.tonBgFillTertiary)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HStack(spacing: 12) {
        TONAdjustButton(icon: .filter) {}
        TONAdjustButton(icon: .calendar) {}
        TONAdjustButton(icon: .gas) {}
    }.padding()
}
