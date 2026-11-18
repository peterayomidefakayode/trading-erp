# Repair the sample workspace safely

The application version that was previously delivered includes the SMC strategy form fields, but your hosted Supabase project is missing the migration that adds those fields. The resulting `applicable_instruments` error stopped the sample loader before it could populate the remaining modules.

## 1. Apply the database repair

1. Open Supabase Dashboard → SQL Editor.
2. Open `supabase/REPAIR_STRATEGY_AND_TRADE_FIELDS.sql` from this project and copy its complete contents into a new SQL query.
3. Run it once. It uses `ADD COLUMN IF NOT EXISTS`, so it preserves existing strategy and trade records. It does not drop tables, delete records, disable RLS, or reset the database.
4. Wait a few seconds for the schema cache reload.

## 2. Load the sample workspace

1. Sign out of the ERP and sign back in.
2. Open Overview and click **Load sample workspace**.
3. The loader checks for existing demo records before inserting them, so a retry after a partial run will reuse existing records rather than blindly duplicating them.
4. If any later database error occurs, the application refreshes the records already created and reports the exact table/error. Correct that issue and retry.

## 3. Sample records included

The loader creates clearly labelled `[DEMO]` records for the SMC strategy and checklist, brokers and four accounts, sample closed/open trades, six-timeframe analysis, plans and watchlist, alerts, risk rules, goals and weekly review/action, psychology journal, prop-firm programme, notifications, account transaction, and a sample CSV import batch with two review rows.

All sample records are ordinary editable user-owned records. They are not live broker data or trading signals. Broker-specific contract size, tick value and volume settings are not assumed to be verified.

## 4. Protect existing records

Do not run a database reset, drop tables, truncate records, or disable RLS. Existing user records are preserved by this repair. The demo cleanup button only deletes IDs recorded as created by the successful demo run in that browser; do not use it if you want to keep the sample records.
