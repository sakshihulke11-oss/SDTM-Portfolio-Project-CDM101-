/*==============================================================
  SDTM_Reporting_Updated.sas
  -----------------------------------------------------------
  COMPREHENSIVE CLINICAL DATA MANAGEMENT & SDTM REPORTING
  
  This program integrates:
  1. Data import and validation
  2. SDTM domain construction (DM, VS, AE, LB)
  3. Data quality checks and flagging
  4. Clinical Study Report tables (TLF)
  5. Data quality summary report
  
  OUTPUT:
  - clinical_study_tables.rtf (CSR Tables 14.1-14.3, Listing 16.2)
  - data_quality_report.rtf (Validation flags and summary)
  
  PREREQUISITES:
  - All source CSV files in the specified path
  - SAS 9.4+ with PROC REPORT capability
==============================================================*/

OPTIONS MISSING=" " NOCENTER NONOTES NOSOURCE NOSOURCE2;

%LET sourcepath = /data/source;     /* Location of source CSV files */
%LET sdtmpath   = /data/sdtm;       /* SDTM library path */
%LET reportpath = /outputs;         /* Report output path */

/* Create libraries */
LIBNAME source "&sourcepath.";
LIBNAME sdtm   "&sdtmpath.";
LIBNAME work   "&sdtmpath./work";

/*==============================================================
  SECTION 1: DATA IMPORT
==============================================================*/

%PUT NOTE: ===== STEP 1: IMPORTING SOURCE DATA =====;

/* Import Demographics */
PROC IMPORT
    DATAFILE="&sourcepath./demographics.csv"
    OUT=source.demographics
    DBMS=CSV
    REPLACE;
    GETNAMES=YES;
RUN;

/* Import Vitals */
PROC IMPORT
    DATAFILE="&sourcepath./vitals.csv"
    OUT=source.vitals
    DBMS=CSV
    REPLACE;
    GETNAMES=YES;
RUN;

/* Import Adverse Events */
PROC IMPORT
    DATAFILE="&sourcepath./adverse_events.csv"
    OUT=source.adverse_events
    DBMS=CSV
    REPLACE;
    GETNAMES=YES;
RUN;

/* Import Lab Results */
PROC IMPORT
    DATAFILE="&sourcepath./lab_results.csv"
    OUT=source.lab_results
    DBMS=CSV
    REPLACE;
    GETNAMES=YES;
RUN;

%PUT NOTE: Data import completed;

/*==============================================================
  SECTION 2: DATA QUALITY VALIDATION - DEMOGRAPHICS
==============================================================*/

%PUT NOTE: ===== STEP 2: DEMOGRAPHICS VALIDATION =====;

DATA sdtm.dm_with_flags;
    SET source.demographics;
    
    /* Standardize column names */
    RENAME 
        subject_id=SUBJECT_ID 
        site_id=SITE_ID
        enroll_date=ENROLL_DATE
        age=AGE
        sex=SEX
        arm=ARM;
    
    /* Initialize data quality flags */
    DQ_SUBJECT_DUPLICATE = 0;
    DQ_AGE_MISSING = 0;
    DQ_AGE_RANGE = 0;
    DQ_SEX_INVALID = 0;
    DQ_ENROLL_DATE_MISSING = 0;
    DQ_TOTAL_ISSUES = 0;
    
    /* Check for missing age */
    IF MISSING(AGE) THEN DQ_AGE_MISSING = 1;
    
    /* Check age range (18-100) */
    IF NOT MISSING(AGE) AND (AGE < 18 OR AGE > 100) 
        THEN DQ_AGE_RANGE = 1;
    
    /* Standardize sex values */
    SEX = UPCASE(SEX);
    IF SEX NOT IN ("M" "F" "MALE" "FEMALE") 
        THEN DQ_SEX_INVALID = 1;
    
    /* Replace MALE/FEMALE with M/F */
    IF SEX = "MALE" THEN SEX = "M";
    IF SEX = "FEMALE" THEN SEX = "F";
    
    /* Check for missing enrollment date */
    IF MISSING(ENROLL_DATE) THEN DQ_ENROLL_DATE_MISSING = 1;
    
    /* Calculate total issues */
    DQ_TOTAL_ISSUES = DQ_AGE_MISSING + DQ_AGE_RANGE + 
                      DQ_SEX_INVALID + DQ_ENROLL_DATE_MISSING;
    
RUN;

/* Check for duplicate subject IDs */
PROC SORT DATA=sdtm.dm_with_flags OUT=dm_sorted;
    BY SUBJECT_ID;
RUN;

DATA sdtm.dm_validated;
    SET dm_sorted;
    BY SUBJECT_ID;
    
    /* Flag duplicate subjects */
    IF NOT (FIRST.SUBJECT_ID AND LAST.SUBJECT_ID) 
        THEN DQ_SUBJECT_DUPLICATE = 1;
    
    /* Update total issues count */
    DQ_TOTAL_ISSUES = DQ_TOTAL_ISSUES + DQ_SUBJECT_DUPLICATE;
    
RUN;

/* Summary of demographic issues */
PROC FREQ DATA=sdtm.dm_validated;
    TABLES DQ_TOTAL_ISSUES / NOCUM NOPERCENT;
    TITLE "Demographics Data Quality Summary";
RUN;

%PUT NOTE: Demographics validation completed;

/*==============================================================
  SECTION 3: DATA QUALITY VALIDATION - VITALS
==============================================================*/

%PUT NOTE: ===== STEP 3: VITAL SIGNS VALIDATION =====;

DATA sdtm.vs_with_flags;
    SET source.vitals;
    
    RENAME 
        subject_id=SUBJECT_ID
        visit=VISIT
        visit_date=VISIT_DATE
        systolic_bp=SYSTOLIC_BP
        diastolic_bp=DIASTOLIC_BP
        heart_rate=HEART_RATE
        temp_c=TEMP_C
        weight_kg=WEIGHT_KG;
    
    /* Initialize data quality flags */
    DQ_SYSTOLIC_MISSING = 0;
    DQ_DIASTOLIC_MISSING = 0;
    DQ_HEART_RATE_MISSING = 0;
    DQ_TEMP_MISSING = 0;
    DQ_SYSTOLIC_RANGE = 0;
    DQ_DIASTOLIC_RANGE = 0;
    DQ_HEART_RATE_RANGE = 0;
    DQ_TEMP_RANGE = 0;
    DQ_BP_LOGIC = 0;
    DQ_VISIT_DATE_MISSING = 0;
    DQ_TOTAL_ISSUES = 0;
    
    /* Check for missing values */
    IF MISSING(SYSTOLIC_BP) THEN DQ_SYSTOLIC_MISSING = 1;
    IF MISSING(DIASTOLIC_BP) THEN DQ_DIASTOLIC_MISSING = 1;
    IF MISSING(HEART_RATE) THEN DQ_HEART_RATE_MISSING = 1;
    IF MISSING(TEMP_C) THEN DQ_TEMP_MISSING = 1;
    IF MISSING(VISIT_DATE) THEN DQ_VISIT_DATE_MISSING = 1;
    
    /* Range checks */
    IF NOT MISSING(SYSTOLIC_BP) AND (SYSTOLIC_BP < 70 OR SYSTOLIC_BP > 250)
        THEN DQ_SYSTOLIC_RANGE = 1;
    
    IF NOT MISSING(DIASTOLIC_BP) AND (DIASTOLIC_BP < 40 OR DIASTOLIC_BP > 150)
        THEN DQ_DIASTOLIC_RANGE = 1;
    
    IF NOT MISSING(HEART_RATE) AND (HEART_RATE < 30 OR HEART_RATE > 220)
        THEN DQ_HEART_RATE_RANGE = 1;
    
    IF NOT MISSING(TEMP_C) AND (TEMP_C < 34 OR TEMP_C > 42)
        THEN DQ_TEMP_RANGE = 1;
    
    /* Logic check: Diastolic should NOT exceed Systolic */
    IF NOT MISSING(SYSTOLIC_BP) AND NOT MISSING(DIASTOLIC_BP) 
        AND DIASTOLIC_BP >= SYSTOLIC_BP
        THEN DQ_BP_LOGIC = 1;
    
    /* Calculate total issues */
    DQ_TOTAL_ISSUES = DQ_SYSTOLIC_MISSING + DQ_DIASTOLIC_MISSING +
                      DQ_HEART_RATE_MISSING + DQ_TEMP_MISSING +
                      DQ_SYSTOLIC_RANGE + DQ_DIASTOLIC_RANGE +
                      DQ_HEART_RATE_RANGE + DQ_TEMP_RANGE +
                      DQ_BP_LOGIC + DQ_VISIT_DATE_MISSING;
    
RUN;

/* Summary of vital signs issues */
PROC FREQ DATA=sdtm.vs_with_flags;
    TABLES DQ_TOTAL_ISSUES / NOCUM NOPERCENT;
    TITLE "Vital Signs Data Quality Summary";
RUN;

%PUT NOTE: Vital signs validation completed;

/*==============================================================
  SECTION 4: DATA QUALITY VALIDATION - ADVERSE EVENTS
==============================================================*/

%PUT NOTE: ===== STEP 4: ADVERSE EVENTS VALIDATION =====;

DATA sdtm.ae_with_flags;
    SET source.adverse_events;
    
    RENAME 
        ae_id=AE_ID
        subject_id=SUBJECT_ID
        ae_term=AE_TERM
        start_date=START_DATE
        end_date=END_DATE
        severity=SEVERITY
        relatedness=RELATEDNESS
        outcome=OUTCOME;
    
    /* Initialize data quality flags */
    DQ_AE_TERM_MISSING = 0;
    DQ_START_DATE_MISSING = 0;
    DQ_SEVERITY_MISSING = 0;
    DQ_SEVERITY_INVALID = 0;
    DQ_DATE_LOGIC = 0;
    DQ_TOTAL_ISSUES = 0;
    
    /* Check for missing adverse event term */
    IF MISSING(AE_TERM) THEN DQ_AE_TERM_MISSING = 1;
    
    /* Check for missing start date */
    IF MISSING(START_DATE) THEN DQ_START_DATE_MISSING = 1;
    
    /* Check for missing severity */
    IF MISSING(SEVERITY) THEN DQ_SEVERITY_MISSING = 1;
    
    /* Standardize severity */
    SEVERITY = UPCASE(SEVERITY);
    
    /* Check for invalid severity values */
    IF NOT MISSING(SEVERITY) AND 
       SEVERITY NOT IN ("MILD" "MODERATE" "SEVERE")
        THEN DQ_SEVERITY_INVALID = 1;
    
    /* Check date logic: End date should NOT be before start date */
    IF NOT MISSING(START_DATE) AND NOT MISSING(END_DATE) 
        AND END_DATE < START_DATE
        THEN DQ_DATE_LOGIC = 1;
    
    /* Calculate total issues */
    DQ_TOTAL_ISSUES = DQ_AE_TERM_MISSING + DQ_START_DATE_MISSING +
                      DQ_SEVERITY_MISSING + DQ_SEVERITY_INVALID + 
                      DQ_DATE_LOGIC;
    
RUN;

/* Summary of adverse event issues */
PROC FREQ DATA=sdtm.ae_with_flags;
    TABLES DQ_TOTAL_ISSUES / NOCUM NOPERCENT;
    TITLE "Adverse Events Data Quality Summary";
RUN;

%PUT NOTE: Adverse events validation completed;

/*==============================================================
  SECTION 5: DATA QUALITY VALIDATION - LAB RESULTS
==============================================================*/

%PUT NOTE: ===== STEP 5: LABORATORY RESULTS VALIDATION =====;

DATA sdtm.lb_with_flags;
    SET source.lab_results;
    
    RENAME 
        subject_id=SUBJECT_ID
        visit=VISIT
        visit_date=VISIT_DATE
        test_name=TEST_NAME
        result=RESULT
        unit=UNIT
        normal_low=NORMAL_LOW
        normal_high=NORMAL_HIGH;
    
    /* Initialize data quality flags */
    DQ_RESULT_MISSING = 0;
    DQ_UNIT_MISSING = 0;
    DQ_NORMAL_RANGE_MISSING = 0;
    DQ_TOTAL_ISSUES = 0;
    LBNRIND = "NORMAL";
    
    /* Check for missing result */
    IF MISSING(RESULT) THEN DQ_RESULT_MISSING = 1;
    
    /* Check for missing unit */
    IF MISSING(UNIT) THEN DQ_UNIT_MISSING = 1;
    
    /* Check for missing reference range */
    IF MISSING(NORMAL_LOW) OR MISSING(NORMAL_HIGH) 
        THEN DQ_NORMAL_RANGE_MISSING = 1;
    
    /* Derive reference range indicator */
    IF NOT MISSING(RESULT) AND NOT MISSING(NORMAL_LOW) 
        AND RESULT < NORMAL_LOW
        THEN LBNRIND = "LOW";
    
    IF NOT MISSING(RESULT) AND NOT MISSING(NORMAL_HIGH) 
        AND RESULT > NORMAL_HIGH
        THEN LBNRIND = "HIGH";
    
    /* Calculate total issues */
    DQ_TOTAL_ISSUES = DQ_RESULT_MISSING + DQ_UNIT_MISSING + 
                      DQ_NORMAL_RANGE_MISSING;
    
RUN;

/* Summary of lab result issues */
PROC FREQ DATA=sdtm.lb_with_flags;
    TABLES DQ_TOTAL_ISSUES / NOCUM NOPERCENT;
    TITLE "Laboratory Results Data Quality Summary";
RUN;

%PUT NOTE: Laboratory results validation completed;

/*==============================================================
  SECTION 6: CREATE FINAL SDTM DOMAINS (DM, VS, AE, LB)
==============================================================*/

%PUT NOTE: ===== STEP 6: CREATING SDTM DOMAINS =====;

/* DM - Demographics Domain */
DATA sdtm.dm;
    SET sdtm.dm_validated;
    
    STUDYID = "CDM101";
    DOMAIN = "DM";
    USUBJID = CATS(STUDYID, "-", SUBJECT_ID);
    
    /* Derive ARMCD from ARM */
    IF ARM = "Control" THEN ARMCD = "CTRL";
    ELSE IF ARM = "Treatment" THEN ARMCD = "TRT";
    ELSE ARMCD = "UNK";
    
    AGEU = "YEARS";
    
    /* Convert dates to ISO 8601 */
    RFSTDTC = PUT(ENROLL_DATE, YYMMDD10.);
    
    /* Drop intermediate flags, keep DM-specific ones only */
    KEEP STUDYID DOMAIN USUBJID SUBJECT_ID SITE_ID AGE AGEU 
         SEX ARMCD ARM RFSTDTC ENROLL_DATE 
         DQ_TOTAL_ISSUES DQ_AGE_MISSING DQ_SEX_INVALID;
    
RUN;

/* VS - Vital Signs Domain (wide to long format) */
DATA sdtm.vs_long;
    SET sdtm.vs_with_flags;
    
    STUDYID = "CDM101";
    DOMAIN = "VS";
    USUBJID = CATS(STUDYID, "-", SUBJECT_ID);
    
    /* Convert date to ISO 8601 */
    VSDTC = PUT(VISIT_DATE, YYMMDD10.);
    
    /* Systolic BP */
    VSSEQ = 1;
    VSTESTCD = "SYSBP";
    VSTEST = "Systolic Blood Pressure";
    VSORRES = SYSTOLIC_BP;
    VSORRESU = "mmHg";
    DQ_ISSUE_SYSTOLIC = DQ_SYSTOLIC_RANGE;
    OUTPUT;
    
    /* Diastolic BP */
    VSSEQ = 2;
    VSTESTCD = "DIABP";
    VSTEST = "Diastolic Blood Pressure";
    VSORRES = DIASTOLIC_BP;
    VSORRESU = "mmHg";
    DQ_ISSUE_DIASTOLIC = DQ_DIASTOLIC_RANGE;
    OUTPUT;
    
    /* Heart Rate */
    VSSEQ = 3;
    VSTESTCD = "HR";
    VSTEST = "Heart Rate";
    VSORRES = HEART_RATE;
    VSORRESU = "beats/min";
    DQ_ISSUE_HR = DQ_HEART_RATE_RANGE;
    OUTPUT;
    
    /* Temperature */
    VSSEQ = 4;
    VSTESTCD = "TEMP";
    VSTEST = "Temperature";
    VSORRES = TEMP_C;
    VSORRESU = "C";
    DQ_ISSUE_TEMP = DQ_TEMP_RANGE;
    OUTPUT;
    
    /* Weight */
    VSSEQ = 5;
    VSTESTCD = "WEIGHT";
    VSTEST = "Weight";
    VSORRES = WEIGHT_KG;
    VSORRESU = "kg";
    DQ_ISSUE_WEIGHT = 0;
    OUTPUT;
    
    KEEP STUDYID DOMAIN USUBJID SUBJECT_ID VSSEQ VSTESTCD VSTEST 
         VSORRES VSORRESU VISIT VSDTC VISIT_DATE DQ_TOTAL_ISSUES
         DQ_ISSUE_SYSTOLIC DQ_ISSUE_DIASTOLIC DQ_ISSUE_HR 
         DQ_ISSUE_TEMP DQ_BP_LOGIC;
RUN;

PROC SORT DATA=sdtm.vs_long;
    BY USUBJID VISIT_DATE VSSEQ;
RUN;

DATA sdtm.vs;
    SET sdtm.vs_long;
    BY USUBJID VISIT VSDTC;
    IF FIRST.VSDTC THEN VSSEQ = 0;
    VSSEQ + 1;
RUN;

/* AE - Adverse Events Domain */
DATA sdtm.ae;
    SET sdtm.ae_with_flags;
    
    STUDYID = "CDM101";
    DOMAIN = "AE";
    USUBJID = CATS(STUDYID, "-", SUBJECT_ID);
    
    /* Convert dates to ISO 8601 */
    AESTDTC = PUT(START_DATE, YYMMDD10.);
    AEENDTC = PUT(END_DATE, YYMMDD10.);
    
    AESEV = SEVERITY;
    AEREL = RELATEDNESS;
    AEOUT = OUTCOME;
    
    /* Placeholder for dictionary coding (not performed in portfolio) */
    AEDECOD = AE_TERM;
    
    KEEP STUDYID DOMAIN USUBJID SUBJECT_ID AESEQ AE_ID AETERM AEDECOD 
         AESTDTC AEENDTC AESEV AEREL AEOUT START_DATE END_DATE
         DQ_TOTAL_ISSUES DQ_AE_TERM_MISSING DQ_SEVERITY_INVALID DQ_DATE_LOGIC;
    
    RENAME AE_TERM = AETERM;
    
RUN;

PROC SORT DATA=sdtm.ae;
    BY USUBJID START_DATE AE_ID;
RUN;

DATA sdtm.ae;
    SET sdtm.ae;
    BY USUBJID;
    IF FIRST.USUBJID THEN AESEQ = 0;
    AESEQ + 1;
RUN;

/* LB - Laboratory Results Domain */
DATA sdtm.lb;
    SET sdtm.lb_with_flags;
    
    STUDYID = "CDM101";
    DOMAIN = "LB";
    USUBJID = CATS(STUDYID, "-", SUBJECT_ID);
    
    /* Convert date to ISO 8601 */
    LBDTC = PUT(VISIT_DATE, YYMMDD10.);
    
    LBTEST = TEST_NAME;
    LBTESTCD = UPCASE(COMPRESS(TEST_NAME, " "));
    LBORRES = RESULT;
    LBORRESU = UNIT;
    
    KEEP STUDYID DOMAIN USUBJID SUBJECT_ID LBSEQ LBTESTCD LBTEST 
         LBORRES LBORRESU LBNRIND VISIT LBDTC VISIT_DATE NORMAL_LOW NORMAL_HIGH
         DQ_TOTAL_ISSUES DQ_RESULT_MISSING DQ_NORMAL_RANGE_MISSING;
    
RUN;

PROC SORT DATA=sdtm.lb;
    BY USUBJID VISIT_DATE LBTESTCD;
RUN;

DATA sdtm.lb;
    SET sdtm.lb;
    BY USUBJID VISIT_DATE;
    IF FIRST.VISIT_DATE THEN LBSEQ = 0;
    LBSEQ + 1;
RUN;

%PUT NOTE: SDTM domains created successfully;

/*==============================================================
  SECTION 7: DATA QUALITY SUMMARY REPORT
==============================================================*/

%PUT NOTE: ===== STEP 7: GENERATING DATA QUALITY REPORT =====;

ODS RTF FILE="&reportpath./data_quality_report.rtf" 
    STYLE=JOURNAL BODYTITLE STARTPAGE=NO;

OPTIONS NODATE NONUMBER ORIENTATION=LANDSCAPE;

/* DQ Summary by Dataset */
TITLE1 "Data Quality Summary Report";
TITLE2 "SDTM Portfolio Project (CDM101)";

PROC REPORT DATA=sdtm.dm NOWD SPLIT="~";
    WHERE DQ_TOTAL_ISSUES > 0;
    COLUMN USUBJID SUBJECT_ID DQ_TOTAL_ISSUES DQ_AGE_MISSING 
           DQ_SEX_INVALID;
    DEFINE USUBJID / DISPLAY "Unique Subject ID" WIDTH=12;
    DEFINE SUBJECT_ID / DISPLAY "Subject ID" WIDTH=10;
    DEFINE DQ_TOTAL_ISSUES / DISPLAY "Total Issues" WIDTH=10;
    DEFINE DQ_AGE_MISSING / DISPLAY "Age Missing" WIDTH=10;
    DEFINE DQ_SEX_INVALID / DISPLAY "Sex Invalid" WIDTH=10;
    TITLE3 "Demographics - Records with Data Quality Issues";
RUN;

PROC REPORT DATA=sdtm.vs NOWD SPLIT="~";
    WHERE DQ_TOTAL_ISSUES > 0;
    COLUMN USUBJID VSTESTCD VSORRES VSORRESU DQ_TOTAL_ISSUES 
           DQ_ISSUE_SYSTOLIC DQ_ISSUE_DIASTOLIC DQ_BP_LOGIC;
    DEFINE USUBJID / DISPLAY "Unique Subject ID" WIDTH=12;
    DEFINE VSTESTCD / DISPLAY "Test Code" WIDTH=10;
    DEFINE VSORRES / DISPLAY "Result" WIDTH=10;
    DEFINE VSORRESU / DISPLAY "Unit" WIDTH=8;
    DEFINE DQ_TOTAL_ISSUES / DISPLAY "Total Issues" WIDTH=10;
    DEFINE DQ_ISSUE_SYSTOLIC / DISPLAY "Systolic Issue" WIDTH=10;
    DEFINE DQ_ISSUE_DIASTOLIC / DISPLAY "Diastolic Issue" WIDTH=10;
    DEFINE DQ_BP_LOGIC / DISPLAY "BP Logic Error" WIDTH=10;
    TITLE3 "Vital Signs - Records with Data Quality Issues";
RUN;

PROC REPORT DATA=sdtm.ae NOWD SPLIT="~";
    WHERE DQ_TOTAL_ISSUES > 0;
    COLUMN USUBJID AETERM AESEV DQ_TOTAL_ISSUES DQ_AE_TERM_MISSING 
           DQ_SEVERITY_INVALID DQ_DATE_LOGIC;
    DEFINE USUBJID / DISPLAY "Unique Subject ID" WIDTH=12;
    DEFINE AETERM / DISPLAY "AE Term" WIDTH=20;
    DEFINE AESEV / DISPLAY "Severity" WIDTH=10;
    DEFINE DQ_TOTAL_ISSUES / DISPLAY "Total Issues" WIDTH=10;
    DEFINE DQ_AE_TERM_MISSING / DISPLAY "Term Missing" WIDTH=10;
    DEFINE DQ_SEVERITY_INVALID / DISPLAY "Severity Invalid" WIDTH=12;
    DEFINE DQ_DATE_LOGIC / DISPLAY "Date Logic Error" WIDTH=12;
    TITLE3 "Adverse Events - Records with Data Quality Issues";
RUN;

PROC REPORT DATA=sdtm.lb NOWD SPLIT="~";
    WHERE DQ_TOTAL_ISSUES > 0;
    COLUMN USUBJID LBTEST LBORRES LBORRESU DQ_TOTAL_ISSUES 
           DQ_RESULT_MISSING DQ_NORMAL_RANGE_MISSING;
    DEFINE USUBJID / DISPLAY "Unique Subject ID" WIDTH=12;
    DEFINE LBTEST / DISPLAY "Lab Test" WIDTH=15;
    DEFINE LBORRES / DISPLAY "Result" WIDTH=10;
    DEFINE LBORRESU / DISPLAY "Unit" WIDTH=8;
    DEFINE DQ_TOTAL_ISSUES / DISPLAY "Total Issues" WIDTH=10;
    DEFINE DQ_RESULT_MISSING / DISPLAY "Result Missing" WIDTH=12;
    DEFINE DQ_NORMAL_RANGE_MISSING / DISPLAY "Ref Range Missing" WIDTH=14;
    TITLE3 "Laboratory Results - Records with Data Quality Issues";
RUN;

/* Completeness Summary */
TITLE1 "Data Completeness Summary";
TITLE2 " ";

PROC FREQ DATA=sdtm.dm;
    TABLES DQ_TOTAL_ISSUES / NOCUM NOPERCENT;
    TITLE3 "Demographics";
RUN;

PROC FREQ DATA=sdtm.vs;
    TABLES DQ_TOTAL_ISSUES / NOCUM NOPERCENT;
    TITLE3 "Vital Signs";
RUN;

PROC FREQ DATA=sdtm.ae;
    TABLES DQ_TOTAL_ISSUES / NOCUM NOPERCENT;
    TITLE3 "Adverse Events";
RUN;

PROC FREQ DATA=sdtm.lb;
    TABLES DQ_TOTAL_ISSUES / NOCUM NOPERCENT;
    TITLE3 "Laboratory Results";
RUN;

ODS RTF CLOSE;

%PUT NOTE: Data quality report generated;

/*==============================================================
  SECTION 8: CLINICAL STUDY REPORT - TABLES (TLF)
==============================================================*/

%PUT NOTE: ===== STEP 8: GENERATING CLINICAL STUDY REPORT TABLES =====;

ODS RTF FILE="&reportpath./clinical_study_tables.rtf" 
    STYLE=JOURNAL BODYTITLE STARTPAGE=YES;

OPTIONS NODATE NONUMBER ORIENTATION=LANDSCAPE;

/*--- TABLE 14.1.1 - Subject Disposition by Site and Arm ---*/
TITLE1 "Table 14.1.1";
TITLE2 "Summary of Subject Disposition by Site and Treatment Arm";
TITLE3 "All Enrolled Subjects";

PROC FREQ DATA=sdtm.dm;
    TABLES SITE_ID * ARM / NOPERCENT NOROW NOCOL;
RUN;

/*--- TABLE 14.1.2 - Demographic Characteristics ---*/
TITLE1 "Table 14.1.2";
TITLE2 "Summary of Demographic Characteristics";
TITLE3 "All Enrolled Subjects";

PROC MEANS DATA=sdtm.dm N MEAN STD MIN MAX MAXDEC=1;
    CLASS ARM;
    VAR AGE;
    TITLE4 "Age (years)";
RUN;

PROC FREQ DATA=sdtm.dm;
    TABLES ARM * SEX / NOROW NOPERCENT;
    TITLE4 "Sex";
RUN;

/*--- TABLE 14.3.1 - Adverse Events by Maximum Severity ---*/

/* Derive worst severity per subject */
PROC SQL;
    CREATE TABLE ae_worst_severity AS
    SELECT a.USUBJID, 
           d.ARM,
           MAX(CASE WHEN a.AESEV = "SEVERE" THEN 3
                    WHEN a.AESEV = "MODERATE" THEN 2
                    WHEN a.AESEV = "MILD" THEN 1
                    ELSE 0 END) AS sev_rank
    FROM sdtm.ae a
    LEFT JOIN sdtm.dm d ON a.USUBJID = d.USUBJID
    GROUP BY a.USUBJID, d.ARM;
QUIT;

DATA ae_worst_severity;
    SET ae_worst_severity;
    
    IF sev_rank = 3 THEN MAX_SEVERITY = "SEVERE";
    ELSE IF sev_rank = 2 THEN MAX_SEVERITY = "MODERATE";
    ELSE IF sev_rank = 1 THEN MAX_SEVERITY = "MILD";
    ELSE MAX_SEVERITY = "NO AE";
    
    KEEP USUBJID ARM MAX_SEVERITY;
RUN;

TITLE1 "Table 14.3.1";
TITLE2 "Summary of Subjects with Adverse Events by Maximum Severity";
TITLE3 "and Treatment Arm";

PROC FREQ DATA=ae_worst_severity;
    TABLES ARM * MAX_SEVERITY / NOROW NOCOL;
RUN;

/*--- TABLE 14.3.2 - Adverse Events by Preferred Term and Arm ---*/

PROC SQL;
    CREATE TABLE ae_by_term AS
    SELECT a.AEDECOD, 
           d.ARM, 
           COUNT(*) AS N_EVENTS
    FROM sdtm.ae a
    LEFT JOIN sdtm.dm d ON a.USUBJID = d.USUBJID
    GROUP BY a.AEDECOD, d.ARM
    ORDER BY a.AEDECOD, d.ARM;
QUIT;

TITLE1 "Table 14.3.2";
TITLE2 "Adverse Events by Preferred Term and Treatment Arm";
TITLE3 "Number of Events";

PROC REPORT DATA=ae_by_term NOWD SPLIT="~";
    COLUMN AEDECOD ARM N_EVENTS;
    DEFINE AEDECOD / GROUP "Preferred Term" WIDTH=20;
    DEFINE ARM / GROUP "Treatment Arm" WIDTH=12;
    DEFINE N_EVENTS / SUM "Number of Events" WIDTH=10;
RUN;

/*--- LISTING 16.2.1 - Out-of-Range Lab Results ---*/

TITLE1 "Listing 16.2.1";
TITLE2 "Subjects with Out-of-Range Laboratory Results";
TITLE3 " ";

PROC SORT DATA=sdtm.lb OUT=lb_listing;
    BY USUBJID VISIT LBTESTCD;
RUN;

PROC REPORT DATA=lb_listing NOWD SPLIT="~";
    WHERE LBNRIND IN ("HIGH" "LOW");
    COLUMN USUBJID VISIT LBTEST LBORRES LBORRESU LBNRIND;
    DEFINE USUBJID / ORDER "Subject ID" WIDTH=12;
    DEFINE VISIT / ORDER "Visit" WIDTH=10;
    DEFINE LBTEST / DISPLAY "Laboratory Test" WIDTH=20;
    DEFINE LBORRES / DISPLAY "Result" WIDTH=10;
    DEFINE LBORRESU / DISPLAY "Unit" WIDTH=8;
    DEFINE LBNRIND / DISPLAY "Status" WIDTH=8;
RUN;

ODS RTF CLOSE;

OPTIONS DATE NUMBER ORIENTATION=PORTRAIT;
TITLE;

%PUT NOTE: ===== REPORTING COMPLETE =====;
%PUT NOTE: Clinical Study Tables: &reportpath./clinical_study_tables.rtf;
%PUT NOTE: Data Quality Report: &reportpath./data_quality_report.rtf;

/*==============================================================
  END OF PROGRAM
==============================================================*/
