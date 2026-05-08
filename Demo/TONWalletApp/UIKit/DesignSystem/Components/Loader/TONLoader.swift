import SwiftUI

struct TONLoader: View {
    var body: some View {
        ProgressView()
            .progressViewStyle(.circular)
    }
}

#Preview {
    TONLoader()
        .foregroundStyle(Color.tonTextBrand)
        .size(24)
}
