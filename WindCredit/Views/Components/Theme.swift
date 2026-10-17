import SwiftUI

/// Coastal Clean: white, ocean teal, coral. New York serif for headings, SF Pro for text.
enum Theme {
    static let teal = Color(light: 0x0E7C7B, dark: 0x3FB8AF)
    static let coral = Color(light: 0xFF6F59, dark: 0xFF8A78)
    static let ink = Color(light: 0x10302E, dark: 0xE8F3F1)
    static let muted = Color(light: 0x5B7471, dark: 0x9DB5B1)
    static let mist = Color(light: 0xE3F1EF, dark: 0x1C3533)
    static let card = Color(light: 0xFFFFFF, dark: 0x132624)
    static let background = Color(light: 0xF6FAF9, dark: 0x0B1A19)

    static func serif(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
}

extension Color {
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light) })
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
    }
}

// MARK: - Buttons

struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = Theme.teal
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 54)
            .foregroundStyle(.white)
            .background(color.opacity(configuration.isPressed ? 0.85 : 1), in: RoundedRectangle(cornerRadius: 16))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 50)
            .foregroundStyle(Theme.teal)
            .background(Theme.mist.opacity(configuration.isPressed ? 0.7 : 1), in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Common pieces

struct Card<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) { content }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Theme.mist, lineWidth: 1))
    }
}

struct ScreenHeader: View {
    let step: String?
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let step { Text(step).font(.footnote.weight(.semibold)).foregroundStyle(Theme.coral) }
            Text(title).font(Theme.serif(30)).foregroundStyle(Theme.ink)
            Text(subtitle).font(.body).foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ProgressRing: View {
    let progress: Double
    var lineWidth: CGFloat = 8
    var body: some View {
        ZStack {
            Circle().stroke(Theme.mist, lineWidth: lineWidth)
            Circle().trim(from: 0, to: progress)
                .stroke(Theme.coral, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(duration: 0.5), value: progress)
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label).foregroundStyle(Theme.muted)
            Spacer()
            Text(value).foregroundStyle(Theme.ink).fontWeight(.medium).multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }
}

/// A full-width bottom area for the main button on each screen.
struct BottomBar<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(spacing: 10) { content }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .background(.bar)
    }
}
