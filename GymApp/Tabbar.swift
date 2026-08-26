//
//  Tabbar.swift
//  GymApp
//
//  Created by Gabriel Amaral on 26/08/26.
//

import SwiftUI

enum Tab: Hashable {
    case home, routine, exercises
}

struct Tabbar: View {
    @State private var selectedTab: Tab = .home
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ContentView()
                .tabItem { Label("Treinos", systemImage: "dumbbell") }
                .tag(Tab.home)
            
            RoutineView()
                .tabItem { Label("Rotinas", systemImage: "list.bullet") }
                .tag(Tab.routine)
            
            ExercisesView()
                .tabItem { Label("Exercícios", systemImage: "figure.gymnastics") }
                .tag(Tab.exercises)
        }
    }
}

#Preview {
    Tabbar()
}
