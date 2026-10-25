# Submitting WindCredit to the Congressional App Challenge

Two stages:

- **Stage 1 (now):** register and fill in everything except the video link.
- **Stage 2 (after the video is up):** paste the YouTube link and submit.

**Deadline:** 12:00 pm EDT, Monday Oct 26, 2026 (2026 rules PDF). Submit Sunday night if at all possible.

## What only you can do (the agent will stop for these)
1. **Create the account yourself** at congressionalappchallenge.us with a **personal** email (not a school email), and choose the password. The agent won't create accounts or type passwords.
2. **Sign in yourself** in Chrome, then hand off to the agent.
3. **Give the agent your details in chat:**
   - full legal name
   - home street address
   - grade
   - school name and address
   - a parent's or guardian's name and email
   - optionally, a teacher or mentor's name and email
4. **Answer the eligibility quiz yourself** if it asks you to attest to anything.
5. **Read every answer before the final Submit.** It's your entry, and the answers must sound like you.

---

## Answers to paste (review and edit these first)

The rules expect your own words. These drafts are factual starting points; change anything that doesn't sound like you before the agent uses them.

- **App title:** WindCredit
- **Platform:** iOS (iPhone)
- **Languages and tools:** Swift, SwiftUI, Apple Vision, VisionKit, MapKit, UserNotifications, Xcode, XcodeGen; GoogleSignIn-iOS (open source); public data from Palm Beach County GIS, the Palm Beach County Property Appraiser, the Florida statewide parcel layer, and the Florida Office of Insurance Regulation (OIR-B1-1699 credit table)
- **Target audience:** Palm Beach County homeowners, especially families in homes built before Florida's 2002 building code

**1. What does your app do? (one sentence)**
WindCredit shows Florida homeowners which hurricane-insurance discounts their home qualifies for but isn't getting, in dollars, and the steps to claim them.

**2. What inspired you?**
I live in Boca Raton, where the average home insurance bill is about $6,323 a year. Florida law (Fla. Stat. 627.0629) already requires insurers to give discounts to homes built to handle hurricanes, like hip roofs, roof-to-wall straps, and storm shutters, but you have to prove your home qualifies, and most families don't know these discounts exist. I wanted to make that take two minutes instead of never happening.

**3. What technical difficulty did you face, and how did you solve it?**
Florida's discounts don't add up. A hip roof alone is about a 47% discount and roof clips alone about 35%, but together they're 62%, not 82%. Adding percentages gave impossible answers. I converted the state's official credit table into data the app can read and made the code combine all of a home's features into one key, then look up that exact combination. A second challenge was that the Palm Beach County Property Appraiser has no public API for roof details, so the app reads the data the website already includes in its page.

**4. What did you learn?**
Checking facts against primary sources matters. When I verified the app's claims against Florida's official documents, several numbers I had seen online turned out to be wrong, and I corrected them. I also learned to design for people who answer "not sure," so the app never promises money it can't back up.

**5. What would you add in version 2.0?**
Spanish and Haitian Creole, every Florida county (each county's property records work differently), scanning the official inspection form directly, and a neighborhood view that cities could use to help residents claim these discounts.

**AI disclosure (required).** It must be accurate. Edit it so it matches exactly what you did.
I used Claude, an AI assistant made by Anthropic, extensively while building WindCredit. It researched past winners, Florida insurance rules and public data sources, and it generated most of the Swift and SwiftUI code and the in-app illustrations based on my direction and design choices. I chose the problem and the design, made the decisions about features and accuracy, tested the app on real Palm Beach County addresses in the iPhone Simulator, reviewed and fact-checked the information it shows, recorded the video, and can explain how every part of the app works. Open-source software used: GoogleSignIn-iOS; fonts Fraunces, Plus Jakarta Sans and Google Sans (SIL Open Font License).

- **Source code:** `https://github.com/bennygx234-design/windcredit` (private). Either make it public before submitting, or leave this field blank and share it if a judge asks. Refusing a judge's request means disqualification.
- **Video:** YouTube link, **Public**, 1–3 minutes (Stage 2).

---

## Prompt to give the agent (Claude in Chrome)

Paste this after you've signed in to congressionalappchallenge.us in Chrome:

```
You're helping me (Benjamin Gober) register and submit my app to the 2026 Congressional App Challenge at
congressionalappchallenge.us. I'm already signed in in this Chrome window.

Rules:
- Never create accounts, type passwords, or answer 2FA. If asked, stop and tell me.
- Use ONLY the information I give you in this chat and the text in the "Answers to paste" section below.
  Never invent personal details. If a field needs something you don't have, stop and ask me.
- Paste my answers exactly as written. Don't rewrite, shorten, or improve them. If a field has a character
  limit and my answer is too long, stop and show me; don't cut it yourself.
- Before clicking any button that submits, finalizes, or certifies something (Submit, Finalize, I certify,
  I agree), show me a summary of every field and wait for my "yes".
- If you see an eligibility attestation or quiz question about me, ask me for the answer.

Stage 1 (now):
1. Open my profile / registration. Fill in my personal info, school, grade and parent/guardian contact
   from what I give you in chat.
2. Find my congressional district: go to https://www.house.gov/representatives/find-your-representative,
   enter my home street address and ZIP, and tell me the district and representative. Then look up my
   9-digit ZIP at https://tools.usps.com/zip-code-lookup.htm (by address) if the form asks for it.
   Confirm with me before using them.
3. Complete my profile and the eligibility quiz (ask me each question you're unsure of).
4. Open the app submission form. Fill in every field from "Answers to paste". Team: individual
   (just me). Leave the video link empty.
5. Save as a draft (do NOT submit). Tell me which fields are still empty and any character limits you saw.

Stage 2 (when I send you the YouTube link):
6. Open the link and confirm it plays while signed out (public) and is between 1:00 and 3:00 long.
7. Paste the link into the video field.
8. Show me the full summary and wait for my "yes", then submit.
9. Tell me the confirmation message/number and take a screenshot of it.

[Paste the "Answers to paste" section here]
```

## Format rules the agent should double-check
| Item | Requirement (2026 rules) |
|---|---|
| Video | YouTube or Vimeo, **Public**, 1–3 minutes |
| Video must show | name(s), app name, one-sentence purpose, audience, tools/languages, the app working |
| Team | individual, or up to 4; at least half live or go to school in the district |
| App | created after Oct 30, 2025 (it was) |
| AI use | allowed, must be fully disclosed |
| Open source | must be documented (listed above) |
| Deadline | 12:00 pm EDT, Mon Oct 26, 2026 |
