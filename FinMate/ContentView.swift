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
