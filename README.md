# SDTM Reporting with Data Quality Validation
## Clinical Data Management Portfolio Project (CDM101)

**Author:** Clinical Data Management Portfolio 

---

## 📋 Project Overview

This is a **complete end-to-end SDTM implementation** demonstrating:
- ✅ Clinical data import and standardization
- ✅ **26 automated validation rules** across 4 domains
- ✅ SDTM domain construction (DM, VS, AE, LB) following CDISC standards
- ✅ Data quality flagging and separate DQ report
- ✅ Clinical Study Report (CSR) tables and listings
- ✅ Professional RTF output for regulatory submissions


## 🎯 Quick Start

### Prerequisites
```
✓ SAS 9.4 or higher
✓ Read/write access to file system
✓ 4 source CSV files (demographics, vitals, adverse_events, lab_results)
```

### Run the Program
```sas
%LET sourcepath = C:\clinical_data;    /* Update path to your data */
%LET sdtmpath   = C:\sdtm_output;
%LET reportpath = C:\reports;

%INCLUDE "SDTM_Reporting_Updated.sas";
```

### Expected Output
Two RTF files will be generated:
1. **clinical_study_tables.rtf** — CSR tables/listings for submission
2. **data_quality_report.rtf** — Detailed validation results

---

## 📊 What Gets Validated? (26 Checks)

### Demographics (5 Checks)
| Check | Rule | Flag | Action |
|-------|------|------|--------|
| 1 | Age present | `DQ_AGE_MISSING` | Query if missing |
| 2 | Age 18-100 years | `DQ_AGE_RANGE` | Investigate outliers |
| 3 | Sex = M or F | `DQ_SEX_INVALID` | Standardize values |
| 4 | Enrollment date present | `DQ_ENROLL_MISSING` | Required for visit windows |
| 5 | Subject ID unique | Detected in PROC SORT | Report duplicates |

**Rationale:**
- Age: Lower bound = enrollment criterion; upper bound = outlier detector
- Sex: Standard CDISC values (M/F)
- Enrollment date: Reference point for all visit windows

---

### Vital Signs (12 Checks)

**Missing Value Checks (4):**
```
✓ Systolic BP present
✓ Diastolic BP present
✓ Heart Rate present
✓ Temperature present
```

**Range Validation (4):**
| Parameter | Range | Flag | Rationale |
|-----------|-------|------|-----------|
| Systolic BP | 70-250 mmHg | `DQ_SYSTOLIC_RANGE` | <70 = shock; >250 = hypertensive crisis |
| Diastolic BP | 40-150 mmHg | `DQ_DIASTOLIC_RANGE` | Physiologic extremes |
| Heart Rate | 30-220 bpm | `DQ_HR_RANGE` | <30 = bradycardia; >220 = extreme |
| Temperature | 34-42°C | `DQ_TEMP_RANGE` | <34 = hypothermia; >42 = fever |

**Logic Checks (2):**
```
✓ Diastolic BP < Systolic BP (catches transposed values)
✓ Visit Date not missing
```

**Portfolio Value:** "I implemented 12 validation checks on vital signs including 
physiologic range validation and BP logic checks. This caught one subject with 
diastolic=120/systolic=80 (reversed values) that would have been missed by 
simple range checks."

---

### Adverse Events (5 Checks)

| Check | Rule | Flag | Standard |
|-------|------|------|----------|
| 1 | AE term present | `DQ_TERM_MISSING` | ICH-GCP requirement |
| 2 | Start date present | `DQ_START_MISSING` | Essential for temporal analysis |
| 3 | Severity present | `DQ_SEVERITY_MISSING` | MedDRA coding prerequisite |
| 4 | Severity ∈ {MILD, MODERATE, SEVERE} | `DQ_SEVERITY_INVALID` | CDISC standard values |
| 5 | End date ≥ Start date | `DQ_DATE_LOGIC` | Data integrity |

**Example Catches:**
- Missing severity → Cannot code with MedDRA
- End before start → Dates transposed or entered incorrectly
- Invalid values → "Grade 1", "MINOR" standardized to MILD/MODERATE/SEVERE

---

### Laboratory Results (4 Checks)

| Check | Rule | Flag | Purpose |
|-------|------|------|---------|
| 1 | Result present | `DQ_RESULT_MISSING` | Cannot analyze missing labs |
| 2 | Unit present | `DQ_UNIT_MISSING` | Result meaningless without unit |
| 3 | Result is numeric | Implicit in data type | Non-numeric results (e.g., ">500") need coding |
| 4 | Reference range indicator | `LBNRIND` | Auto-derive LOW/NORMAL/HIGH |

**Auto-Derived LBNRIND Logic:**
```
IF RESULT < NORMAL_LOW  → "LOW"
IF RESULT > NORMAL_HIGH → "HIGH"
ELSE                    → "NORMAL"
```

---



---

## 🔧 Program Flow

```
STEP 1: IMPORT
  CSV → SAS datasets (4 source tables)
       
STEP 2: VALIDATE & FLAG
  Each domain gets validation checks
  Binary flags created (1=issue, 0=ok)
  
STEP 3: CREATE SDTM DOMAINS
  DM:  Demographics (one record/subject)
  VS:  Vital Signs (wide→long format, 5 measurements per visit)
  AE:  Adverse Events (one record per event, sequenced)
  LB:  Lab Results (one record per subject/visit/test)
  
STEP 4: GENERATE REPORTS
  clinical_study_tables.rtf  ← CSR format (Tables 14.1-14.3)
  data_quality_report.rtf    ← Validation details
```

---

## 📊 Output File Descriptions

### clinical_study_tables.rtf

**Table 14.1.1** — Subject Disposition by Site and Arm
- Cross-tabulation: SITE_ID × ARM
- Shows enrollment distribution across sites

**Table 14.1.2** — Demographic Characteristics
- Age: N, Mean, Std, Min, Max by arm
- Sex: Frequency distribution by arm

**Table 14.3.1** — Subjects with AE by Maximum Severity
- One row per subject (worst severity derived)
- Cross-tab: ARM × MAX_SEVERITY
- Standard CSR practice (prevents over-counting)

**Table 14.3.2** — Adverse Events by Preferred Term and Arm
- Count of AE **events** (not subjects)
- Sorted: AEDECOD × ARM
- Regulatory standard table

**Listing 16.2.1** — Out-of-Range Laboratory Results
- All labs with LBNRIND = "LOW" or "HIGH"
- Sorted: Subject → Visit → Test
- Medical reviewer inspection list

### data_quality_report.rtf

**Demographics Issues:**
- Records with age/sex/enrollment problems
- One row per problematic record

**Vital Signs Issues:**
- Range violations and BP logic errors
- Which parameter failed for which subject

**Adverse Event Issues:**
- Missing terms, invalid severity, date logic errors
- Actionable for data coordinator

**Lab Result Issues:**
- Missing results/units
- Reference range missing or incomplete


---

## 🔑 Key Features

### 1. Data Quality Flagging
✅ Not exclusion-based ("remove bad data")  
✅ Flag-based ("mark and report bad data")  
✅ Allows medical review and resolution  
✅ Meets regulatory transparency requirements  

### 2. SDTM Domain Sequencing
✅ DM: One record per subject  
✅ VS: Sequenced per subject/visit  
✅ AE: Sequenced per subject  
✅ LB: Sequenced per subject/visit  

**Why it matters:** SDTM requires sequential numbering for regulatory submissions.

### 3. Worst Severity Derivation
```sql
SELECT a.USUBJID, d.ARM,
  MAX(CASE WHEN a.AESEV="SEVERE" THEN 3 ...
FROM sdtm.ae a LEFT JOIN sdtm.dm d
GROUP BY a.USUBJID, d.ARM
```
Standard CSR practice — prevents double-counting.

### 4. Reference Range Indicator
Auto-derived: `LBNRIND` = LOW/NORMAL/HIGH  
No manual coding needed  
Flagged for medical review

---


## 📈 Validation Summary Statistics

### Typical Results (varies by data)
```
Domain              Records Imported    Issues Found    % Flagged
─────────────────────────────────────────────────────────────────
Demographics             50                  1-2           2-4%
Vital Signs            500                  5-10           1-2%
Adverse Events          30                   0-2           0-7%
Laboratory Results     200                   2-5           1-2%
```

**Normal pattern:** 1-3% flagged records (data entry typos, edge cases)  
**Red flag:** >10% flagged (data collection or source system issue)


## 🏥 Regulatory Compliance

This implementation aligns with:
- ✅ **ICH-GCP** — Data traceability and quality
- ✅ **CDISC SDTM** — Domain structure and sequencing



## 📄 License

Portfolio project — for educational and demonstration purposes.

