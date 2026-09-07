## 2026-08-01

- Set up GCP project + BigQuery Sandbox, confirmed access via COUNT(*) query on ga4_obfuscated_sample_ecommerce (4.29M events, 270k users, 92 days)
- Surprised that BigQuery's Marketplace search and Gemini assistant can't find this dataset even though direct SQL access works.  So the data uncatalogued, not missing. Wrote this up properly in data_quality_notes.md.
- Learned starring a project is just a personal sidebar bookmark, doesn't grant or change access
- Next: write .gitignore for the project

## 2026-08-04

- Wrote .gitignore from scratch instead of copy pasting GitHub's template, went
  line by line through what each pattern does and cut everything that didn't apply
  to this stack (no PyInstaller, Django, Poetry, etc. Just kept Python cache, venv,
  Jupyter checkpoints, GCP credentials, Power BI lock files, CSVs)
- Learned .gitkeep isn't a real Git feature, just a convention to stop Git from
  ignoring empty folders. 
- Next: schema drill on events_* table and guess field/nesting
  structure before checking against the actual Schema tab

## 2026-08-16

- Went through the [GA4 Bigiquery Export schema reference] (https://support.google.com/analytics/answer/7029846)
- Understood `flat columns`, and `Record columns`. Record columns are of two types: structs and array of structs. 
- Understood the usage of UNNEST. 

- Next: Go through schema, preview and details of the dataset in bigquery

## 2026-08-17

- Explored `events_20201101` via Schema, Preview, and Details tabs in BigQuery console. 
- Identified flat colums (event_name, event_date, event_timestamp,event_previous_timestamp, and more)
- Identified Record columns (event_params, device, items, privacy_info and more)
- Ran the first UNNEST query on event_params after hitting "Cannot access field" error when tried to dot acess it. 

**what surprised me? :**  
- Mode = REPEATED in the schema tab is the real indicator of the need of UNNEST. The absence of a `.key` field doesn't mean UNNEST is not needed. 
*for instance: `items` is a record column with mode = REPEATED, it doesn't have `.key` field yet needs UNNEST to unpack it*

- Next: 
1. Confirm items really are multi valued using ARRAY_LENGTH()
2. Write correct UNNEST query for items using its own named fields, not .key/.values

## 2026-08-18

Ran ARRAY_LENGTH (items), Confirmed that multi-item purchases exist in the dataset. 
- Wrote and fixed UNNEST query for items (had made some aliasing bugs, all fixed now). 
- *pt 2 schema literacy completed.*
- Next: Start reading what story the data tells and ask relevant business questions. 

## 2026-08-21

- Studied AARRR (Acquisition, Activation, Rentention, Revenue, Referral) as the core framework for this dataset.
- Confirmed AARRR is suitable for GA4's event level , timestamped, user_pseudo_id-key structure. 

- Next: Draft questions across 5 AARRR stages

## 2026-08-22

- Ran the blind guess drill: wrote 5 guesses about the data before running any query. The questions being:
1. The traffic from referrals must be low (Assuming that few people refer merchandise to others)
2. Repurchases might be low as this is a merch shop 
3. Mobile users might make up more users hence traffic (Assuming people search ecomm sites often on their mobiles) 
4. Revenue generated from Desktop users might be more than Mobile users (Assuming people viewing on destops might be more intentional, and maybe are purchasing from desktop after viewing on mobile)
5. US might have larger revenue share as this is a US based merch store 
6. No. of items purchased might be 1-2 on average as this is a merch store not a grocery store. 
7. Revenue generated on weekends might be more than revenue generated on weekdays. 
8. The most difference in funnel (% drop in conversion) comes between add to cart and buy stages. 
*will check during exploration stage**

- Drafted questions across all 5 AARRR (Pirate Metrics framework) stages. (Covered Acquisition, Activation, Retention, Referral, Revenue)

**What surprised me:**
- AARRR and "descriptive/diagnostic/predictive/prescriptive" are orthogonal axes, not competing frameworks. (a real analysis usually would specify both)

## 2026-08-25

- Added 3 more blind guesses:
  6. No. of items purchased might be 1-2 on average as this is a merch store not a grocery store. 
  7. Revenue generated on weekends might be more than revenue generated on weekdays. 
  8. The most difference in funnel (% drop in conversion) comes between add to cart and buy stages. 
  -- confirmed blind guesses using SQL in 01_exploration.sql and noted down the verdicts of each guess
  
  -- what surprised me is that bigquery has a built-in day of week calculator (would have been cumbersome to calculate guess no. 7 without it)

  -- Next: Conclude 01_exploration.sql and hence the exploration in SQL by studying the data quality
  
## 2026-08-29
- find and replace all was used liberally and not as carefully, now, there is a big mess to clean (group by is cnt everywhere,... )
- Lesson learnt: commit even small changes to code to land in this situation. 
- Writing data profiling section again. 

## 2026-08-31
- profiling section done
- Next: Complete the exploration. 

## 2026-09-01
- completed exploration
- Key findings are: 
-   As no refund orders are present in the data ,AARRR_based_questions no. 14 is not needed now. 
-   15 windows + mobile rows exist
-   13 records with buy timestamp preceeding view timestamps
-   no duplicates exist, 
- Next: cleaning

## 2026-09-02
- before cleaning, decided to go through files and realized i need items_category cardinality for Q13, need to check whether repurchase id from 329 disagrees with transaction ids 

- Also, checked 810 distinct items from 22 categories and transaction id based repurchase count turns out to be 502 which disagrees with 329

## 2026-09-05
-  Created 3 views in 02_cleaning.sql namely: v_events_clean, v_repurchasers, v_user_first_touch. 

- Basically relabelled '<Other>', '(data deleted)' traffic medium; '(not set)' country as unknown , standardized transaction_id for repurchases and user_first_touch_ timestamp for first visit timing, fladding the users with absurd purchase before view timestamp. 

- Next: validation of cleaning

## 2026-09-06
- Ran the validation queries. Got expected values

- Filtered the AARRR questions to find the relevant ones and documented it in docs -> AARRR_based_questions.md

- Next: Build 03_metrics.sql against cleaned views.

## 2026-09-07
- upon validation of 03_metrics.sql queries, it was found that user_first_touch dates back to 2019 which corrupts the retention curve and analysis for first_visit_activation so rebuilt v_user_first_touch with min timestamp instead. 

- rerun that with fix, then run validation query 7 (date range check) and then rerun retention_curve and m_first_visit activation. 

-- validated metrics as well teh retention curve still returns bad dates, so would change v_user_first_touch and use event_date instead of event_timestamp now. 
-- m_retention_curve still looks funny

-- WHAT ACTUALLY HAPPENED: first theory was that timestamp could be corrupted, ruled that one out because event_timestamp and event_date always agreed. 
second theory was that event_date might be corrupted again ruled out as event_date and _table_suffix agreed too

Real cause was: create or replace table does not auto-refresh an upstream view changes. I had already fixed v_user_first_touch to use_event_date instead of teh timestamp field but kept viewing stale version of the m_retention_curve. 

- while reviewing all 8 exposed metric csvs before moving to python, found issues with m_category_performance_geo_device.csv, missed during 01_exploration and 02_cleaning. 

- next: look into this 



