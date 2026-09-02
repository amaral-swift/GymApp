//
//  ExerciseSet.swift
//  GymApp
//
//  Created by Gabriel Amaral on 24/08/26.
//

import Foundation
import SwiftData

@Model
final class ExerciseSet {
    var name: String
    @Relationship(deleteRule: .nullify, inverse: \Exercise.exerciseSets) var exercises: [Exercise] = []

    init(name: String, exercises: [Exercise]) {
        self.name = name
        self.exercises = exercises
    }
}
