#if DEBUG
import SwiftUI

struct DebugMenuView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Typography") { TypographyDebugView() }
                NavigationLink("Colors")     { ColorsDebugView() }
                NavigationLink("Icons")      { IconsDebugView() }
                NavigationLink("Controls")   { ControlsDebugView() }
            }
            .navigationTitle("Design System")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

#Preview { DebugMenuView() }
#endif
