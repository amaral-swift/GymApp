//
//  ExerciseSet.swift
//  GymApp
//
//  Created by Gabriel Amaral on 24/08/26.
//

import Foundation
import SwiftData

@Model
final class WorkoutExercise {
    var order: Int
    var exercises: Exercise?
    var workouts: Workout?
    
    init(order: Int, exercises: Exercise?, workouts: Workout?) {
        self.order = order
        self.exercises = exercises
        self.workouts = workouts
    }
}
