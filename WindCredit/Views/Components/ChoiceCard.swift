import SwiftUI

/// A tappable picture choice used on the "Your home" questions.
struct ChoiceCard: View {
    let title: String
    let detail: String
    let art: ChoiceArt
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                art.view
                    .frame(height: 54)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(selected ? Theme.teal : Theme.muted)
                Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(detail).font(.caption).foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
            .background(selected ? Theme.mist : Theme.card, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(selected ? Theme.teal : Theme.mist, lineWidth: selected ? 2 : 1))
            .overlay(alignment: .topTrailing) {
                if selected {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.teal).padding(8)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

/// Simple line drawings so homeowners can match what they see.
enum ChoiceArt {
    case roof(RoofShape), strap(RoofToWall), window(OpeningProtection), symbol(String)

    @ViewBuilder var view: some View {
        switch self {
        case .roof(let s): RoofDrawing(shape: s)
        case .strap(let r): Image(systemName: Self.strapSymbol(r)).font(.system(size: 34))
        case .window(let o): Image(systemName: Self.windowSymbol(o)).font(.system(size: 34))
        case .symbol(let name): Image(systemName: name).font(.system(size: 34))
        }
    }

    static func strapSymbol(_ r: RoofToWall) -> String {
        switch r {
        case .toeNails: "hammer"
        case .clips: "paperclip"
        case .singleWraps: "link"
        case .doubleWraps: "link.badge.plus"
        case .notSure: "questionmark.circle"
        }
    }

    static func windowSymbol(_ o: OpeningProtection) -> String {
        switch o {
        case .hurricane: "shield.lefthalf.filled"
        case .basic: "window.shade.closed"
        case .none: "window.casement"
        case .notSure: "questionmark.circle"
        }
    }
}

/// Draws a house with the chosen roof shape, in perspective-free side view.
struct RoofDrawing: View {
    let shape: RoofShape
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let base = min(w * 0.7, h * 1.4)
            let left = (w - base) / 2, right = left + base
            let wallTop = h * 0.55
            var house = Path()
            house.addRect(CGRect(x: left + base * 0.08, y: wallTop, width: base * 0.84, height: h * 0.42))
            ctx.stroke(house, with: .foreground, lineWidth: 2)
            var roof = Path()
            switch shape {
            case .hip:
                roof.move(to: CGPoint(x: left, y: wallTop))
                roof.addLine(to: CGPoint(x: left + base * 0.3, y: h * 0.1))
                roof.addLine(to: CGPoint(x: right - base * 0.3, y: h * 0.1))
                roof.addLine(to: CGPoint(x: right, y: wallTop))
                roof.closeSubpath()
            case .gable:
                roof.move(to: CGPoint(x: left, y: wallTop))
                roof.addLine(to: CGPoint(x: w / 2, y: h * 0.05))
                roof.addLine(to: CGPoint(x: right, y: wallTop))
                roof.closeSubpath()
            case .flat:
                roof.addRect(CGRect(x: left, y: wallTop - h * 0.1, width: base, height: h * 0.1))
            case .notSure:
                ctx.draw(Text("?").font(.system(size: h * 0.4, weight: .semibold)), at: CGPoint(x: w / 2, y: h * 0.3))
            }
            ctx.stroke(roof, with: .foreground, style: StrokeStyle(lineWidth: 2.5, lineJoin: .round))
        }
        .accessibilityHidden(true)
    }
}
