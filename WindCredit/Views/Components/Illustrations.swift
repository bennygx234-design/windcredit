import SwiftUI

// All drawings use 0–1 coordinates and get scaled to the view.
private extension CGSize {
    func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * width, y: y * height) }
}

private func poly(_ s: CGSize, _ pts: [(CGFloat, CGFloat)]) -> Path {
    var path = Path()
    path.addLines(pts.map { s.p($0.0, $0.1) })
    path.closeSubpath()
    return path
}

// MARK: - House with a roof shape (3/4 view)

struct HouseIllustration: View {
    let shape: RoofShape
    var accent: Color = Theme.teal

    var body: some View {
        Canvas { ctx, s in
            let stroke = StrokeStyle(lineWidth: 1.6, lineJoin: .round)
            let ink = GraphicsContext.Shading.color(Theme.ink.opacity(0.85))
            let front = poly(s, [(0.12, 0.55), (0.62, 0.55), (0.62, 0.93), (0.12, 0.93)])
            let side = poly(s, [(0.62, 0.55), (0.88, 0.45), (0.88, 0.83), (0.62, 0.93)])
            ctx.fill(front, with: .color(Theme.sand))
            ctx.fill(side, with: .color(Theme.line))
            ctx.fill(poly(s, [(0.33, 0.72), (0.41, 0.72), (0.41, 0.93), (0.33, 0.93)]), with: .color(accent.opacity(0.35)))
            ctx.stroke(poly(s, [(0.17, 0.66), (0.27, 0.66), (0.27, 0.78), (0.17, 0.78)]), with: ink, style: stroke)
            ctx.stroke(poly(s, [(0.47, 0.66), (0.57, 0.66), (0.57, 0.78), (0.47, 0.78)]), with: ink, style: stroke)
            ctx.stroke(front, with: ink, style: stroke)
            ctx.stroke(side, with: ink, style: stroke)

            switch shape {
            case .gable:
                let plane = poly(s, [(0.12, 0.55), (0.62, 0.55), (0.75, 0.22), (0.25, 0.22)])
                let gableEnd = poly(s, [(0.62, 0.55), (0.88, 0.45), (0.75, 0.22)])
                ctx.fill(plane, with: .color(accent))
                ctx.fill(gableEnd, with: .color(Theme.sand))
                ctx.stroke(plane, with: ink, style: stroke)
                ctx.stroke(gableEnd, with: ink, style: stroke)
            case .hip:
                let plane = poly(s, [(0.12, 0.55), (0.62, 0.55), (0.62, 0.24), (0.38, 0.24)])
                let hipEnd = poly(s, [(0.62, 0.55), (0.88, 0.45), (0.62, 0.24)])
                ctx.fill(plane, with: .color(accent))
                ctx.fill(hipEnd, with: .color(accent.opacity(0.7)))
                ctx.stroke(plane, with: ink, style: stroke)
                ctx.stroke(hipEnd, with: ink, style: stroke)
            case .flat:
                let slab = poly(s, [(0.10, 0.55), (0.62, 0.55), (0.90, 0.45), (0.38, 0.45)])
                let lip = poly(s, [(0.10, 0.50), (0.62, 0.50), (0.62, 0.55), (0.10, 0.55)])
                ctx.fill(slab, with: .color(accent))
                ctx.fill(lip, with: .color(accent.opacity(0.75)))
                ctx.stroke(slab, with: ink, style: stroke)
                ctx.stroke(lip, with: ink, style: stroke)
            case .notSure:
                let plane = poly(s, [(0.12, 0.55), (0.62, 0.55), (0.70, 0.26), (0.30, 0.26)])
                ctx.stroke(plane, with: ink, style: StrokeStyle(lineWidth: 1.6, dash: [4, 3]))
                ctx.draw(Text("?").font(.custom("WCDisplay-SemiBold", size: s.height * 0.26)).foregroundStyle(accent),
                         at: s.p(0.45, 0.36))
            }
        }
        .aspectRatio(1.35, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

// MARK: - How the roof is tied to the walls (cutaway)

struct ConnectionIllustration: View {
    let kind: RoofToWall
    var accent: Color = Theme.teal

    private func top(_ x: CGFloat) -> CGFloat { 0.10 + 0.42 * (x - 0.04) }

    var body: some View {
        Canvas { ctx, s in
            let ink = GraphicsContext.Shading.color(Theme.ink.opacity(0.85))
            let stroke = StrokeStyle(lineWidth: 1.6, lineJoin: .round)
            // block wall + wood top plate
            let wall = poly(s, [(0.50, 0.62), (0.90, 0.62), (0.90, 0.97), (0.50, 0.97)])
            let plate = poly(s, [(0.46, 0.53), (0.94, 0.53), (0.94, 0.62), (0.46, 0.62)])
            ctx.fill(wall, with: .color(Theme.sand))
            for y in [0.74, 0.86] as [CGFloat] {
                var joint = Path(); joint.move(to: s.p(0.50, y)); joint.addLine(to: s.p(0.90, y))
                ctx.stroke(joint, with: .color(Theme.ink.opacity(0.25)), lineWidth: 1)
            }
            ctx.fill(plate, with: .color(Color(light: 0xE6C9A0, dark: 0x8A6E4B)))
            ctx.stroke(wall, with: ink, style: stroke)
            ctx.stroke(plate, with: ink, style: stroke)
            // rafter
            let rafter = poly(s, [(0.04, top(0.04)), (0.98, top(0.98)), (0.98, top(0.98) + 0.13), (0.04, top(0.04) + 0.13)])
            ctx.fill(rafter, with: .color(Color(light: 0xD8B47F, dark: 0x9C7B50)))
            ctx.stroke(rafter, with: ink, style: stroke)

            let metal = GraphicsContext.Shading.color(accent)
            switch kind {
            case .toeNails:
                for x in [0.58, 0.74] as [CGFloat] {
                    var nail = Path()
                    nail.move(to: s.p(x, top(x) + 0.07))
                    nail.addLine(to: s.p(x + 0.08, 0.60))
                    ctx.stroke(nail, with: metal, style: StrokeStyle(lineWidth: 2.6, lineCap: .round))
                    let r = s.width * 0.028
                    ctx.fill(Path(ellipseIn: CGRect(x: x * s.width - r, y: (top(x) + 0.07) * s.height - r, width: r * 2, height: r * 2)), with: metal)
                }
            case .clips:
                let x: CGFloat = 0.68
                let clip = poly(s, [(x, top(x) + 0.10), (x + 0.10, top(x + 0.10) + 0.10), (x + 0.10, 0.62), (x, 0.62)])
                ctx.fill(clip, with: metal)
                ctx.stroke(clip, with: ink, style: StrokeStyle(lineWidth: 1))
                for (cx, cy) in [(x + 0.03, 0.57), (x + 0.07, 0.57)] as [(CGFloat, CGFloat)] {
                    ctx.fill(Path(ellipseIn: CGRect(origin: s.p(cx - 0.01, cy - 0.01), size: CGSize(width: s.width * 0.02, height: s.width * 0.02))), with: .color(.white.opacity(0.8)))
                }
            case .singleWraps, .doubleWraps:
                let xs: [CGFloat] = kind == .singleWraps ? [0.66] : [0.60, 0.76]
                for x in xs {
                    var strap = Path()
                    strap.move(to: s.p(x, 0.92))
                    strap.addLine(to: s.p(x, top(x) - 0.01))
                    strap.addLine(to: s.p(x + 0.07, top(x + 0.07) - 0.01))
                    strap.addLine(to: s.p(x + 0.07, 0.92))
                    ctx.stroke(strap, with: metal, style: StrokeStyle(lineWidth: 3.4, lineJoin: .round))
                }
            case .notSure:
                ctx.draw(Text("?").font(.custom("WCDisplay-SemiBold", size: s.height * 0.32)).foregroundStyle(accent),
                         at: s.p(0.24, 0.62))
            }
        }
        .aspectRatio(1.25, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

// MARK: - Window protection

struct WindowIllustration: View {
    let kind: OpeningProtection
    var accent: Color = Theme.teal

    var body: some View {
        Canvas { ctx, s in
            let ink = GraphicsContext.Shading.color(Theme.ink.opacity(0.85))
            let stroke = StrokeStyle(lineWidth: 1.6, lineJoin: .round)
            let frame = poly(s, [(0.24, 0.10), (0.76, 0.10), (0.76, 0.92), (0.24, 0.92)])
            let glass = poly(s, [(0.29, 0.16), (0.71, 0.16), (0.71, 0.86), (0.29, 0.86)])
            ctx.fill(frame, with: .color(Theme.sand))
            ctx.fill(glass, with: .color(Color(light: 0xCFE6F0, dark: 0x2A4A57)))
            var mullion = Path()
            mullion.move(to: s.p(0.5, 0.16)); mullion.addLine(to: s.p(0.5, 0.86))
            mullion.move(to: s.p(0.29, 0.51)); mullion.addLine(to: s.p(0.71, 0.51))
            ctx.stroke(mullion, with: ink, style: stroke)

            switch kind {
            case .hurricane:
                // accordion shutter, closed
                for i in 0..<7 {
                    let x = 0.27 + CGFloat(i) * 0.066
                    let slat = poly(s, [(x, 0.12), (x + 0.066, 0.12), (x + 0.066, 0.90), (x, 0.90)])
                    ctx.fill(slat, with: .color(i.isMultiple(of: 2) ? accent : accent.opacity(0.75)))
                }
            case .basic:

                let panel = poly(s, [(0.27, 0.12), (0.73, 0.12), (0.73, 0.48), (0.27, 0.48)])
                ctx.fill(panel, with: .color(accent.opacity(0.55)))
                ctx.stroke(panel, with: ink, style: StrokeStyle(lineWidth: 1))
            case .none:
                // plywood: no credit
                let ply = poly(s, [(0.20, 0.30), (0.80, 0.24), (0.82, 0.70), (0.22, 0.76)])
                ctx.fill(ply, with: .color(Color(light: 0xD9B98A, dark: 0x7D6443)))
                ctx.stroke(ply, with: ink, style: stroke)
            case .notSure:
                ctx.draw(Text("?").font(.custom("WCDisplay-SemiBold", size: s.height * 0.4)).foregroundStyle(accent),
                         at: s.p(0.5, 0.5))
            }
            ctx.stroke(frame, with: ink, style: stroke)
        }
        .aspectRatio(0.9, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

// MARK: - Roof age

struct RoofAgeIllustration: View {
    let answer: YesNoUnsure
    var accent: Color = Theme.teal
    var body: some View {
        Text(answer == .yes ? "2002+" : answer == .no ? "Older" : "?")
            .font(.wcFigure(26))
            .foregroundStyle(accent)
            .accessibilityHidden(true)
    }
}
