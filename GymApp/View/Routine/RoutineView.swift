//
//  RoutineView.swift
//  GymApp
//
//  Created by Gabriel Amaral on 26/08/26.
//

import SwiftUI
import SwiftData

struct RoutineView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var routineTemapletes: [RoutineTemplate]
    @State private var addingRoutine: Bool = false
    @State private var isEditing: Bool = false

    var body: some View {
        NavigationStack {
            Group {
                if routineTemapletes.isEmpty {
                    ContentUnavailableView("Sem rotinas", systemImage: "list.bullet", description: Text("Adicione uma rotina para começar"))
                } else {
                    List {
                        ForEach(routineTemapletes) { routine in
                            Section(routine.name) {
                                ForEach(routine.workouts) { workout in
                                    NavigationLink(workout.name, destination: WorkoutView(workout: workout))
                                }
                            }
                        }
                        .onDelete(perform: deleteRoutine)
                    }
                }
            }
            .sheet(isPresented: $addingRoutine) {
                AddRoutineView()
            }
            .toolbar {
                ToolbarItem {
                    Button {
                        addingRoutine = true
                    } label: {
                        Label("Add Sample Data", systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(isEditing ? "Concluído" : "Editar") {
                        withAnimation {
                            isEditing.toggle()
                        }
                    }
                }
            }
            .navigationTitle("Rotinas")
        }
    }
    
    private func deleteRoutine(offset: IndexSet) {
        withAnimation {
            for index in offset {
                modelContext.delete(routineTemapletes[index])
            }
        }
    }
}

#Preview {
    RoutineView()
}
