//
//  RoutineTemplate.swift
//  GymApp
//
//  Created by Gabriel Amaral on 24/08/26.
//

import Foundation
import SwiftData

@Model
final class RoutineTemplate {
    var name: String
    @Relationship(deleteRule: .nullify, inverse: \Workout.routineTemplate) var workouts: [Workout] = []

    init(name: String, workouts: [Workout]) {
        self.name = name
        self.workouts = workouts
    }
}
