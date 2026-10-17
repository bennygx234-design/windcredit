# WindCredit build plan

**One sentence:** WindCredit shows Palm Beach County homeowners which hurricane-insurance discounts their home likely qualifies for but isn't getting, and what it's worth in dollars a year.

**Who it's for:** a Boca Raton homeowner with an older house who pays about $6,300 a year for insurance (the Palm Beach average, OIR, July 2026) and has never had a wind-mitigation inspection.

**Deadline:** Monday, Oct 26, 2026. Submit before **noon ET**. The rules PDF says noon; the registration page says 9 pm, so noon is the safe choice.

---

## 1. What past winners did (and what we copy)

These come from 13 winner pages and 9 demo-video transcripts, including BoostT1D (2025 national winner), SunGuard (FL23 2025, our own district office), BinGo (FL22 2025) and CoFIS (IA01 2025).

| Pattern | Evidence | What WindCredit does |
|---|---|---|
| SwiftUI is a credible winning stack | BoostT1D, SunGuard and OptiSense were all native Swift | Native SwiftUI app |
| Local Florida number in the first 15 seconds | SunGuard ("FL 2nd in melanoma"), Kidney Buddy (Broward stats) | Open with "Palm Beach homeowners pay $6,323 a year on average" |
| Few screens, one clear flow | Flip the Switch had 4 tabs; Kidney Buddy pitched "8 simple steps" | About 8 screens, one straight path |
| Trust in onboarding | BoostT1D shows an "informational only" screen; Flip the Switch had no account, for privacy | "Estimate, not a quote" screen; the policy photo is read on the phone and never uploaded |
| Proof against real outcomes | CoFIS: 90% match to a real flood; RoadWatch: accuracy by condition | Run the app on 5–10 real Boca homes with real inspection forms and report the match rate |
| Show the code for 15–25 seconds | CoFIS walked its folders; Computerpreter showed charts | Show `DiscountEngine.swift` and explain the "discounts don't add up" rule |
| Two technical challenges, with numbers | SunGuard: "compression cut costs 60%" | (1) the roof data is buried in an HTML page; (2) discounts combine through a table, not by adding |
| Real users on camera | BinGo: 30 testers; Computerpreter: interviewed an expert | 2–3 homeowners plus one inspector or insurance agent |
| Stay under 3:00, public, stays up | Videos over 3:00 risk a penalty; FireSafe's video vanished | Aim for 2:50, public on YouTube |

**Rubric (sample, 30 points):** relevance of need, impact, video structure, functionality, code explanation, design/ease of use. Every one is covered above.

---

## 2. Data: where every number comes from

All public, free and keyless. Every source was tested with real Boca parcels on Oct 17.

| Need | Source | How |
|---|---|---|
| Address autocomplete | Apple MapKit (`MKLocalSearchCompleter`) | Built into iOS, free |
| Exact point for the house | PBC Situs geocoder (`gis.pbcgov.org/.../Geocoder_New/Situs_115/GeocodeServer`) | Rooftop-level point (score 99) |
| Parcel ID, property use, condo flag, values, homestead | PBC `Parcels/PARCEL_INFO/FeatureServer/4` (PARCEL_DETAILS) | Point-in-parcel query with a 25 m buffer |
| Year built, living area, use code | Florida statewide cadastral (FGIO, DOR tax roll), `ACT_YR_BLT`, `TOT_LVG_AR`, `DOR_UC` | Query by parcel ID |
| **Roof cover and roof structure** | Palm Beach Property Appraiser page `pbcpao.gov/Property/Details?parcelId=…` | The page carries a JSON `model` object; read `structuralDetails` "Roof Cover" / "Roof Structure". One request per lookup, cached |
| Discount values | **OIR-B1-1699** official credit table (Fla. Stat. 627.0629), about 150 values, built into the app | Lookup, not addition |
| Inspection questions | **OIR-B1-1802** (Rev. 04/26), 7 questions | Our "confirm your home" questions mirror it in plain words |
| Premium and current credits | The user's declarations page (the summary page of their policy) | On-device text reading (Apple Vision OCR) plus a keyword parser. Manual entry as a fallback |
| Grant eligibility | My Safe Florida Home rules (Fla. Stat. 215.5586) | Homestead + built before 2008 + insured at $700K or less + single-family/townhouse |

**Gaps, handled honestly:**
- "Roof structure" can say "GABLE/HIP" or "WOOD TRUSS", so it's only a hint. The user confirms roof shape by tapping a picture, with the hint preselected.
- Roof-to-wall straps and shutters aren't in any public record. The user answers with pictures, or picks "Not sure", which counts as no credit.
- Insurers' own tables differ from the OIR table and are newer, so results show a **range** (50%–75% of the raw estimate), rounded to $50, labeled "estimate."
- If the declarations page doesn't list the wind premium, we assume 65% of the total premium for homes built before 2002 and 45% for 2002 and later (based on Brookings WP114, 2026).

### The math (`DiscountEngine`)
1. Look up `c_now` (credit from features already on the policy) and `c_could` (credit from features the home likely has) in the OIR-B1-1699 table. The table key is roof cover × deck × roof-to-wall × openings × shape × SWR (secondary water resistance, a sealed roof deck) × terrain.
2. Homes built 2002 or later use the new-construction table, with a 68% minimum.
3. Everything is capped at 89%.
4. `missed = windPremium × (c_could − c_now) / (1 − c_now)`.
5. Show the range `missed × 0.5` to `missed × 0.75`.

---

## 3. Screens (8, each one tested in the iOS Simulator)

```
Welcome (3 swipe cards, Skip always visible)
  → Sign in (Apple / Google)
  → Address (type it, autocomplete)
  → Your home (data found + 4 picture questions)
  → Your policy (scan it, or enter premium by hand)
  → Results ($ range, which discounts, why)
  → Action plan (checklist + renewal reminder)   ← home screen after setup
  → Settings (sources, disclaimer, sign out, delete account)
```

- **Welcome:** 3 cards: "Floridians pay the most for insurance" → "The law says your roof can earn discounts" → "Find yours in 2 minutes." Skip on every card.
- **Sign in:** Sign in with Apple and Sign in with Google (App Store rule 4.8 requires Apple when Google is offered). Under them, one line: "Your policy photo never leaves your phone."
- **Address:** one search field with suggestions. A Palm Beach County check gives a clear message if the address is outside the county.
- **Your home:** a card showing what the county records say (year built, roof cover, size, homestead). Then 4 questions, each with picture cards and a "Not sure" choice:
  1. Roof shape
  2. Roof-to-wall connection
  3. Window protection
  4. Roof replaced since 2004?
- **Your policy:** "Scan declarations page" (camera on a real phone, photo library in the Simulator) or "Type my premium." Show what was read so the user can fix it.
- **Results:** a big "$1,350–$2,050 a year" in New York serif, then a list of discounts found and missing (each with a one-line why), then a My Safe Florida Home eligibility badge.
- **Action plan:** a 4-step checklist with a progress ring (Coastal Clean design):
  1. Scan your policy
  2. Confirm your home
  3. Book a wind-mitigation inspection (about $100–$200, or free through MSFH)
  4. Send the report to your agent

  Plus "Remind me 30 days before renewal" (a local notification, asked for only after this tap).
- **Settings:** data sources with links, "Estimate, not a quote", sign out, **delete account** (App Store rule 5.1.1(v)).

**Engagement (simple, no streaks):** the checklist ring, the renewal reminder, and a "Share my report" button that creates a PDF to send to an agent.

**Not building (on purpose):** chat, community features, maps of every house, insurer price comparison, Android.

**Stretch, only if everything above works by Oct 22:** a neighborhood view: "Of the 214 homes on your street, 71% were built before 2002 and may be missing credits" (one county GIS query by area). This is the civic layer.

---

## 4. Design: Coastal Clean (picked Oct 17)

- **Colors:** white background, ocean teal `#0E7C7B` (primary), coral `#FF6F59` (next action), ink `#10302E`, mist `#E3F1EF`. Dark mode: ink background, lighter teal `#3FB8AF`.
- **Fonts:** New York (Apple's built-in serif) for headings and big dollar amounts; SF Pro for everything else. Both are built in, so nothing to license.
- **Feel:** big touch targets, one primary button per screen, Dynamic Type supported (text grows with the user's text-size setting), works on iPhone 17e through 18 Pro Max.

---

## 5. Tech stack

- **SwiftUI**, iOS 26+, Xcode 27. The project is generated by XcodeGen from `project.yml`.
- **Supabase** (`supabase-swift` 2.x) for sign-in and saving the user's home. **GoogleSignIn-iOS** for the Google button.
- **Apple frameworks:** MapKit (search), Vision (OCR), VisionKit (document camera), UserNotifications (reminder), PDFKit (report).
- **Tests:** XCTest for the discount engine, the declarations-page parser and the property-page parser.

### What Benny has to set up (I can't create accounts)
1. A Supabase project (or reuse one), then paste its URL and anon key into `Config.xcconfig`.
2. Google Cloud: an iOS OAuth client (bundle ID `com.bennygober.windcredit`) plus a Web client, both added to Supabase → Auth → Google.
3. Apple Developer: Sign in with Apple capability on the App ID.

Until these are done, the app runs in **demo mode**: sign-in buttons are shown, and "Continue in demo mode" lets every other screen be built and tested.

---

## 6. Schedule

| Day | Work |
|---|---|
| Sat Oct 17 | Plan, design, project skeleton, discount engine and tests, data lookups |
| Sun Oct 18 | All 8 screens in the Simulator, OCR parser |
| Mon Oct 19 | Sign-in (once keys exist), reminders, PDF report, debugging every screen |
| Tue–Wed Oct 20–21 | Test on 5–10 real Boca homes; record accuracy |
| Thu Oct 22 | Fixes; stretch neighborhood view only if green |
| Fri–Sat Oct 23–24 | Record and edit the video (2:50) |
| Sun Oct 25 | Register, upload to YouTube (public), fill out the form |
| Mon Oct 26 | Submit by **noon ET** |

## 7. Video outline (2:50)
- 0:00–0:15: Palm Beach premium number; name, "WindCredit", one-sentence purpose.
- 0:15–0:35: who it's for, why it matters to Benny (his family's Boca home, his property-data work), dollars missed.
- 0:35–1:35: screen recording of the full flow on a real home.
- 1:35–2:05: stack slide, code tour of `DiscountEngine`, two challenges and their fixes. Disclose AI use (required).
- 2:05–2:30: accuracy on N real homes, homeowner and inspector clips.
- 2:30–2:50: what's next, thank FL22/FL23.
