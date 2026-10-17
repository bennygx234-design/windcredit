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
            VStack(alignment: .leading, spacing: 6) {
                art.view(accent: selected ? Theme.teal : Theme.muted.opacity(0.55))
                    .frame(height: 74)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 4)
                Text(title).font(.wcSubStrong).foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(detail).font(.wcCaption).foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 172, alignment: .topLeading)
            .background(selected ? Theme.mist : Theme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(selected ? Theme.teal : Theme.line, lineWidth: selected ? 2 : 1))
            .overlay(alignment: .topTrailing) {
                if selected {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 20)).foregroundStyle(Theme.teal).padding(10)
                }
            }
            .animation(.easeOut(duration: 0.15), value: selected)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .sensoryFeedback(.selection, trigger: selected)
    }
}

enum ChoiceArt {
    case roof(RoofShape), connection(RoofToWall), window(OpeningProtection), roofAge(YesNoUnsure)

    @ViewBuilder func view(accent: Color) -> some View {
        switch self {
        case .roof(let s): HouseIllustration(shape: s, accent: accent)
        case .connection(let r): ConnectionIllustration(kind: r, accent: accent)
        case .window(let o): WindowIllustration(kind: o, accent: accent)
        case .roofAge(let a): RoofAgeIllustration(answer: a, accent: accent)
        }
    }
}
