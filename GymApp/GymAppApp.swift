//
//  GymAppApp.swift
//  GymApp
//

import SwiftUI
import SwiftData

@main
struct GymAppApp: App {
    @StateObject private var auth = SupabaseAuthManager()
    @StateObject private var syncService: SyncService

    init() {
        let authManager = SupabaseAuthManager()
        _auth = StateObject(wrappedValue: authManager)
        _syncService = StateObject(wrappedValue: SyncService(auth: authManager))
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Exercise.self,
            RoutineDay.self,
            RoutineExercise.self,
            WorkoutSession.self,
            LoggedSet.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            Group {
                if auth.isAuthenticated {
                    RootTabView()
                } else {
                    AuthView()
                }
            }
            .environmentObject(auth)
            .environmentObject(syncService)
            .tint(AppColor.strength)
            .preferredColorScheme(.dark)
            .background(AppColor.background.ignoresSafeArea())
        }
        .modelContainer(sharedModelContainer)
    }
}
