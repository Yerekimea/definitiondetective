# Definition Detective

This is a Next.js word puzzle game created with Firebase Studio.

## Features

- **Endless Puzzles**: Procedurally generated levels for a new challenge every time.
- **Definition Scrambler**: Unscramble definitions to guess the hidden word.
- **Smart AI Hints**: Get intelligent hints from a GenAI model that knows which letters you've already tried.
- **Score & Progress Tracking**: Compete on leaderboards and track your stats.
- **User Profiles**: Customize your profile and view your achievements.

To get started, run the development server:

```bash
npm run dev
```

Then open [http://localhost:9002](http://localhost:9002) in your browser.

Builds and CI
---------------

This repository contains two app targets:

- Web: a Next.js app located under `src/app` (bridged to `app/` for Codespaces/preview).
- Mobile: a Flutter app in `app/` (Android/iOS builds).

Local build commands

- Web (production build):

```bash
npm ci
npm run build
```

- Android (local machine with Flutter installed):

```bash
# switch to Flutter project folder
cd app
flutter pub get
flutter build apk --release
flutter build appbundle --release
```

- iOS (macOS machine with Xcode & Flutter):

```bash
cd app
flutter pub get
# build unsigned ipa (no signing)
flutter build ipa --no-codesign --export-method ad-hoc
```

CI

There are GitHub Actions workflows to build the web and mobile artifacts:

- `.github/workflows/web.yml` — builds the Next web app and uploads `.next` as an artifact.
- `.github/workflows/android.yml` — builds Android `apk` and `aab` from the Flutter `app/` folder and uploads them.
- `.github/workflows/ios.yml` — builds an unsigned iOS `ipa` on `macos-latest` and uploads it; code signing is not handled by the workflow.

Notes
- iOS signed artifacts require provisioning profiles, certificates and secrets. The `ios.yml` provided builds an unsigned IPA for testing on macOS runners. For App Store distribution you'll need to add secure secrets and signing steps (fastlane is recommended).
- The repo keeps the Next app under `src/app` and uses small bridge files under root `app/` so Codespaces/preview works without moving the Flutter folder.
