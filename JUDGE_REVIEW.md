# Judge review: WindCredit v1 (Oct 17, 2026)

I scored the app the way a district judge would, using the CAC sample rubric (6 categories, 5 points each). The judge is usually a staffer or local tech volunteer who watches the video and may open the app. They have no Palm Beach address memorized and about 5 minutes.

## Score: v1 (before fixes)

| Category | Score | What a judge sees |
|---|---|---|
| Ideology (need) | 4/5 | Real, local, costly problem. The app explains it on welcome card 1, but the number doesn't land: it's small gray body text under an icon. |
| Impact | 3/5 | Helps one household. Nothing shows impact on the **community**, the thing a Member of Congress cares about. The "civic layer" in the plan wasn't built. |
| Video structure | n/a | Not recorded yet. |
| Functionality | 3/5 | Works end to end, but: (1) a **sign-in wall before any value**, and sign-in isn't set up, so a judge hits "demo mode" and it feels unfinished; (2) **a judge outside Palm Beach can't get past the address screen**; (3) results don't say whether the inspection is worth paying for. |
| Code | 4/5 | Strong: live county data, state table, non-stacking rule, on-device OCR, 15 tests. Not visible inside the app. |
| Design / ease of use | 2/5 | Clean but generic. All Apple system fonts; SF Symbol icons in circles (paperclip for "clips", hammer for "nails") read as template / AI-made. Hip and gable drawings look nearly the same. Cold mint-white background. Nothing memorable. |

**Estimated: 16/25 plus video.** That's a solid entry, not a district winner. Past FL22/FL23 winners scored high on design and community story.

## The gaps, and the fix for each

| # | Gap | Fix |
|---|---|---|
| 1 | Sign-in wall before value; "demo mode" label looks unfinished | Move sign-in to **after** results as "Save your plan". Offer "Keep it on this phone" (no account). Rename demo mode. |
| 2 | Judges outside Palm Beach get stuck | **"Try a sample Boca home"** button on the address screen. |
| 3 | No community impact | **Your neighborhood** card: homes within about a quarter mile, share built before 2002, and an estimate of the dollars per year the neighborhood could be missing. One-tap "Share with my representative". Built from statewide parcel data. |
| 4 | "Is it worth it?" unanswered | **Payback line**: "A $150 inspection pays for itself in about N weeks." |
| 5 | Generic system typography | Bundled **Fraunces** (warm editorial serif) for headlines and dollar figures, **Plus Jakarta Sans** for text. Both scale with the iPhone text-size setting. |
| 6 | Template icons | Custom-drawn illustrations: roof shapes in 3/4 view, roof-to-wall connections (rafter + wall + connector), window protection. |
| 7 | Weak welcome | Editorial cards: a giant **$6,323** hero number, an illustrated house with labeled features, and a 3-step "how it works". |
| 8 | Results lack a picture | **Before/after bar**: wind premium now vs. with credits. |
| 9 | Cold palette | Warm sand background `#FBF8F3`, deep ink `#0F2A2E`, teal kept as primary, coral for the next action. |
| 10 | Code invisible to judge | "How WindCredit works" sheet: 4 numbered steps naming the real sources (county records, OIR-B1-1699, on-device reading). Doubles as the video's code-explanation shot. |
| 11 | Found during re-test: answering "Not sure" to everything showed **"Good news, you're already getting the discounts"**, which is wrong | New "Not sure yet" result: "Up to $X a year is possible", plus what each feature (hip roof, protected windows, clips) is worth if an inspector finds it. Covered by a unit test. |
| 12 | Typography details | Curly apostrophes and quotes everywhere; the source line no longer overlaps the page dots; illustrations keep their proportions; the bottom bar is solid. |

## v2: after fixes (verified in the iOS Simulator, Oct 17)

| Category | v1 | v2 | Why |
|---|---|---|---|
| Ideology | 4 | 5 | Opens on the $6,323 Palm Beach number; state law and the state's own percentages on card 2. |
| Impact | 3 | 5 | Neighborhood card: 96% of 369 nearby homes predate the 2002 code; neighborhood overpaying about $132,750/yr if 1 in 4 is missing a discount; one-tap share with a representative. |
| Functionality | 3 | 5 | Value before sign-in; sample home and sample policy for judges; payback in weeks; honest "not sure" path; 17 tests. |
| Code | 4 | 5 | Same depth, now visible in-app ("How WindCredit works"). |
| Design | 2 | 4–5 | Bundled Fraunces + Plus Jakarta Sans, warm palette, custom house/connection/window drawings, editorial welcome. Tested light and dark, iPhone 17 Pro and 17e. |

**About 24/25 before the video.** What still decides it is outside the app: (1) a real accuracy number from 5–10 Boca homes with real inspection reports, (2) the 2:50 video, (3) real sign-in keys so the Apple and Google buttons work for judges.

Not reproduced: one early run jumped back from "Your policy" to "Your home". Three later runs of the same steps worked, so it was likely a tap that landed during a scroll. Watch for it while testing.

## v3: free, fact-checked, animated (Oct 17, late)

- **Free:** removed Supabase (free tier pauses after 7 idle days, a risk during judging) and Sign in with Apple ($99/yr program; App Store-only rule). Google sign-in only, no backend; all data stays on the phone. "Free. No ads, no subscriptions" stated in the app.
- **Google button:** custom pill per Google's 2026 branding guidelines (official gradient G at 20pt, Google Sans Medium, #FFFFFF/#747775/#1F1F1F light and #131314/#8E918F/#E3E3E3 dark, "Continue with Google").
- **Fact-check (12 claims, primary sources):** corrected the 89% cap wording (82–84% for most existing Palm Beach homes; 89% only applies in the HVHZ), MSFH eligibility ("built before 2008", "insured value", grants are income-limited, applications open in phases), the roof-permit rule (permit on/after 3/1/2002, or original roof on a 2004+ home), plywood (no credit *at Citizens*), the clips claim (softened), the "about half" hurricane share, and the $6,323 source (OIR Stability Report, July 2026). Inspections are valid 5 years if there are no material changes.
- **Animations:** count-up figures, staggered reveals, growing bars, neighborhood houses lighting up, bouncing checkmarks, and an animated lookup screen. All respect Reduce Motion.
- **Code cleanup:** about 70 comments that restated the code were removed or shortened; the rest explain decisions. Duplicate helpers were removed.

## v4: scored against the official rubric text (Oct 18)

Official sample rubric: 6 rows, 1–5 each, 30 total. The 2026 rules add three criteria: idea quality, implementation (UX and design), and coding excellence.

| Row | What a 5 requires (rubric wording) | Where WindCredit is | What decides it |
|---|---|---|---|
| Ideology | "Issue or need is extremely relevant" | **5.** $6,323 average premium, state law, local data. | Say it in the first 12 seconds. |
| Impact | "Immense usage of creativity is featured as impact is explained" | **4–5.** Neighborhood card plus share with representative, grant check, payback. | Explain the community impact on camera, with your field-test result. |
| Structure | "Video is innovative and engaging" | Not filmed yet. | VIDEO_SCRIPT.md: on-location hook, captions, real home, under 3:00. |
| Function | "App is functional with complex features" | **5.** Live county data, on-device OCR, state-table engine, notifications, PDF, 17 tests. | Show it working on a real home without cuts that hide steps. |
| Code | "Explanation of code indicates immense understanding" | **At risk.** Depends entirely on *you* explaining it. | CODE_TOUR.md; build YOUR_BUILD feature 1 yourself; explain one challenge in depth. |
| UI | "App is highly innovative in design and interface" | **4–5.** Custom type, hand-drawn illustrations, animations, dark mode. | Show the animations in the demo. |

### The biggest risk is the rules, not the rubric
- **Originality:** "All coding and technical development must be done by the student."
- **AI usage:** permitted with full disclosure, but AI "must not constitute the entirety of the technical development," and students must show "significant individual contributions and technical understanding."
- **Access:** judges can request the app and source code; refusing means disqualification.

Most of the code so far was AI-generated. The fix is real, not cosmetic:
1. Build YOUR_BUILD.md features yourself.
2. Learn CODE_TOUR.md until you can explain every file.
3. Disclose accurately (SUBMISSION.md §4).

No video can guarantee an award: it depends on the other entries in your district and on the judges. But a strong, honest entry that you fully understand is the best possible position.
