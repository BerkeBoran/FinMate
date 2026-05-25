import SwiftUI
import LocalAuthentication

struct ContentView: View {
    @State private var splashDone = false
    @AppStorage(SettingsKeys.onboardingCompleted) private var onboardingCompleted: Bool = false

    var body: some View {
        Group {
            if !splashDone {
                SplashView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { splashDone = true }
                        }
                    }
            } else if !onboardingCompleted {
                OnboardingView(onComplete: {
                    // AppStorage onboardingCompleted = true zaten ayarlandı,
                    // sadece geçişi animasyonla pekiştir
                    withAnimation { /* trigger re-render */ }
                })
            } else {
                SecurityGate { MainView() }
            }
        }
    }
}

// MARK: - Security Gate (Face ID veya Şifre, tek aşama)

struct SecurityGate<Content: View>: View {
    @AppStorage(SettingsKeys.securityMode) private var securityModeRaw: String = ""
    @State private var unlocked = false
    @State private var error: String?
    @State private var isAuthenticating = false
    @Environment(\.scenePhase) private var scenePhase

    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    private var securityMode: SecurityMode? {
        SecurityMode(rawValue: securityModeRaw)
    }

    var body: some View {
        ZStack {
            if shouldShowContent {
                content
                    .transition(.opacity)
            } else {
                lockSurface
                    .transition(.opacity)
            }
        }
        .onAppear { startAuthIfNeeded() }
        .onChange(of: securityModeRaw) { _, _ in
            unlocked = false
            startAuthIfNeeded()
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background, .inactive:
                if securityMode != nil { unlocked = false }
            case .active:
                if securityMode != nil && !unlocked && !isAuthenticating {
                    startAuthIfNeeded()
                }
            @unknown default: break
            }
        }
    }

    private var shouldShowContent: Bool {
        securityMode == nil || unlocked
    }

    @ViewBuilder
    private var lockSurface: some View {
        switch securityMode {
        case .passcode:
            // Şifre ile aç (Şifremi Unuttum YOK — doğru şifre zorunlu)
            PasscodeView(
                mode: .verify,
                onSuccess: {
                    error = nil
                    withAnimation { unlocked = true }
                }
            )
        case .faceID, .none:
            // Biyometri ile aç (varsayılan)
            BiometricLockScreen(
                error: error,
                isAuthenticating: isAuthenticating,
                onUnlock: authenticateBiometric
            )
        }
    }

    private func startAuthIfNeeded() {
        guard let mode = securityMode else { return }
        // Biyometri modunda otomatik tetikle. Şifre modunda kullanıcı pad'i kullanır.
        if mode == .faceID { authenticateBiometric() }
    }

    private func authenticateBiometric() {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        let context = LAContext()
        context.localizedFallbackTitle = "Şifreyi Kullan"
        let reason = "FinMate'e erişmek için kimliğinizi doğrulayın"

        var nsErr: NSError?
        let policy: LAPolicy = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &nsErr)
            ? .deviceOwnerAuthenticationWithBiometrics
            : .deviceOwnerAuthentication

        context.evaluatePolicy(policy, localizedReason: reason) { success, evalError in
            DispatchQueue.main.async {
                isAuthenticating = false
                if success {
                    error = nil
                    withAnimation { unlocked = true }
                } else {
                    error = (evalError as? LAError)?.friendlyMessage ?? "Doğrulama başarısız."
                }
            }
        }
    }
}

// MARK: - Biometric Lock Screen (legacy compat — also used by SecurityGate)

private struct BiometricLockScreen: View {
    let error: String?
    let isAuthenticating: Bool
    let onUnlock: () -> Void

    var body: some View {
        ZStack {
            Color.midnightBackground.ignoresSafeArea()
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: biometricIcon)
                    .font(.system(size: 80, weight: .light))
                    .foregroundColor(.neonBlue)
                    .shadow(color: .neonBlue.opacity(0.5), radius: 14)
                Text("FinMate Kilitli")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                Text("Devam etmek için kimliğinizi doğrulayın")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                if let error {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.neonRed)
                        .padding(.horizontal, 30)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                Button(action: onUnlock) {
                    HStack(spacing: 10) {
                        if isAuthenticating {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.black)
                        } else {
                            Image(systemName: biometricIcon)
                        }
                        Text(isAuthenticating ? "Doğrulanıyor…" : "Kilidi Aç")
                    }
                }
                .disabled(isAuthenticating)
                .neonButton(color: .neonBlue)
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
            }
        }
    }

    private var biometricIcon: String {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return "lock.fill"
        }
        switch context.biometryType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .opticID: return "opticid"
        default: return "lock.fill"
        }
    }
}

private extension LAError {
    var friendlyMessage: String {
        switch code {
        case .userCancel, .systemCancel, .appCancel: return "Doğrulama iptal edildi."
        case .authenticationFailed: return "Kimlik doğrulanamadı. Tekrar deneyin."
        case .biometryNotAvailable: return "Bu cihazda biyometri kullanılamaz."
        case .biometryNotEnrolled: return "Cihazda biyometrik veri kayıtlı değil."
        case .biometryLockout: return "Çok fazla başarısız deneme. Şifreyle açın."
        case .passcodeNotSet: return "Cihaz şifresi ayarlı değil."
        default: return "Doğrulama başarısız."
        }
    }
}

#Preview {
    ContentView()
}
