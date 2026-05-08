import Foundation
import LocalAuthentication

@MainActor
final class UnlockPinViewModel: ObservableObject {
    @Published var pin: String = ""
    @Published var error: String?

    private let passwordStorage = PasswordStorage()
    private let walletsStorage = WalletsStorage()

    func checkPin(_ entered: String) -> Bool {
        do {
            let stored = try passwordStorage.password()
            let isEqual = stored == entered
            if !isEqual {
                error = "Incorrect PIN. Please try again."
                pin = ""
            }
            return isEqual
        } catch {
            debugPrint(error.localizedDescription)
            self.error = "Incorrect PIN. Please try again."
            pin = ""
            return false
        }
    }

    func reset() {
        try? passwordStorage.removePassword()
        try? walletsStorage.removeAllWallets()
    }

    func tryBiometryAuthentication() async -> Bool {
        let context = LAContext()
        var laError: NSError?
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &laError)
        guard canEvaluate else { return false }
        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "This app uses Face ID to authenticate the user."
            )
        } catch {
            return false
        }
    }
}
