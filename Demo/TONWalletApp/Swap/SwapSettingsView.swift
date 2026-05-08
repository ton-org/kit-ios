import SwiftUI

struct SwapSettingsView: View {
    @Binding var slippageBps: Int
    @Binding var isPresented: Bool

    @State private var customValue = ""
    @State private var editingSlippage: Int

    private let presets: [(label: String, bps: Int)] = [
        ("0.5%", 50),
        ("1%", 100),
        ("3%", 300),
        ("5%", 500),
    ]

    init(slippageBps: Binding<Int>, isPresented: Binding<Bool>) {
        _slippageBps = slippageBps
        _isPresented = isPresented
        _editingSlippage = State(initialValue: slippageBps.wrappedValue)
    }

    var body: some View {
        VStack(spacing: AppSpacing.spacing(6)) {
            Text("Slippage Tolerance")
                .textLG(weight: .semibold)
                .foregroundColor(Color.TON.gray900)

            HStack(spacing: AppSpacing.spacing(2)) {
                ForEach(presets, id: \.bps) { preset in
                    Button(preset.label) {
                        editingSlippage = preset.bps
                        customValue = ""
                    }
                    .textSM(weight: editingSlippage == preset.bps ? .semibold : .regular)
                    .foregroundColor(editingSlippage == preset.bps ? Color.TON.white : Color.TON.gray700)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.spacing(2.5))
                    .background(editingSlippage == preset.bps ? Color.TON.blue600 : Color.TON.gray100)
                    .cornerRadius(AppRadius.standard)
                }
            }

            VStack(alignment: .leading, spacing: AppSpacing.spacing(1)) {
                Text("Custom (bps)")
                    .textSM()
                    .foregroundColor(Color.TON.gray500)

                TextField("e.g. 150", text: $customValue)
                    .textFieldStyle(TONTextFieldStyle())
                    .keyboardType(.numberPad)
                    .onChange(of: customValue) { newValue in
                        if let bps = Int(newValue), bps >= 10, bps <= 5000 {
                            editingSlippage = bps
                        }
                    }

                Text("Range: 10 - 5000 bps (0.1% - 50%)")
                    .textXS()
                    .foregroundColor(Color.TON.gray400)
            }

            Spacer()

            HStack(spacing: AppSpacing.spacing(3)) {
                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(TONLegacyButtonStyle(type: .secondary))

                Button("Save") {
                    slippageBps = editingSlippage
                    isPresented = false
                }
                .buttonStyle(TONLegacyButtonStyle(type: .primary))
            }
        }
        .padding(AppSpacing.spacing(4))
    }
}
