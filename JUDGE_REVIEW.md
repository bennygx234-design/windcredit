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
