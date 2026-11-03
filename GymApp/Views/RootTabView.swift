import SwiftUI
import SwiftData

struct RootTabView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var syncService: SyncService
    @State private var didSeedAndSync = false

    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Hoje", systemImage: "dumbbell.fill") }

            HistoryView()
                .tabItem { Label("Histórico", systemImage: "clock.arrow.circlepath") }

            RoutineView()
                .tabItem { Label("Rotina", systemImage: "calendar") }

            ExerciseLibraryView()
                .tabItem { Label("Exercícios", systemImage: "list.bullet") }
        }
        .tint(AppColor.strength)
        .toolbarBackground(AppColor.surface, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
        .task {
            guard !didSeedAndSync else { return }
            didSeedAndSync = true
            await syncService.sync(context: context)
            SeedService.seedDefaultRoutineIfNeeded(context: context)
            await syncService.sync(context: context)
        }
    }
}
