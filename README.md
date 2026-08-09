# Michael & Son Nesting Champions — V7

Flutter Web + Supabase implementation of the Nesting Champions competition.

## Run the app

The Supabase project URL and browser publishable key are already configured.

```powershell
flutter clean
flutter pub get
flutter run -d chrome
```

The easiest option on Windows is to double-click `run_web.bat`.

## What is fixed

- One clean interactive layer per screen; no duplicated panels or controls.
- Original 1672 x 941 artwork proportions are preserved.
- Extra-wide browser space uses a softened extension of the current page rather than stretching the UI.
- Login fields align with the empty fields in the artwork.
- Agent and admin pages use transparent hotspots and lightweight live-data overlays.
- Real Supabase data replaces all demo names, scores, bookings, users, and activity.
- The client configuration strips accidental quotes, commas, and spaces from optional command-line overrides.

## Supabase

Default project:

```text
https://ryzedpbkzspwvrnrppij.supabase.co
```

You can override the built-in browser key when needed:

```powershell
flutter run -d chrome --dart-define="SUPABASE_URL=https://YOUR_PROJECT.supabase.co" --dart-define="SUPABASE_PUBLISHABLE_KEY=YOUR_CLIENT_KEY"
```

Never use a secret/service-role key in Flutter Web.

## Database and functions

The existing migration is under `supabase/migrations/` and the user-creation Edge Function remains under `supabase/functions/create-user/` when present in the source repository. The Flutter app expects the schema and admin profile created in the previous setup steps.
