import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var auth: SupabaseAuthManager
    @EnvironmentObject private var stravaAuth: StravaAuthManager
    @EnvironmentObject private var syncService: SyncService

    @State private var isImporting = false
    @State private var importMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppMetrics.spacing) {
                    SectionHeaderLabel(text: "Strava")
                    stravaCard

                    SectionHeaderLabel(text: "Conta")
                        .padding(.top, 8)
                    accountCard
                }
                .padding(16)
            }
            .screenBackground()
            .navigationTitle("Perfil")
        }
    }

    private var stravaCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "figure.run.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(AppColor.cardio)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Strava")
                        .font(AppFont.headline())
                        .foregroundStyle(AppColor.textPrimary)
                    Text(stravaAuth.isConnected ? "Conectado" : "Não conectado")
                        .font(AppFont.caption(12))
                        .foregroundStyle(stravaAuth.isConnected ? AppColor.success : AppColor.textSecondary)
                }
                Spacer()
            }

            if !StravaConfig.isConfigured {
                Text("Falta configurar o Client ID/Secret do Strava (StravaConfig.swift) antes de conectar.")
                    .font(AppFont.caption(12))
                    .foregroundStyle(AppColor.textSecondary)
            }

            if let error = stravaAuth.lastError {
                Text(error)
                    .font(AppFont.caption(12))
                    .foregroundStyle(AppColor.danger)
            }

            if let importMessage {
                Text(importMessage)
                    .font(AppFont.caption(12))
                    .foregroundStyle(AppColor.success)
            }

            if stravaAuth.isConnected {
                Button {
                    Task { await importActivities() }
                } label: {
                    if isImporting {
                        ProgressView().tint(.black)
                    } else {
                        Text("Importar atividades recentes")
                    }
                }
                .buttonStyle(PrimaryButtonStyle(color: AppColor.cardio))
                .disabled(isImporting)

                Button("Desconectar do Strava") {
                    stravaAuth.disconnect()
                }
                .font(AppFont.caption(13))
                .foregroundStyle(AppColor.danger)
            } else {
                Button("Conectar com Strava") {
                    stravaAuth.connect()
                }
                .buttonStyle(PrimaryButtonStyle(color: AppColor.cardio))
                .disabled(!StravaConfig.isConfigured)
            }
        }
        .cardStyle()
    }

    private var accountCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(AppColor.strength)
                Text("Conta conectada ao Supabase")
                    .font(AppFont.body(14))
                    .foregroundStyle(AppColor.textPrimary)
                Spacer()
            }
            Button("Sair") {
                auth.signOut()
            }
            .font(AppFont.caption(13))
            .foregroundStyle(AppColor.danger)
        }
        .cardStyle()
    }

    private func importActivities() async {
        isImporting = true
        importMessage = nil
        let service = StravaService(auth: stravaAuth)
        let count = await service.importActivities(context: context)
        await syncService.sync(context: context)
        importMessage = count > 0 ? "\(count) atividade(s) importada(s)." : "Nenhuma atividade nova pra importar."
        isImporting = false
    }
}
