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