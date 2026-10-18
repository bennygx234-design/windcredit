# WindCredit submission checklist (2026 Congressional App Challenge)

Source: official 2026 CAC Rules PDF. **Deadline: 12:00 pm EDT, Monday, October 26, 2026.** After the deadline, the submission can't be changed.

## 1. Eligibility (confirm now)
- [ ] Enrolled in middle or high school on Oct 26, 2026.
- [ ] District: ZIP 33496 is split between FL-22 (Frankel) and FL-23 (Moskowitz). Look up your **full street address** at house.gov ("Find your representative"). You may enter where you **live** or where you **attend school**, but only one district.
- [ ] App created after Oct 30, 2025.
- [ ] One app per person.

## 2. Registration (congressionalappchallenge.us)
Have these ready:
- [ ] A **personal** email (not your school email)
- [ ] Home address with **9-digit ZIP**, district, and Member of Congress
- [ ] School address with 9-digit ZIP, district, and Member
- [ ] A parent's or guardian's name and email
- [ ] Coding teacher or mentor name and email (optional)
- [ ] Complete the personal profile and the **eligibility quiz**, then wait for the email that unlocks the application. **Do this today**; don't leave it until Oct 25.

## 3. Written questions
The rules list questions "similar to" these. **Answer in your own words.** Judges compare your answers with the video, and they can ask you about your app in person. Below are facts and pointers, not finished answers.

1. **Title:** WindCredit
2. **Purpose** (one sentence): it shows Florida homeowners which hurricane-insurance (wind-mitigation) discounts their home likely qualifies for but isn't getting, in dollars, and the steps to claim them.
3. **Inspiration:** your true reason. Supporting facts: Palm Beach average premium $6,323 (Florida OIR, July 2026); Florida law (Fla. Stat. 627.0629) requires insurers to offer the discounts; many homes in your area predate the 2002 code (the neighborhood card shows this).
4. **Technical difficulty:** pick one you can explain deeply (CODE_TOUR.md lists three): no API for roof data; non-stacking credits; reading any insurer's page. Describe what *you* tried, what broke, and how it was fixed.
5. **What you learned / biggest takeaway:** your own reflection. Possible threads: verifying claims against primary sources changed several numbers (the fact-check fixed four of twelve); designing for people who answer "Not sure"; privacy by design.
6. **Version 2.0:** Spanish and Haitian Creole; every Florida county (each Property Appraiser is different); scan the inspection form itself; compare against insurers' filed tables; a city or county dashboard for outreach.

## 4. AI disclosure (required: "all AI usage is fully disclosed")
Fill this in truthfully. Under-disclosing is the risky choice. Put it in the submission form, the YouTube description, and the README.

> **AI disclosure:** I used Claude, an AI assistant made by Anthropic, during this project. It helped with: [be specific, for example: researching past winners and Florida insurance rules, generating most of the initial Swift/SwiftUI code from my design decisions, drawing the illustrations in code, and fact-checking]. I personally: [chose the problem and the design / built FEATURES FROM YOUR_BUILD.md / tested on N real homes / verified data against official sources / recorded and edited the video]. I can explain how every part of the app works.

Make the "I personally" list true before you submit. YOUR_BUILD.md is the plan for that.

## 5. Open-source and data credits (required: "clearly document any such usage")
- GoogleSignIn-iOS (Google, Apache 2.0)
- Fonts: Fraunces, Plus Jakarta Sans, Google Sans (SIL Open Font License)
- Google "G" logo used per Google's sign-in branding guidelines
- Data: Palm Beach County GIS (geocoder, parcels), Palm Beach County Property Appraiser, Florida statewide parcel layer (FL Dept. of Revenue / FGIO), Florida OIR (OIR-B1-1699 credit table, OIR-B1-1802 inspection form, Property Insurance Stability Report), My Safe Florida Home, Brookings WP114 (2026)
- Apple frameworks: SwiftUI, Vision, VisionKit, MapKit, UserNotifications

## 6. YouTube description template
```
WindCredit shows Florida homeowners which hurricane-insurance discounts their home qualifies for but isn't getting, in dollars.

Built by [name], [school], for the 2026 Congressional App Challenge (FL-[22/23]).
Made with Swift, SwiftUI, Apple Vision and MapKit. Data: Palm Beach County GIS and Property Appraiser, Florida statewide parcels, Florida OIR credit table (OIR-B1-1699).

AI disclosure: [same text as the form]
Open-source: GoogleSignIn-iOS; fonts Fraunces, Plus Jakarta Sans, Google Sans (OFL).
Estimates only, not insurance quotes.
```

## 7. If a judge asks to see the app (rules: refusing means disqualification)
- **Live demo:** in person or on a video call, from your iPhone or the Simulator.
- **Source code:** the GitHub repo `bennygx234-design/windcredit` is private. Either make it public before submitting, or be ready to add a judge as a viewer when asked.
- **Your own iPhone:** with a free Apple ID, apps installed from Xcode work for about 7 days (unverified; plan to reinstall before any demo). TestFlight and the App Store need the paid program, and the Challenge doesn't require either.

## 8. Day-by-day plan
| Date | Do |
|---|---|
| Sun Oct 18 | Register and take the eligibility quiz. Confirm the district. Start YOUR_BUILD feature 1. |
| Mon–Tue Oct 19–20 | Finish feature 1 (your code, your tests). Read CODE_TOUR.md until you can explain each file. |
| Wed Oct 21 | Field test: 5–10 homes with inspection reports (family, neighbors, a local inspector or agent). |
| Thu Oct 22 | Write your answers to the 6 questions. Get the free Google client ID (optional). |
| Fri Oct 23 | Film the hook, intro and close outside; screen-record the demo and Xcode. |
| Sat Oct 24 | Edit to 2:45, add captions, upload as **Public**, watch it with sound off. |
| Sun Oct 25 | Fill out and submit the form. Don't wait for Monday. |
| Mon Oct 26 | Buffer only. Hard deadline 12:00 pm EDT. |
