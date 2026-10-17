import SwiftUI

/// A one-page PDF a homeowner can send to their insurance agent.
@MainActor
enum ReportRenderer {
    static func makePDF(model: AppModel) -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("WindCredit-Report.pdf")
        let renderer = ImageRenderer(content: ReportPage(model: model).frame(width: 612, height: 792))
        renderer.render { size, draw in
            var box = CGRect(origin: .zero, size: size)
            guard let ctx = CGContext(url as CFURL, mediaBox: &box, nil) else { return }
            ctx.beginPDFPage(nil)
            draw(ctx)
            ctx.endPDFPage()
            ctx.closePDF()
        }
        return url
    }
}

private struct ReportPage: View {
    let model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("WindCredit").font(.system(size: 26, weight: .semibold, design: .serif)).foregroundStyle(Color(hex: 0x0E7C7B))
                Spacer()
                Text(Date.now.formatted(date: .long, time: .omitted)).font(.caption)
            }
            Text("Wind-mitigation discount review").font(.system(size: 18, design: .serif))
            if let r = model.saved.record {
                Group {
                    row("Address", r.displayAddress)
                    row("Parcel", r.parcelID)
                    row("Year built", r.yearBuilt.map(String.init) ?? "—")
                    row("Roof cover (county)", r.roofCoverText.capitalized)
                }
            }
            Divider()
            Text("Owner-reported features").font(.headline)
            row("Roof shape", model.saved.home.roofShape.title)
            row("Roof-to-wall", model.saved.home.roofToWall.title)
            row("Window protection", model.saved.home.openings.title)
            row("Roof after 2002", model.saved.home.roofMeetsCode.title)
            Divider()
            if let e = model.estimate {
                Text("Estimated missed savings: \(model.savingsText) per year").font(.headline)
                ForEach(e.missing) { m in row(m.title, "up to \(AppModel.money(m.yearlyHigh))") }
                row("Credit now → possible", "\(pct(e.creditNow)) → \(pct(e.creditPossible))")
            }
            Divider()
            Text("Request: please review my policy for Florida wind-mitigation credits under Fla. Stat. 627.0629. I'm scheduling a Uniform Mitigation Verification Inspection (OIR-B1-1802) and will send the completed form.")
                .font(.callout)
            Spacer()
            Text("Estimate only, based on the Florida OIR-B1-1699 credit table and Palm Beach County public records. Not an insurance quote.")
                .font(.caption2).foregroundStyle(.secondary)
        }
        .padding(48)
        .background(Color.white)
        .foregroundStyle(Color.black)
        .environment(\.colorScheme, .light)
    }

    private func row(_ k: String, _ v: String) -> some View {
        HStack { Text(k).foregroundStyle(.secondary); Spacer(); Text(v) }.font(.callout)
    }

    private func pct(_ v: Double) -> String { v.formatted(.percent.precision(.fractionLength(0))) }
}

private extension Color {
    init(hex: UInt32) { self.init(uiColor: UIColor(hex: hex)) }
}
