import SwiftUI
import SwiftData

struct RootTabView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var syncService: SyncService
    @State private var didSeedAndSync = false

    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Hoje", systemImage: "figure.strengthtraining.traditional") }

            HistoryView()
                .tabItem { Label("Histórico", systemImage: "clock.arrow.circlepath") }

            RoutineView()
                .tabItem { Label("Rotina", systemImage: "calendar") }

            ExerciseLibraryView()
                .tabItem { Label("Exercícios", systemImage: "list.bullet") }
        }
        .task {
            guard !didSeedAndSync else { return }
            didSeedAndSync = true
            await syncService.sync(context: context)
            SeedService.seedDefaultRoutineIfNeeded(context: context)
            await syncService.sync(context: context)
        }
    }
}
