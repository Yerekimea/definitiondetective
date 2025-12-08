# Flutter Mapping: Web -> Mobile

This document maps key web components (from `src/components` and `src/app`) to suggested Flutter widgets, implementation notes, and required assets/APIs. Use this as the authoritative guide when porting UI and behavior into `app/lib`.

## Summary
- Primary pages to port: Home (`src/app/page.tsx`), Game (`src/components/game/game-client.tsx`), Leaderboard (`src/app/leaderboard/page.tsx`), Store (`src/app/store/page.tsx`), Profile (`src/app/profile/page.tsx`), Login/Signup (`src/app/login`, `src/app/signup`).
- Key APIs: `/api/sound` (POST -> { soundDataUri }), `/api/hint` (POST -> { hint }), `/api/genkit/*` (internal genkit proxy).
- Static assets found: `public/sounds/{correct.wav,incorrect.wav,win.wav}`, `src/lib/placeholder-images.json`, `src/app/favicon.ico`, `src/app/globals.css`.

## Component Mapping

- `src/components/header.tsx`
  - Purpose: App header with logo, nav links (Leaderboard, Store), mute toggle, user avatar + menu (Profile, Store, Logout), and login button.
  - Flutter mapping:
    - Root: `AppBar` or a custom `PreferredSize` widget to match height.
    - Logo + title: `Row` with `Icon` (`Icons.puzzle` or custom asset) and `Text` (hidden on small widths via responsive layout).
    - Nav links: `TextButton`s (or `BottomNavigationBar` on mobile for persistent navigation).
    - Mute toggle: `IconButton` toggling audio service state.
    - Avatar + menu: `PopupMenuButton` + `CircleAvatar`.
  - Notes:
    - Use `ScaffoldMessenger` for toasts. Avatar image can point to `placeholder-images.json` or user-specific photo URL from Firebase.

- `src/components/game/game-client.tsx`
  - Purpose: Main game UI and logic: definition card, displayed word grid, guess keyboard, hints, rewarded-ad simulation, sound integration, score/level display, share buttons, Firestore updates.
  - Flutter mapping:
    - `GameScreen` StatefulWidget for game state and lifecycle.
    - Definition: `Card` with `Text` styled italic + centered.
    - Word display: `Wrap` / `Row` of fixed-size `Container`s with border and large `Text` for letters.
    - Keyboard: port `Keyboard` component into `KeyboardWidget` that builds rows of `ElevatedButton`/`OutlinedButton` matching disabled/correct/incorrect/hinted styles.
    - Hints: `ElevatedButton` and `showDialog`for rewarded ad simulation; `LinearProgressIndicator` for ad progress.
    - Alerts/Result state: `AlertDialog` or `SnackBar` for win/loss and retry.
    - Sounds: use `audioplayers` to play either local `assets/sounds/*.wav` or base64-decoded temp files returned by `/api/sound`.
    - Firestore: use `cloud_firestore` and `firebase_auth` packages; port `updateFirestoreUser()` logic using `FieldValue.increment`.
  - Notes:
    - Keep identical rules: MAX_INCORRECT_TRIES = 6, reveal logic, hint flow.
    - Use `FutureBuilder`/`StreamBuilder` for user profile and hints count.

- `src/components/game/keyboard.tsx`
  - Purpose: On-screen keyboard with letter buttons and visual states.
  - Flutter mapping:
    - `KeyboardWidget` that renders three rows with `GridView` or nested `Row`s and `Wrap`.
    - Button states: correct -> green, incorrect -> red, hinted -> blue/disabled.

- `src/components/ui/*` (button, input, card, alert, dialog, progress, badge, skeleton, etc.)
  - Purpose: Design system primitives used across the site.
  - Flutter mapping:
    - `Button` -> map to `ElevatedButton` / `TextButton` / `OutlinedButton`.
    - `Input` -> `TextField` / `TextFormField`.
    - `Card` -> `Card` widget.
    - `Alert`, `AlertDialog` -> `AlertDialog` / `SnackBar`.
    - `Progress` -> `LinearProgressIndicator` / `CircularProgressIndicator`.
    - `Skeleton` -> use `shimmer` package (optional) or `Container` with gradient animation.
  - Notes:
    - Reuse a small `widgets/ui` library in `app/lib/widgets` to centralize styling and make porting easier.

- `src/components/FirebaseErrorListener.tsx`
  - Purpose: Listens to errors from Firestore and displays helpful UI.
  - Flutter mapping:
    - A global `Stream`/`Provider` that listens for permission errors and displays dialogs/snackbars. Consider using `provider` or `riverpod` for app-wide error events.

- `src/components/providers.tsx`
  - Purpose: Wraps the app with context providers (Auth, Toasts, Theme, etc.)
  - Flutter mapping:
    - Initialize Firebase in `main()` and use `StreamBuilder` on `FirebaseAuth.instance.authStateChanges()` to switch between `LoginScreen`/`HomeScreen`.
    - Use `ChangeNotifierProvider` or `Riverpod` for shared state (sound, mute, theme).

## APIs and Sound/Hint Flow

- `/api/sound` (POST { sound: 'correct' | 'incorrect' | 'win' })
  - Returns: `{ soundDataUri }` or static public path `/sounds/{key}.wav`.
  - Flutter notes:
    - Prefer local assets (`assets/sounds/*.wav`) when present for performance/packaging.
    - For API-provided base64 data URIs, decode and write to a temporary file (use `path_provider`) then play via `audioplayers` (this is already implemented in `main.dart`).

- `/api/hint` (POST { word, incorrectGuesses, lettersToReveal })
  - Returns: `{ hint }` or `{ error }`.
  - Flutter notes:
    - Call via `http` package and show progress/disabled state while awaiting response. Refund hint on error.

## Assets

- Sounds: `public/sounds/correct.wav`, `incorrect.wav`, `win.wav` — copy into Flutter `app/assets/sounds/` and reference in `pubspec.yaml`.
- Placeholder images: `src/lib/placeholder-images.json` contains external avatar URL(s); acceptable to use as default avatar or download and bundle a local fallback.
- Icons: The web uses `lucide-react`; on Flutter use `Icons` or include equivalent vector assets (SVG via `flutter_svg`) for visual parity.

## Implementation Notes & Priorities

- High priority for porting:
  - `GameScreen` + `KeyboardWidget` + hint flow + sound playback + Firestore integration.
  - `Auth` flows (Login, Signup) and `ProfileScreen` persistence.

- Medium priority:
  - Leaderboard and Store CRUD interactions with Firestore (store purchases are Firestore writes).
  - App header and navigation (persistent bottom nav recommended on mobile).

- Low priority:
  - Exact visual parity for every UI primitive; start with functional widgets and iterate on spacing/typography.

## Next Steps (for the port)

1. Add `assets/sounds/*` to Flutter `app/assets` and update `pubspec.yaml`.
2. Create `app/lib/widgets/` UI primitives (Button, Card, Avatar, KeyboardWidget, GameCard).
3. Implement `GameScreen` stateful port following logic in `src/components/game/game-client.tsx` (preserve scoring, hint refund, ad-sim flow).
4. Wire `LoginScreen`, `SignupScreen`, `ProfileScreen`, and `LeaderboardScreen` to Firestore.
5. Test on Android emulator (use `10.0.2.2` for `apiBaseUrl` or override using `.env`).

---

If you want, I can now:
- (A) generate the Flutter UI primitives and wire `GameScreen` (functional port), or
- (B) add sound assets to `app/assets` and update `pubspec.yaml` first.

Tell me which next step you prefer and I'll implement it.
