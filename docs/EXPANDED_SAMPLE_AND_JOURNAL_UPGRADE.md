# Expanded Trading ERP sample workspace and journal upgrade

## What this update changes

- The sample loader is now repeatable: it checks for existing demo records by stable identifying fields and inserts only missing examples. It does not ask you to delete the earlier sample set before expanding it.
- It creates at least 20 distinct records for the main operational datasets: strategies, closed trades, plans, watchlist entries, alerts, risk rules, goals, reviews, psychology journal entries, prop-firm programme trackers, statement batches, account ledger entries, notifications, and mistake/emotion reference lists. Each generated trade has six timeframe analysis records (D1, H4, H1, M15, M5 and M1).
- It creates 20 demo accounts across the two real broker entries already in the workspace: Vantage and Deriv. The broker directory intentionally remains two brokers; it does not invent 18 additional broker companies.
- All synthetic performance figures and trading scenarios are marked `[DEMO]`. They are teaching data, not broker statements, live prices, trading signals, or evidence of a real trading edge.
- Generic data tabs now show cards. The record-entry form opens only after choosing **Add new record**. Selecting a card opens the record detail view with edit/delete controls.
- The Overview dashboard includes equity, weekly/monthly/yearly net performance, expectancy, win rate, profit factor, average win/loss, drawdown, plan adherence, achieved R, most-traded instrument, strategy/session/instrument/market-condition/entry-quality and plan-adherence charts.
- Demo, live and prop account performance can be filtered separately.
- Trade journal entries support separate Google Drive URLs for before/analysis, entry/place-of-trade, and after-trade screenshots. Plans, strategy examples, and psychology journal entries also accept Google Drive image links. SMC screenshot records accept a Google Drive link or an uploaded private image. Click an image preview to enlarge it.

## Database update required

Apply `supabase/migrations/0010_journal_analytics_media.sql` in the Supabase SQL Editor before using the new journal fields, screenshot links, and expanded sample loader. This migration only adds columns and an index; it does not drop or truncate tables or records. It also requests a PostgREST schema-cache refresh.

Keep Row Level Security enabled. The sample loader still requires the signed-in account to be approved.

## Updating the application

1. Keep your existing `.env.local` file and its Supabase URL/publishable key.
2. Replace the old project source with this update.
3. Apply migration `0010_journal_analytics_media.sql` in Supabase.
4. Install dependencies and build the project, then deploy the updated application.
5. Sign in and click **Load sample workspace** on Overview. The loader is safe to run again: existing `[DEMO]` rows are checked before missing rows are added.

## Screenshot link requirements

For Google Drive previews, set the file's general access to **Anyone with the link – Viewer**, then paste the share link. The ERP stores the link; it does not change Google Drive permissions. If a file is private or Drive blocks direct image rendering, the preview may not load even though the link is stored correctly.

## Analytics interpretation

Expectancy is net closed-trade P/L divided by closed trades. Profit factor is gross winning P/L divided by absolute gross losing P/L. The current equity curve is reconstructed from recorded closed-trade net P/L; it does not yet include intratrade equity, external deposits/withdrawals, or a verified broker equity feed. Treat demo analytics as a software demonstration only. A strategy assessment should generally use at least 30–50 trades per setup and verified broker data.
