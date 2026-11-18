# Resolve the pending workspace and load sample records

## Why saving and sample loading are blocked

This project deliberately requires an approved profile for creating or changing broker, account, instrument and trading records. The current profile is `pending`, so the database Row Level Security (RLS) policies reject those writes. The sample-workspace function also checks for `approval_status = 'approved'` before inserting anything. This is why the sample button appeared to do nothing useful while the account was pending.

Do not remove RLS or change the policies to `using (true)`. That would expose every trader's records.

## One-time first administrator setup

1. Register your own account in the application first, and verify the email if Supabase email confirmation is enabled.
2. Open Supabase Dashboard → SQL Editor.
3. Open `supabase/ADMIN_BOOTSTRAP_APPROVAL.sql` from this project.
4. Replace both occurrences of `REPLACE-WITH-YOUR-LOGIN-EMAIL@example.com` with the exact email address you used to register. The SQL deliberately refuses to run while the placeholder remains.
5. Run the SQL while signed in as the owner of this Supabase project.
6. Confirm the result shows your email, `approved`, and role `admin`.
7. Sign out of the ERP and sign in again, or refresh after the session is reloaded.

This is an explicit owner-controlled bootstrap. It approves only the one email you specify and grants it the first administrator role. Do not grant admin rights to anyone else's account. Thereafter, use the Administration tab to approve other registered traders.

## Load the sample workspace

1. Confirm the sidebar workspace status reads `APPROVED`.
2. Confirm migrations 0001–0009 have been applied in order.
3. Open Overview and click **Load sample workspace**.
4. Wait for the success message. If a table insert fails, the message names the table and database error; fix that issue before retrying.
5. Sample records are labelled `[DEMO]` in names or notes. They are editable and removable. They are fictional and are not broker statements or trading signals.

The sample data is stored in your own Supabase account. It cannot be loaded while the profile remains pending because doing so would require bypassing the same protections that prevent unauthorized users from creating real records.

## Navigation behaviour

The desktop navigation is now sticky within the viewport and scrolls independently if the menu itself is taller than the screen. It no longer moves down the page with the main content. On narrow/mobile screens it returns to a compact horizontal navigation bar.
