import Foundation
import SwiftUI
struct SplashView: View {
    var body: some View {
        VStack() {
            Image("SplashLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 350,height: 350)
            Text("FinMate ile gelir ve giderlerini kolayca takip et, bütçeni kontrol altında tut!")
                .fontWeight(.heavy)
                .font(.system(size: 25, weight: .heavy))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
        }
    }
}
#Preview {
    SplashView()
}
