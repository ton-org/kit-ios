#if DEBUG
import Combine
import SwiftUI

/// Playground for the rolling-digit ("odometer") balance animation used on WalletHome.
/// Renders an amount with `.contentTransition(.numericText())` and lets you mutate it so the
/// digits roll on each change. The auto-update toggle simulates streaming balance updates.
struct NumericTextDebugView: View {
    @State private var amount: Double = 2593.47
    @State private var autoUpdate = false

    private let ticker = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                balanceSection
                controlsSection
            }
            .padding(20)
        }
        .background(Color.tonBgPrimary)
        .navigationTitle("Numeric Text")
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(ticker) { _ in
            guard autoUpdate else { return }
            change(by: Double.random(in: 0.5...250))
        }
    }

    // MARK: - Balance (same rendering as WalletHome)

    private var balanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Balance — .numericText()")

            HStack(alignment: .lastTextBaseline, spacing: 0) {
                Text(integerPart)
                    .textStyle(.price50)
                    .foregroundStyle(Color.tonTextPrimary)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: integerPart)
                Text(".")
                    .textStyle(.price40)
                    .foregroundStyle(Color.tonTextSecondary)
                Text(fractionDigits)
                    .textStyle(.price30)
                    .foregroundStyle(Color.tonTextSecondary)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: fractionDigits)
                Text(" GRAM")
                    .textStyle(.price30)
                    .foregroundStyle(Color.tonTextSecondary)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Controls

    private var controlsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Controls")

            HStack(spacing: 12) {
                Button("− random") { change(by: -Double.random(in: 0.5...250)) }
                    .buttonStyle(.ton(.secondary.medium))
                Button("+ random") { change(by: Double.random(in: 0.5...250)) }
                    .buttonStyle(.ton(.secondary.medium))
            }

            Button("Set random balance") {
                withAnimation(.snappy) { amount = Double.random(in: 0...9_999.99) }
            }
            .buttonStyle(.ton(.secondary.medium))

            Button("Reset") {
                withAnimation(.snappy) { amount = 2593.47 }
            }
            .buttonStyle(.ton(.secondary.medium))

            Toggle("Auto-update (stream simulation)", isOn: $autoUpdate)
                .toggleStyle(.tonSwitch)
                .textStyle(.body)
                .foregroundStyle(Color.tonTextPrimary)
        }
    }

    // MARK: - Helpers

    private func change(by delta: Double) {
        withAnimation(.snappy) {
            amount = max(0, amount + delta)
        }
    }

    private var integerPart: String {
        let totalCents = Int((amount * 100).rounded())
        return (totalCents / 100).formatted(.number.grouping(.automatic))
    }

    private var fractionDigits: String {
        let totalCents = Int((amount * 100).rounded())
        return String(format: "%02d", totalCents % 100)
    }

    @ViewBuilder
    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .textStyle(.footnoteCaps)
            .foregroundStyle(Color.tonTextTertiary)
    }
}

#Preview { NavigationStack { NumericTextDebugView() } }
#endif
