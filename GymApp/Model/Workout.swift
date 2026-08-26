//
//  Workout.swift
//  GymApp
//
//  Created by Gabriel Amaral on 24/08/26.
//

import Foundation
import SwiftData

@Model
final class Workout {
    var name: String
    @Relationship(deleteRule: .nullify, inverse: \ExerciseSet.workout) var exerciseSets: [ExerciseSet] = []
    var weekDay: weekDay
    var type: workoutType
    var routineTemplate: [RoutineTemplate]? = []
        
    init(name: String, exerciseSets: [ExerciseSet], weekDay: weekDay, type: workoutType) {
        self.name = name
        self.exerciseSets = exerciseSets
        self.weekDay = weekDay
        self.type = type
    }
}

enum weekDay: String, Codable {
    case monday, tuesday, wednesday, thursday, friday, saturday, sunday
}

enum workoutType: String, CaseIterable, Identifiable, Codable {
    case ABC, ABCD, ABCAB
    
    var id: Self { self }
}
