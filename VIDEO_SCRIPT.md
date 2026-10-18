# WindCredit demo video: script and shot list (target 2:45)

The rules call the video *"the most critical component."* Judges often score from the video alone. It must be **1–3 minutes** (outside that range "may be penalized") and uploaded to YouTube or Vimeo as **Public**.

## Required by the 2026 rules (check each one off in the final cut)
- [ ] Your name (and every teammate's, if any)
- [ ] The app's name: WindCredit
- [ ] Its purpose **in one clear sentence**
- [ ] The target audience
- [ ] The tools and coding languages used
- [ ] The app's functionality, shown working
- [ ] AI use disclosed. The rules require disclosure "in the submission materials"; saying it on camera too is the safest choice.

## How each segment maps to the rubric (6 rows × 5 points)

| Time | Segment | Rubric row it wins |
|---|---|---|
| 0:00–0:12 | Hook | Ideology, Structure |
| 0:12–0:27 | Who you are, one sentence, audience | Required elements |
| 0:27–0:45 | Why it matters to you, plus the neighborhood | Impact |
| 0:45–1:45 | Live demo on a real home | Function, UI |
| 1:45–2:15 | How it works: tools, code, challenges | Code |
| 2:15–2:32 | Proof: field test, real people | Impact, Function |
| 2:32–2:45 | What's next, thanks | Structure |

## Script

Write it in your own words; the lines below are a starting skeleton. Replace every `[bracket]` with something true about you.

**0:00–0:12 · Hook** (filmed outside, in front of a Boca house, ideally yours)
> "The average home insurance bill in Palm Beach County is **$6,323 a year**. And a lot of homes here qualify for hurricane discounts nobody ever claims."
On screen: big "$6,323" with "Source: Florida OIR, July 2026".

**0:12–0:27 · Required elements**
> "I'm [full name], a [grade] at [school], and this is **WindCredit**: an iPhone app that shows Florida homeowners which hurricane-insurance discounts their home qualifies for but isn't getting, in dollars. It's built for Palm Beach County homeowners, especially the families in older homes built before Florida's 2002 building code."
On screen: name, school, "WindCredit", the one-sentence purpose as a caption.

**0:27–0:45 · Why, and the community**
> "[Your real reason: your family's premium, a neighbor, something you saw.] Florida law requires insurers to give these discounts, but you have to prove your roof qualifies, and most people don't know that."
Cut to the app's neighborhood card:
> "Around my street, [96]% of the [369] homes were built before 2002."

**0:45–1:45 · Demo** (screen recording; see the recording tips below)
1. Type the address. The county-records animation plays, then the satellite roof view with year built and roof cover. *"It pulls my house from Palm Beach County's public records."*
2. Tap through the 4 picture questions. *"I answer four questions from the state's inspection form, with pictures so anyone can do it."*
3. Scan the declarations page. *"It reads my policy on the phone. Nothing gets uploaded."*
4. Results: the number counts up, the bars grow, then the payback line. Pause here and say the number.
5. Plan: check off a step (it bounces), turn on the reminder, share the PDF report.
6. Neighborhood card, then "Share with my representative".

Keep each tap visible and slow. Don't narrate every button; narrate the *point*.

**1:45–2:15 · How it works** (screen-record Xcode)
> "I built it in **Swift and SwiftUI** with Apple's **Vision** and **MapKit** frameworks. It connects to **Palm Beach County's GIS services**, the **Property Appraiser**, and the **Florida statewide parcel layer**, and it uses Florida's official credit table, **OIR-B1-1699**."
Show `DiscountEngine.swift`, the `credit(for:)` lookup and the `missed =` line:
> "The hard part: Florida discounts don't add up. Hip roof alone is 47%, clips are 35%, but together they're 62%, not 82%. So instead of adding, my code looks up the whole combination."
Then the second challenge you know best (CODE_TOUR.md has three to choose from).
AI disclosure, one honest sentence, for example:
> "I used an AI assistant, Claude, to help write [what it actually did], and I [built X myself / tested and verified everything / can explain every part]."

**2:15–2:32 · Proof**
> "I tested WindCredit on [N] Boca homes that had real inspection reports. It flagged a real missed discount in [X] of them."
Add a 3–5 second clip of a homeowner (with permission): *"[their reaction]"*.

**2:32–2:45 · Close**
> "Next, I want to add Spanish and Haitian Creole and expand to every Florida county. Thank you, Representative [Frankel / Moskowitz], for running the Congressional App Challenge."
End card: WindCredit logo, your name, district.

## Making it "innovative and engaging" (rubric 5 for Structure)
- Open on location, not on a title slide. First words = the number.
- Captions for every key number (many judges watch muted).
- Real home, real policy (blur the policy number and the address on screen).
- Quick cuts: no clip longer than about 8 seconds without a change.
- Low background music, clear voice. Record voice-over in a quiet room (closet with clothes works).
- Your face on camera at least at the start and end.

## Recording the app cleanly
**On your iPhone:** Control Center ▸ Screen Recording. Turn on Do Not Disturb first.

**In the Simulator:** set a clean status bar, then record:
```bash
xcrun simctl status_bar booted override --time 9:41 --batteryState charged --batteryLevel 100 --wifiBars 3 --cellularBars 4
```
```bash
xcrun simctl io booted recordVideo --codec=h264 ~/Desktop/windcredit-demo.mp4
```
Press Ctrl-C in that terminal to stop recording. To start from the welcome screen, delete and reinstall the app, or launch it with `-resetState`.

## Before you upload
- [ ] Length between 1:00 and 3:00 (aim for 2:45)
- [ ] YouTube visibility = **Public** (not Unlisted, not Private)
- [ ] Title: `WindCredit | 2026 Congressional App Challenge | FL-[22/23]`
- [ ] Description: one-sentence purpose, tools, data sources, AI disclosure, open-source credits (copy from SUBMISSION.md)
- [ ] Watch it once with sound off: does every point still come through?
