-- 01_exploration.sql
-- This file contains dataset shape, blind guess confirmation, field level profiling
-- and data quality checks. 

-- Dataset: Bigquery public data's GA4_obfuscated_sample_ecommerce
-- Date range: full dataset, November 2020 to January 2021


---------------------------------------------------------------------------------------
--EXPLORATION
---------------------------------------------------------------------------------------

-- date range of the data:
select min(_table_suffix) as earliest, max(_table_suffix) as latest
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
where _table_suffix is not null; 
-- earliest: 20201101	
-- latest: 20210131
-- so the dataset spans 3 months from nov 2020 to jan 2021

-- to understand the schema, used a single table out of the dataset
select * from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.INFORMATION_SCHEMA.COLUMNS`
where table_name = 'events_20201101';

-- distinct event types:
select DISTINCT(event_name) from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201101`; 

-- total users who had any event 
select count(DISTINCT(user_pseudo_id)) as total_users 
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
where _table_suffix is not null; 
-- 270154


---------------------------------------------------------------------------------------
-- CONFIRMATION OF BLIND GUESSES
---------------------------------------------------------------------------------------

-- GUESS 1. 
-- "The traffic from referrals must be low (Assuming that few people refer merchandise to others)"
-- traffic_medium has info on whether it was an organic event or referral
select traffic_source.medium, count(*) as event_count 
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
where _table_suffix is not null
group by traffic_source.medium order by event_count desc;  
-- VERDICT: INCORRECT GUESS
-- medium         |   count
-- organic	      |   1439399
-- (none)	      |   989684
-- referral	      |   778087
-- <Other>	      |   597482
-- (data deleted) |   313917
-- cpc	          |   177015
-- referral traffic is more than expected, 3rd highest. It is about 18% of the total
-- as 778087/4295584 = 0.181

-- GUESS 2. 
-- "Repurchases might be low as this is a merch shop"
-- 1. no. of people who repurchased
select count(*) as total_repurchasers 
from
(select user_pseudo_id, count(DISTINCT event_date) as days_active 
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
where event_name = 'purchase'
group by user_pseudo_id
having count(DISTINCT event_date) > 1); 
-- turns out to be 329
 

-- 2. no. of people who made any purchase:
select count(DISTINCT(user_pseudo_id)) as total_users 
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
where event_name = 'purchase'; 
-- turns out to be 4419

-- VERDICT: CORRECT ASSUMPTION
-- 329 people repurchased 2 or 3 times whereas the purchase events are 4419 for the whole dataset
-- so, about about 7% purchasers repurchase. 


-- GUESS 3.
-- "Mobile users might make up more users hence traffic (Assuming people search ecomm sites often on their mobiles)"
-- checking traffic across devices:
select device.category, count(*) as event_count
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` 
where _table_suffix is not null
group by device.category; 
-- VERDICT: INCORRECT ASSUMPTION,
-- Row	category	event_count
-- 1	desktop	    2498330
-- 2	mobile	    1704069
-- 3	tablet	    93185
-- turns out desktop traffic is more than any other traffic


-- GUESS 4. 
-- "Revenue generated from Desktop users might be more than Mobile users (Assuming people viewing on destops might be more intentional, and maybe are purchasing from desktop after viewing on mobile)"
select device.category, SUM(ecommerce.purchase_revenue) as total_revenue 
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
where event_name = 'purchase'
group by device.category;
-- VERDICT:  CORRECT ASSUMPTION
-- Row	category	total_revenue
-- 1	desktop	    208815.0
-- 2	mobile	    146768.0
-- 3	tablet	    6582.0
-- yes more revenue is generated from desktop users as compared to mobile users however its not a stark difference


-- GUESS 5
-- "US might have larger revenue share as this is a US based merch store "
select geo.country, SUM(ecommerce.purchase_revenue) as revenue
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
where event_name = 'purchase' 
group by geo.country
order by revenue desc; 
-- VERDICT: CORRECT ASSUMPTION
-- Row	country	          revenue
-- 1	United States	  160573.0
-- 2	India	          34986.0
-- 3	Canada	          32799.0
-- 4	United Kingdom	  11458.0
-- ...
-- yes, US generates highest revenue. 


-- GUESS 6. 
-- "No. of items purchased might be 1-2 on average as this is a merch store not a grocery store."
-- can count number of event_ids (not using distinct as one could buy 2 of something with same id) per purchase event
select AVG(item.quantity) as avg_item_quantity 
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
UNNEST(items) as item
where event_name = 'purchase'; 
-- VERDICT: CORRECT ASSUMPTION
-- average is 1.4606235936997749


-- GUESS 7.
-- "Revenue generated on weekends might be more than revenue generated on weekdays. "
-- (so, turns out bigquery has as built-in function to calculate day of week)
select 
format_date('%A', PARSE_DATE('%Y%m%d', event_date)) as day_of_week,
sum(ecommerce.purchase_revenue) as revenue
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
where _table_suffix is not null
and event_name = 'purchase'
group by day_of_week
order by revenue desc; 
-- VERDICT:  WRONG ASSUMPTION
-- Top 3 days of week with highest revenue are wednesdays and tuesdays followed by monday
-- so week start is when the sale is highest. Whereas weekends have the lowest revenue generation. 

-- Row	day_of_week	revenue
-- 1	Wednesday	63937.0
-- 2	Tuesday	    61970.0
-- 3	Monday	    61870.0
-- 4	Friday	    59281.0
-- 5	Thursday	49691.0
-- 6	Saturday	38412.0
-- 7	Sunday	    27004.0	


-- GUESS 8. 
-- "The most difference in funnel (% drop in conversion) comes between add to cart and buy stages."
-- Need distinct user counts at each funnel step to compare
select event_name, count(distinct(user_pseudo_id)) as users
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
where event_name in ('view_item', 'add_to_cart', 'purchase')
group by event_name; 
-- VERDICT: INCORRECT ASSUMPTION
-- Row  Event_name  Users
-- 1	view_item	61252
-- 2	purchase	4419
-- 3	add_to_cart	12545	

-- drop off % = (step A users - step B users / step A users )*100
-- view_item to add_to_cart: 79.5% drop
-- add_to_cart to purchase: 64.8% drop

-- note to self: the sequential steps % i was doing: (no. add to cart/no view item) *100 was retention rate or conversion rate, not drop off %


---------------------------------------------------------------------------------------
-- FIELD LEVEL PROFILING 
---------------------------------------------------------------------------------------

-- Quick check on event_params keys. Just want to see what we're working with.
select ep.key, count(*) as cnt
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
UNNEST(event_params) AS ep
where _table_suffix is not null
group by 1 order by 2 desc limit 30;

-- o/p is: UNNESt(event_params) and their counts, run command again in bigquery to view it 
-- note: would try to skip lengthy outputs to avoid the file from becoming cumbersome. 


-- Checking nulls. Are these fields even populated?
select
  countif(user_id is null) AS null_user_id,
  countif(user_pseudo_id is null) AS null_pseudo_id,
  countif(geo.country is null) AS null_country,
  countif(device.category is null) AS null_device,
  countif(traffic_source.medium is null) AS null_medium,
  count(*) AS total_rows
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
where _table_suffix is not null;

-- Cardinality check
select
  count(DISTINCT device.category) as devices,
  count(DISTINCT geo.country) as countries,
  count(DISTINCT traffic_source.medium) as mediums,
  count(DISTINCT event_name) as events
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
where _table_suffix is not null;

-- Revenue stuff. Is there weird outlier data?
select
  MIN(ecommerce.purchase_revenue) as min_rev,
  MAX(ecommerce.purchase_revenue) as max_rev,
  AVG(ecommerce.purchase_revenue) as avg_rev,
  APPROX_QUANTILES(ecommerce.purchase_revenue, 100)[OFFSET(50)] as med_rev
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
where event_name = 'purchase' and _table_suffix is not null;

-- min_rev	max_rev	    avg_rev    	med_rev
-- 1.0	    1530.0	    69.0890	    48.0

-- Wait, check item quantity too.
select
  MIN(item.quantity) as min_qty,
  MAX(item.quantity) as max_qty,
  APPROX_QUANTILES(item.quantity, 100)[OFFSET(50)] as med_qty
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
UNNEST(items) AS item
where event_name = 'purchase' and _table_suffix is not null;

-- 	min_qty	   max_qty	med_qty
-- 	1	       160	      1


-- === Round 2:  digging deeper ===

-- Check user_properties for segments
select up.key, count(*) as cnt
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
UNNEST(user_properties) AS up
where _table_suffix is not null
group by 1 order by 2 desc limit 30;

-- 136 users have user_properties and they all have key null (expected from an obfuscated data) 

-- Is event_previous_timestamp useful?
select countif(event_previous_timestamp is null) as null_count, count(*) as total
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
where _table_suffix is not null;
-- oddly, "as nulls" kept giving syntax error, didn't expect that
-- now changed to null_count
-- its 4295584

-- Privacy info - do we have consent data?
select privacy_info.analytics_storage, privacy_info.ads_storage, count(*) as cnt
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
where _table_suffix is not null
group by 1, 2;

-- First touch vs first visit. Do they match?
-- (Self-note: If these don't match, the logic for user acquisition is gonna be a pain)
WITH ft AS (
  select user_pseudo_id, MIN(user_first_touch_timestamp) as ts
  from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  where _table_suffix is not null group by 1
),
fv AS (
  select user_pseudo_id, MIN(event_timestamp) as ts
  from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  where _table_suffix is not null and event_name = 'first_visit' group by 1
)
select count(*) as diffs
from ft JOIN fv USING(user_pseudo_id)
where ft.ts != fv.ts;

-- 548

-- Device language check
select device.language, count(*) as cnt
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
where _table_suffix is not null
group by 1 order by 2 desc limit 20;
-- english variants and zh are predominantly used. 

-- Timezone offsets (needed for local time adjustments later)
select MIN(device.time_zone_offset_seconds), MAX(device.time_zone_offset_seconds)
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
where _table_suffix is not null;
-- all null, field is null, won't use this

-- Check if this is web-only or if there's app data mixed in
select platform, count(*) from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
where _table_suffix is not null group by 1;
-- web, 4295584	

-- Refund check
select
  countif(ecommerce.refund_value_in_usd is not null) as refund_events,
  SUM(ecommerce.refund_value_in_usd) as total_refund
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
where _table_suffix is not null;
-- 0 refund events in this dataset. 

-- TODO: Check if coupons exist at all.
select countif(item.coupon is not null) as coupons
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
UNNEST(items) AS item
where _table_suffix is not null;
-- 3982732

---------------------------------------------------------------------------------------
-- DATA QUALITY CHECKS
-- Mostly just making sure the data isn't lying to me before I start building stuff.
---------------------------------------------------------------------------------------

-- Daily row counts - if one day is tiny, something probably broke in the pipeline.
select _table_suffix AS day, count(*) as cnt
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
where _table_suffix is not null
group by 1 order by 1;
-- all are comparable, 

-- Check for dupes. If this returns anything, my counts are gonna be wrong.
select user_pseudo_id, event_name, event_timestamp, count(*) as cnt
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
where _table_suffix is not null
group by 1, 2, 3
having count(*) > 1
limit 20;
-- no dupes here

-- How often do users jump between devices? 
-- (Just curious if I can treat device as a static property or if it's messy)
select user_pseudo_id, count(DISTINCT device.category) as dev_types
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
where _table_suffix is not null
group by 1
having count(DISTINCT device.category) > 1
limit 20;
-- cannot because a user_pseudo_id has instances of using different devices (usually 2)

-- Sanity check: Does mobile/desktop match the OS? 
-- (If I see "mobile" + "Windows", something is definitely weird)
select device.category, device.operating_system, count(*) as cnt
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
where _table_suffix is not null
group by 1, 2 order by 3 desc;
--	mobile	Windows	15 (wasn't really expecting to find it)
-- rest looks fine. 


-- Funnel logic: Can someone purchase before they view an item?
-- (If this returns rows, the event timestamps are definitely messed up)
WITH funnel AS (
  select
    user_pseudo_id,
    MIN(CASE WHEN event_name = 'view_item' THEN event_timestamp END) as view_ts,
    MIN(CASE WHEN event_name = 'purchase' THEN event_timestamp END) as buy_ts
  from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  where _table_suffix is not null
  group by 1
)
select * from funnel
where buy_ts is not null and view_ts is not null and buy_ts < view_ts;

-- I see 13 such records

-- Checking for junk values in traffic source. 
-- Note: '(data deleted)' shows up a lot, need to filter that out later.
select traffic_source.medium, count(*) as cnt
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
where _table_suffix is not null
  and traffic_source.medium IN ('<Other>', '(data deleted)')
group by 1;

-- 	medium	            cnt
-- <Other>	          597482
-- (data deleted)	    313917

-- Same junk check but for geo.
select geo.country, count(*) as cnt
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
where _table_suffix is not null
  and geo.country in ('<Other>', '(not set)')
group by 1;

--	country	   cnt
-- (not set)	32208