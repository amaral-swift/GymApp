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
    
    var body: some View {
        NavigationStack {
            VStack {
                Text(workout.name)
                ForEach(workout.exerciseSets) { exerciseSet in
                    Text(exerciseSet.name)
                }
            }
            .navigationTitle(workout.name)
        }
    }
}

#Preview {
    //    WorkoutView()
}
