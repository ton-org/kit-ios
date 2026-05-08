import Foundation
import LocalAuthentication

@MainActor
final class CreatePinViewModel: ObservableObject {
    enum Phase: Equatable {
        case entering
        case confirming(firstPin: String)
    }

    @Published var phase: Phase = .entering
    @Published var pin: String = ""
    @Published var error: String?

    private let passwordStorage = PasswordStorage()

    /// Step 1 → step 2 transition (auto-fires when 4 digits typed in entering phase).
    func advanceToConfirming(with entered: String) {
        guard case .entering = phase else { return }
        phase = .confirming(firstPin: entered)
        pin = ""
        error = nil
    }

    /// Step 2 confirmation (only fired by Save button tap when 4 digits typed).
    func commitConfirmation() async -> Bool {
        guard case .confirming(let first) = phase, pin.count == 4 else { return false }
        guard pin == first else {
            error = "The PIN codes do not match"
            phase = .entering
            pin = ""
            return false
        }
        do {
            try passwordStorage.set(password: pin)
            await requestBiometry()
            return true
        } catch {
            debugPrint(error.localizedDescription)
            self.error = "Failed to save PIN code"
            return false
        }
    }

    var isEntering: Bool {
        if case .entering = phase { return true }
        return false
    }

    var screenTitle: String {
        switch phase {
        case .entering:   return "Create PIN"
        case .confirming: return "Enter your PIN again"
        }
    }

    var screenDescription: String {
        "Create a 4-digit PIN to protect your wallet.\nYou can back up your wallet later in Settings."
    }

    private func requestBiometry() async {
        let context = LAContext()
        var laError: NSError?
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &laError)
        if canEvaluate && context.biometryType != .none {
            do {
                try await context.evaluatePolicy(
                    .deviceOwnerAuthenticationWithBiometrics,
                    localizedReason: "This app uses Face ID to authenticate the user."
                )
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
    }
}
