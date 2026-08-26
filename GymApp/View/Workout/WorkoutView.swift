//
//  WorkoutView.swift
//  GymApp
//
//  Created by Gabriel Amaral on 25/08/26.
//

import SwiftUI

struct WorkoutView: View {
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
