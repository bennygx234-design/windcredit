# WindCredit code tour

Read this with Xcode open next to it. The goal: you can explain any file to a judge in your own words, and answer "how does that work?" without notes. The rubric's top "Code" score is *"Explanation of code indicates immense understanding."*

## The whole app in one picture

```
 You type an address
        │
        ▼
 PropertyLookupService ──► Palm Beach County geocoder ──► exact point on the house
        │                  County parcel layer        ──► parcel ID, use, homestead
        │                  Property Appraiser page    ──► year built, roof cover
        ▼
 ConfirmHomeView: 4 picture questions (roof shape, roof-to-wall, windows, roof age)
        │
        ▼
 PolicyView ──► PolicyScanner (Apple Vision OCR, on the phone) ──► PolicyParser
        │                                                    (premiums, dates, credits)
        ▼
 DiscountEngine ──► looks up Florida's credit table (OIR-B1-1699) twice:
        │             credit NOW (what the policy already gives)
        │             credit POSSIBLE (what the house likely has)
        ▼
 ResultsView ──► $ range, payback, missing discounts, grant check
        │
        ▼
 DashboardView ──► 4-step plan, NeighborhoodService (civic view), reminder, PDF
```

Everything you enter is saved on the phone by `AppModel` (it encodes one `Saved` struct to `UserDefaults`). There is no server.

## Files, in the order data flows

| File | What it does | Be ready to explain |
|---|---|---|
| `Models/HomeModels.swift` | The vocabulary: `RoofShape`, `RoofToWall`, `OpeningProtection`, `MitigationFeatures`, `PropertyRecord`, `PolicyInfo`, `PlanStep`. | Why "Not sure" maps to the *weakest* option (we never promise money we can't back up). |
| `Services/PropertyLookupService.swift` | Address → county records in 3 web requests. | The **house-number match**: a geocoded point often lands on the lot line, so we retry with a 25 m buffer, which can grab the neighbor's lot, so we pick the parcel whose address starts with your house number. |
| | | The Property Appraiser has **no official API**. Its web page embeds the data as `var model = {...};`, so we cut that JSON out of the HTML and parse it (`parseAppraiserPage`). |
| `Services/PolicyParser.swift` | `PolicyScanner` runs Apple's `VNRecognizeTextRequest` on the photo; `PolicyParser` finds labels like "HURRICANE PREMIUM" and grabs the dollar amount on the same or next line. | **Reading order:** Vision's y-axis starts at the *bottom*, so we sort lines top-to-bottom, then left-to-right. |
| | | **Years aren't premiums:** a bare "2026" is skipped. |
| `Services/DiscountEngine.swift` | The math (below). Also `safeFloridaHome` (grant eligibility) and `whatIf` (what each "Not sure" feature would be worth). | The non-stacking rule and the formula. |
| `Resources/oir_b1_1699.json` | Florida's official credit table, converted from the OIR spreadsheet: 576 combinations for existing homes, plus new-construction values. | Where it came from (floir.gov) and why it's a lookup, not a sum. |
| `Services/NeighborhoodService.swift` | Two count queries on the Florida statewide parcel layer inside a box about a quarter mile each way: all single-family homes, and those built before 2002. | Why a box instead of a radius: the server rejects distance buffers in latitude/longitude. |
| `Services/AppModel.swift` | Holds and saves everything; computes `estimate`, `whatIf`, `savingsText`. | `@Published var saved` with `didSet { persist() }`: every change saves automatically. |
| `Services/AuthService.swift` | Optional Google sign-in, no backend. | Why no Sign in with Apple and no Supabase (README "Free, by design"). |
| `Services/ReminderService.swift` | Local notifications 30 and 7 days before renewal. | Permission is only requested after the user taps the button. |
| `Views/…` | SwiftUI screens. `Components/` holds the theme, illustrations, animations and the Google button. | Illustrations are drawn with `Canvas` in 0–1 coordinates, so they scale to any size. |
| `WindCreditTests/WindCreditTests.swift` | 17 unit tests: engine values against the state table, the non-stacking rule, the parser, the Property Appraiser page, the neighborhood math. | You ran them (`⌘U`) and they pass. |

## The math (say this out loud until it's easy)

1. **Florida discounts don't add up.** The state table gives **one** credit for each *combination* of features. Hip roof alone is 46.8%; clips alone are 34.6%; hip **and** clips together are 61.6%, not 81.4%. So the engine builds a key like `nonFBC|A|clips|none|B|hip|noswr` and looks it up.
2. Look up **c_now** (what the policy already credits) and **c_possible** (what the house likely has).
3. The hurricane premium on the policy (**H**) is already discounted by c_now, so first undo that:
   `missed = H × (c_possible − c_now) ÷ (1 − c_now)`
4. Insurers file their own, newer tables, so show a cautious range: 50% to 75% of `missed`, rounded to $50.

**Worked example (the sample policy):** H = $3,912, c_now = 0, c_possible = 61.6% (hip + clips).
missed = 3,912 × 0.616 = $2,410, so the app shows **$1,200–$1,800 a year**. A $150 inspection pays for itself in 150 ÷ (1,200 ÷ 52) ≈ **7 weeks**.

## The two technical challenges (good for the video and submission question 4)

Pick the ones you understand best. Explain them in your own words, from what you actually worked on.

1. **Getting roof data that has no API.** Year built and roof cover only exist on the Property Appraiser's web page. Fix: find the embedded JSON in the HTML and parse it, cached per lookup. Also: geocoded points miss the parcel, so retry with a buffer and match the house number.
2. **Discounts that don't stack.** Adding percentages gives impossible numbers (they can pass 100%). Fix: convert the state's 2006 spreadsheet to JSON and look up whole combinations; back the current credit out of the premium before computing the gap.
3. *(alternate)* **Reading any insurer's page.** Every declarations page looks different. Fix: on-device OCR, sorted into reading order, then label matching with fallbacks (amount on the same line or the next).

## Questions a judge might ask (answer these without notes)

- How do you know the numbers are right? (Official OIR table, unit tests against it, field test on real homes.)
- Why a range instead of one number?
- What happens if the county website is down? (`LookupError.network`, friendly message; the sample home still works.)
- Where does the user's data go? (Nowhere. On the phone only; the photo is read on-device.)
- Why Swift/SwiftUI?
- What did AI help with, and what did you do yourself? (Be specific and honest; see SUBMISSION.md.)
- What would you add next?
