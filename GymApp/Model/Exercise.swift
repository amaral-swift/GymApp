//
//  Exercise.swift
//  GymApp
//
//  Created by Gabriel Amaral on 24/08/26.
//

import Foundation
import SwiftData

@Model
final class Exercise {
    var name: String
    var series: Int
    var repetition: Int
    var rest: Int
    var exerciseSets: [ExerciseSet] = []

    init(name: String, series: Int, repetition: Int, rest: Int) {
        self.name = name
        self.series = series
        self.repetition = repetition
        self.rest = rest
    }
}
