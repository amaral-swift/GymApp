import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var auth: SupabaseAuthManager

    @State private var email = ""
    @State private var password = ""
    @State private var mode: Mode = .signIn
    @State private var isLoading = false

    enum Mode: String, CaseIterable {
        case signIn = "Entrar"
        case signUp = "Criar conta"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.background.ignoresSafeArea()

                VStack(spacing: 28) {
                    Spacer(minLength: 20)

                    VStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(AppColor.strength.opacity(0.18))
                                .frame(width: 92, height: 92)
                            Image(systemName: "dumbbell.fill")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundStyle(AppColor.strength)
                        }

                        VStack(spacing: 4) {
                            Text("GymApp")
                                .font(AppFont.largeTitle(34))
                                .foregroundStyle(AppColor.textPrimary)
                            Text("Seu treino, acompanhado pelo Claude")
                                .font(AppFont.body(14))
                                .foregroundStyle(AppColor.textSecondary)
                        }
                    }

                    Picker("Modo", selection: $mode) {
                        ForEach(Mode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 32)

                    VStack(spacing: 12) {
                        TextField("", text: $email, prompt: Text("E-mail").foregroundStyle(AppColor.textSecondary))
                            .textContentType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.emailAddress)
                            .foregroundStyle(AppColor.textPrimary)
                            .padding(14)
                            .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppMetrics.smallCornerRadius, style: .continuous))

                        SecureField("", text: $password, prompt: Text("Senha").foregroundStyle(AppColor.textSecondary))
                            .textContentType(mode == .signIn ? .password : .newPassword)
                            .foregroundStyle(AppColor.textPrimary)
                            .padding(14)
                            .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppMetrics.smallCornerRadius, style: .continuous))
                    }
                    .padding(.horizontal, 24)

                    if let error = auth.lastError {
                        Text(error)
                            .font(AppFont.caption(13))
                            .foregroundStyle(AppColor.danger)
                            .padding(.horizontal, 24)
                            .multilineTextAlignment(.center)
                    }

                    Button {
                        Task { await submit() }
                    } label: {
                        if isLoading {
                            ProgressView()
                                .tint(.black)
                        } else {
                            Text(mode.rawValue)
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, 24)
                    .disabled(email.isEmpty || password.count < 6 || isLoading)

                    if mode == .signUp {
                        Text("Use o e-mail e senha que você quiser — essa conta é só sua, pra guardar seus treinos.")
                            .font(AppFont.caption(12))
                            .foregroundStyle(AppColor.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }

                    Spacer()
                }
            }
        }
    }

    private func submit() async {
        isLoading = true
        defer { isLoading = false }
        switch mode {
        case .signIn: await auth.signIn(email: email, password: password)
        case .signUp: await auth.signUp(email: email, password: password)
        }
    }
}
