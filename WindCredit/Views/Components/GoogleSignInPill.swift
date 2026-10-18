import SwiftUI

// Custom button built to Google's branding guidelines (developers.google.com/identity/branding-guidelines):
// official gradient "G" at 20pt (can't be resized or recolored), Google Sans Medium,
// light theme #FFFFFF / stroke #747775 / text #1F1F1F, dark theme #131314 / #8E918F / #E3E3E3,
// 16pt before the logo and 12pt between logo and text.
struct GoogleSignInPill: View {
    let action: () -> Void
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image("GoogleG")
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 20, height: 20)
                Text("Continue with Google")
                    .font(.custom("WCButton-Medium", size: 16, relativeTo: .headline))
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 54)
            .foregroundStyle(Color(uiColor: UIColor(hex: scheme == .dark ? 0xE3E3E3 : 0x1F1F1F)))
            .background(Color(uiColor: UIColor(hex: scheme == .dark ? 0x131314 : 0xFFFFFF)), in: Capsule())
            .overlay(Capsule().strokeBorder(Color(uiColor: UIColor(hex: scheme == .dark ? 0x8E918F : 0x747775)), lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(PressableStyle())
        .accessibilityIdentifier("googleSignIn")
    }
}

struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
