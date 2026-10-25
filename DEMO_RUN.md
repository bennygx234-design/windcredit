# Demo run sheet (the 0:45–1:45 part of the video)

Verified screen by screen in the Simulator on Oct 25 with a real Boca address. Say the **bold** number when it's on screen; the rest is optional.

## Before you record
- Delete and reinstall the app (or launch with `-resetState`) so it starts on the welcome card.
- Simulator status bar shows 9:41 and full battery:
  `xcrun simctl status_bar booted override --time 9:41 --batteryState charged --batteryLevel 100 --wifiBars 3 --cellularBars 4`
- Add the sample declarations page to Photos once:
  `xcrun simctl addmedia booted DemoAssets/sample-declarations-page.jpg`
- Wi-Fi on (county records and the neighborhood count are live).

## Taps (about 60 seconds)
| # | Screen | Tap | Say / point at |
|---|---|---|---|
| 1 | Welcome card 1 | let **$6,323** count up, tap Next | "Average Palm Beach premium" |
| 2 | Card 2 | Next | "Florida law: hip roof 47%, shutters 44%, clips 35%" |
| 3 | Card 3 | **Check my home** | |
| 4 | Address | type `1398 SW 18th`, tap the Boca Raton suggestion | "Pulled from county records" (house animation) |
| 5 | Your home | point at the satellite view: **1993, tile roof, homestead** | |
| 6 | Questions | Hip, Metal clips, Impact windows, roof "No", then **Looks right** | "Pictures, so anyone can answer" |
| 7 | Your policy | **Choose a photo**, then the SAMPLE page | "Read on the phone, never uploaded": **5,716 / 3,912 / 385,000**, renews Mar 15, 2027 |
| 8 | | **See my savings** | |
| 9 | Results | let it count up: **$1,350–$2,050 a year**; bars: **$3,912 to $2,212**; **worth it in about 6 weeks** | the pause here is the most important moment of the video |
| 10 | | scroll: missing discounts, free inspection badge | |
| 11 | | **Make my plan**, then **Save my plan** | |
| 12 | Plan | tap "Get a wind-mitigation inspection" (it checks off and bounces) | |
| 13 | | scroll: **96% of 392 homes** built before 2002; neighborhood overpays about **$160,650/yr**; tap **Share with my representative** | the civic point |
| 14 | | **Share report with my agent** (PDF sheet) | |

For the code segment: on the Results screen, tap **How WindCredit works** and screen-record it, then cut to `DiscountEngine.swift` in Xcode.

## If something goes wrong on camera
- The address lookup fails (county server slow): tap **Try a sample 1993 Boca house**, then **Use the sample policy**. Every number still works.
- Don't tap Google sign-in; it's hidden until a Google client ID is added.
