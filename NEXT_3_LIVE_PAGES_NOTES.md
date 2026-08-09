# Next 3 Admin Pages — Live Flutter/Supabase build

This checkpoint converts three admin pages from image overlays to real Flutter UI:

1. Users Management
2. Manual Draw
3. Adjust Points

## Data behavior

- Users is populated from `public.profiles` through `SupabaseRepository.getUsers()`.
- Creating a user calls the existing `create-user` Supabase Edge Function.
- Activating/deactivating users calls `admin_set_user_active`.
- Manual Draw grants exactly one real pending draw through `manual_grant_draw`; it does not let the admin choose the card result.
- Adjust Points calls `admin_adjust_points` and requires a reason.
- Recent manual grants and point adjustments are shown from `audit_logs`.
- No fake users, scores, counts, or sample database rows are embedded in these pages.

## Files added

- `lib/screens/admin/admin_live_scaffold.dart`
- `lib/screens/admin/admin_users_page.dart`
- `lib/screens/admin/admin_manual_draw_page.dart`
- `lib/screens/admin/admin_adjust_points_page.dart`

`lib/screens/admin/admin_shell.dart` routes these three pages to the new live Flutter UI. Other pages remain unchanged.

## Design references

The three separate reference images are in `design_reference/`. They are not used as functional UI backgrounds.

## Run

```powershell
flutter clean
flutter pub get
flutter analyze
flutter run -d chrome
```

The `create-user` Edge Function must already be deployed in the connected Supabase project for Add User to work.
