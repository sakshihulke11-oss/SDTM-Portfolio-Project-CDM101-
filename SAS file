 ============================================================
   CLINICAL DATA ANALYSIS
   STEP 1: IMPORT CLINICAL DATASETS
 ============================================================ 


Import Demographics

PROC IMPORT
    DATAFILE="/home/u64365325/demographics.csv"
    OUT=demographics
    DBMS=CSV
    REPLACE;
    GETNAMES=YES;
RUN;


 Import Vitals 

PROC IMPORT
    DATAFILE="/home/u64365325/vitals.csv"
    OUT=vitals
    DBMS=CSV
    REPLACE;
    GETNAMES=YES;
RUN;


Import Adverse Events 

PROC IMPORT
    DATAFILE="/home/u64365325/adverse_events.csv"
    OUT=adverse_events
    DBMS=CSV
    REPLACE;
    GETNAMES=YES;
RUN;


Import Lab Results 

PROC IMPORT
    DATAFILE="/home/u64365325/lab_results.csv"
    OUT=lab_results
    DBMS=CSV
    REPLACE;
    GETNAMES=YES;
RUN;

============================================================
   STEP 2: CHECK DATASET STRUCTURE
============================================================ 

PROC CONTENTS DATA=demographics;
RUN;

PROC CONTENTS DATA=vitals;
RUN;

PROC CONTENTS DATA=adverse_events;
RUN;

PROC CONTENTS DATA=lab_results;
RUN;


============================================================
   STEP 3: VIEW SAMPLE RECORDS
============================================================ 

PROC PRINT DATA=demographics (OBS=10);
RUN;

PROC PRINT DATA=vitals (OBS=10);
RUN;

PROC PRINT DATA=adverse_events (OBS=10);
RUN;

PROC PRINT DATA=lab_results (OBS=10);
RUN;

============================================================
   STEP 4: DEMOGRAPHICS SUMMARY
============================================================ 

 Summary of age 

PROC MEANS DATA=demographics N MEAN MIN MAX MAXDEC=1;
    VAR age;
RUN;


Distribution of subjects by treatment arm 

PROC FREQ DATA=demographics;
    TABLES arm;
RUN;


Distribution of subjects by sex 

PROC FREQ DATA=demographics;
    TABLES sex;
RUN;

============================================================
   STEP 5: VITAL SIGNS ANALYSIS
============================================================ 

PROC MEANS DATA=vitals N MEAN MIN MAX MAXDEC=1;
    VAR systolic_bp diastolic_bp heart_rate temp_c weight_kg;
RUN;


--compare average vital signs by visit

PROC MEANS DATA=vitals MEAN MAXDEC=1;
    CLASS visit;
    VAR systolic_bp diastolic_bp heart_rate;
RUN;

--Number of vital records at each visit
PROC FREQ DATA=vitals;
    TABLES visit;
RUN;


 ============================================================
   STEP 6: ADVERSE EVENTS ANALYSIS
 ============================================================ 

 Number of adverse events by severity 

PROC FREQ DATA=adverse_events;
    TABLES severity;
RUN;


Most frequently reported adverse events 

PROC FREQ DATA=adverse_events ORDER=FREQ;
    TABLES ae_term;
RUN;


 Adverse events by relatedness 

PROC FREQ DATA=adverse_events;
    TABLES relatedness;
RUN;


/* Adverse event outcomes */

PROC FREQ DATA=adverse_events;
    TABLES outcome;
RUN;


============================================================
   STEP 7: LABORATORY RESULTS ANALYSIS
 ============================================================ 

Summary statistics for laboratory results 

PROC MEANS DATA=lab_results N MEAN MIN MAX MAXDEC=2;
    VAR result;
RUN;


Number of records for each laboratory test 

PROC FREQ DATA=lab_results;
    TABLES test_name;
RUN;


 Identify laboratory results outside the normal range 

DATA abnormal_labs;
    SET lab_results;

    IF result < normal_low OR result > normal_high;
RUN;


/* View abnormal laboratory results */

PROC PRINT DATA=abnormal_labs;
    OBS=20;
RUN;


Count abnormal results by laboratory test 

PROC FREQ DATA=abnormal_labs;
    TABLES test_name;
RUN;


STEP 8: COMBINE DEMOGRAPHICS AND ADVERSE EVENTS
  

PROC SORT DATA=demographics;
    BY subject_id;
RUN;

PROC SORT DATA=adverse_events;
    BY subject_id;
RUN;


/* Merge subject information with adverse events */

DATA subject_adverse_events;

    MERGE demographics (IN=a)
          adverse_events (IN=b);

    BY subject_id;

    IF a AND b;

RUN;


 View combined dataset 

PROC PRINT DATA=subject_adverse_events (OBS=20);
RUN;


============================================================
   STEP 9: ADVERSE EVENTS BY TREATMENT ARM
============================================================ 

PROC FREQ DATA=subject_adverse_events;
    TABLES arm * severity / NOROW NOCOL NOPERCENT;
RUN;




