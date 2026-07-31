# Chomp — Project Build Guide

GitHub analytics + AI monitoring app for intermediate developers.
Flutter mobile app · NVIDIA NIM (code/security) · Groq (docs/tests) · Neon Postgres backend.

---

## 0. Architecture Note — Read This First

You asked for hourly background scans. Here's the one architectural decision that determines how everything else works:

**Flutter cannot reliably run hourly background jobs on iOS.**

- **Android** — `workmanager` can genuinely run periodic tasks in the background, minimum interval 15 min, so hourly works.
- **iOS** — background execution uses `BGAppRefreshTask`, which is *opportunistic*. iOS decides when your task actually runs based on battery, usage patterns, and system load. It is **not guaranteed to fire every hour** — it might run every 3-6 hours in practice, or not at all if the user doesn't open the app often.

**Consequence:** if the scan engine lives on-device, iOS users get an unreliable, inconsistent experience. That defeats the "every hour" requirement you care about.

**The fix:** the scan engine runs **server-side**, not on-device.

```
Neon Postgres + Neon Functions (cron every hour)
        ↓
   Runs the scan for every user's watched repos
        ↓
   Calls GitHub API → NVIDIA NIM → Groq
        ↓
   Writes results to Neon DB
        ↓
   If new issue/score drop → sends push via Firebase Cloud Messaging (FCM)
        ↓
Flutter app receives it → shows via flutter_local_notifications
```

This means:
- The scan runs identically and reliably for every user, every hour, regardless of platform or whether the app is open.
- The Flutter app becomes a **client** that reads scan results from Neon and displays them — it does not run the AI calls itself.
- `flutter_local_notifications` displays the notification when FCM delivers it, or when the user manually triggers "Scan Again" from inside the app (that one call *can* happen client-side, directly from the phone, since it's user-initiated and doesn't need to be reliable in the background).

So there are actually two scan paths:
| Path | Trigger | Runs on | Uses |
|---|---|---|---|
| Automatic hourly scan | Neon Function cron | Server | GitHub API + NVIDIA + Groq → writes to DB → FCM |
| Manual "Scan Again" | User taps button | Phone (direct API calls) | Same APIs, live in the UI with the phase log you wanted |

This is why "focus on the engine working" matters so much — the engine is really two things: a server cron job and a client-triggered manual scan, sharing the same scan logic.

---

## 1. Task Overview

### What you're building
A Flutter mobile app where a developer connects their GitHub account. The app:
- Shows their repos on Home
- Auto-monitors their 3 most recently active repos + up to 4 manually watched repos (7 total)
- Every hour, a server job scans those repos for security issues, code quality, doc quality, test coverage
- Notifies the user only when something changed or a new issue appeared
- Shows results as 4 speedometer/gauge dials per repo (Security, Code Quality numeric 0-100; Docs, Tests qualitative labels)
- Has an Insights tab (AI weekly summary), a Feed tab (personal activity timeline), and Profile (settings, watchlist management, theme)

### Build priority (your instruction, confirmed)
1. **Engine first** — GitHub OAuth, GitHub data fetching, NVIDIA scan, Groq scan, Neon storage, manual scan flow with phase log, hourly server cron, notifications.
2. **UI polish last** — theming, animations, empty states, loading skeletons.

---

## 2. Accounts & Credentials to Get (do these first, before writing code)

Go through this list in order. Each one blocks something downstream.

### 2.1 GitHub OAuth App
1. Go to `https://github.com/settings/developers`
2. Click **New OAuth App**
3. Fill in:
   - Application name: `Chomp`
   - Homepage URL: `https://chomp.app` (placeholder is fine for dev)
   - Authorization callback URL: `chomp://callback` (custom scheme — you'll register this in Flutter)
4. Save the **Client ID**
5. Generate a **Client Secret** and save it
6. Note: the client secret must never live in the Flutter app itself — it's used only in your Neon Function (server-side) when exchanging the OAuth code for a token. The mobile app only ever sees the temporary auth code.

**Scopes to request:** `repo` (read access to private + public repos), `read:user`

### 2.2 NVIDIA NIM API Key
1. Go to `https://build.nvidia.com`
2. Sign in / create an NVIDIA Developer account (free, no credit card)
3. Go to **API Keys** in settings, click **Generate Key**
4. Save the key — it starts with `nvapi-`
5. Note the base URL: `https://integrate.api.nvidia.com/v1` (OpenAI-compatible schema)
6. **Known limits to plan around:** free tier is rate-limited to roughly 40 requests/minute per model, and NVIDIA's docs are explicit that the free tier is for prototyping/dev, not guaranteed production throughput. Since your scans are hourly and batched, this is fine at small user counts, but you'll want to queue/throttle requests once you have real users.
7. **Model choice:** for code + security analysis pick a strong code model from the catalog (e.g. a Qwen-Coder or Nemotron variant — check current availability in the catalog since NVIDIA rotates models in/out).

### 2.3 Groq API Key
1. Go to `https://console.groq.com`
2. Sign in, go to **API Keys**
3. Create a new key, save it
4. Note the base URL: `https://api.groq.com/openai/v1` (also OpenAI-compatible)
5. Pick a fast general model for docs/test qualitative evaluation (Groq's value is inference speed — good fit since this is a secondary, lighter-weight judgment call, not deep code reasoning).

### 2.4 Neon Postgres
1. Go to `https://neon.com`, sign up
2. Create a new project — this gives you a Postgres connection string instantly
3. Save the **connection string** (found in your project dashboard)
4. Neon now ships more than just a database — it has **Neon Auth**, **Neon Functions** (long-running, no timeouts, good for your cron scanner), **Neon Data API** (PostgREST-style HTTPS layer so the Flutter app can talk to Postgres over plain HTTPS instead of a raw TCP driver, which mobile apps handle much better)
5. **Critical for your use case:** you're using Neon specifically to avoid Supabase's pausing behavior — confirm on your plan's dashboard what Neon's own compute **scale-to-zero** behavior is for your tier, since Neon computes also suspend after inactivity (they auto-wake on the next connection, ~300-500ms cold start, which is very different from Supabase pausing a whole project, but it's worth knowing it's not "always-on" unless you're on a paid tier that disables it).
6. Enable **Neon Functions** in your project — this is where the hourly cron scan job will live.

### 2.5 Firebase (for Push Notifications)
1. Go to `https://console.firebase.google.com`
2. Create a new project (Google Analytics optional, skip it for now)
3. Add an Android app — package name should match your Flutter app's `applicationId` (you'll set this in step 3)
4. Add an iOS app — bundle ID should match your iOS `PRODUCT_BUNDLE_IDENTIFIER`
5. Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) — you'll place these in your Flutter project later
6. Generate a **Server Key / Service Account** under Project Settings → Cloud Messaging → for sending pushes from your Neon Function

### 2.6 Summary — Your `.env` File

Create this file at the project root. **Never commit it** — add it to `.gitignore` immediately.

```env
# GitHub OAuth
GITHUB_CLIENT_ID=your_client_id
GITHUB_CLIENT_SECRET=your_client_secret          # server-side only, never in Flutter build
GITHUB_CALLBACK_SCHEME=chomp

# NVIDIA NIM
NVIDIA_API_KEY=nvapi-xxxxxxxxxxxx
NVIDIA_BASE_URL=https://integrate.api.nvidia.com/v1
NVIDIA_MODEL=your-chosen-code-model

# Groq
GROQ_API_KEY=gsk_xxxxxxxxxxxx
GROQ_BASE_URL=https://api.groq.com/openai/v1
GROQ_MODEL=your-chosen-model

# Neon
NEON_DATABASE_URL=postgresql://user:pass@ep-xxxx.neon.tech/chomp
NEON_DATA_API_URL=https://your-project.neon-data-api.com

# Firebase
FIREBASE_PROJECT_ID=chomp-xxxx
FCM_SERVER_KEY=your_server_key
```

**Important distinction:** `GITHUB_CLIENT_SECRET`, `NVIDIA_API_KEY`, `GROQ_API_KEY`, and `NEON_DATABASE_URL` (direct connection) must live **only** in your Neon Functions (server environment variables), never bundled into the Flutter app binary — anyone can decompile a mobile app and extract embedded secrets. The Flutter app should only ever call your Neon Functions/Data API endpoints, which then use those secrets server-side.

---

## 3. Things To Download / Install

Run through these before writing any code.

### 3.1 Core tooling
```bash
# Flutter SDK (check current stable channel)
flutter --version
flutter doctor          # run this and resolve every red/yellow flag before continuing
```

### 3.2 Editor
- VS Code or Android Studio, with the Flutter + Dart plugins installed

### 3.3 Flutter packages (added via pubspec.yaml, listed here so you know what's coming)
```yaml
dependencies:
  flutter:
    sdk: flutter

  # Auth / networking
  flutter_web_auth_2: ^latest      # GitHub OAuth browser flow
  http: ^latest
  flutter_secure_storage: ^latest  # store tokens securely on-device

  # State management
  flutter_riverpod: ^latest        # or provider — pick one, riverpod recommended for this scale

  # Backend
  postgrest: ^latest               # if using Neon Data API (PostgREST-compatible)

  # Notifications
  flutter_local_notifications: ^latest
  firebase_core: ^latest
  firebase_messaging: ^latest

  # UI
  fl_chart: ^latest                # for speedometers/gauges and heatmap strips
  syncfusion_flutter_gauges: ^latest  # alternative dedicated gauge package — evaluate both

  # Utilities
  intl: ^latest                    # date formatting
  url_launcher: ^latest            # "View on GitHub" links
  flutter_dotenv: ^latest          # loading non-secret client-side config
```

### 3.4 Server side (Neon Functions)
Neon Functions run Node.js. You'll need:
```bash
node --version    # LTS version
npm --version
```
Neon Functions are deployed via the Neon CLI:
```bash
npm install -g neonctl
neonctl auth
```

### 3.5 Native platform requirements
- **Android:** Android Studio + Android SDK, a physical device or emulator with API 26+
- **iOS:** Xcode (Mac only), CocoaPods (`sudo gem install cocoapods`), a physical device or simulator

### 3.6 Git
```bash
git --version
```
You'll need a GitHub repo for the project itself (separate from the repos Chomp analyzes).

---

## 4. Project Setup

```bash
flutter create chomp --org com.yourname --platforms=android,ios
cd chomp
```

### 4.1 Folder structure

```
chomp/
  .env                          # gitignored
  .gitignore
  pubspec.yaml
  lib/
    main.dart
    core/
      constants.dart
      theme.dart
      env.dart                 # reads .env safely, client-side non-secret values only
    models/
      repo.dart
      scan_result.dart
      alert.dart
      feed_item.dart
      user.dart
    services/
      auth_service.dart        # GitHub OAuth flow
      github_service.dart      # GitHub REST API calls
      scan_engine.dart         # shared scan logic used by manual scan
      nvidia_service.dart
      groq_service.dart
      neon_service.dart        # Data API / Postgrest client
      notification_service.dart
      fcm_service.dart
    providers/
      auth_provider.dart
      repo_provider.dart
      scan_provider.dart
      feed_provider.dart
      settings_provider.dart
    screens/
      onboarding/
        welcome_screen.dart
        github_connect_screen.dart
      home/
        home_screen.dart
      repo_detail/
        repo_detail_screen.dart
      insights/
        insights_screen.dart
      feed/
        feed_screen.dart
      profile/
        profile_screen.dart
        watchlist_manager_screen.dart
        notification_settings_screen.dart
    widgets/
      repo_card.dart
      speedometer_gauge.dart
      qualitative_gauge.dart
      heatmap_strip.dart
      scan_log_view.dart
      alert_tile.dart
      feed_item_tile.dart
  android/
  ios/
server/                          # Neon Functions live here, separate from Flutter app
  functions/
    hourly-scan.js               # the cron job
    github-oauth-exchange.js     # exchanges OAuth code for token, keeps secret safe
    scan-repo.js                 # shared scan logic (mirrors scan_engine.dart conceptually)
  neon.config.json
```

---

## 5. Engine First — Build Order

This is the part you said matters most. Build and test each piece in isolation before moving to the next — don't wire the UI until the engine works end to end from a terminal/Postman-style test.

### Step 1 — GitHub OAuth
**Goal:** user taps "Connect GitHub," browser opens, they approve, app receives an access token.

- `flutter_web_auth_2` opens `https://github.com/login/oauth/authorize?client_id=...&scope=repo,read:user&redirect_uri=chomp://callback`
- GitHub redirects to `chomp://callback?code=xxx`
- Flutter captures that code, sends it to your Neon Function `github-oauth-exchange.js`
- That function calls GitHub's token endpoint server-side (using the client secret, which never touches the phone), gets back an access token
- Function stores the token (encrypted) in Neon against the user's row, returns a session token to the app
- App stores the session token in `flutter_secure_storage`

**Android setup required:**
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<activity android:name="com.linusu.flutter_web_auth_2.CallbackActivity" android:exported="true">
  <intent-filter android:label="flutter_web_auth_2">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="chomp" />
  </intent-filter>
</activity>
```

**iOS setup required:** add the `chomp` URL scheme in `ios/Runner/Info.plist` under `CFBundleURLTypes`.

**Test before moving on:** confirm you can log the returned access token and successfully call `GET https://api.github.com/user` with it.

### Step 2 — Pull Repos
- `github_service.dart` calls `GET /user/repos?sort=pushed&per_page=100`
- Sort by `pushed_at` to determine the "3 latest" for auto-watch
- Map response into your `Repo` model
- Store repo list in Neon so the server-side cron knows what to scan

**Test:** print the repo list, confirm the top 3 by `pushed_at` match what you'd expect from your actual GitHub account.

### Step 3 — NVIDIA Scan (Security + Code Quality)
- `nvidia_service.dart` sends the repo's relevant files (or a diff/summary — full repos can exceed context, so decide: send README + package manifest + a sample of recently changed files, not the entire codebase) to the NVIDIA endpoint
- Prompt should return **structured JSON** — this matters a lot for reliably driving your speedometers. Example target shape:
```json
{
  "security_score": 84,
  "security_findings": ["Outdated dependency in pubspec.yaml", "..."],
  "code_quality_score": 71,
  "code_quality_findings": ["No error handling in auth_service.dart"]
}
```
- Instruct the model explicitly: *"Respond only with valid JSON matching this schema, no prose, no markdown fences."*
- Parse defensively — strip code fences if the model adds them anyway, wrap in try/catch, have a fallback score of `null` (shown as "pending" in UI) rather than crashing on a bad parse.

**Test:** run this against one real repo, confirm you get parseable JSON with reasonable scores.

### Step 4 — Groq Scan (Docs + Tests)
- `groq_service.dart` sends README content + repo file tree (to detect test folders/files) to Groq
- Ask for a **qualitative label**, constrained to your fixed set: `Excellent | Great | Good | Standard | Poor | Critical`
- Same structured JSON approach:
```json
{
  "docs_rating": "Good",
  "docs_reasoning": "README covers setup but lacks usage examples",
  "tests_rating": "Poor",
  "tests_reasoning": "No test directory detected"
}
```

**Test:** same as above, confirm valid structured output on a real repo.

### Step 5 — Neon Storage
- Design your tables (see 5.1 below)
- Write scan results after each scan
- Confirm you can read them back via the Neon Data API from a simple HTTP call (test with curl/Postman before wiring Flutter)

#### 5.1 Minimal schema
```sql
create table users (
  id uuid primary key default gen_random_uuid(),
  github_id bigint unique not null,
  github_username text not null,
  access_token_encrypted text not null,
  created_at timestamptz default now()
);

create table repos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id),
  github_repo_id bigint not null,
  name text not null,
  full_name text not null,
  is_auto_watched boolean default false,
  is_manually_watched boolean default false,
  last_pushed_at timestamptz,
  created_at timestamptz default now()
);

create table scan_results (
  id uuid primary key default gen_random_uuid(),
  repo_id uuid references repos(id),
  security_score int,
  code_quality_score int,
  docs_rating text,
  tests_rating text,
  findings jsonb,
  scanned_at timestamptz default now()
);

create table alerts (
  id uuid primary key default gen_random_uuid(),
  repo_id uuid references repos(id),
  scan_result_id uuid references scan_results(id),
  message text,
  severity text,
  resolved boolean default false,
  created_at timestamptz default now()
);

create table feed_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id),
  repo_id uuid references repos(id),
  type text,              -- commit | pr | issue | scan_complete
  title text,
  github_url text,
  created_at timestamptz default now()
);
```

### Step 6 — Manual "Scan Again" Flow (client-triggered)
This is the one path that runs live from the phone, because it's user-initiated:
1. User taps **Scan Again**
2. `scan_engine.dart` runs sequentially, updating a local state stream that the UI listens to for the phase log:
```dart
enum ScanPhase { fetching, ingesting, analysing, codeReview, securityCheck, docsEval, testsEval, complete }
```
3. Each phase transition emits an event → `scan_log_view.dart` renders a new line
4. On completion, result is written to Neon, UI updates the speedometers

### Step 7 — Hourly Server Cron (Neon Function)
- `server/functions/hourly-scan.js` — scheduled to run every hour via Neon's function scheduling (check current Neon docs for the exact cron configuration syntax at the time you build this, since Neon Functions are a newer feature and the scheduling API may still be evolving)
- Logic:
```
for each user:
  for each watched repo (auto top 3 + manual watchlist):
    run same scan logic as scan-repo.js
    compare new scores to last scan_results row
    if new alert OR score dropped beyond threshold:
      insert alert
      send FCM push to user's device token
    always insert new scan_results row
    always insert feed_item for scan_complete
```

### Step 8 — Notifications
- **FCM** delivers the "wake up" push from the server when something's worth telling the user about
- **`flutter_local_notifications`** renders it as a native notification on the device (FCM background handler triggers a local notification with the alert content)
- Also use `flutter_local_notifications` directly for anything triggered while the app is in the foreground (e.g. manual scan just completed)

```dart
// notification_service.dart — core setup
final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings();
  const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
  await flutterLocalNotificationsPlugin.initialize(settings);
}

Future<void> showAlertNotification(String repoName, String message) async {
  const androidDetails = AndroidNotificationDetails(
    'chomp_alerts', 'Repo Alerts',
    importance: Importance.high, priority: Priority.high,
  );
  const details = NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails());
  await flutterLocalNotificationsPlugin.show(0, repoName, message, details);
}
```

**Test:** trigger a manual scan that intentionally has a finding, confirm a notification appears.

---

## 6. Widget Guides

Brief build notes for the trickier custom widgets — the ones with obvious CRUD-ish screens (Profile, Feed list) aren't detailed here since they're standard ListView/Form patterns.

### `speedometer_gauge.dart`
Numeric 0-100 dial for Security + Code Quality.
- Use `syncfusion_flutter_gauges`' `SfRadialGauge` or build with `fl_chart`'s custom painters if you want to avoid the extra dependency
- Color bands: 0-40 red, 41-70 amber, 71-100 green
- Animate the needle/arc on value change with an `AnimationController`

### `qualitative_gauge.dart`
Same visual dial shape as above for consistency, but instead of a numeric needle position, map the 6-tier label to a fixed position on the arc:
```
Critical → Poor → Standard → Good → Great → Excellent
   (0)      (1)      (2)      (3)     (4)      (5)
```
Show the label as the center text instead of a number.

### `heatmap_strip.dart`
GitHub-style commit heatmap for the last 30 days.
- Fetch commit dates from `GET /repos/{owner}/{repo}/commits`
- Bucket by day, render as a row of colored squares (`Container` in a `Wrap` or `GridView`, intensity by commit count that day)
- Streak counter: count consecutive days with at least 1 commit, walking backward from today

### `scan_log_view.dart`
- Listens to a `Stream<ScanPhase>` from `scan_engine.dart`
- `AnimatedList` so each new phase line animates in
- Auto-scrolls to bottom on new entry

---

## 7. UI Polish (Last — After Engine Works)

Only start this once every screen can show real data end to end. In order:
1. Empty states (no repos connected yet, watchlist empty, no alerts)
2. Loading skeletons instead of spinners on Home and Repo Detail
3. Light/Dark/System theme toggle wired to `ThemeMode`
4. Accent color picker (store choice in Neon under user settings or locally)
5. Micro-animations on the speedometers and scan log
6. Pull-to-refresh on Home and Feed

---

## 8. CLI Checks Before Running on Your Phone

Run these in order every time before testing on-device — catching issues here is much faster than debugging on a real phone.

```bash
# 1. Get dependencies
flutter pub get

# 2. Format check — auto-fixes formatting issues
dart format .

# 3. Static analysis — type errors, unused imports, lint issues
flutter analyze

# 4. Run any unit tests you've written
flutter test

# 5. Clean build artifacts if you're getting weird stale-build errors
flutter clean
flutter pub get
```

If `flutter analyze` reports issues, fix them before proceeding — don't run on-device with known analyzer errors, they tend to surface as runtime crashes.

### Viewing on your phone

**Android (physical device):**
```bash
# Enable Developer Options + USB Debugging on your phone first
flutter devices          # confirm your phone is listed
flutter run              # builds debug APK and installs directly
```

**iOS (physical device, Mac only):**
```bash
flutter devices
flutter run               # you'll need to trust your developer certificate on the phone the first time, under Settings → General → VPN & Device Management
```

**Hot reload while developing:** once `flutter run` is active, press `r` in the terminal for hot reload, `R` for hot restart.

---

## 9. Producing an APK (Android) for GitHub Release + Phone Install

```bash
# Debug APK — fastest, larger file, includes debug info
flutter build apk --debug

# Release APK — what you actually want to share/distribute
flutter build apk --release

# Split per-architecture (smaller individual files, recommended for distribution)
flutter build apk --release --split-per-abi
```

Output location:
```
build/app/outputs/flutter-apk/app-release.apk
```
(or `app-arm64-v8a-release.apk` etc. if you used `--split-per-abi`)

### Installing directly on your phone
```bash
flutter install     # installs the most recent build directly if phone is connected
# or manually copy the .apk to your phone and open it (enable "install from unknown sources" first)
```

### Publishing the APK to GitHub
1. Commit your code as normal (the `.env` file should already be gitignored — double check it never got committed)
2. On GitHub, go to your repo → **Releases** → **Draft a new release**
3. Tag it (e.g. `v0.1.0`), write release notes
4. Drag the `.apk` file from `build/app/outputs/flutter-apk/` into the release assets
5. Publish — anyone with the link can now download and sideload it

### Before your first release — sign the release build properly
A debug-signed release APK will show warnings and can't later be upgraded to a Play Store build with a different signature. Generate a proper keystore:
```bash
keytool -genkey -v -keystore ~/chomp-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias chomp
```
Then configure `android/key.properties` and reference it in `android/app/build.gradle` per Flutter's official Android deployment docs (this step is worth doing once, early, rather than retrofitting it after you've already shared APKs signed with the debug key).

---

## 10. Quick Reference — Full Command Sequence

```bash
# One-time setup
flutter create chomp --org com.yourname --platforms=android,ios
cd chomp
flutter pub get

# Every session before testing
dart format .
flutter analyze
flutter test
flutter run

# When ready to share
flutter build apk --release --split-per-abi
# → upload build/app/outputs/flutter-apk/*.apk to GitHub Releases
```
