
import SwiftUI
import LocalAuthentication

struct OnboardingView: View {
    var onComplete: () -> Void

    @State private var step: Int = 0    // 0: ad-soyad, 1: güvenlik, 2: şifre belirleme

    @AppStorage(SettingsKeys.userName) private var userName: String = "Kullanıcı"
    @AppStorage(SettingsKeys.lastName) private var lastName: String = ""
    @AppStorage(SettingsKeys.securityMode) private var securityModeRaw: String = ""
    @AppStorage(SettingsKeys.onboardingCompleted) private var onboardingCompleted: Bool = false

    @State private var draftFirstName: String = ""
    @State private var draftLastName: String = ""
    @State private var selectedMode: SecurityMode? = nil
    @State private var nameError: String?
    @State private var biometricError: String?

    var body: some View {
        ZStack {
            Color.midnightBackground.ignoresSafeArea()
            LinearGradient(
                colors: [Color.neonBlue.opacity(0.12), .clear],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                progressIndicator
                    .padding(.top, 16)

                Group {
                    switch step {
                    case 0: nameStep
                    case 1: securityStep
                    case 2: passcodeStep
                    default: EmptyView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            }
        }
    }

    private var progressIndicator: some View {
        let stepCount = selectedMode?.requiresPasscode == true ? 3 : 2
        return HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { i in
                Capsule()
                    .fill(i <= step ? Color.neonBlue : Color.white.opacity(0.15))
                    .frame(height: 4)
                    .opacity(i < stepCount ? 1 : 0)
            }
        }
        .padding(.horizontal, 30)
        .animation(.easeInOut, value: step)
        .animation(.easeInOut, value: selectedMode)
    }

    private var nameStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 64, weight: .light))
                .foregroundColor(.neonBlue)
                .shadow(color: .neonBlue.opacity(0.5), radius: 12)

            VStack(spacing: 8) {
                Text("Hoş Geldiniz")
                    .font(.title.bold())
                    .foregroundColor(.white)
                Text("Sizi tanıyalım — adınızı ve soyadınızı girin")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 30)

            VStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Ad")
                        .font(.caption)
                        .foregroundColor(.gray)
                    TextField("Adınız", text: $draftFirstName)
                        .textContentType(.givenName)
                        .autocorrectionDisabled()
                        .neoTextField()
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Soyad")
                        .font(.caption)
                        .foregroundColor(.gray)
                    TextField("Soyadınız", text: $draftLastName)
                        .textContentType(.familyName)
                        .autocorrectionDisabled()
                        .neoTextField()
                }
            }
            .padding(.horizontal, 30)

            if let nameError {
                Text(nameError)
                    .font(.caption)
                    .foregroundColor(.neonRed)
                    .padding(.horizontal, 30)
            }

            Spacer()

            Button(action: submitName) {
                HStack {
                    Text("Devam Et")
                    Image(systemName: "arrow.right")
                }
                .neonButton(color: .neonBlue)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 40)
        }
        .onAppear {
            draftFirstName = userName == "Kullanıcı" ? "" : userName
            draftLastName = lastName
        }
    }

    private func submitName() {
        let f = draftFirstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let l = draftLastName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !f.isEmpty, !l.isEmpty else {
            nameError = "Lütfen hem ad hem soyad girin."
            return
        }
        nameError = nil
        userName = f
        lastName = l
        withAnimation { step = 1 }
    }

    private var securityStep: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 20)

            Image(systemName: "lock.shield.fill")
                .font(.system(size: 56, weight: .light))
                .foregroundColor(.neonBlue)
                .shadow(color: .neonBlue.opacity(0.5), radius: 12)

            VStack(spacing: 8) {
                Text("Güvenlik")
                    .font(.title.bold())
                    .foregroundColor(.white)
                Text("FinMate'e nasıl erişmek istiyorsunuz?")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 30)

            VStack(spacing: 12) {
                ForEach(SecurityMode.allCases) { mode in
                    SecurityOptionCard(
                        mode: mode,
                        isSelected: selectedMode == mode,
                        isDisabled: mode.requiresBiometric && !biometricAvailable,
                        action: { selectedMode = mode }
                    )
                }
            }
            .padding(.horizontal, 24)

            if let biometricError {
                Text(biometricError)
                    .font(.caption)
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 30)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            HStack(spacing: 12) {
                Button(action: { withAnimation { step = 0 } }) {
                    HStack {
                        Image(systemName: "arrow.left")
                        Text("Geri")
                    }
                    .font(.headline)
                    .foregroundColor(.gray)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(15)
                }
                Button(action: submitSecurity) {
                    HStack {
                        Text(selectedMode?.requiresPasscode == true ? "Şifre Belirle" : "Tamam")
                        Image(systemName: "arrow.right")
                    }
                    .neonButton(color: selectedMode == nil ? .gray : .neonBlue)
                }
                .disabled(selectedMode == nil)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .onAppear {
            checkBiometricAvailability()
        }
    }

    private var biometricAvailable: Bool {
        let ctx = LAContext()
        var err: NSError?
        return ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err)
    }

    private func checkBiometricAvailability() {
        if !biometricAvailable {
            biometricError = "Bu cihazda biyometrik kimlik kullanılamaz — Şifre seçeneğini kullanabilirsiniz."
        }
    }

    private func submitSecurity() {
        guard let mode = selectedMode else { return }
        securityModeRaw = mode.rawValue
        if mode.requiresPasscode {
            withAnimation { step = 2 }
        } else {
            PasscodeManager.save(nil)
            complete()
        }
    }

    private var passcodeStep: some View {
        PasscodeView(
            mode: .create,
            onSuccess: { complete() },
            onCancel: { withAnimation { step = 1 } }
        )
    }

    private func complete() {
        onboardingCompleted = true
        onComplete()
    }
}

private struct SecurityOptionCard: View {
    let mode: SecurityMode
    let isSelected: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: { if !isDisabled { action() } }) {
            HStack(spacing: 14) {
                Image(systemName: mode.icon)
                    .font(.system(size: 28))
                    .foregroundColor(isSelected ? .neonBlue : (isDisabled ? .gray : .white))
                    .frame(width: 50, height: 50)
                    .background((isSelected ? Color.neonBlue : Color.white).opacity(isSelected ? 0.18 : 0.05))
                    .cornerRadius(12)

                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(isDisabled ? .gray : .white)
                    Text(mode.description)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.neonBlue)
                        .font(.title3)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color.neonBlue.opacity(0.12) : Color.white.opacity(0.04))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.neonBlue : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
            )
            .opacity(isDisabled ? 0.5 : 1)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}
