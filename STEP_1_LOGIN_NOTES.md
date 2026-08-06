# Step 1 — Light Login Screen

This build intentionally updates only the login screen.

Working controls:
- Agent/Admin role tabs
- Username field
- Password field
- Show/hide password
- Remember-me checkbox
- Forgot-password information
- Sign-in button and loading state
- Supabase authentication

## Fresh Supabase key

The previous hardcoded key was removed because Supabase rejected it.

1. Double-click `run_web.bat`.
2. Paste the current **Publishable key** from Supabase when asked.
3. The key is saved locally in `.supabase_publishable_key` and is excluded from Git.
4. Run `reset_supabase_key.bat` whenever the key is changed or entered incorrectly.

The file `.supabase_publishable_key` is local-only and must not be committed.
