-- 03_metrics.sql
-- building the final tables for python and powerbi. 
-- keeping these as tables because i don't want to re-run the logic every time i open a dashboard.

-- dropping questions i decided to skip (check log.md for the reasoning):
-- q2, q4, q8, q10, q11, q12, q14.
-- q14 is a total bust, no refund data anywhere.

---------------------------------------------------------------------------------------
-- q1: channel performance
-- checking if the high-volume channels are actually converting well.
---------------------------------------------------------------------------------------
create or replace table `ga4-ecommerce-analysis-504204.ga4_analysis.m_channel_performance` as
select
  medium_clean,
  count(distinct user_pseudo_id) as total_visitors,
  count(distinct case when event_name = 'purchase' then user_pseudo_id end) as total_purchasers,
  safe_divide(
    count(distinct case when event_name = 'purchase' then user_pseudo_id end),
    count(distinct user_pseudo_id)
  ) as conversion_rate
from `ga4-ecommerce-analysis-504204.ga4_analysis.v_events_clean`
group by 1
order by total_visitors desc;


---------------------------------------------------------------------------------------
-- q3: daily patterns by geo
-- do people buy more on weekends? grouping countries so i don't get a massive list.
---------------------------------------------------------------------------------------
create or replace table `ga4-ecommerce-analysis-504204.ga4_analysis.m_daily_pattern_by_geo` as
select
  format_date('%A', parse_date('%Y%m%d', event_date)) as day_of_week,
  case
    when country_clean in ('United States', 'India', 'Canada', 'United Kingdom') then country_clean
    else 'Other'
  end as country_group,
  count(*) as total_events,
  count(distinct case when event_name = 'purchase' then user_pseudo_id end) as purchasers,
  sum(case when event_name = 'purchase' then ecommerce.purchase_revenue else 0 end) as revenue
from `ga4-ecommerce-analysis-504204.ga4_analysis.v_events_clean`
group by 1, 2
order by country_group, revenue desc;

--- check:
select count(*) from `ga4-ecommerce-analysis-504204.ga4_analysis.m_daily_pattern_by_geo`;
-- expected 35, got 35
---------------------------------------------------------------------------------------
-- q5: activation
-- what % of new users add to cart on day 1?
-- note: no session_id, so i'm just using 'same calendar day' as a proxy. 
-- it's not perfect, but it's the best i can do with this data.
---------------------------------------------------------------------------------------
create or replace table `ga4-ecommerce-analysis-504204.ga4_analysis.m_first_visit_activation` as
with first_day_events as (
  select
    e.user_pseudo_id,
    e.event_name,
    ft.first_touch_date
  from `ga4-ecommerce-analysis-504204.ga4_analysis.v_events_clean` e
  join `ga4-ecommerce-analysis-504204.ga4_analysis.v_user_first_touch` ft
    using (user_pseudo_id)
  where parse_date('%Y%m%d', e.event_date) = ft.first_touch_date
)
select
  count(distinct case when event_name = 'view_item' then user_pseudo_id end) as viewed_item_first_day,
  count(distinct case when event_name = 'add_to_cart' then user_pseudo_id end) as added_to_cart_first_day,
  safe_divide(
    count(distinct case when event_name = 'add_to_cart' then user_pseudo_id end),
    count(distinct case when event_name = 'view_item' then user_pseudo_id end)
  ) as view_to_cart_rate_first_day
from first_day_events;


---------------------------------------------------------------------------------------
-- q6: funnel by device and channel
-- looking at the drop-off from view -> cart -> purchase.
---------------------------------------------------------------------------------------
create or replace table `ga4-ecommerce-analysis-504204.ga4_analysis.m_funnel_by_device_channel` as
select
  device.category as device_category,
  medium_clean,
  count(distinct case when event_name = 'view_item' then user_pseudo_id end) as view_item_users,
  count(distinct case when event_name = 'add_to_cart' then user_pseudo_id end) as add_to_cart_users,
  count(distinct case when event_name = 'purchase' then user_pseudo_id end) as purchase_users
from `ga4-ecommerce-analysis-504204.ga4_analysis.v_events_clean`
where event_name in ('view_item', 'add_to_cart', 'purchase')
group by 1, 2
order by 1, 2;

-- check:
select * from `ga4-ecommerce-analysis-504204.ga4_analysis.m_funnel_by_device_channel` 
where purchase_users > add_to_cart_users or add_to_cart_users > view_item_users;
-- expected 0 rows, output: 0 rows 

---------------------------------------------------------------------------------------
-- q7: retention curve
-- cohort analysis. how many users come back after 1, 2, 3, 4 weeks?
---------------------------------------------------------------------------------------
create or replace table `ga4-ecommerce-analysis-504204.ga4_analysis.m_retention_curve` as
with user_activity as (
  select
    e.user_pseudo_id,
    ft.first_touch_date,
    parse_date('%Y%m%d', e.event_date) as activity_date
  from `ga4-ecommerce-analysis-504204.ga4_analysis.v_events_clean` e
  join `ga4-ecommerce-analysis-504204.ga4_analysis.v_user_first_touch` ft
    using (user_pseudo_id)
),
weeks_since as (
  select
    user_pseudo_id,
    date_trunc(first_touch_date, week) as cohort_week,
    div(date_diff(activity_date, first_touch_date, day), 7) as week_number
  from user_activity
)
select
  cohort_week,
  count(distinct user_pseudo_id) as cohort_size,
  count(distinct case when week_number = 1 then user_pseudo_id end) as active_week_1,
  count(distinct case when week_number = 2 then user_pseudo_id end) as active_week_2,
  count(distinct case when week_number = 3 then user_pseudo_id end) as active_week_3,
  count(distinct case when week_number = 4 then user_pseudo_id end) as active_week_4
from weeks_since
group by 1
order by 1;


---------------------------------------------------------------------------------------
-- q9: visits before purchase
-- how many days do they browse before buying?
-- using distinct active days as a proxy for "visit".
---------------------------------------------------------------------------------------
create or replace table `ga4-ecommerce-analysis-504204.ga4_analysis.m_visits_before_purchase` as
with first_purchase as (
  select user_pseudo_id, min(event_timestamp) as first_purchase_ts
  from `ga4-ecommerce-analysis-504204.ga4_analysis.v_events_clean`
  where event_name = 'purchase'
  group by 1
),
days_before as (
  select
    e.user_pseudo_id,
    count(distinct e.event_date) as active_days_before_purchase
  from `ga4-ecommerce-analysis-504204.ga4_analysis.v_events_clean` e
  join first_purchase fp using (user_pseudo_id)
  where e.event_timestamp <= fp.first_purchase_ts
  group by 1
)
select
  avg(active_days_before_purchase) as avg_active_days_before_purchase,
  approx_quantiles(active_days_before_purchase, 100)[offset(50)] as median_active_days_before_purchase
from days_before;


---------------------------------------------------------------------------------------
-- q13: category performance
-- which categories are hot in which country?
---------------------------------------------------------------------------------------
create or replace table `ga4-ecommerce-analysis-504204.ga4_analysis.m_category_performance_geo_device` as
select
  item.item_category,
  e.country_clean,
  e.device.category as device_category,
  sum(item.item_revenue) as total_revenue,
  count(distinct item.item_id) as distinct_items_sold
from `ga4-ecommerce-analysis-504204.ga4_analysis.v_events_clean` e,
unnest(e.items) as item
where e.event_name = 'purchase'
group by 1, 2, 3
order by total_revenue desc;


-- check:
select sum(total_revenue) from `ga4-ecommerce-analysis-504204.ga4_analysis.m_category_performance_geo_device`; 
-- 362110
---------------------------------------------------------------------------------------
-- q15: revenue distribution
-- just checking the spread of revenue. mean vs median.
---------------------------------------------------------------------------------------
create or replace table `ga4-ecommerce-analysis-504204.ga4_analysis.m_revenue_distribution` as
select
  min(ecommerce.purchase_revenue) as min_rev,
  max(ecommerce.purchase_revenue) as max_rev,
  avg(ecommerce.purchase_revenue) as mean_rev,
  approx_quantiles(ecommerce.purchase_revenue, 100)[offset(50)] as median_rev,
  approx_quantiles(ecommerce.purchase_revenue, 100)[offset(99)] as p99_rev
from `ga4-ecommerce-analysis-504204.ga4_analysis.v_events_clean`
where event_name = 'purchase';



--- 

-- validation_checks.sql
-- Run these after rebuilding m_retention_curve and m_first_visit_activation.
-- Note: I remember that these depend on the fixed v_user_first_touch, so if these fail, check that view first.

-- 1. m_channel_performance
-- Should be small, like 5 rows (organic, none, referral, cpc, etc.)
select count(*) as row_count
from `ga4-ecommerce-analysis-504204.ga4_analysis.m_channel_performance`;
-- is 5 rows

-- Eyeball check: conversion_rate should be 0-1.
select *
from `ga4-ecommerce-analysis-504204.ga4_analysis.m_channel_performance`
where conversion_rate < 0 or conversion_rate > 1;
-- If this returns anything, something is definitely broken.
-- is 0, all good

-- 2. m_daily_pattern_by_geo
-- 7 days * 5 country groups = 35 rows.
select count(*) as row_count
from `ga4-ecommerce-analysis-504204.ga4_analysis.m_daily_pattern_by_geo`;
-- 35 confirmed


-- Just making sure we didn't lose any countries
select count(DISTINCT country_group) as distinct_groups
from `ga4-ecommerce-analysis-504204.ga4_analysis.m_daily_pattern_by_geo`;
-- 5

-- 3. m_first_visit_activation
-- Should just be one row.
select *
from `ga4-ecommerce-analysis-504204.ga4_analysis.m_first_visit_activation`;
-- TODO: Check if view_to_cart_rate_first_day looks sane (not > 1).
-- its aobut 0.1771 so that is fine

-- 4. m_funnel_by_device_channel
-- Funnel logic: counts shouldn't grow as we go down the funnel.
-- purchase > add_to_cart is impossible.
SELECT *
from `ga4-ecommerce-analysis-504204.ga4_analysis.m_funnel_by_device_channel`
where purchase_users > add_to_cart_users
   or add_to_cart_users > view_item_users;
-- 0 rows

-- 5. m_retention_curve
-- Check dates first.
SELECT MIN(cohort_week) as earliest, MAX(cohort_week) as latest
from `ga4-ecommerce-analysis-504204.ga4_analysis.m_retention_curve`;
-- dates are sane

-- The nulls were annoying me last time, let's make sure they are gone.
SELECT count(*) as null_cohort_rows
from `ga4-ecommerce-analysis-504204.ga4_analysis.m_retention_curve`
where cohort_week is NULL;

-- nul_cohort_rows = 1

-- Retention decay check.
-- active_week_1 >= active_week_2 >= active_week_3...
-- If this isn't true, it's probably just a new cohort that doesn't have enough data yet.
SELECT *
from `ga4-ecommerce-analysis-504204.ga4_analysis.m_retention_curve`
where active_week_1 < active_week_2
   or active_week_2 < active_week_3
   or active_week_3 < active_week_4
order by cohort_week;


-- 6. m_visits_before_purchase
-- Should be 1 row.
SELECT *
from `ga4-ecommerce-analysis-504204.ga4_analysis.m_visits_before_purchase`;
-- avg_active_days_before_purchase should be a small number.
-- confirmed

-- 7. m_category_performance_geo_device
-- Summing revenue to see if it matches the exploration file.
-- Expected roughly 362165.
SELECT SUM(total_revenue) as grand_total_revenue
from `ga4-ecommerce-analysis-504204.ga4_analysis.m_category_performance_geo_device`;
-- confirmed

-- 8. m_revenue_distribution
-- Compare these to 01_exploration.sql. If they don't match, I probably messed up the filters again.
SELECT *
from `ga4-ecommerce-analysis-504204.ga4_analysis.m_revenue_distribution`;
-- values match with exploration
-- End of checks. If all these pass, the metrics should be good to go.