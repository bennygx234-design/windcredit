import SwiftUI

// Animation helpers. All of them skip straight to the end state when Reduce Motion is on.

struct Reveal: ViewModifier {
    var delay: Double
    @State private var shown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown || reduceMotion ? 0 : 16)
            .onAppear {
                guard !shown else { return }
                if reduceMotion { shown = true; return }
                withAnimation(.spring(duration: 0.55, bounce: 0.18).delay(delay)) { shown = true }
            }
    }
}

extension View {
    /// Fade + slide up on first appear. Stagger lists with increasing delays.
    func reveal(_ delay: Double = 0) -> some View { modifier(Reveal(delay: delay)) }
}

struct CountUp: View {
    let values: [Int]
    var prefix = ""
    var font: Font = .wcFigure(48)
    var color: Color = Theme.teal
    var delay: Double = 0.15

    @State private var progress = 0.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Text(prefix + values.map { AppModel.money(Int(Double($0) * progress)) }.joined(separator: "–"))
            .font(font)
            .foregroundStyle(color)
            .contentTransition(.numericText(value: progress))
            .monospacedDigit()
            .onAppear {
                guard progress == 0 else { return }
                if reduceMotion { progress = 1; return }
                withAnimation(.smooth(duration: 1.0).delay(delay)) { progress = 1 }
            }
            .onChange(of: values) { progress = 1 }
            .accessibilityLabel(prefix + values.map { AppModel.money($0) }.joined(separator: " to "))
    }
}

struct LookupAnimation: View {
    @State private var blowing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                HouseIllustration(shape: .hip).frame(width: 120, height: 90)
                ForEach(0..<3) { i in
                    Capsule()
                        .fill(Theme.teal.opacity(0.35))
                        .frame(width: 34 - CGFloat(i) * 6, height: 3)
                        .offset(x: blowing ? 90 : -90, y: CGFloat(i) * 16 - 26)
                        .opacity(blowing ? 0 : 1)
                        .animation(reduceMotion ? nil : .easeIn(duration: 1.1).repeatForever(autoreverses: false).delay(Double(i) * 0.25),
                                   value: blowing)
                }
            }
            .frame(height: 100)
            Text("Checking county records…").font(.wcSub).foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .onAppear { blowing = true }
        .accessibilityElement(children: .combine)
    }
}
