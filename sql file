
-- CLINICAL DATA MANAGEMENT SQL ANALYSIS


-- Remove tables if they already exist

DROP TABLE IF EXISTS lab_results;
DROP TABLE IF EXISTS adverse_events;
DROP TABLE IF EXISTS vitals;
DROP TABLE IF EXISTS demographics;



-- DEMOGRAPHICS TABLE


CREATE TABLE demographics (
    subject_id TEXT PRIMARY KEY,
    site_id TEXT NOT NULL,
    enroll_date DATE,
    age INTEGER,
    sex TEXT,
    arm TEXT
);



-- VITALS TABLE

CREATE TABLE vitals (
    vital_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    subject_id TEXT NOT NULL,
    visit TEXT,
    visit_date DATE,
    systolic_bp INTEGER,
    diastolic_bp INTEGER,
    heart_rate INTEGER,
    temp_c REAL,
    weight_kg REAL,

    FOREIGN KEY (subject_id)
        REFERENCES demographics(subject_id)
);



-- ADVERSE EVENTS TABLE

CREATE TABLE adverse_events (
    ae_id TEXT PRIMARY KEY,
    subject_id TEXT NOT NULL,
    ae_term TEXT,
    start_date DATE,
    end_date DATE,
    severity TEXT,
    relatedness TEXT,
    outcome TEXT,

    FOREIGN KEY (subject_id)
        REFERENCES demographics(subject_id)
);



-- LAB RESULTS TABLE

CREATE TABLE lab_results (
    lab_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    subject_id TEXT NOT NULL,
    visit TEXT,
    visit_date DATE,
    test_name TEXT,
    result REAL,
    unit TEXT,
    normal_low REAL,
    normal_high REAL,

    FOREIGN KEY (subject_id)
        REFERENCES demographics(subject_id)
);


DROP TABLE IF EXISTS demographics CASCADE;

CREATE TABLE demographics (
    subject_id TEXT,
    site_id TEXT NOT NULL,
    enroll_date DATE,
    age NUMERIC,
    sex TEXT,
    arm TEXT
);

SELECT subject_id, COUNT(*) AS duplicate_count
FROM demographics
GROUP BY subject_id
HAVING COUNT(*) > 1;


DROP TABLE IF EXISTS lab_results;

CREATE TABLE lab_results (
    subject_id TEXT NOT NULL,
    visit TEXT,
    visit_date DATE,
    test_name TEXT,
    result REAL,
    unit TEXT,
    normal_low REAL,
    normal_high REAL
);



DROP TABLE IF EXISTS vitals;

CREATE TABLE vitals (
    subject_id TEXT,
    visit TEXT,
    visit_date DATE,
    systolic_bp NUMERIC,
    diastolic_bp NUMERIC,
    heart_rate NUMERIC,
    temp_c NUMERIC,
    weight_kg NUMERIC
);

-- checking all data loaded correctly

SELECT * FROM demographics;

SELECT * FROM vitals;

SELECT * FROM adverse_events;

SELECT * FROM lab_results;

--count records in each table
SELECT COUNT(*) AS total_subjects
FROM demographics;

SELECT COUNT(*) AS total_vital_records
FROM vitals;

SELECT COUNT(*) AS total_adverse_events
FROM adverse_events;

SELECT COUNT(*) AS total_lab_results
FROM lab_results;

--check treatment groups
SELECT
    arm,
    COUNT(*) AS total_subjects
FROM demographics
GROUP BY arm;

--check gender distribution
SELECT
    sex,
    COUNT(*) AS total_subjects
FROM demographics
GROUP BY sex;

--Average age
SELECT
    ROUND(AVG(age), 1) AS average_age
FROM demographics;

--Average vital signs by visit
SELECT
    visit,
    ROUND(AVG(systolic_bp), 1) AS avg_systolic_bp,
    ROUND(AVG(diastolic_bp), 1) AS avg_diastolic_bp,
    ROUND(AVG(heart_rate), 1) AS avg_heart_rate
FROM vitals
GROUP BY visit
ORDER BY visit;

--find subjects with multiple visits
SELECT
    subject_id,
    COUNT(*) AS total_visits
FROM vitals
GROUP BY subject_id
HAVING COUNT(*) > 1;

--most common adverse events
SELECT
    ae_term,
    COUNT(*) AS total_events
FROM adverse_events
GROUP BY ae_term
ORDER BY total_events DESC;

--count abnormal results by test
SELECT
    test_name,
    COUNT(*) AS abnormal_results
FROM lab_results
WHERE result < normal_low
   OR result > normal_high
GROUP BY test_name;


--simple tratment arm analysis
SELECT
    demographics.arm,
    COUNT(adverse_events.ae_id) AS total_adverse_events
FROM demographics
JOIN adverse_events
ON demographics.subject_id = adverse_events.subject_id
GROUP BY demographics.arm;


--Is the study population distributed across treatment groups?
SELECT
    arm,
    COUNT(*) AS total_subjects
FROM demographics
GROUP BY arm;

--Are the average vital signs changing between visits?
SELECT
    visit,
    ROUND(AVG(systolic_bp), 1) AS avg_systolic_bp,
    ROUND(AVG(diastolic_bp), 1) AS avg_diastolic_bp,
    ROUND(AVG(heart_rate), 1) AS avg_heart_rate
FROM vitals
GROUP BY visit
ORDER BY visit;

--Which subjects have repeated clinical observations?
SELECT
    subject_id,
    COUNT(*) AS total_visits
FROM vitals
GROUP BY subject_id
HAVING COUNT(*) > 1
ORDER BY total_visits DESC;


--Which severity level occurs most?
SELECT
    severity,
    COUNT(*) AS total_events
FROM adverse_events
GROUP BY severity
ORDER BY total_events DESC;

--Which lab results are outside their normal range?
SELECT
    subject_id,
    visit,
    test_name,
    result,
    normal_low,
    normal_high
FROM lab_results
WHERE result < normal_low
   OR result > normal_high;

-- Which laboratory tests have the most abnormal results?

SELECT
    test_name,
    COUNT(*) AS abnormal_results
FROM lab_results
WHERE result < normal_low
   OR result > normal_high
GROUP BY test_name
ORDER BY abnormal_results DESC;

--Do adverse events differ by treatment arm?
   SELECT
    d.arm,
    COUNT(a.ae_id) AS total_adverse_events
FROM demographics d
JOIN adverse_events a
    ON d.subject_id = a.subject_id
GROUP BY d.arm
ORDER BY total_adverse_events DESC;

--Show patient details with their adverse events
SELECT
    d.subject_id,
    d.age,
    d.sex,
    d.arm,
    a.ae_term,
    a.severity
FROM demographics d
JOIN adverse_events a
    ON d.subject_id = a.subject_id
ORDER BY d.subject_id;




































