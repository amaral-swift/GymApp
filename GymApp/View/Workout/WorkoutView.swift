//
//  WorkoutView.swift
//  GymApp
//
//  Created by Gabriel Amaral on 25/08/26.
//

import SwiftUI
import SwiftData

struct WorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isEditing: Bool = false
    let workout: Workout

    private var sortedExercises: [WorkoutExercise] {
        workout.exerciseSets.sorted { $0.order < $1.order }
    }

    var body: some View {
        NavigationStack {
            VStack {
                List {
                    ForEach(sortedExercises) { workoutExercise in
                        Text(workoutExercise.exercises?.name ?? "")
                    }
                    .onMove(perform: moveExercise)
                }
            }
            .navigationTitle(workout.name)
        }
    }
    
    private func moveExercise(from source: IndexSet, to destination: Int) {
        var reordered = sortedExercises
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, set) in reordered.enumerated() {
            set.order = index
        }
    }
}

#Preview {
    //    WorkoutView()
}
