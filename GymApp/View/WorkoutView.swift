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
        Text(workout.name)
    }
}

#Preview {
//    WorkoutView()
}
