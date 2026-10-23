# Getting WindCredit onto TestFlight

## Step 0: Decide which Apple account publishes it (only you can decide)

TestFlight requires the **paid Apple Developer Program** ($99/year). What this Mac has (checked Oct 23):

| Team | Type | TestFlight? |
|---|---|---|
| Benjamin Gober (Personal Team), `D4KNL86J9X` | Free | **No** |
| Channing Barnett (Personal Team) | Free | No |
| **Barnett Dermatology PA**, `U5FYSQGURR` | Paid (Beachable was published here) | Yes |

Your options:
1. **Barnett Dermatology PA's account.** Ready now, but only with the account owner's OK. The App Store and TestFlight will show **"Barnett Dermatology PA" as the developer**. Also, the CAC rules say *"No other party should have any rights or interest in the app."* An app owned by a business account could be questioned, so ask your district office before relying on it.
2. **Your own account.** Apple requires the account holder to be an adult (18+), so a **parent enrolls as an individual** ($99) and the app lists their name. Enrollment can take 24–48 hours, which is tight for Oct 26.
3. **Skip TestFlight for the Challenge.** The 2026 rules don't require any store listing. The video plus a live demo or source code is enough. You can do TestFlight after Oct 26.

Whichever you choose, put the team ID into `Config.xcconfig` → `WC_TEAM_ID = …`.

## Step 1: Things only you do (accounts and passwords)
- Sign in to that team's Apple ID in **Xcode ▸ Settings ▸ Accounts**.
- Sign in at **appstoreconnect.apple.com** in the browser. Accept any pending agreements in *Business* (the Account Holder may have to do this).
- Publish the privacy policy at a public URL: paste `PRIVACY.md` into a public GitHub Gist or a Google Doc shared as "Anyone with the link", and fill in your contact email first.

## Step 2: Upload the build (Terminal, from the WindCredit folder)
```bash
./scripts/testflight.sh
```
This archives a release build, signs it with the team in `WC_TEAM_ID`, registers the bundle ID `com.bennygober.windcredit` if needed, and uploads it. A unique build number is generated each run.

## Step 3: App Store Connect (paste this prompt into an agent with browser control)

Use Claude in Chrome (your logged-in browser) after you've signed in yourself.

```
You are helping me put my iPhone app "WindCredit" on TestFlight in App Store Connect.
I am already signed in at https://appstoreconnect.apple.com in this browser.

Rules:
- Never enter passwords, 2FA codes, or payment details. If a sign-in or 2FA prompt appears, stop and ask me.
- Before clicking any button that creates, submits, or accepts something (Create, Submit for Review, Accept, Add, Save),
  tell me exactly what you're about to do and wait for my "yes".
- Don't change any existing app (e.g. Beachable) or account settings.

Tasks:
1. Apps ▸ "+" ▸ New App. Platform: iOS. Name: "WindCredit" (if taken, propose "WindCredit: Storm Savings" and ask me).
   Primary language: English (U.S.). Bundle ID: com.bennygober.windcredit. SKU: windcredit-2026. User access: Full.
2. Open WindCredit ▸ App Information. Category: Finance (secondary: Utilities). Content rights: no third-party content.
3. App Privacy: Privacy Policy URL = <PASTE URL>. Data collection: "No, we do not collect data from this app."
4. TestFlight tab: wait until the uploaded build shows "Ready to Submit" or "Ready to Test" (refresh every few minutes;
   processing takes ~10–30 min). If it asks about encryption, the answer is "None of the algorithms mentioned above"
   (the app only uses HTTPS; Info.plist already declares ITSAppUsesNonExemptEncryption = NO).
5. Internal testing: create group "Team", add me (<YOUR APPLE ID EMAIL>), enable the build. Tell me when done.
6. External testing (only if I say so): create group "Judges", fill Test Information
   - Beta App Description: "WindCredit shows Palm Beach County homeowners which hurricane-insurance discounts their home
     likely qualifies for but isn't getting, in dollars. Tip: tap 'Try a sample 1993 Boca house' and 'Use the sample policy'."
   - Feedback email: <YOUR EMAIL>
   - Privacy Policy URL: <PASTE URL>
   - Sign-in required: No
   then show me the form before "Submit for Review". After approval, enable a Public Link and give it to me.
Report what you did at each step.
```

**Timing:** internal testers can install within about 30 minutes of upload. External testers (judges, via a public link) need Apple's **Beta App Review**, usually about a day and sometimes longer. That's very tight for the Oct 26 deadline. Don't let it block your submission.
