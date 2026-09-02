# SDTM Reporting Program: Implementation Guide

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

Includes:
1. **Issue-Flagged Records** by domain (only records with DQ_TOTAL_ISSUES > 0)
2. **Completeness Frequency** tables
3. **Record-level DQ flags** for investigation
4. **Actionable query list** for data clarification

**Why This Matters for Your Portfolio:**
- Shows you **caught data quality issues** before analysis
- Demonstrates understanding of **edit checks** (critical CDM skill)
- Proves ability to **flag problems** vs. blindly accepting data




