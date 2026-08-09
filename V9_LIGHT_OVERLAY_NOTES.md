# V9 Light Artwork + Live Flutter/Supabase Overlay

This build uses the new light gray / baby blue / white / navy / nude-gold visual theme as real runtime artwork.

## Newly wired generated artwork
- Login
- Admin Dashboard
- Booking Approvals
- Users Management
- Manual Draw
- Adjust Points
- Audit History
- Admin Settings
- Agent Dashboard
- My Bookings

The image provides the visual shell, decoration, card frames, icons and layout. Live values, rows, authentication, actions and database results are Flutter widgets driven by the existing AppController / SupabaseRepository.

## Real logic retained
- Supabase authentication and roles
- Dashboard stats and activity
- Booking submission
- Admin booking review / approve / reject
- User creation and activate/deactivate
- Manual draw grants through `manual_grant_draw`
- Point adjustments through `admin_adjust_points`
- Audit history

## Existing screens retained
Card reveal and the agent card/reward/special-card screens that were not part of this latest generated light-image batch remain on their existing artwork so their game logic is not broken.

## Run
```powershell
flutter clean
flutter pub get
flutter analyze
flutter run -d chrome
```
