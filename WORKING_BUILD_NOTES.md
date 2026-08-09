# V7 visual integration repair

This build fixes the two problems in the previous package:

1. **No duplicated page overlays.** The generated artwork is the only page background. Flutter now adds only transparent hit targets, real form fields, and live Supabase values in the intended empty areas.
2. **No stretched/fat images.** Every 1672 x 941 page keeps its original aspect ratio. A blurred copy of the same artwork fills extra-wide browser space and blends at the edges.
3. **Supabase startup is preconfigured.** `run_web.bat` uses the project URL and client publishable key directly. Dart-define values are cleaned of accidental quotes, commas, and whitespace, and either `SUPABASE_PUBLISHABLE_KEY` or the legacy `SUPABASE_ANON_KEY` can override the built-in client key.
4. **Real data only.** Names, scores, bookings, users, approvals, audit rows, and activity entries come from the connected Supabase project. No demo records are inserted by the Flutter app.

## Start

Double-click:

```text
run_web.bat
```

Or run:

```powershell
flutter clean
flutter pub get
flutter run -d chrome
```

The project contains only a browser-safe publishable key. It does not contain a secret/service-role key.
