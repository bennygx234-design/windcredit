import SwiftUI

// Fonts: Fraunces for headlines/numbers, Plus Jakarta Sans for text (both OFL, bundled).
enum Theme {
    static let teal = Color(light: 0x0E7C7B, dark: 0x45BDB3)
    static let tealDeep = Color(light: 0x0A5958, dark: 0x2E9C93)
    static let coral = Color(light: 0xF2654D, dark: 0xFF8A73)
    static let ink = Color(light: 0x0F2A2E, dark: 0xEEF4F2)
    static let muted = Color(light: 0x5E6F6E, dark: 0xA3B5B2)
    static let line = Color(light: 0xE9E3D8, dark: 0x22393A)
    static let mist = Color(light: 0xE4F1EE, dark: 0x173332)
    static let sand = Color(light: 0xF4EDE1, dark: 0x1A2B2B)
    static let card = Color(light: 0xFFFFFF, dark: 0x132625)
    static let background = Color(light: 0xFBF8F3, dark: 0x0B1A1A)
}

// MARK: - Type scale

extension Font {
    static func wcFigure(_ size: CGFloat) -> Font { .custom("WCDisplay-SemiBold", size: size, relativeTo: .largeTitle) }
    static let wcTitle = Font.custom("WCDisplay-SemiBold", size: 32, relativeTo: .largeTitle)
    static let wcHeading = Font.custom("WCDisplay-Regular", size: 22, relativeTo: .title2)
    static let wcHeadingSmall = Font.custom("WCDisplay-SemiBold", size: 19, relativeTo: .title3)

    static let wcBody = Font.custom("WCText-Regular", size: 16, relativeTo: .body)
    static let wcBodyMedium = Font.custom("WCText-Medium", size: 16, relativeTo: .body)
    static let wcHeadline = Font.custom("WCText-SemiBold", size: 16, relativeTo: .headline)
    static let wcButton = Font.custom("WCText-Bold", size: 16, relativeTo: .headline)
    static let wcSub = Font.custom("WCText-Regular", size: 14.5, relativeTo: .subheadline)
    static let wcSubStrong = Font.custom("WCText-SemiBold", size: 14.5, relativeTo: .subheadline)
    static let wcCaption = Font.custom("WCText-Regular", size: 12.5, relativeTo: .caption)
    static let wcCaptionStrong = Font.custom("WCText-SemiBold", size: 12.5, relativeTo: .caption)
    static let wcEyebrow = Font.custom("WCText-Bold", size: 11.5, relativeTo: .caption2)
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

// Nav bar titles still come from UIKit.
enum Appearance {
    static func apply() {
        let nav = UINavigationBarAppearance()
        nav.configureWithTransparentBackground()
        if let f = UIFont(name: "WCText-SemiBold", size: 17) { nav.titleTextAttributes = [.font: f] }
        if let f = UIFont(name: "WCDisplay-SemiBold", size: 34) { nav.largeTitleTextAttributes = [.font: f] }
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
    }
}

// MARK: - Buttons

struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = Theme.teal
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.wcButton)
            .frame(maxWidth: .infinity, minHeight: 56)
            .foregroundStyle(.white)
            .background(color.opacity(configuration.isPressed ? 0.86 : 1), in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.wcButton)
            .frame(maxWidth: .infinity, minHeight: 52)
            .foregroundStyle(Theme.tealDeep)
            .background(Theme.mist.opacity(configuration.isPressed ? 0.7 : 1), in: Capsule())
    }
}

struct PillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.wcCaptionStrong)
            .padding(.horizontal, 14).padding(.vertical, 9)
            .foregroundStyle(Theme.tealDeep)
            .background(Theme.mist.opacity(configuration.isPressed ? 0.7 : 1), in: Capsule())
    }
}

// MARK: - Common pieces

struct Card<Content: View>: View {
    var padding: CGFloat = 20
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) { content }
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Theme.line, lineWidth: 1))
    }
}

struct Eyebrow: View {
    let text: String
    var color: Color = Theme.coral
    var body: some View {
        Text(text.uppercased()).font(.wcEyebrow).tracking(1.2).foregroundStyle(color)
    }
}

struct ScreenHeader: View {
    let step: String?
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let step { Eyebrow(text: step) }
            Text(title).font(.wcTitle).foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(subtitle).font(.wcBody).foregroundStyle(Theme.muted).lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ProgressRing: View {
    let progress: Double
    var lineWidth: CGFloat = 7
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
        HStack(alignment: .firstTextBaseline) {
            Text(label).font(.wcSub).foregroundStyle(Theme.muted)
            Spacer()
            Text(value).font(.wcSubStrong).foregroundStyle(Theme.ink).multilineTextAlignment(.trailing)
        }
    }
}

struct BottomBar<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(spacing: 10) { content }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .background(Theme.background)
            .overlay(alignment: .top) { Rectangle().fill(Theme.line).frame(height: 1) }
    }
}
