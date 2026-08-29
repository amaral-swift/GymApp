//
//  ExercisesView.swift
//  GymApp
//
//  Created by Gabriel Amaral on 26/08/26.
//

import SwiftUI
import SwiftData

struct ExercisesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var exercises: [Exercise]
    @State private var addingExercise: Bool = false
    
    var body: some View {
        NavigationStack {
            Group {
                if exercises.isEmpty {
                    ContentUnavailableView("Sem exercícios", systemImage: "figure.gymnastics", description: Text("Adicione um exercício para começar"))
                } else {
                    List {
                        ForEach(exercises) { exercise in
                            Text(exercise.name)
                        }
                        .onDelete(perform: deleteExercise)
                    }
                }
            }
            .sheet(isPresented: $addingExercise) {
                AddExerciseView()
            }
            .toolbar {
                ToolbarItem {
                    Button {
                        addingExercise = true
                    } label: {
                        Label("Add exercise", systemImage: "plus")
                    }
                }
            }
            .navigationTitle("Exercícios")
        }
    }
    
    private func deleteExercise(offset: IndexSet) {
        withAnimation {
            for index in offset {
                modelContext.delete(exercises[index])
            }
        }
    }
}

#Preview {
    ExercisesView()
}
