-- ==========================================================
-- Brain Cancer Clinical Trials — Master Queries (SQLite)
-- Source: ClinicalTrials.gov export loaded as table: brain_cancer_trials
-- Author: Adesh Gurung
-- ==========================================================

/* Quick schema peek */
SELECT * FROM brain_cancer_trials LIMIT 10;
PRAGMA table_info(brain_cancer_trials);

/* Total trials and uniqueness check */
SELECT COUNT(*) AS total_rows FROM brain_cancer_trials;

SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT "NCT Number") AS unique_ids
FROM brain_cancer_trials;

/* Phase values present (raw) */
SELECT DISTINCT Phases FROM brain_cancer_trials;

/* Earliest and latest start dates (strings) */
SELECT MIN("Start Date") AS min_start, MAX("Start Date") AS max_start
FROM brain_cancer_trials;

/* ----------------------------------------------------------
   Q1. Trials started per year (2000–2025)
   ---------------------------------------------------------- */
WITH base AS (
  SELECT
    SUBSTR("Start Date", 1, 4) AS start_year
  FROM brain_cancer_trials
)
SELECT start_year AS year,
       COUNT(*)   AS n_trials
FROM base
WHERE start_year BETWEEN '2000' AND '2024'
GROUP BY start_year
ORDER BY start_year;

/* ----------------------------------------------------------
   Q2. Phase distribution (with Unknown)
   ---------------------------------------------------------- */
SELECT
  CASE
    WHEN Phases IS NULL OR Phases IN ('NA','N/A','') THEN 'Unknown'
    ELSE Phases
  END AS clean_phase,
  COUNT(*) AS n_trials
FROM brain_cancer_trials
WHERE SUBSTR("Start Date",1,4) BETWEEN '2000' AND '2024'
GROUP BY clean_phase
ORDER BY n_trials DESC;

/* ----------------------------------------------------------
   Q3. Top sponsors driving trials
   ---------------------------------------------------------- */
SELECT 
  CASE
    WHEN Sponsor IS NULL OR Sponsor IN ('NA','N/A','') THEN 'Unknown'
    ELSE Sponsor
  END AS clean_sponsor,
  COUNT(*) AS number_of_studies_sponsored
FROM brain_cancer_trials
WHERE SUBSTR("Start Date",1,4) BETWEEN '2000' AND '2024'
GROUP BY clean_sponsor
ORDER BY number_of_studies_sponsored DESC
LIMIT 30;

/* ----------------------------------------------------------
   Status summary (for Q4–Q6 buckets)
   ---------------------------------------------------------- */
SELECT "Study Status", COUNT(*) AS n_trials
FROM brain_cancer_trials
GROUP BY "Study Status"
ORDER BY n_trials DESC;

/* ----------------------------------------------------------
   Common filtered view (phase/status/year/enrollment)
   ---------------------------------------------------------- */
DROP VIEW IF EXISTS filtered;
CREATE TEMP VIEW filtered AS
SELECT
  CASE
    WHEN "Study Status" = 'COMPLETED' THEN 'Success'
    WHEN "Study Status" IN ('TERMINATED','WITHDRAWN','SUSPENDED','NO_LONGER_AVAILABLE') THEN 'Failure'
    WHEN "Study Status" IN ('RECRUITING','ACTIVE_NOT_RECRUITING','NOT_YET_RECRUITING','ENROLLING_BY_INVITATION') THEN 'Ongoing'
    ELSE 'Other'
  END AS status_bucket,
  CASE
    WHEN Phases IS NULL OR Phases IN ('NA','N/A','') THEN 'Unknown'
    ELSE Phases
  END AS clean_phase,
  SUBSTR("Start Date",1,4) AS start_year,
  Enrollment AS enrollment
FROM brain_cancer_trials
WHERE SUBSTR("Start Date",1,4) BETWEEN '2000' AND '2025';

/* ----------------------------------------------------------
   Q4a. Counts by status (Success / Failure / Ongoing / Other)
   ---------------------------------------------------------- */
SELECT status_bucket, COUNT(*) AS n_trials
FROM filtered
GROUP BY status_bucket
ORDER BY n_trials DESC;

/* ----------------------------------------------------------
   Q5. Failure rate by phase (considering Success+Failure only)
   ---------------------------------------------------------- */
SELECT
  clean_phase,
  SUM(status_bucket='Failure') AS n_fail,
  SUM(status_bucket='Success') AS n_success,
  ROUND(
    1.0 * SUM(status_bucket='Failure') /
    NULLIF(SUM(CASE WHEN status_bucket IN ('Failure','Success') THEN 1 ELSE 0 END), 0)
  , 3) AS fail_rate
FROM filtered
GROUP BY clean_phase
ORDER BY fail_rate DESC;

/* ----------------------------------------------------------
   Q6a. Average enrollment for Completed vs Terminated
   (directly answers “Completed vs Terminated vs Ongoing?”)
   ---------------------------------------------------------- */
SELECT
  status_bucket,
  COUNT(*) AS n_trials,
  ROUND(AVG(enrollment), 1) AS avg_enrollment
FROM filtered
WHERE status_bucket IN ('Success','Failure')
  AND enrollment IS NOT NULL AND enrollment > 0
GROUP BY status_bucket
ORDER BY status_bucket;

/* ----------------------------------------------------------
   Q6b. Median enrollment by phase for successful trials
   (uses window trick; median of 1 or 2 middle rows)
   ---------------------------------------------------------- */
SELECT
  clean_phase,
  ROUND(AVG(enrollment * 1.0), 1) AS median_enrollment
FROM (
  SELECT
    clean_phase,
    enrollment,
    ROW_NUMBER() OVER (PARTITION BY clean_phase ORDER BY enrollment) AS rn,
    COUNT(*)    OVER (PARTITION BY clean_phase)                       AS cnt
  FROM filtered
  WHERE status_bucket = 'Success'
    AND enrollment IS NOT NULL
    AND enrollment > 0
)
WHERE rn IN (
  CAST((cnt + 1) / 2 AS INT),   -- lower middle
  CAST((cnt + 2) / 2 AS INT)    -- upper middle (same when cnt is odd)
)
GROUP BY clean_phase
ORDER BY median_enrollment DESC;

/* ----------------------------------------------------------
   Subtype distribution via heuristic mapping
   ---------------------------------------------------------- */
SELECT 
  CASE
    WHEN LOWER(Conditions) LIKE '%glioblastoma%' OR LOWER(Conditions) LIKE '%gbm%' THEN 'glioblastoma'
    WHEN LOWER(Conditions) LIKE '%astrocytoma%' THEN 'astrocytoma'
    WHEN LOWER(Conditions) LIKE '%oligodendroglioma%' THEN 'oligodendroglioma'
    WHEN LOWER(Conditions) LIKE '%medulloblastoma%' THEN 'medulloblastoma'
    WHEN LOWER(Conditions) LIKE '%meningioma%' THEN 'meningioma'
    WHEN LOWER(Conditions) LIKE '%ependymoma%' THEN 'ependymoma'
    WHEN LOWER(Conditions) LIKE '%glioma%' THEN 'glioma'
    WHEN LOWER(Conditions) LIKE '%brain neoplasm%' OR LOWER(Conditions) LIKE '%brain tumor%' OR LOWER(Conditions) LIKE '%malignant brain%' THEN 'brain cancer (general)'
    ELSE 'other/unspecified'
  END AS condition_group,
  COUNT(*) AS n_trials
FROM brain_cancer_trials
GROUP BY condition_group
ORDER BY n_trials DESC;

