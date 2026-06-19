
import SwiftUI

extension Color {
    static let midnightBackground = Color(red: 0.05, green: 0.07, blue: 0.12) // Deep dark blue-black
    static let surface = Color(red: 0.1, green: 0.12, blue: 0.18) // Slightly lighter for cards
    
    static let neonGreen = Color(red: 0.2, green: 1.0, blue: 0.6)
    static let neonBlue = Color(red: 0.2, green: 0.6, blue: 1.0)
    static let neonPurple = Color(red: 0.8, green: 0.2, blue: 1.0)
    static let neonRed = Color(red: 1.0, green: 0.3, blue: 0.4)
    
    static let textPrimary = Color.white
    static let textSecondary = Color.gray.opacity(0.8)
}

extension LinearGradient {
    static let mainBackground = LinearGradient(
        gradient: Gradient(colors: [Color.midnightBackground, Color(red: 0.02, green: 0.03, blue: 0.05)]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let glassGradient = LinearGradient(
        gradient: Gradient(colors: [Color.white.opacity(0.15), Color.white.opacity(0.05)]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct BackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            LinearGradient.mainBackground
                .ignoresSafeArea()
            content
        }
    }
}

struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 20
    
    func body(content: Content) -> some View {
        content
            .background(BlurView(style: .systemUltraThinMaterialDark))
            .background(LinearGradient.glassGradient)
            .cornerRadius(cornerRadius)
            .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(LinearGradient(
                        gradient: Gradient(colors: [.white.opacity(0.3), .clear, .white.opacity(0.1)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ), lineWidth: 1)
            )
    }
}

struct NeonButtonModifier: ViewModifier {
    var color: Color
    
    func body(content: Content) -> some View {
        content
            .font(.headline)
            .foregroundColor(.black)
            .padding()
            .frame(maxWidth: .infinity)
            .background(color)
            .cornerRadius(15)
            .shadow(color: color.opacity(0.5), radius: 10, x: 0, y: 0) // Neon Glow
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
            )
    }
}

struct NeoTextFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.surface.opacity(0.5))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .foregroundColor(.textPrimary)
            .accentColor(.neonBlue)
    }
}

struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

extension View {
    func midnightTheme() -> some View {
        self.modifier(BackgroundModifier())
    }
    
    func glassCard() -> some View {
        self.modifier(GlassCardModifier())
    }
    
    func neonButton(color: Color = .neonBlue) -> some View {
        self.modifier(NeonButtonModifier(color: color))
    }
    
    func neoTextField() -> some View {
        self.modifier(NeoTextFieldModifier())
    }
}
