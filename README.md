# WindCredit

An iPhone app that shows Palm Beach County homeowners which hurricane-insurance (wind-mitigation) discounts their home likely qualifies for but isn't getting. Built for the 2026 Congressional App Challenge.

See [PLAN.md](PLAN.md) for the research, data sources, screens and schedule.

## Run it
1. `brew install xcodegen` (once), then `xcodegen generate`
2. Open `WindCredit.xcodeproj`, pick an iPhone simulator, press Run.
3. With no keys in `Config.xcconfig` the app runs in **demo mode** (every screen works; sign-in buttons explain they aren't set up).

## Turn on real sign-in
1. Copy `Config.example.xcconfig` to `Config.xcconfig`.
2. Supabase: create a project, paste its URL and anon key. Run `supabase/migrations/001_homes.sql`, deploy `supabase/functions/delete-account`.
3. Google Cloud: create an **iOS** OAuth client (bundle ID `com.bennygober.windcredit`) and a **Web** client. Put the iOS client ID and its reversed form in `Config.xcconfig`; add both IDs in Supabase → Auth → Providers → Google, and turn on "Skip nonce check".
4. Apple: enable Sign in with Apple on the App ID; add the bundle ID in Supabase → Auth → Providers → Apple.

## Code map
- `Services/DiscountEngine.swift`: the math. Looks up Florida's official credit table (OIR-B1-1699, in `Resources/oir_b1_1699.json`); discounts don't add up, capped at 89%.
- `Services/PropertyLookupService.swift`: county geocoder → parcel layer → Property Appraiser page (year built, roof cover).
- `Services/PolicyParser.swift`: on-device text reading (Apple Vision) of the declarations page.
- `Views/`: Welcome, Sign in, Address, Your home, Your policy, Results, Dashboard (plan), Settings.
- `WindCreditTests/`: 15 unit tests (engine, parser, county page).
- `DemoAssets/sample-declarations-page.jpg`: a clearly-marked SAMPLE page for demos (`xcrun simctl addmedia booted DemoAssets/sample-declarations-page.jpg`).

Estimates only, not insurance quotes.
