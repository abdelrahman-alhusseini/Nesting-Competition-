# V8.2 Hybrid Visual Pages

The Users, Manual Draw, and Adjust Points admin pages now use **real image assets inside the running Flutter UI**.

Used assets:
- `assets/images/admin_users_visual.png`
- `assets/images/admin_manual_draw_visual.png`
- `assets/images/admin_adjust_points_visual.png`

The images are decorative only. All functional content remains Flutter + Supabase:
- Users: live profiles, filters, create user, activate/deactivate.
- Manual Draw: live agent list and `manual_grant_draw` RPC.
- Adjust Points: live agent list and `admin_adjust_points` RPC with audit history.

The visual assets are rendered by `AdminLiveScaffold` through `Image.asset(...)`; they are not unused reference files.
