# Michael & Son Nesting Champions

Flutter Web + Supabase implementation of the internal Nesting Champions booking game.

## Included now

- Supabase username/password authentication for agents and admins
- Admin-created accounts through a protected Edge Function
- Active/inactive user controls
- One active competition and live leaderboard
- Globally unique ServiceTitan job IDs and normalized links
- Booking submission, approval, rejection, and corrected booking type
- Maximum three pending draws; the oldest pending draw expires when a fourth is granted
- Server-generated card results and server-applied point transactions
- Number cards, Lucky 7, +2, +4, Reverse, Skip, and even-number risk choice
- Booking-type special-card chances
- One saved special card per agent, expiring after five additional approved bookings
- Admin manual draws and point adjustments
- Public activity feed and private admin audit history
- Booking reversal schema and RPC for undoing linked booking effects
- Row Level Security (RLS)
- Unlimited local admin card-animation/sound testing that never changes database data

## Important status

The code is connected to Supabase, but it needs your own Supabase project URL and publishable key at runtime. No secret/service-role key is stored in Flutter or committed to Git.

The current database stores saved special cards and action history. The final target-selection behavior for every special-card type can be expanded after the remaining card rules are finalized.

## 1. Create and deploy Supabase

Install the Supabase CLI, sign in, and create a Supabase project. From this project folder run:

```powershell
supabase login
supabase link --project-ref YOUR_PROJECT_REF
supabase db push
supabase functions deploy create-user
```

The migration is located at:

```text
supabase/migrations/202608050001_initial_game_schema.sql
```

The protected account-creation function is located at:

```text
supabase/functions/create-user/index.ts
```

## 2. Create the first admin

In Supabase Dashboard, open **Authentication > Users** and create a confirmed user:

```text
Email: admin@nesting.local
Password: choose at least 6 characters
```

Then run `supabase/bootstrap_admin.sql` in the Supabase SQL Editor. The app login username will be `admin`.

After that, the admin can create agent/admin accounts from the Users page in the app.

## 3. Run Flutter Web

Double-click:

```text
run_web_supabase.bat
```

It asks for:

- Supabase Project URL
- Supabase publishable key

Or run manually:

```powershell
flutter pub get
flutter run -d chrome `
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

## 4. Push to GitHub

This folder is initialized as a Git repository with an initial commit. Create an empty GitHub repository, then double-click:

```text
push_to_github.bat
```

Never commit a Supabase secret/service-role key, passwords, or `.env` files.

## Architecture

```text
lib/
├── config/
├── models/
│   └── database/
├── repositories/
├── screens/
│   ├── admin/
│   ├── agent/
│   └── shared/
├── services/
├── state/
└── widgets/

supabase/
├── functions/create-user/
├── migrations/
└── bootstrap_admin.sql
```

## Validation note

This package was prepared in an environment without the Flutter SDK, so run `flutter analyze` locally. A GitHub Actions workflow is included to analyze and build Flutter Web after pushing.
