//
//  ContentView.swift
//  FinMate
//
//  Created by Berke Boran on 7.10.2025.
//

import SwiftUI

struct ContentView: View {
    @State private var isActive = false
    var body: some View {
        if isActive {
            MainView()
        } else {
            SplashView()
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            isActive = true
                        }
                    }
                }
            
        }
    }
}
#Preview {
    ContentView()
}
