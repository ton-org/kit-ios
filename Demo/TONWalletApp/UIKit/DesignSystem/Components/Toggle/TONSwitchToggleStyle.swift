import SwiftUI

// Track 64x28, knob is a rounded pill 39x24 with 2px inset; on=accent blue, off=gray (#93939d).
private enum Layout {
    static let trackWidth: CGFloat = 64
    static let trackHeight: CGFloat = 28
    static let knobInset: CGFloat = 2
    static let knobWidth: CGFloat = 39
    static let knobHeight: CGFloat = 24
}

struct TONSwitchToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer(minLength: 0)
            Capsule()
                .fill(configuration.isOn ? Color.tonBgBrand : Color.tonGray)
                .frame(width: Layout.trackWidth, height: Layout.trackHeight)
                .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                    Capsule()
                        .fill(Color.tonWhite)
                        .frame(width: Layout.knobWidth, height: Layout.knobHeight)
                        .padding(Layout.knobInset)
                }
                .onTapGesture {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                        configuration.isOn.toggle()
                    }
                }
        }
    }
}

extension ToggleStyle where Self == TONSwitchToggleStyle {
    static var tonSwitch: TONSwitchToggleStyle { TONSwitchToggleStyle() }
}

#Preview { StatefulPreview() }
private struct StatefulPreview: View {
    @State private var on = true
    @State private var off = false
    var body: some View {
        VStack {
            Toggle("Enabled",  isOn: $on).toggleStyle(.tonSwitch)
            Toggle("Disabled", isOn: $off).toggleStyle(.tonSwitch)
        }.padding()
    }
}
