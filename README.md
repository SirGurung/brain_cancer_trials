# Brain Cancer Clinical Trials (2000–2025): Activity, Phases, Sponsors, Risk

**Goal.** Explore ClinicalTrials.gov brain cancer trials to understand activity over time, phase mix, who sponsors them, where trials fail, and how big successful trials are.

**Data Source.** ClinicalTrials.gov export (condition filter: *brain cancer*). Period restricted to 2000–2025 because registry coverage is reliable post-2000.  
> Please download the CSV yourself (instructions below); raw files are not included in this repo.

## Reproduce

1. Go to [ClinicalTrials.gov](https://clinicaltrials.gov/).  
2. In the search bar, enter **brain cancer** as the condition.  
3. Use the **Download** option (top-right) and choose **CSV** format.  
   - Include all available studies (2000–2025).  
   - Select fields such as:  
     - NCT Number  
     - Study Title  
     - Study Status  
     - Start Date  
     - Completion Date  
     - Enrollment  
     - Phase  
     - Sponsor  
     - Funder Type  
     - Conditions  
4. Place the downloaded CSV into the `data/raw/` folder of this repo.  
5. Run the notebooks in `/notebooks` to generate processed CSVs and figures (saved to `/figures`).  

⚠️ Note: ClinicalTrials.gov is updated daily, so your counts may differ slightly from those shown here.

## Key Decisions
- **Year window:** 2000–2025 (registry reliability + consistency across analyses).
- **Phase cleaning:** `NULL`, `NA`, `N/A` → `Unknown`. For performance plots, `Unknown` is excluded; for distribution plots it is shown to highlight data quality.
- **Status buckets:** Success = `COMPLETED`. Failure = `TERMINATED`, `WITHDRAWN`, `SUSPENDED`, `NO_LONGER_AVAILABLE`. Ongoing = recruiting variants. Rates computed only among terminal outcomes (Success/Failure).
- **Enrollment metric:** median preferred over mean (means skewed by a few very large studies).
- **Condition groups:** SQL `CASE WHEN` to aggregate messy free-text into buckets (glioblastoma, glioma, etc.); generic labels (e.g., “brain neoplasm”) shown separately.

## Results (highlights)
- **Activity:** Trials per year increased steadily from 2000–2024.  
- **Phase mix:** A striking share of trials are labelled **“Unknown phase”**; among classified trials, Phase 1 and 2 dominate.  
- **Sponsors:** Concentrated among major US cancer centers and government (e.g., NCI), with industry representation.  
- **Risk:** **Failure (termination/withdrawal) is highest in Early Phase 1 (~42%)**, drops through Phase 2 (~33%) and Phase 3 (~24%), lowest in Phase 4 (~19%).  
- **Size:** **Median enrollment grows with phase** (e.g., Phase 1 tens of patients; Phase 3 ~200).  
- **Subtypes:** After grouping synonyms, **glioblastoma** is the most studied specific subtype; many trials use general labels (“brain cancer/general” or other/unspecified), reflecting uneven condition reporting.

## Figures
See `/Notebook` for figure outputs. Each block in the notebook writes out the plot(s).

## Limitations
- Registry fields (Phase, Condition) are free-text or inconsistently used; “Unknown phase” and generic conditions are common.
- Status is a **snapshot**; some “ongoing” trials will later complete/terminate.
- Condition grouping via SQL patterns is approximate; a richer mapping could refine counts.

## License & Attribution
- Code: MIT
- Data: Derived from [ClinicalTrials.gov](https://clinicaltrials.gov/), maintained by the U.S. National Library of Medicine (NLM).  
  > Analyses and interpretations are solely my own and do not represent the views of NLM.
