-- 02_cleaning.sql
-- Cleaning up the GA4 data based on what I found in 01_exploration.sql.
-- Keeping this separate so I don't mess up the raw data.

-- Decisions log:
-- 1. traffic_source.medium: '<Other>' and '(data deleted)' are huge chunks of data (~21%). 
--    Can't drop them, so just grouping them into 'Unknown' for now.
-- 2. geo.country: '(not set)' is small, but let's just dump it into 'Unknown' too for consistency.
-- 3. item.coupon: useless column, it's populated on every row. ignoring it downstream.
-- 4. Repurchase logic: switching to transaction_id. event_date was hiding multiple orders in one day.
-- 5. user_first_touch: sticking with user_first_touch_timestamp. first_visit event is flaky.
-- 6. Funnel timing: found 13 weird users where purchase < view_item. Flagging them, not deleting.
-- 7. Windows mobile: 15 rows. weird, but whatever. ignoring.
-- 8. Refunds: zero data. Q14 is impossible to answer.

---------------------------------------------------------------------------------------
-- VIEW 1: Base table with cleaned up labels
---------------------------------------------------------------------------------------
create or replace VIEW `ga4-ecommerce-analysis-504204.ga4_analysis.v_events_clean
` as
select
  e.*,

  -- grouping the junk values together
  case 
    when traffic_source.medium in ('<Other>', '(data deleted)') then 'Unknown'
    else traffic_source.medium 
  end as medium_clean,

  -- same for country, just keeping it consistent
  case 
    when geo.country = '(not set)' then 'Unknown'
    else geo.country 
  end as country_clean,

  -- flagging those 13 weird users who bought before viewing. 
  -- subquery is a bit heavy, but it works.
  user_pseudo_id in (
    select user_pseudo_id
    from (
      select
        user_pseudo_id,
        min(case when event_name = 'view_item' then event_timestamp end) as view_ts,
        min(case when event_name = 'purchase' then event_timestamp end) as buy_ts
      from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
      where _table_suffix is not null
      group by 1
    )
    where buy_ts is not null and view_ts is not null and buy_ts < view_ts
  ) as has_invalid_funnel_timing

from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` e
where _table_suffix is not null;


---------------------------------------------------------------------------------------
-- VIEW 2: Repurchasers
-- using transaction_id instead of event_date. 502 repurchasers total.
---------------------------------------------------------------------------------------
create or replace VIEW `ga4-ecommerce-analysis-504204.ga4_analysis.v_repurchasers` AS
select
  user_pseudo_id,
  count(distinct ecommerce.transaction_id) as distinct_transactions,
  count(distinct ecommerce.transaction_id) > 1 as is_repurchaser
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
where _table_suffix is not null
  and event_name = 'purchase'
group by 1;


---------------------------------------------------------------------------------------
-- VIEW 3: First touch
-- using the GA field, not the event. 
---------------------------------------------------------------------------------------
create or replace VIEW `ga4-ecommerce-analysis-504204.ga4_analysis.v_user_first_touch` AS
select
  user_pseudo_id,
  min(user_first_touch_timestamp) as first_touch_ts
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
where _table_suffix is not null
group by 1;


---------------------------------------------------------------------------------------
-- VALIDATION
-- run these to make sure I didn't break anything.
---------------------------------------------------------------------------------------

-- 1. check row counts. should be same as raw (4,295,584).
select count(*) from `ga4-ecommerce-analysis-504204.ga4_analysis.v_events_clean`;
-- row count is same, verified. 

-- 2. check if any junk values are still hiding in the clean columns
select medium_clean, count(*) 
from `ga4-ecommerce-analysis-504204.ga4_analysis.v_events_clean`
where medium_clean in ('<Other>', '(data deleted)')
group by 1;
-- all good here

select country_clean, count(*) 
from `ga4-ecommerce-analysis-504204.ga4_analysis.v_events_clean`
where country_clean = '(not set)'
group by 1;
-- good to go

-- 3. check the 'Unknown' bucket volume
select medium_clean, count(*)
from `ga4-ecommerce-analysis-504204.ga4_analysis.v_events_clean`
where medium_clean = 'Unknown'
group by 1;
-- Unknown buckets are 911399

-- 4. verify the 13 flagged users
select count(distinct user_pseudo_id) 
from `ga4-ecommerce-analysis-504204.ga4_analysis.v_events_clean`
where has_invalid_funnel_timing = true;
-- 13 is the output

-- 5. check repurchaser count (should be 502)
select count(*) 
from `ga4-ecommerce-analysis-504204.ga4_analysis.v_repurchasers`
where is_repurchaser = true;
-- 502

-- 6. check first touch uniqueness
select count(*), count(distinct user_pseudo_id)
from `ga4-ecommerce-analysis-504204.ga4_analysis.v_user_first_touch`;
-- 270154 both 



-- todo: maybe add a check for that windows/mobile thing later? skipping for now.