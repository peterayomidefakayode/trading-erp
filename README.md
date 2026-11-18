# Trading ERP — usability, sample workspace and data-management update

This build adds a dedicated broker/account workspace, a trader-owned instrument catalogue, a one-click sample workspace, contextual help, and improved save feedback.

## Before starting

1. Keep a backup of your current project and Supabase database.
2. Extract this ZIP into a new folder.
3. Copy your existing `.env.local` into the new project root. Do not share it or commit it.
4. Install dependencies with `npm install`.
5. Start locally with `npm run dev`.

## Required database migration

If migrations `0001` through `0007` are already applied, apply `supabase/migrations/0008_instrument_catalogue_and_ownership.sql` to the same Supabase project. If this is a fresh database, apply migrations `0001` through `0008` in numerical order.

Migration 0008:
- adds `owner_id` to the global `instruments` catalogue;
- keeps shared catalogue rows readable to authenticated users;
- allows approved users to add, edit and delete only instruments they own;
- adds major/minor/exotic FX examples, metals, indices, crypto, synthetic examples and illustrative US/UK equities;
- marks all catalogue contract details unverified. Broker contract sizes, tick values, volume limits, suffixes and trading hours must be checked against the actual broker/platform.

Do not run a migration against production without first backing up and testing it in a staging project.

## First-time workspace setup

1. Sign in.
2. Your profile must have `approval_status = 'approved'` before the database allows writes. If the workspace says pending/rejected/suspended, an administrator must resolve that first. The application now displays this explicitly.
3. Open **Overview** and select **Load sample workspace**.
4. The sample loader creates example Vantage and Deriv broker entries; Vantage LIVE, Vantage DEMO, Deriv LIVE and Deriv DEMO accounts; a strategy; closed and open sample trades; SMC multi-timeframe analysis; a trade plan; risk rule; goal; journal entry; weekly review and action; watchlist item; manual alert; account deposit; notification; and prop-firm programme.
5. Sample records are labelled `[DEMO]` in names/notes where applicable. They are real editable rows in your own workspace, not fake display-only cards.
6. Use the pencil and bin controls to edit/delete records. **Remove sample records** removes the sample batch created by that browser for that signed-in user; it does not remove records created separately.

The instrument catalogue is shared starter data and is not removed by the demo cleanup. Add any other symbol in **Instrument Library**. The database symbol is unique, so a symbol already in the shared catalogue cannot be added a second time.

## Where to create important records

- **Accounts & Brokers:** add a broker first, then create a live/demo/prop account beneath it. Both lists support edit and delete.
- **Instrument Library:** add a symbol, name, asset class and optional base/quote currencies. Your own custom instruments can be edited/deleted. Shared catalogue instruments are read-only for ordinary traders.
- **Trade Journal:** choose an account and instrument before recording the execution, position, risk, P/L, costs and review details.
- **Risk & Position Size:** enter the actual broker-specific tick size/value, volume minimum/step/maximum and quote-to-account conversion. Never assume these values are universal.
- **SMC Analysis:** select a trade and record D1, 4H, 1H, 15M, 5M and 1M bias, structure, liquidity, FVG, order block and premium/discount observations. Screenshots are private and stored in the `trade-screenshots` bucket.
- **Planner & Watchlist:** create a plan and maintain watchlist bias/key levels.
- **Alerts:** enter the current quote manually to evaluate an alert. Live market-data polling is not included without a configured provider.

## Help

Every workspace header has **Help & field guide**. It explains the module and available field meanings, provides examples, and links to related setup pages such as Accounts & Brokers, Instrument Library and Strategies.

## Save troubleshooting

- If the profile is not approved, writes are intentionally blocked by Supabase RLS. Have the administrator approve the profile.
- If a dropdown is empty, create its prerequisite record first: broker → account; instrument → trade/plan/alert; strategy → trade.
- If a trade save reports a risk preflight issue, the UI now warns if preflight is unavailable rather than silently discarding the trade. A genuine blocking risk-rule result still blocks the trade.
- Read the exact Supabase error shown in the application; do not disable RLS to bypass it.

## Important boundaries

- This is a training-friendly sample environment. Sample trades and prices are fictional and must not be used as market signals.
- Vantage/Deriv broker names and example accounts do not create a live broker connection or import credentials.
- Market quotes, automatic alert polling, live broker equity, and automatic broker statement sync require provider/API integrations and are not implied by the sample data.
- The build's TypeScript project check was run successfully. The production Vite bundle could not be completed in this Linux build environment because the supplied dependency archive does not contain Rollup's Linux native optional package. On Windows, run `npm install` to install platform-specific dependencies, then `npm run build`.

## User methodology starter data (migration 0009)

Apply `supabase/migrations/0009_strategy_methodology.sql` after migrations 0001–0008. It adds editable strategy methodology fields and the requested SMC trade-context and psychology fields, and adds the `partially_closed` trade status without deleting existing records.

After the migration, sign in with an approved trader account and use **Overview → Load sample workspace**. The sample workspace provisions the user's stated primary strategy, **Forex Smart Money Concepts (SMC) Day Trading**, with detailed methodology notes covering:

- Market structure, BOS, CHoCH, order blocks, FVGs, liquidity sweeps, equal highs/lows, premium/discount, support/resistance, supply/demand and higher-timeframe bias.
- D1, H4, H1, M15, M5 and M1 roles.
- Entry, exit, stop-loss, take-profit, risk and confirmation rules.
- London, New York and London–New York overlap, with Sydney and Tokyo/Asian session support noted as configurable.
- A linked SMC pre-trade checklist, sample trades and multi-timeframe analysis.
- Starter emotion and mistake categories plus editable risk-rule examples.

The Strategy Library supports adding, editing, archiving (set status to `archived`), activating (`active`), drafting (`draft`), duplicating and deleting strategies. Strategy examples are editable records, not immutable system defaults. The user may add additional strategies and methodologies independently.

The SMC risk percentages and examples are illustrative starting points, not financial advice or a guarantee. Verify all broker contract specifications and configure risk limits to the trader's own policy before live trading. Session clocks should be interpreted using the trader's configured timezone and daylight-saving rules; the starter text intentionally does not hard-code universal clock hours.
