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
            VStack(spacing: 20) {
                Spacer()

                VStack(spacing: 4) {
                    Text("GymApp")
                        .font(.largeTitle.bold())
                    Text("Seu treino, acompanhado pelo Claude")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Picker("Modo", selection: $mode) {
                    ForEach(Mode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                VStack(spacing: 12) {
                    TextField("E-mail", text: $email)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)
                        .padding(12)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))

                    SecureField("Senha", text: $password)
                        .textContentType(mode == .signIn ? .password : .newPassword)
                        .padding(12)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
                }
                .padding(.horizontal)

                if let error = auth.lastError {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }

                Button {
                    Task { await submit() }
                } label: {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text(mode.rawValue)
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                .disabled(email.isEmpty || password.count < 6 || isLoading)

                if mode == .signUp {
                    Text("Use o e-mail e senha que você quiser — essa conta é só sua, pra guardar seus treinos.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()
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
