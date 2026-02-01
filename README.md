# DisasterLink — Global Disaster Response & Resource Coordination

Cross-platform Flutter app with 6 core modules: Disaster Map Dashboard, Volunteer Hub, Resource Tracker, Notifications, AI Predictor, and Analytics.

## Modules
- Disaster Map Dashboard: Google Maps with markers (stubs), quick access cards, and analytics shortcut.
- Volunteer Hub: Manage volunteers (UI placeholder).
- Resource Tracker: Inventory list with increment/decrement actions (placeholders).
- Notifications: Carded list of alerts.
- AI Predictor: Run a mock prediction (UI placeholder).
- Analytics: Admin/NGO stat cards and recent activity.

## Getting started
1) Prereqs
	- Flutter SDK installed and on PATH
	- Android SDK + an emulator image with Google Play services (for Maps)
	- iOS: Xcode + Cocoapods (if building on macOS)

2) Install dependencies
	- Run from project root:
	  - `flutter pub get`

3) Configure Google Maps API key (Android)
	- Recommended: put your key in `android/local.properties` (not committed):
	  - `MAPS_API_KEY=YOUR_ANDROID_MAPS_KEY`
	- The Android build reads MAPS_API_KEY and injects it as `@string/google_maps_key` (see `android/app/build.gradle.kts`).
	- A fallback value exists in `android/app/src/main/res/values/strings.xml`, but don’t commit real keys to source control.

4) Run
	- `flutter run`

## Project layout (high level)
- `lib/app.dart` — MaterialApp + routes and theme
- `lib/main.dart` — bootstrap + global error handling
- `lib/screens/*` — individual modules/screens
- `lib/widgets/*` — shared widgets (Drawer, cards)
- `lib/services/*` — stubs for future Firebase/AWS wiring

## Notes
- We added a loading overlay on the map until `onMapCreated` fires.
- Drawer navigation closes first and then navigates (with a brief delay) to avoid layout race conditions.
- Analyzer is clean; tests include a login screen smoke test.

## Next steps (when ready)
- Firebase Auth + Firestore wiring for auth, map markers, resources, and notifications.
- Securely store API keys/secrets using build-time injection or runtime secret managers.
- Add CI (analyze + tests) and better widget test coverage.
