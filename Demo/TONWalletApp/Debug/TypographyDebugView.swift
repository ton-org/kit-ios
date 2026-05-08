#if DEBUG
import SwiftUI

struct TypographyDebugView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ForEach(TONTypography.TextStyle.allStyles, id: \.self) { style in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(style.name)
                            .textStyle(.footnoteCaps)
                            .foregroundStyle(Color.tonTextTertiary)
                        Text("The quick brown fox 1234")
                            .textStyle(style)
                            .foregroundStyle(Color.tonTextPrimary)
                    }
                    Divider()
                }
            }
            .padding(20)
        }
        .background(Color.tonBgPrimary)
        .navigationTitle("Typography")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview { NavigationStack { TypographyDebugView() } }
#endif
