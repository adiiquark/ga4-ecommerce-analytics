



---------------------------------------------------------------------------------------
--EXPLORATION
---------------------------------------------------------------------------------------
SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'events_20201101';

-- need to check type of events so:
select DISTINCT(event_name) from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201101`; 

-- total users who had any event:
select COUNT(DISTINCT(user_pseudo_id)) as total_users 
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
where _table_suffix between '20201101' and '20201130'; 
-- 79421
---------------------------------------------------------------------------------------
-- CONFIRMATION OF BLIND GUESSES
---------------------------------------------------------------------------------------

-- GUESS 1. 
-- "The traffic from referrals must be low (Assuming that few people refer merchandise to others)"
-- traffic_medium has info on whether it was an organic event or referral
select traffic_source.medium, COUNT(*) as event_count 
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
where _table_suffix between '20201101' and '20201130'
group by traffic_source.medium order by event_count desc;  
-- VERDICT: 
-- medium         |   count
-- organic	      |   496289
-- (none)	      |   334787
-- referral	      |   267501
-- <Other>	      |   204123
-- (data deleted) |   109133
-- cpc	          |   60879	
-- GUESS : INCORRECT
-- referral traffic is more than expected, 3rd highest. It is about 18% of the total


-- GUESS 2. 
-- "Repurchases might be low as this is a merch shop"
-- 1. no. of people who repurchased
select user_pseudo_id, COUNT(DISTINCT(event_date)) as days_active 
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
where _table_suffix between '20201101' and '20201130' and event_name = 'purchase'
group by user_pseudo_id
having COUNT(DISTINCT(event_date)) > 1; 
-- turns out to be 50 

-- 2. no. of people who made any purchase:
select COUNT(DISTINCT(user_pseudo_id)) as total_users 
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
where _table_suffix between '20201101' and '20201130'
and event_name = 'purchase'; 
-- turns out to be 1532

-- VERDICT: CORRECT ASSUMPTION
-- 50 people repurchased 2 or 3 times whereas the purchase events are 1532 in month of November
-- so, about about 3% purchasers repurchase. 


-- GUESS 3.
-- "Mobile users might make up more users hence traffic (Assuming people search ecomm sites often on their mobiles)"
-- checking traffic across devices:
select device.category, COUNT(*) as event_count
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` 
where _table_suffix between '20201101' and '20201130'
group by device.category; 
-- VERDICT: INCORRECT ASSUMPTION,
-- Row	category	event_count
-- 1	desktop	    849334
-- 2	mobile	    590494
-- 3	tablet	    32884
-- turns out desktop traffic is more than any other traffic


-- GUESS 4. 
-- "Revenue generated from Desktop users might be more than Mobile users (Assuming people viewing on destops might be more intentional, and maybe are purchasing from desktop after viewing on mobile)"
select device.category, SUM(ecommerce.purchase_revenue) as total_revenue 
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
where event_name = 'purchase'
and _table_suffix between '20201101' and '20201130'
group by device.category;
-- VERDICT:  CORRECT ASSUMPTION
-- Row	category	total_revenue
-- 1	desktop	    79289.0
-- 2	mobile	    62087.0
-- 3	tablet	    2884.0
-- yes more revenue is generated from desktop users as compared to mobile users however its not a stark difference


-- GUESS 5
-- "US might have larger revenue share as this is a US based merch store "
select geo.country, SUM(ecommerce.purchase_revenue) as revenue
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
where event_name = 'purchase' and 
_table_suffix between '20201101' and '20201130'
group by geo.country
order by revenue desc; 
-- VERDICT: CORRECT ASSUMPTION
-- Row	country	          revenue
-- 1	United States	  65797.0
-- 2	India	          13132.0
-- 3	Canada	          12729.0
-- 4	United Kingdom	  3492.0
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
where _table_suffix between '20201101' and '20201130'
and event_name = 'purchase'
group by day_of_week; 
-- VERDICT:  


-- GUESS 8. 
-- "The most difference in funnel (% drop in conversion) comes between add to cart and buy stages."
-- Need distinct user counts at each funnel step to compare
select event_name, count(distinct(user_pseudo_id)) as users
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
where _table_suffix between '20201101' and '20201130'
and event_name in ('view_item', 'add_to_cart', 'purchase')
group by event_name; 
-- VERDICT: INCORRECT ASSUMPTION
-- Row	event_name	users
-- 1	view_item	21440
-- 2	purchase	1532
-- 3	add_to_cart	2060
-- view_item to add_to_cart: 90.4% drop
-- add_to_cart to purchase: 25.6% drop