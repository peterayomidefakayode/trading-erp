# Setup and deployment

## 1. Prerequisites
- Node.js 20+
- Supabase CLI
- A Supabase project
- A Vercel project

## 2. Local setup
```bash
npm install
cp .env.example .env.local
# Set VITE_SUPABASE_URL and VITE_SUPABASE_PUBLISHABLE_KEY
npm run dev
```

## 3. Database
```bash
supabase login
supabase link --project-ref YOUR_PROJECT_REF
supabase db push
```
Review migrations in a staging project first. Run `docs/ADMIN_SETUP.sql` after the administrator has registered.

## 4. Edge Functions
Set server-side Supabase secrets in the Supabase dashboard/CLI; never expose service role credentials in Vite:
```bash
supabase secrets set SUPABASE_URL=... SUPABASE_ANON_KEY=... SUPABASE_SERVICE_ROLE_KEY=...
supabase functions deploy approve-user
supabase functions deploy evaluate-trade
```

## 5. Storage
Create a private bucket named `trade-screenshots`. Add storage object policies restricting paths to the authenticated user's UUID prefix. The storage policy is intentionally a deployment gate and must be installed before enabling screenshot upload.

## 6. Vercel
Import the Git repository into Vercel. Set `VITE_SUPABASE_URL` and `VITE_SUPABASE_PUBLISHABLE_KEY` as environment variables for Preview and Production. Build command `npm run build`; output directory `dist`.

## 7. First admin
Register with the specified admin email, then execute `docs/ADMIN_SETUP.sql` in the Supabase SQL editor. This promotes the existing Auth user; it does not create a password.

## 8. Test
```bash
npm test
npm run build
```
