# Interview Focus Lock (iOS)

A native iOS app that locks the distracting apps you pick, and only unlocks them
for **10 minutes per correct answer**, capped at **60 minutes total per day**, to
senior-level (6 yrs exp) interview questions covering **Talend/ETL, SQL,
Java/Spring Boot, Apache NiFi, and general SWE/system design**.

Questions are **generated live by the Claude API** using your own Anthropic API
key, so they're fresh every time instead of repeating from a fixed list. A
50-question seed bank is bundled as an **offline fallback** for when there's no
API key configured, no network, or the API call fails.

## Why this needs to be a real iOS app (not a web app)

Apple sandboxes every app - there is no way for a third-party app to see or block
other apps on iOS except through Apple's own **Screen Time / Family Controls**
framework (`FamilyControls`, `ManagedSettings`, `DeviceActivity`). That's what this
app is built on:

- **FamilyControls** - `AuthorizationCenter` (Screen Time permission) and
  `FamilyActivityPicker` (lets you pick apps/categories to lock without the app
  ever learning their real names - Apple keeps that private).
- **ManagedSettings** - `ManagedSettingsStore().shield` actually blocks the chosen
  apps behind a system "shield" screen.
- **DeviceActivity** - schedules the exact moment the 10-minute window ends and
  runs a small extension (`InterviewFocusLockMonitor`) that re-applies the shield,
  even if the main app isn't running.

## Project layout

```
InterviewFocusLock/
  project.yml                          # XcodeGen spec - generates the .xcodeproj
  InterviewFocusLock/                  # main app target
    InterviewFocusLockApp.swift
    Models/Question.swift, QuestionBank.swift
    Managers/ScreenTimeManager.swift    # Screen Time auth + shield on/off
    Managers/UnlockManager.swift        # grants a 10-min unlock, enforces 60-min/day cap
    Managers/QuizManager.swift          # AI-first question selection, tracks correct/incorrect stats
    Managers/AIQuestionService.swift    # calls the Claude API to generate a question on demand
    Managers/KeychainStore.swift        # stores your Anthropic API key in the Keychain
    Views/                              # Onboarding, AppSelection, Home, Quiz, StudyMode, Stats, Settings
    Resources/Questions.json            # 50 seeded questions (10 per topic) - offline fallback only
  InterviewFocusLockMonitor/            # DeviceActivityMonitor extension target
    DeviceActivityMonitorExtension.swift # re-locks apps when the unlock window ends
  Shared/                               # code/constants shared by both targets (App Group)
```

## One-time setup

1. Install Xcode (free, from the Mac App Store) and
   [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`).
2. Pick your own App Group id (must be unique-ish, starts with `group.`) and your
   own bundle id prefix. Replace `group.com.kushal.interviewfocuslock` in:
   - `Shared/AppGroup.swift`
   - `InterviewFocusLock/InterviewFocusLock.entitlements`
   - `InterviewFocusLockMonitor/InterviewFocusLockMonitor.entitlements`
3. In `project.yml`, set `DEVELOPMENT_TEAM` to your Apple ID's personal team ID
   (Xcode > Settings > Accounts > your Apple ID > team name shows the ID), for
   both targets. A free Apple Developer account is enough to run this on your
   own iPhone - no paid membership required.
4. From the `InterviewFocusLock/` folder, run:
   ```
   xcodegen generate
   open InterviewFocusLock.xcodeproj
   ```
5. In Xcode, select your iPhone as the run destination (a **real device is
   required** - the Simulator does not reliably support Family Controls
   shielding) and hit Run. Trust the developer certificate on your phone under
   Settings > General > VPN & Device Management if prompted.
6. On first launch, tap **Enable Screen Time Access** and approve the prompt,
   then pick the apps/categories to lock.
7. Tap the gear icon on the home screen and paste in your own Anthropic API key
   (get one at console.anthropic.com) so questions are generated live instead
   of falling back to the offline bank. This step is optional - the app works
   without a key, just with a fixed question set instead of fresh ones.

## How the lock/unlock flow works

1. You select apps/categories once (`AppSelectionView`) - they get shielded
   immediately.
2. Tap **Answer a Question to Unlock**, pick topics. `QuizManager` asks
   `AIQuestionService` to generate one MCQ question via the Claude API for a
   random category/difficulty from what you picked, avoiding the last few
   questions you were asked; if that fails for any reason (no key, no
   network, bad response) it silently falls back to a random question from
   the offline seed bank and shows an "Offline bank" badge so you know.
3. Correct answer -> `UnlockManager` removes the shield and schedules a
   `DeviceActivity` for exactly 10 minutes from now.
4. When that 10-minute window ends, iOS runs `DeviceActivityMonitorExtension`
   (even if the app is closed) and it re-applies the shield.
5. `DailyUsageStore` tracks minutes used today (App Group `UserDefaults`,
   resets at midnight); once 60 minutes are used, no more unlocks are granted
   until the next day, regardless of how many questions you answer correctly.
6. **Study Mode** lets you browse all 50 questions with answers/explanations
   any time, without needing to unlock anything - pure prep, no gate.

## AI question generation

- Settings (gear icon) lets you paste your **own** Anthropic API key and pick a
  model (`claude-sonnet-5` by default; `claude-opus-4-8`, `claude-haiku-4-5`,
  and `claude-fable-5` are also selectable).
- The key is saved only in the iOS **Keychain** via `KeychainStore` - it is
  never written to `UserDefaults`, never logged, never committed to git, and
  never leaves the device except in the direct HTTPS call to
  `api.anthropic.com`.
- Every question you're asked costs a small Claude API call billed to **your**
  Anthropic account - at typical per-question token usage this is a fraction
  of a cent per question, but it's your usage to monitor at
  console.anthropic.com, not something this app tracks or caps for you.
- If you'd rather not use your key at all, just leave it blank - the app runs
  entirely offline on the 50-question seed bank.

## Known limitations (be upfront about these)

- This is an **honor-system-adjacent** lock, not unbreakable: a determined user
  could remove the app itself, or revoke Screen Time permission in Settings, to
  drop the shield. There's no way around this on iOS - Apple doesn't allow any
  app that level of unremovable control (that's a deliberate privacy/security
  boundary, not a bug).
- The Simulator does not reliably enforce shields - **test on a real iPhone**.
  `FamilyActivityPicker` also does not run in the Simulator on most Xcode
  versions.
- The 10-minute unlock schedule is computed from time-of-day components; if an
  unlock is granted within 10 minutes of midnight, the window's end time wraps
  to the next day and won't re-lock as expected. Answering right around
  midnight is an edge case worth avoiding.
- If you background-kill the app during the 10-minute window, the unlock still
  ends correctly because the extension (not the app process) enforces it - but
  double check this behaves as expected on your iOS version, since Apple has
  changed `DeviceActivity` timing behavior across releases.
- AI-generated questions require network access and a valid API key; expect
  occasional fallback to the offline bank on flaky connections, rate limits,
  or if Claude doesn't return parseable JSON on a given call.

## Other ideas to make this actually help you land the job

- **Difficulty ramp**: start every session on `mid` questions, promote to
  `senior` only after a few correct answers in a row (the JSON already has a
  `difficulty` field for this).
- **Spaced repetition**: log every wrong answer and resurface it more often over
  the next few days instead of pure random selection.
- **Mock interview timer**: a 45-minute "simulate the real interview" mode with
  a fixed set of questions and no lock/unlock mechanic at all, just timed
  practice.
- **Morning-of-interview digest**: a local notification the morning of a
  calendar event titled "interview" (via EventKit) with your weakest 5 topics.
- **Voice answers**: use on-device speech-to-text so you practice saying
  answers out loud, not just picking multiple choice (much closer to a real
  interview).
- **Home Screen widget**: shows remaining daily unlock minutes and today's
  accuracy at a glance.
- **Cost of an "emergency override"**: let yourself skip the quiz once per day,
  but it costs double the unlock minutes next time - keeps you honest without
  ever fully locking yourself out.

## Editing the offline fallback bank

This only matters for the no-key/no-network fallback path - normal usage with
an API key configured never touches this file. Edit
`InterviewFocusLock/Resources/Questions.json` - it's a flat array of:
```json
{
  "id": "unique-id",
  "category": "etlTalend | sql | javaSpringBoot | nifi | generalSWE",
  "difficulty": "mid | senior",
  "prompt": "...",
  "options": ["...", "...", "...", "..."],
  "correctIndex": 0,
  "explanation": "..."
}
```
