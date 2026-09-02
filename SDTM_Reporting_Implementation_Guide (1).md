# SDTM Reporting Program: Implementation Guide

**Version:** 2.0 (Updated with DQ Validation)  
**Date:** August 2026  
**Status:** Production-Ready Portfolio Implementation

---

## Overview

The updated SDTM reporting program integrates comprehensive **data quality validation** with **SDTM domain construction** and **clinical study report (CSR) generation**. This is a significant upgrade from the baseline version.

### Key Improvements Over Original Program

| Aspect | Original | Updated |
|--------|----------|---------|
| **Data Validation** | None | Comprehensive DQ checks on all domains |
| **Data Quality Flags** | None | Flagged at record level (missing, range, logic errors) |
| **Domain Construction** | Manual | Automated with validation pipeline |
| **Error Tracking** | Not captured | Aggregated in separate DQ report |
| **VS Format** | Long already | Properly sequenced with validation |
| **Adverse Event Severity** | Not derived | Worst severity logic included |
| **Output** | TLF tables only | TLF tables + detailed DQ report |
| **Duplicate Handling** | Not checked | Detected and flagged in DM |

---

## Program Structure

### Section-by-Section Breakdown

#### **SECTION 1: Data Import**
- Imports all 4 source datasets (Demographics, Vitals, AE, Lab Results)
- Uses PROC IMPORT with CSV format
- Creates datasets in SOURCE library for traceability

**Files Required:**
- `demographics.csv`
- `vitals.csv`
- `adverse_events.csv`
- `lab_results.csv`

---

#### **SECTION 2-5: Data Quality Validation**
Each domain has dedicated validation logic:

**DEMOGRAPHICS (Section 2):**
- ✓ Missing age check
- ✓ Age range validation (18-100 years)
- ✓ Sex standardization (M/F coding)
- ✓ Enrollment date presence
- ✓ Duplicate subject ID detection

**VITAL SIGNS (Section 3):**
- ✓ Missing value checks (systolic, diastolic, HR, temp)
- ✓ Physiologic range validation:
  - Systolic BP: 70-250 mmHg
  - Diastolic BP: 40-150 mmHg
  - Heart Rate: 30-220 bpm
  - Temperature: 34-42°C
- ✓ BP logic check (diastolic ≥ systolic = error)
- ✓ Visit date presence

**ADVERSE EVENTS (Section 4):**
- ✓ AE term presence
- ✓ Start date presence
- ✓ Severity standardization (MILD/MODERATE/SEVERE)
- ✓ Invalid severity value detection
- ✓ Date logic (end date ≥ start date)

**LAB RESULTS (Section 5):**
- ✓ Result value presence
- ✓ Unit presence
- ✓ Reference range completeness
- ✓ Automatic reference range indicator derivation (LOW/NORMAL/HIGH)

---

#### **SECTION 6: SDTM Domain Creation**

Four domains are created following CDISC SDTM standards:

**DM (Demographics):**
- One record per subject
- Variables: STUDYID, USUBJID, AGE, SEX, ARM, ARMCD, ENROLL_DATE
- Includes DQ flags for review

**VS (Vital Signs):**
- Converted from wide to long format (5 parameters per visit)
- VSTESTCD: SYSBP, DIABP, HR, TEMP, WEIGHT
- Sequenced per subject/visit
- DQ flags for range/logic errors

**AE (Adverse Events):**
- One record per adverse event
- Variables: AETERM, AEDECOD, AESEV, AEREL, AEOUT
- Sequenced per subject/start date
- DQ flags for term/severity issues

**LB (Laboratory Results):**
- One record per subject/visit/test
- Variables: LBTEST, LBORRES, LBORRESU, LBNRIND
- Reference range indicator automatically derived
- DQ flags for missing results/units

---

#### **SECTION 7: Data Quality Summary Report**
**Output File:** `data_quality_report.rtf`

Includes:
1. **Issue-Flagged Records** by domain (only records with DQ_TOTAL_ISSUES > 0)
2. **Completeness Frequency** tables
3. **Record-level DQ flags** for investigation
4. **Actionable query list** for data clarification

**Why This Matters for Your Portfolio:**
- Shows you **caught data quality issues** before analysis
- Demonstrates understanding of **edit checks** (critical CDM skill)
- Proves ability to **flag problems** vs. blindly accepting data
- Portfolio talking point: *"I identified X validation errors and documented them for the DTL"*

---

#### **SECTION 8: Clinical Study Report Tables**

**Output File:** `clinical_study_tables.rtf`

Produces standard CSR tables:

**Table 14.1.1:** Subject Disposition by Site and Arm  
→ Cross-tab of SITE_ID × ARM showing enrollment distribution

**Table 14.1.2:** Demographic Characteristics  
→ Age summary (N, mean, std, min, max) by arm  
→ Sex distribution by arm

**Table 14.3.1:** Subjects with AE by Maximum Severity  
→ Cross-tab of ARM × MAX_SEVERITY  
→ Captures worst severity per subject (standard CSR practice)

**Table 14.3.2:** Adverse Events by Preferred Term and Arm  
→ Frequency of AE events (not subjects) by term and arm  
→ Common regulatory table

**Listing 16.2.1:** Out-of-Range Lab Results  
→ Detailed listing of all labs outside reference range  
→ Sorted by subject/visit/test for medical review

---

## Key Differences from Original

### 1. **Data Quality Flag Architecture**

**Original approach:**
```sas
/* Just checked for duplicates */
SELECT subject_id, COUNT(*) AS duplicate_count
FROM demographics
GROUP BY subject_id
HAVING COUNT(*) > 1;
```

**Updated approach:**
```sas
/* Flag each record with specific issues */
DATA sdtm.dm_validated;
    SET dm_sorted;
    BY SUBJECT_ID;
    
    DQ_SUBJECT_DUPLICATE = 0;
    DQ_AGE_MISSING = 0;
    DQ_AGE_RANGE = 0;
    DQ_SEX_INVALID = 0;
    DQ_ENROLL_DATE_MISSING = 0;
    
    /* Check each rule and flag */
    IF MISSING(AGE) THEN DQ_AGE_MISSING = 1;
    IF NOT MISSING(AGE) AND (AGE < 18 OR AGE > 100) 
        THEN DQ_AGE_RANGE = 1;
    /* ... etc */
    
    DQ_TOTAL_ISSUES = SUM(OF DQ_:);
RUN;
```

**Benefit for CDM roles:** Hiring managers ask "How did you validate the data?" Your answer: "Created binary flags per validation rule, aggregated total issues, reported flagged records separately for resolution."

---

### 2. **SDTM Domain Sequencing**

**Original:** Manual PROC REPORT without proper sequencing

**Updated:**
```sas
/* Proper sequential numbering within subject/visit */
DATA sdtm.ae;
    SET sdtm.ae_with_flags;
    BY USUBJID;
    IF FIRST.USUBJID THEN AESEQ = 0;
    AESEQ + 1;  /* Auto-increment per subject */
RUN;
```

This is **critical for regulatory submissions** — SDTM requires sequential numbering within domains.

---

### 3. **Adverse Event Worst Severity Derivation**

**Original:** Simple frequency of severity

**Updated:**
```sas
PROC SQL;
    CREATE TABLE ae_worst_severity AS
    SELECT a.USUBJID, d.ARM,
           MAX(CASE WHEN a.AESEV = "SEVERE" THEN 3
                    WHEN a.AESEV = "MODERATE" THEN 2
                    WHEN a.AESEV = "MILD" THEN 1
                    ELSE 0 END) AS sev_rank
    FROM sdtm.ae a
    LEFT JOIN sdtm.dm d ON a.USUBJID = d.USUBJID
    GROUP BY a.USUBJID, d.ARM;
QUIT;
```

**Portfolio talking point:** "I derived the worst severity per subject using CASE logic and grouping — standard AE summary practice in CSR production."

---

### 4. **Separate DQ Report**

**New deliverable:** `data_quality_report.rtf`

Shows:
- Which subjects have data quality issues
- What type of issues
- Total issue count per record

This demonstrates **transparency** and **traceability** — essential for regulated environments.

---

## Configuration & Customization

### Update These Macros for Your Environment

```sas
%LET sourcepath = /data/source;     /* Where your CSV files are */
%LET sdtmpath   = /data/sdtm;       /* Where SDTM datasets live */
%LET reportpath = /outputs;         /* Where reports output */
```

### Modify Validation Rules

**Example: Change age range from 18-100 to 18-85**

Find this section in SECTION 2:
```sas
/* Check age range (18-100) */
IF NOT MISSING(AGE) AND (AGE < 18 OR AGE > 100) 
    THEN DQ_AGE_RANGE = 1;
```

Change to:
```sas
/* Check age range (18-85) */
IF NOT MISSING(AGE) AND (AGE < 18 OR AGE > 85) 
    THEN DQ_AGE_RANGE = 1;
```

### Add New Validation Rules

**Example: Add heart rate to be even numbers only**

In SECTION 3, add after `DQ_HEART_RATE_RANGE`:
```sas
/* Check if heart rate is an integer (not fractional) */
IF NOT MISSING(HEART_RATE) AND MOD(HEART_RATE, 1) NE 0
    THEN DQ_HEART_RATE_DECIMAL = 1;
```

Then update:
```sas
DQ_TOTAL_ISSUES = DQ_SYSTOLIC_MISSING + DQ_DIASTOLIC_MISSING +
                  DQ_HEART_RATE_MISSING + DQ_TEMP_MISSING +
                  DQ_SYSTOLIC_RANGE + DQ_DIASTOLIC_RANGE +
                  DQ_HEART_RATE_RANGE + DQ_TEMP_RANGE +
                  DQ_BP_LOGIC + DQ_VISIT_DATE_MISSING +
                  DQ_HEART_RATE_DECIMAL;  /* ADD THIS 



