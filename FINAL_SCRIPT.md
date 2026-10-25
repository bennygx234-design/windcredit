# WindCredit: final script and filming plan

**Length:** 2:50. **Due:** upload to YouTube as **Public** before noon ET, Mon Oct 26.

App footage, diagram, title and end cards are already made in `VideoClips/`.

## Filled in from your info
- **Grade and school:** sophomore at David Posnack Day School (your site says Class of 2029).
- **Why you:** co-founder and CTO of Praxelis, which builds AI tools for real estate businesses.
- **Representative:** the close thanks "my representative" without a name, because ZIP 33496 is split between Rep. Frankel and Rep. Moskowitz and I don't know your street address. If you want to say the name, look it up at house.gov first.

---

## Filming plan: 3 places, about 20 minutes

| # | Where | What you film | Used in |
|---|---|---|---|
| 1 | Sidewalk in front of your house (roof visible behind you) | Section 1, on camera | 0:00–0:30 |
| 2 | Same street, walking around | 4 silent shots, 4–5 seconds each: (a) a roof that slopes on all four sides, (b) storm shutters or impact windows, (c) slow pan down your street, (d) your hand opening the app on your phone | Under sections 2–4 |
| 3 | Same street or a corner with a street sign | Section 6, on camera | 2:30–2:55 |
| 4 | Quiet room (a closet is perfect) | Record sections 2, 3 and 4 as voiceover, phone 6 inches from your mouth | 0:30–2:00 |
| 5 | Your Mac | Screen-record Xcode (QuickTime ▸ New Screen Recording) while you read section 5: show `DiscountEngine.swift` line 63 | 2:00–2:30 |
| optional | Your kitchen | A parent or neighbor saying one sentence, like "I had no idea our house could qualify for that." | Before section 6 |

**Camera tips:**
- Phone horizontal, at eye level, steady (lean it on something or use a tripod).
- Morning or late afternoon light, facing the sun.
- No wind, look at the lens.
- Do each take 2–3 times and keep the best.

---

## Script

### 1. Hook and intro (0:00–0:30) · ON CAMERA, in front of your house
> "Here in Palm Beach County, families pay about six thousand three hundred dollars a year just to insure their home. That's more than almost anywhere in the country. But here's what most people don't know: a lot of them are paying more than they have to. I'm Benjamin Gober, a sophomore at David Posnack Day School, and I built WindCredit, an iPhone app that shows you how much money your home could be saving on insurance, and exactly how to get it."

**Then:** title card `G2_title.png` for 2 seconds.

### 2. The problem (0:30–1:00) · VOICEOVER
On screen: `cut/A_welcome.mp4`, your roof and shutter shots, then `cut/B1_address.mp4`.
> "In Florida, there's a law that says if your house is built to handle hurricanes, your insurance company has to give you a discount. A roof that slopes down on all four sides can cut the hurricane part of your bill almost in half. Metal straps that hold the roof down, or storm shutters on your windows, save even more. The problem is, the insurance company won't tell you. You have to prove it yourself, and most families have no idea they even qualify. So with WindCredit, you just start by typing in your address."

### 3. How you use it (1:00–1:30) · VOICEOVER
On screen: your hand-on-phone shot, then `cut/B2_records.mp4`, `C1_roof`, `C2_windows`, `C3_roofage`, `D1_scan`.
> "The app looks up your house in the county's public records, the same records anyone can see, and finds things like what year it was built and what the roof is made of. Then it asks you four quick questions, with pictures, so you don't need to know any construction words. Like, what shape is your roof? How are your windows protected? If you're not sure, that's completely fine. Last, you take a picture of your insurance bill. The phone reads the numbers by itself, and your bill never leaves your phone."

### 4. The result (1:30–2:00) · VOICEOVER
On screen: `cut/D2_results.mp4`, then `cut/F_plan.mp4`, and your street pan on "this street."
> "And here's the answer. This family could be saving about thirteen hundred to two thousand dollars every single year." *(pause 2 seconds)* "To get it, they just need a home check that costs about a hundred fifty dollars, so it pays for itself in about six weeks. The app turns that into a simple to-do list, and reminds you before your insurance renews. It even looks at the whole neighborhood: almost every house on this street is old enough that it could be missing these same savings. With one tap, you can send that to your local representative."

### 5. How it works (2:00–2:30) · VOICEOVER over the diagram, then Xcode
On screen: `G1_how-it-works-diagram.png`, then your Xcode recording at line 63.
> "Behind the scenes, the app does four things: it reads the house records, reads your insurance bill, looks up Florida's official discount chart, and turns the difference into dollars. The hardest part to figure out was that the discounts don't simply add up. A sloped roof saves forty-seven percent, roof straps save thirty-five, but together it's sixty-two, not eighty-two. So instead of adding, my code combines all your answers into one label, and looks up that exact match in the state's chart."

Practice this one until you can say it without reading; judges score how well you understand it.

### 6. Why it matters and close (2:30–2:55) · ON CAMERA, on your street
> "I co-founded a company called Praxelis that builds AI tools for real estate businesses, so I work with property records all the time. That's how I noticed these savings already exist by law, but almost nobody knows to ask for them. Next, I want to add Spanish and Haitian Creole, and cover all of Florida. I used AI to help build WindCredit, and I explained exactly how in my submission. Thank you to my representative for running the Congressional App Challenge."

**Then:** end card `G3_end.png` for 3 seconds.

---

## Captions to add (big, bottom of the screen)
| When | Caption |
|---|---|
| 0:03 | $6,323 a year · Palm Beach County average (FL OIR, 2026) |
| 0:20 | Benjamin Gober · Sophomore, David Posnack Day School |
| 0:40 | Hip roof 47% · Shutters 44% · Roof straps 35% |
| 1:05 | Live Palm Beach County public records |
| 1:25 | Read on the phone · never uploaded |
| 1:32 | $1,350–$2,050 a year |
| 1:40 | Pays for itself in about 6 weeks |
| 1:52 | 96% of nearby homes built before 2002 |
| 2:15 | Swift · SwiftUI · Apple Vision · MapKit |

## Before you upload
- [ ] Under 3:00
- [ ] Watched once with the sound off
- [ ] YouTube title: `WindCredit | 2026 Congressional App Challenge`
- [ ] Visibility: **Public**
- [ ] Paste the YouTube link into chat so the submission agent can use it
