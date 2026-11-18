-- Expand the shared starter catalogue and permit each approved trader to manage
-- their own custom instruments without granting write access to shared rows.
alter table public.instruments add column if not exists owner_id uuid references public.profiles(id) on delete cascade;
drop policy if exists instruments_admin_write on public.instruments;
drop policy if exists instruments_read_authenticated on public.instruments;
create policy instruments_read_authenticated on public.instruments for select to authenticated
using (true);
create policy instruments_insert_owner on public.instruments for insert to authenticated
with check (owner_id = auth.uid() and public.is_approved(auth.uid()));
create policy instruments_update_owner on public.instruments for update to authenticated
using (owner_id = auth.uid() and public.is_approved(auth.uid()))
with check (owner_id = auth.uid() and public.is_approved(auth.uid()));
create policy instruments_delete_owner on public.instruments for delete to authenticated
using (owner_id = auth.uid() and public.is_approved(auth.uid()));

insert into public.instruments(symbol,name,asset_class,base_currency,quote_currency,verification_status,verification_notes)
values
('EURUSD','Euro / US Dollar','forex','EUR','USD','unverified','Verify symbol suffix, contract size, tick size/value and trading hours with broker.'),
('GBPUSD','British Pound / US Dollar','forex','GBP','USD','unverified','Verify broker contract and tick value.'),
('USDJPY','US Dollar / Japanese Yen','forex','USD','JPY','unverified','JPY pip value requires account-currency conversion.'),
('USDCHF','US Dollar / Swiss Franc','forex','USD','CHF','unverified','Verify broker contract and tick value.'),
('AUDUSD','Australian Dollar / US Dollar','forex','AUD','USD','unverified','Verify broker contract and tick value.'),
('NZDUSD','New Zealand Dollar / US Dollar','forex','NZD','USD','unverified','Verify broker contract and tick value.'),
('USDCAD','US Dollar / Canadian Dollar','forex','USD','CAD','unverified','Verify quote-currency conversion.'),
('EURGBP','Euro / British Pound','forex','EUR','GBP','unverified','Verify quote-currency conversion.'),
('EURJPY','Euro / Japanese Yen','forex','EUR','JPY','unverified','Verify quote-currency conversion.'),
('GBPJPY','British Pound / Japanese Yen','forex','GBP','JPY','unverified','Verify quote-currency conversion.'),
('AUDJPY','Australian Dollar / Japanese Yen','forex','AUD','JPY','unverified','Verify quote-currency conversion.'),
('EURAUD','Euro / Australian Dollar','forex','EUR','AUD','unverified','Verify quote-currency conversion.'),
('GBPAUD','British Pound / Australian Dollar','forex','GBP','AUD','unverified','Verify quote-currency conversion.'),
('GBPCAD','British Pound / Canadian Dollar','forex','GBP','CAD','unverified','Verify quote-currency conversion.'),
('USDZAR','US Dollar / South African Rand','forex','USD','ZAR','unverified','Exotic pair; check broker availability, spread and conversion.'),
('USDTRY','US Dollar / Turkish Lira','forex','USD','TRY','unverified','Exotic pair; check broker availability, spread and conversion.'),
('USDMXN','US Dollar / Mexican Peso','forex','USD','MXN','unverified','Exotic pair; check broker availability, spread and conversion.'),
('USDNGN','US Dollar / Nigerian Naira','forex','USD','NGN','unverified','Availability is broker-dependent; do not assume it is tradable.'),
('XAUUSD','Gold / US Dollar','commodity','XAU','USD','unverified','Contract size and point value vary by broker.'),
('XAGUSD','Silver / US Dollar','commodity','XAG','USD','unverified','Contract size and point value vary by broker.'),
('NAS100','US Tech 100 Index','index',null,'USD','unverified','Index contract and point value are broker-specific.'),
('US30','US Wall Street 30 Index','index',null,'USD','unverified','Index contract and point value are broker-specific.'),
('SPX500','US 500 Index','index',null,'USD','unverified','Index contract and point value are broker-specific.'),
('GER40','Germany 40 Index','index',null,'EUR','unverified','Index contract and point value are broker-specific.'),
('UK100','UK 100 Index','index',null,'GBP','unverified','Index contract and point value are broker-specific.'),
('BTCUSD','Bitcoin / US Dollar','crypto','BTC','USD','unverified','Crypto CFD contract and trading hours vary by provider.'),
('ETHUSD','Ethereum / US Dollar','crypto','ETH','USD','unverified','Crypto CFD contract and trading hours vary by provider.'),
('Volatility 10 Index','Deriv Volatility 10 Index','synthetic',null,null,'unverified','Confirm exact Deriv symbol and contract/stake rules.'),
('Volatility 25 Index','Deriv Volatility 25 Index','synthetic',null,null,'unverified','Confirm exact Deriv symbol and contract/stake rules.'),
('Volatility 50 Index','Deriv Volatility 50 Index','synthetic',null,null,'unverified','Confirm exact Deriv symbol and contract/stake rules.'),
('Volatility 75 Index','Deriv Volatility 75 Index','synthetic',null,null,'unverified','Confirm exact Deriv symbol and contract/stake rules.'),
('Volatility 100 Index','Deriv Volatility 100 Index','synthetic',null,null,'unverified','Confirm exact Deriv symbol and contract/stake rules.'),
('Crash 500 Index','Deriv Crash 500 Index','synthetic',null,null,'unverified','Confirm exact Deriv symbol and contract/stake rules.'),
('Boom 500 Index','Deriv Boom 500 Index','synthetic',null,null,'unverified','Confirm exact Deriv symbol and contract/stake rules.'),
('Step Index','Deriv Step Index','synthetic',null,null,'unverified','Confirm exact Deriv symbol and contract/stake rules.')
on conflict(symbol) do update set name=excluded.name,asset_class=excluded.asset_class,
 base_currency=excluded.base_currency,quote_currency=excluded.quote_currency,
 verification_notes=excluded.verification_notes;

-- Illustrative listed equities; add any other exchange-listed symbol from the UI.
insert into public.instruments(symbol,name,asset_class,base_currency,quote_currency,verification_status,verification_notes)
values
('AAPL','Apple Inc.','stock','USD','USD','unverified','Confirm exchange, CFD/share product, currency and broker symbol.'),
('MSFT','Microsoft Corporation','stock','USD','USD','unverified','Confirm exchange, CFD/share product, currency and broker symbol.'),
('NVDA','NVIDIA Corporation','stock','USD','USD','unverified','Confirm exchange, CFD/share product, currency and broker symbol.'),
('TSLA','Tesla Inc.','stock','USD','USD','unverified','Confirm exchange, CFD/share product, currency and broker symbol.'),
('AMZN','Amazon.com Inc.','stock','USD','USD','unverified','Confirm exchange, CFD/share product, currency and broker symbol.'),
('GOOGL','Alphabet Inc. Class A','stock','USD','USD','unverified','Confirm exchange, CFD/share product, currency and broker symbol.'),
('BP','BP plc','stock','GBP','GBP','unverified','Confirm London listing, currency and broker symbol.'),
('VOD','Vodafone Group plc','stock','GBP','GBP','unverified','Confirm London listing, currency and broker symbol.'),
('LLOY','Lloyds Banking Group plc','stock','GBP','GBP','unverified','Confirm London listing, currency and broker symbol.')
on conflict(symbol) do nothing;
