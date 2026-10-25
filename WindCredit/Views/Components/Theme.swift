import SwiftUI

// Plus Jakarta Sans for everything (OFL, bundled). Bold blue header, color-coded tiles,
// red "now" vs green "with discounts".
enum Theme {
    static let teal = Color(light: 0x1D4ED8, dark: 0x6E9BFF)      // brand blue
    static let tealDeep = Color(light: 0x1E40AF, dark: 0x9DBBFF)
    static let coral = Color(light: 0xDC2626, dark: 0xF87171)     // "now" / attention
    static let green = Color(light: 0x15803D, dark: 0x4ADE80)     // "with discounts"
    static let orange = Color(light: 0xC2410C, dark: 0xFB923C)
    static let purple = Color(light: 0x6D28D9, dark: 0xA78BFA)
    static let tealTile = Color(light: 0x0F766E, dark: 0x2DD4BF)
    static let ink = Color(light: 0x0F172A, dark: 0xEEF2F7)
    static let muted = Color(light: 0x475569, dark: 0xA3B1C2)
    static let line = Color(light: 0xE2E8F0, dark: 0x243042)
    static let mist = Color(light: 0xEFF6FF, dark: 0x16233A)
    static let sand = Color(light: 0xFEF3C7, dark: 0x3A2E12)
    static let card = Color(light: 0xFFFFFF, dark: 0x111A27)
    static let background = Color(light: 0xF3F5F9, dark: 0x0A111C)
}

// MARK: - Type scale

extension Font {
    static func wcFigure(_ size: CGFloat) -> Font { .custom("WCText-Bold", size: size, relativeTo: .largeTitle) }
    static let wcTitle = Font.custom("WCText-Bold", size: 28, relativeTo: .largeTitle)
    static let wcHeading = Font.custom("WCText-Bold", size: 19, relativeTo: .title2)
    static let wcHeadingSmall = Font.custom("WCText-Bold", size: 17, relativeTo: .title3)

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
        if let f = UIFont(name: "WCText-Bold", size: 32) { nav.largeTitleTextAttributes = [.font: f] }
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
            .background(color.opacity(configuration.isPressed ? 0.86 : 1), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
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
            .background(Theme.mist.opacity(configuration.isPressed ? 0.7 : 1), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
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
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}

struct Eyebrow: View {
    let text: String
    var color: Color = Theme.teal
    var body: some View {
        Text(text).font(.wcCaptionStrong).foregroundStyle(color)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// "Step 2 of 3" with a three-segment progress bar, then the title. No subtitle.
struct ScreenHeader: View {
    let step: Int
    var of: Int = 3
    let title: String
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                ForEach(1...of, id: \.self) { i in
                    Capsule().fill(i <= step ? Theme.teal : Theme.line).frame(height: 5)
                }
            }
            .accessibilityLabel("Step \(step) of \(of)")
            Text("Step \(step) of \(of)").font(.wcCaptionStrong).foregroundStyle(Theme.teal)
            Text(title).font(.wcTitle).foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Bold brand-colored band across the top of a screen.
struct HeaderBand<Content: View>: View {
    var color: Color = Theme.teal
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 10) { content }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 22).padding(.top, 18).padding(.bottom, 26)
            .background(color, in: UnevenRoundedRectangle(bottomLeadingRadius: 28, bottomTrailingRadius: 28, style: .continuous))
    }
}

/// Small chip on a header band ("Free", "Palm Beach County").
struct HeaderChip: View {
    let text: String
    var body: some View {
        Text(text).font(.wcCaptionStrong)
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(.white.opacity(0.18), in: Capsule())
    }
}

/// Square icon in a solid color, used in rows and tiles.
struct IconBadge: View {
    let systemImage: String
    let color: Color
    var size: CGFloat = 40
    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: size * 0.48, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(color, in: RoundedRectangle(cornerRadius: size * 0.26, style: .continuous))
            .accessibilityHidden(true)
    }
}

struct ProgressRing: View {
    let progress: Double
    var lineWidth: CGFloat = 7
    var body: some View {
        ZStack {
            Circle().stroke(Theme.mist, lineWidth: lineWidth)
            Circle().trim(from: 0, to: progress)
                .stroke(Theme.green, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(duration: 0.5), value: progress)
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
