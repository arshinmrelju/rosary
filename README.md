# Rosary Break

**Five breaks. Five decades. One Rosary.**

A mobile-first web/PWA for a college campus where students pray one decade
during each of the five daily breaks, completing a full Rosary across the
college day (10:00 AM – 4:00 PM).

```
Break 1  11:00 AM  → Decade 1
Break 2  12:05 PM  → Decade 2
Break 3   1:00 PM  → Decade 3   (Lunch break)
Break 4   2:00 PM  → Decade 4
Break 5   3:00 PM  → Decade 5
```

> The break times live in exactly one place: `DefaultBreakScheduleSource`.
> The UI never hardcodes times.

---

## Tech stack

- **Flutter / Dart** (web + Android scaffolds)
- **Firebase** — Firestore, Authentication (anonymous-first), Cloud Messaging
  (reserved for a later step)
- **Go Router** for declarative navigation
- **Google Fonts** (Poppins) for the visual identity
- **flutter_dotenv** for runtime Firebase configuration

---

## Current scope (stage 1)

Built in this foundation step:

- Clean architecture skeleton (`core` / `domain` / `data` / `features`)
- Design system (Marian blue, white, subtle gold, rounded cards, Poppins)
- Bottom navigation: **Home · Today · Intentions · Progress · Profile**
- **Home**: today's mystery, `● ● ○ ○ ○` progress, next break, PRAY NOW,
  intention / reflection / community cards
- **Today's Rosary**: the five-break schedule with live status
- **Today's Decade**: guided decade screen (Sign of the Cross → Our Father →
  10 Hail Marys beads → Glory Be → O My Jesus) with "I prayed this decade"
  completion persisted through the repository layer
- **Intentions**: submit + browse approved community intentions
- Centralized `BreakSchedule` model/service
- Domain models + repository interfaces + Firestore implementations for:
  `users`, `dailyContent`, `participation/{userId}/days/{date}`,
  `prayerIntentions`, `stats`
- Real-time-switchable data layer: **mock mode by default**, Firebase when
  enabled via `.env`
- Loading / error / empty states, responsive layout, accessibility labels

**Deliberately deferred:** notifications, streaks, badges, prayer wall,
leaderboards, admin dashboard, analytics, social login, advanced animations.

---

## Project structure

```
lib/
├─ main.dart                     # bootstrap (dotenv → Firebase → deps → runApp)
├─ app.dart                      # root widget (AppScope + theme + router)
├─ core/
│  ├─ config/app_config.dart     # runtime config from .env
│  ├─ constants/                 # brand constants + debugLog
│  ├─ di/app_scope.dart          # InheritedWidget DI
│  ├─ router/                    # go_router routes
│  ├─ theme/                     # colours, typography, theme, spacing
│  ├─ utils/                     # date/time helpers
│  └─ widgets/                   # AppCard, buttons, state views, responsive frame
├─ domain/                       # pure Dart, no Flutter/Firebase imports
│  ├─ models/                    # UserProfile, DailyContent, DayParticipation…
│  ├─ schedule/                  # BreakSchedule + source abstraction
│  └─ prayers/                   # standard Rosary texts
├─ data/
│  ├─ auth/                      # AuthService (anonymous-first)
│  ├─ firebase/                  # starter + central Firestore path mapping
│  ├─ repositories/              # interfaces
│  ├─ repositories/firestore/    # Firestore implementations
│  ├─ mock/                      # mock repos + content (offline-first UI)
│  └─ dependencies.dart          # composition root (mock vs Firebase)
└─ features/
   ├─ shell/                     # bottom-nav scaffold
   ├─ home/                      # Home screen
   ├─ today/                     # Today's Rosary screen
   ├─ decade/                    # Today's Decade screen
   ├─ intention/                 # Prayer intentions
   ├─ progress/                  # daily progress (placeholders next)
   └─ settings/                  # profile & settings placeholder
```

Feature screens follow the pattern: screen (StatefulWidget + listenable) →
controller (ChangeNotifier) → repositories → models. No external
state-management package is used; `ListenableBuilder` is built into Flutter.

---

## Running the project

### Requirements

- Flutter 3.x (developed on 3.47 / Dart 3.13)
- Chrome is used as the web target

### Run with mock data (default, no Firebase needed)

```bash
flutter pub get
flutter run -d chrome
```

The app boots in **mock mode**: content rotates by calendar day, participation
is stored in-memory (shared across the session), community stats are fixed.

### Run tests

```bash
flutter test
```

### Release web build

```bash
flutter build web --release
# output: build/web  (deployable to Firebase Hosting / any static host)
```

---

## Connecting Firebase

The app intentionally runs without hardcoded credentials.

1. Create a Firebase project and **enable Anonymous Authentication** and
   **Cloud Firestore**.
2. Register a **Web app** in the Firebase console and copy its configuration.
3. Copy the template and fill it in:

   ```bash
   cp assets/env/.env.example assets/env/.env
   ```

   - Set `USE_FIREBASE=true`
   - Add `FIREBASE_API_KEY`, `FIREBASE_AUTH_DOMAIN`, `FIREBASE_PROJECT_ID`,
     `FIREBASE_APP_ID`, `FIREBASE_STORAGE_BUCKET`,
     `FIREBASE_MESSAGING_SENDER_ID`, `FIREBASE_MEASUREMENT_ID`

4. Deploy the Firestore security rules:

   ```bash
   firebase deploy --only firestore:rules
   ```

   Reference rules live in `firestore/firestore.rules` (admin access relies on
   a custom claim `admin=true`; students use anonymous auth).

5. Reload the app — it now talks to Firebase. Guests log in anonymously
   (no registration wall), so participation is per-device until real accounts
   are added in a later stage.

> `.env` is git-ignored. Never commit real Firebase values.

### Seeding daily content

`dailyContent/{date}` drives the Home/Today/Decade screens. Use any admin
client (or the dashboard in a later stage) to write documents with the shape:

```jsonc
// dailyContent/2026-01-05
{
  "date": "2026-01-05",
  "mystery": "Joyful Mysteries",
  "intention": "For peace in our campus community",
  "reflection": "Even one decade, prayed with your whole heart, is a gift.",
  "published": true,
  "decades": [
    { "number": 1, "mysteryTitle": "The Annunciation", "focus": "…" }
    // … 5 decades
  ]
}
```

The student app handles a missing document gracefully (schedule and
participation still work).

---

## Key decisions & notes

- **Mock first, Firebase opt-in**: the default `.env` keeps
  `USE_FIREBASE=false`. This keeps CI/dev friction-free and satisfies
  "no hardcoded credentials".
- **Anonymous auth**: students never face a registration wall. A later step
  can upgrade anonymous sessions to email/social accounts.
- **Repository interfaces** decouple features from Firebase — swap an
  implementation without touching UI.
- **Break schedule is swappable**: `BreakScheduleSource` has a
  `DefaultBreakScheduleSource` today; replace it with a Firestore-backed
  source when the Admin section is built.
- **Refresh-on-return**: screens reload today's state after the decade screen
  is popped, so progress stays consistent across tabs.
- **Two controllers refresh independently** (one per tab). Fine for stage 1;
  if data grows, promote `TodayController` to app-scope.

## Next steps

1. Publish daily content pipeline (admin dashboard).
2. Real accounts + profile completion (department / year).
3. FCM break reminders.
4. Streaks, badges, prayer wall, leaderboards.