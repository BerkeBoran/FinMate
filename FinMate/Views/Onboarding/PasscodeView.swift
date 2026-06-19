
import SwiftUI
import LocalAuthentication

enum PasscodeMode {
    case create
    case change
    case verify
}

struct PasscodeView: View {
    let mode: PasscodeMode
    var onSuccess: () -> Void
    var onCancel: (() -> Void)? = nil

    @State private var phase: Phase
    @State private var entered: String = ""
    @State private var firstEntry: String = ""
    @State private var error: String?
    @State private var shake = false
    @State private var isAuthenticatingBiometric = false

    private enum Phase {
        case biometricChange    // change modu — önce biyometri (yeni)
        case enterNew           // create/change modu — yeni şifre 1. kez
        case confirmNew         // create/change modu — onay (tekrar gir)
        case unlock             // verify modu — kilidi aç
    }

    init(
        mode: PasscodeMode,
        onSuccess: @escaping () -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        self.mode = mode
        self.onSuccess = onSuccess
        self.onCancel = onCancel
        switch mode {
        case .create:  _phase = State(initialValue: .enterNew)
        case .change:  _phase = State(initialValue: .biometricChange)
        case .verify:  _phase = State(initialValue: .unlock)
        }
    }

    private var biometricSupported: Bool {
        let ctx = LAContext()
        var err: NSError?
        return ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err)
    }

    private var biometricIconName: String {
        let ctx = LAContext()
        var err: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err) else {
            return "lock.fill"
        }
        switch ctx.biometryType {
        case .faceID:   return "faceid"
        case .touchID:  return "touchid"
        case .opticID:  return "opticid"
        default:        return "lock.fill"
        }
    }

    var body: some View {
        ZStack {
            Color.midnightBackground.ignoresSafeArea()

            if phase == .biometricChange {
                biometricChangeScreen
            } else {
                passcodeEntryScreen
            }
        }
        .onAppear {
            if phase == .biometricChange && biometricSupported {
                authenticateBiometric { phase = .enterNew }
            }
        }
    }

    private var passcodeEntryScreen: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: iconForPhase)
                .font(.system(size: 64, weight: .light))
                .foregroundColor(.neonBlue)
                .shadow(color: .neonBlue.opacity(0.5), radius: 12)

            Text(titleForPhase)
                .font(.title2.bold())
                .foregroundColor(.white)

            Text(subtitleForPhase)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
                .frame(minHeight: 40)

            HStack(spacing: 16) {
                ForEach(0..<4, id: \.self) { i in
                    Circle()
                        .fill(i < entered.count ? Color.neonBlue : Color.white.opacity(0.18))
                        .frame(width: 18, height: 18)
                        .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
                }
            }
            .offset(x: shake ? -10 : 0)
            .animation(.default.repeatCount(3, autoreverses: true).speed(6), value: shake)

            if let error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.neonRed)
                    .padding(.horizontal, 30)
                    .multilineTextAlignment(.center)
            } else {
                Color.clear.frame(height: 16)
            }

            Spacer()

            NumberPad(
                onDigit: { handleDigit($0) },
                onDelete: { if !entered.isEmpty { entered.removeLast() } },
                onCancel: onCancel
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 30)
        }
    }

    private var biometricChangeScreen: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: biometricIconName)
                .font(.system(size: 80, weight: .light))
                .foregroundColor(.neonBlue)
                .shadow(color: .neonBlue.opacity(0.5), radius: 14)

            Text("Doğrulama Gerekli")
                .font(.title2.bold())
                .foregroundColor(.white)

            Text(biometricSupported
                 ? "Şifrenizi değiştirebilmek için kimliğinizi doğrulayın."
                 : "Bu cihazda biyometrik kimlik kullanılamıyor.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            if let error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.neonRed)
                    .padding(.horizontal, 30)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            if biometricSupported {
                Button(action: { authenticateBiometric { phase = .enterNew } }) {
                    HStack(spacing: 10) {
                        if isAuthenticatingBiometric {
                            ProgressView().tint(.black)
                        } else {
                            Image(systemName: biometricIconName)
                        }
                        Text(isAuthenticatingBiometric ? "Doğrulanıyor…" : "Doğrula")
                    }
                }
                .disabled(isAuthenticatingBiometric)
                .neonButton(color: .neonBlue)
                .padding(.horizontal, 30)
            }

            if let onCancel {
                Button(action: onCancel) {
                    Text("İptal")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 10)
            }

            Spacer().frame(height: 30)
        }
    }

    private func authenticateBiometric(onSuccess success: @escaping () -> Void) {
        guard !isAuthenticatingBiometric else { return }
        isAuthenticatingBiometric = true
        let context = LAContext()
        context.localizedFallbackTitle = "Cihaz Şifresini Kullan"
        let reason = mode == .verify
            ? "Şifrenizi unuttuysanız kimliğinizle giriş yapın"
            : "Şifre değişikliği için kimliğinizi doğrulayın"

        var nsErr: NSError?
        let policy: LAPolicy = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &nsErr)
            ? .deviceOwnerAuthenticationWithBiometrics
            : .deviceOwnerAuthentication

        context.evaluatePolicy(policy, localizedReason: reason) { ok, evalError in
            DispatchQueue.main.async {
                isAuthenticatingBiometric = false
                if ok {
                    error = nil
                    entered = ""
                    success()
                } else {
                    error = friendlyAuthError(evalError)
                }
            }
        }
    }

    private var iconForPhase: String {
        switch phase {
        case .biometricChange: return biometricIconName
        case .enterNew:    return "lock.fill"
        case .confirmNew:  return "checkmark.shield.fill"
        case .unlock:      return "lock.fill"
        }
    }

    private var titleForPhase: String {
        switch phase {
        case .biometricChange: return "Doğrulama Gerekli"
        case .enterNew:    return mode == .change ? "Yeni Şifre" : "Şifre Belirleyin"
        case .confirmNew:  return "Şifreyi Tekrar Girin"
        case .unlock:      return "Şifreyi Girin"
        }
    }

    private var subtitleForPhase: String {
        switch phase {
        case .biometricChange: return "Devam etmek için kimliğinizi doğrulayın"
        case .enterNew:    return "4 haneli yeni şifrenizi belirleyin"
        case .confirmNew:  return "Aynı 4 haneyi tekrar girin"
        case .unlock:      return "FinMate'e erişmek için şifrenizi girin"
        }
    }

    private func handleDigit(_ d: Int) {
        guard entered.count < 4 else { return }
        entered += "\(d)"
        if entered.count == 4 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                processCompleted()
            }
        }
    }

    private func processCompleted() {
        switch phase {
        case .biometricChange:
            break

        case .enterNew:
            firstEntry = entered
            entered = ""
            error = nil
            phase = .confirmNew

        case .confirmNew:
            if entered != firstEntry {
                failWith("Şifreler eşleşmedi")
                firstEntry = ""
                phase = .enterNew
                return
            }
            if PasscodeManager.isRecentlyUsed(entered) {
                failWith("Bu şifre yakın zamanda kullanılmış. Lütfen farklı bir şifre seçin.")
                firstEntry = ""
                phase = .enterNew
                return
            }
            PasscodeManager.save(entered)
            onSuccess()

        case .unlock:
            if PasscodeManager.verify(entered) {
                onSuccess()
            } else {
                failWith("Şifre hatalı")
            }
        }
    }

    private func failWith(_ message: String) {
        error = message
        shake.toggle()
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            entered = ""
        }
    }
}

private struct NumberPad: View {
    var onDigit: (Int) -> Void
    var onDelete: () -> Void
    var onCancel: (() -> Void)?

    private let layout: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["cancel", "0", "delete"]
    ]

    var body: some View {
        VStack(spacing: 14) {
            ForEach(layout, id: \.self) { row in
                HStack(spacing: 14) {
                    ForEach(row, id: \.self) { key in
                        keyView(key)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func keyView(_ key: String) -> some View {
        switch key {
        case "cancel":
            if let onCancel {
                Button(action: onCancel) {
                    Text("İptal")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, minHeight: 60)
                }
                .buttonStyle(.plain)
            } else {
                Color.clear.frame(maxWidth: .infinity, minHeight: 60)
            }
        case "delete":
            Button(action: onDelete) {
                Image(systemName: "delete.left")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 60)
            }
            .buttonStyle(.plain)
        default:
            Button(action: { onDigit(Int(key) ?? 0) }) {
                Text(key)
                    .font(.system(size: 28, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .background(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 30))
            }
            .buttonStyle(.plain)
        }
    }
}

private func friendlyAuthError(_ error: Error?) -> String {
    guard let la = error as? LAError else { return "Doğrulama başarısız." }
    switch la.code {
    case .userCancel, .systemCancel, .appCancel: return "Doğrulama iptal edildi."
    case .authenticationFailed: return "Kimlik doğrulanamadı. Tekrar deneyin."
    case .biometryNotAvailable:  return "Bu cihazda biyometri kullanılamaz."
    case .biometryNotEnrolled:   return "Cihazda biyometrik veri kayıtlı değil."
    case .biometryLockout:       return "Çok fazla deneme. Cihaz şifresiyle açın."
    case .passcodeNotSet:        return "Cihaz şifresi ayarlı değil."
    default:                     return "Doğrulama başarısız."
    }
}
