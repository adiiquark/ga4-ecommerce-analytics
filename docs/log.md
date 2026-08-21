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