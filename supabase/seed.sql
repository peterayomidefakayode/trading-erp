-- Safe starter catalogue only. Contract values remain unverified and must be checked per broker/platform.
insert into public.instruments(symbol,name,asset_class,base_currency,quote_currency,verification_status,verification_notes)
values
('EURUSD','Euro / US Dollar','forex','EUR','USD','unverified','Verify contract, tick value and volume rules with selected broker/platform.'),
('GBPUSD','British Pound / US Dollar','forex','GBP','USD','unverified','Verify contract, tick value and volume rules with selected broker/platform.'),
('USDJPY','US Dollar / Japanese Yen','forex','USD','JPY','unverified','JPY pip and account-currency conversion require broker verification.'),
('XAUUSD','Gold / US Dollar','commodity','XAU','USD','unverified','Gold contract sizes and tick values differ by broker/platform.'),
('XAGUSD','Silver / US Dollar','commodity','XAG','USD','unverified','Silver contract sizes and tick values differ by broker/platform.'),
('US30','US Wall Street 30','index',null,'USD','unverified','Index point value and contract size are broker-specific.'),
('NAS100','US Tech 100','index',null,'USD','unverified','Index point value and contract size are broker-specific.'),
('BTCUSD','Bitcoin / US Dollar','crypto','BTC','USD','unverified','Contract/lot definitions differ across venues.'),
('Volatility 10 Index','Volatility 10 Index','synthetic',null,null,'unverified','Deriv symbol, stake and payout/point mechanics require platform-specific verification.'),
('Volatility 25 Index','Volatility 25 Index','synthetic',null,null,'unverified','Deriv symbol, stake and payout/point mechanics require platform-specific verification.'),
('Volatility 50 Index','Volatility 50 Index','synthetic',null,null,'unverified','Deriv symbol, stake and payout/point mechanics require platform-specific verification.'),
('Volatility 75 Index','Volatility 75 Index','synthetic',null,null,'unverified','Deriv symbol, stake and payout/point mechanics require platform-specific verification.'),
('Volatility 100 Index','Volatility 100 Index','synthetic',null,null,'unverified','Deriv symbol, stake and payout/point mechanics require platform-specific verification.')
on conflict(symbol) do nothing;
