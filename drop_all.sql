-- Drops every GearShare table so gsadmin.sql can be loaded into a database that
-- already has one. Kept separate from gsadmin.sql on purpose: loading the seed must
-- never destroy data on its own.
--
--   docker run --rm -v "D:/Antonio/gear-share/2_2_gear_share_db:/sql" postgres:16 --     psql "<connection-string>" -f /sql/drop_all.sql -f /sql/gsadmin.sql

DROP TABLE IF EXISTS reservation CASCADE;
DROP TABLE IF EXISTS advertisement CASCADE;
DROP TABLE IF EXISTS payment CASCADE;
DROP TABLE IF EXISTS report CASCADE;
DROP TABLE IF EXISTS stripe_connect_account CASCADE;
DROP TABLE IF EXISTS subscription_price CASCADE;
DROP TABLE IF EXISTS itemtype CASCADE;
DROP TABLE IF EXISTS account CASCADE;

DROP FUNCTION IF EXISTS check_trader_role() CASCADE;
