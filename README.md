# WindCredit

An iPhone app that shows Palm Beach County homeowners which hurricane-insurance (wind-mitigation) discounts their home likely qualifies for but isn't getting. Built for the 2026 Congressional App Challenge.

See [VIDEO_PLAN.md](VIDEO_PLAN.md) for the video, [PLAN.md](PLAN.md) for the research and design, [CODE_TOUR.md](CODE_TOUR.md) to understand the code, [YOUR_BUILD.md](YOUR_BUILD.md) for the features to build yourself, [VIDEO_SCRIPT.md](VIDEO_SCRIPT.md) for the demo video, and [SUBMISSION.md](SUBMISSION.md) for the submission checklist.

## Run it
1. `brew install xcodegen` (once), then `xcodegen generate`
2. Open `WindCredit.xcodeproj`, pick an iPhone simulator, press Run.
3. With no client ID in `Config.xcconfig`, the Google button explains it's off in this build and the plan is kept on the phone. Every other screen works. No Palm Beach address? Tap **Try a sample 1993 Boca house**, then **Use the sample policy**.

## Free, by design
WindCredit costs nothing to use or run: no ads, no subscriptions, no servers.
- All data sources are free public records (Palm Beach County GIS, Property Appraiser, Florida statewide parcels, Florida OIR).
- Your home and plan are stored only on the phone. The policy photo is read on the phone (Apple Vision) and never uploaded.
- Sign-in is optional and uses Google only, with no backend. **Sign in with Apple was left out on purpose:** it requires Apple's paid $99/yr developer program, and it's only required for App Store apps. The Congressional App Challenge doesn't require an App Store listing.
- Supabase was removed: its free tier pauses projects after a week without activity, which could break sign-in while judges are reviewing.

## Turn on Google sign-in (free)
1. At console.cloud.google.com, create an OAuth client of type **iOS** for bundle ID `com.bennygober.windcredit`. Keep the scopes basic (email, profile), set the consent screen to **In production**, and don't upload a logo (that avoids Google's verification step).
2. Copy `Config.example.xcconfig` to `Config.xcconfig` and paste the client ID and its reversed form.

## Code map
- `Services/DiscountEngine.swift`: the math. Looks up Florida's official credit table (OIR-B1-1699, in `Resources/oir_b1_1699.json`); discounts don't add up, capped at 89%.
- `Services/PropertyLookupService.swift`: county geocoder → parcel layer → Property Appraiser page (year built, roof cover).
- `Services/PolicyParser.swift`: on-device text reading (Apple Vision) of the declarations page.
- `Services/NeighborhoodService.swift`: the civic view. Counts single-family homes within a quarter mile and how many predate the 2002 building code (Florida statewide parcels).
- `Views/`: Welcome, Address (with sample home), Your home, Your policy (with sample policy), Results (with "How WindCredit works"), Save your plan (sign-in, optional), Dashboard (plan + neighborhood), Settings.
- `Views/Components/Illustrations.swift`: hand-coded drawings of roof shapes, roof-to-wall connections, and window protection.
- `Resources/Fonts/`: Fraunces (headlines) and Plus Jakarta Sans (text), SIL Open Font License (license files included). Google Sans Medium (OFL, button only). Fixed-weight copies renamed `WC Display` / `WC Text` / `WC Button` as the license requires for modified fonts.
- `Views/Components/GoogleSignInPill.swift`: custom Google button built to Google's branding guidelines (official G logo cropped from Google's asset kit, Google Sans Medium, official light/dark colors).
- `Views/Components/Motion.swift`: animations (count-ups, staggered reveals, growing bars). All respect Reduce Motion.
- `WindCreditTests/`: 17 unit tests (engine, what-if, neighborhood, parser, county page).
- `DemoAssets/sample-declarations-page.jpg`: a clearly-marked SAMPLE page for demos (`xcrun simctl addmedia booted DemoAssets/sample-declarations-page.jpg`).

Estimates only, not insurance quotes.

## Built with AI assistance
Parts of this app were written with help from Claude (Anthropic). The 2026 Challenge rules require disclosing all AI use and documenting open-source libraries (GoogleSignIn-iOS, Fraunces, Plus Jakarta Sans, Google Sans), and judges may ask for the source code, so be ready to explain how each part works.
