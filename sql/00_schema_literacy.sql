
-- the goal is to use sql to verify what is understood by reading schema preview of the dataset.
-- Also, Flat columns and Record columns are explored and outputs are viewed to understand behavior
-- of different types of columns.  

------------------------
-- Viewing flat columns
------------------------
select event_name from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201101`
LIMIT 5; -- flat columns show like this

-------------------------------------------------------------------------------------------------------
-- Viewing ARRAY<STRUCT> (repeated record) fields, and using UNNEST() to flatten them to queryable rows
-------------------------------------------------------------------------------------------------------
-- 1. event_params
select event_name ,event_params from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201101`
LIMIT 5; -- array of structs, repeated records 

select event_params.page_location from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201101`
LIMIT 5; -- Cannot access field page_location on a value with type ARRAY<STRUCT<key STRING, value STRUCT<string_value STRING, int_value INT64, float_value FLOAT64, ...>>> at [1:21] 

select event_name, ep.key, ep.value.string_value
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201101`,
UNNEST(event_params) as ep
limit 20; -- UNNEST event_params

-- 2. items
select event_name, items
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201101`
where event_name = 'purchase'
limit 20; -- array of structs -- fixed fields, no .key/.value


select event_name, i.key, i.value.string_value
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201101`,
UNNEST(items) as i limit 20; -- UNNEST items -- error: field_name.key does not exist

select event_name, i.item_id, i.item_name, i.price
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201101`,
UNNEST(items) as i limit 20; -- UNNEST items, -- fixed fields, no .key/.value needed

-- Confirming items is genuinely multi-valued
select event_name, ecommerce.transaction_id, ARRAY_LENGTH(items) as num_items
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201101`
where event_name = 'purchase'
order by num_items desc
limit 10; -- confirms items can have >1 element per purchase

------------------------------------------------
-- struct (not repeated) eg: device
------------------------------------------------
select device from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201101`
LIMIT 5; -- struct 

select device.category from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201101`
LIMIT 5; -- Struct (not array) so dot access works fine, UNNEST is not needed. 




