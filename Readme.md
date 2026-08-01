# GA4 Ecommerce Analytics

**Status:** In progress, early setup and exploration phase.

## What this is
An end-to-end analytics project using Google's public GA4 obfuscated sample ecommerce
dataset (Google Merchandise Store, Nov 2020–Jan 2021) in BigQuery. The goal is to
practice framing real business questions, answer them in SQL, and document findings
the way an analyst would on the job — not just run queries for their own sake.

## Dataset
- Source: `bigquery-public-data.ga4_obfuscated_sample_ecommerce`
- Format: GA4 BigQuery event export (`events_*` tables, one per day)
- Coverage: 92 days, ~4.29M events, ~270k distinct users

## Tools
- BigQuery (SQL, sandbox/free tier)
- Python (pandas, matplotlib/seaborn) — planned, for EDA on aggregated results
- Looker Studio / Power BI — planned, for final dashboard

## Project structure
sql/  exploration, cleaning, and metric queries, in that order
notebooks/  Python EDA on aggregated BigQuery outputs
docs/  running log, data dictionary, data quality notes
outputs/  exported charts and dashboard screenshots

**Note:**

This project uses Google's publicly available GA4 obfuscated sample ecommerce dataset (bigquery-public-data.ga4_obfuscated_sample_ecommerce), provided via the BigQuery Public Datasets program for exploration and learning.