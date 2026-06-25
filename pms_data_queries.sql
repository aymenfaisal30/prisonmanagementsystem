--  PRISON MANAGEMENT SYSTEM
--  Database Implementation Script
--  Course   : CS 220 - Database Systems
--  Semester : BSDS-3-A, 2nd semester 
--  NUST - School of Electrical Engineering & Computer Science


CREATE DATABASE PrisonManagementSystem;
USE PrisonManagementSystem;



--  DROP TABLES (clean slate before re-running)

DROP TABLE IF EXISTS PAROLE;
DROP TABLE IF EXISTS TRANSFER;
DROP TABLE IF EXISTS DISCIPLINARY_RECORD;
DROP TABLE IF EXISTS MEDICAL_RECORD;
DROP TABLE IF EXISTS VISIT;
DROP TABLE IF EXISTS VISITOR;
DROP TABLE IF EXISTS SENTENCE;
DROP TABLE IF EXISTS INMATE;
DROP TABLE IF EXISTS STAFF;
DROP TABLE IF EXISTS CELL;
DROP TABLE IF EXISTS BLOCK;
DROP TABLE IF EXISTS PRISON;


--  TABLE 1 : PRISON
--  The top-level institution that contains all blocks.

CREATE TABLE PRISON (
    prison_id       INT             PRIMARY KEY,
    prison_name     VARCHAR(100)    NOT NULL,
    location        VARCHAR(150)    NOT NULL,
    prison_type     VARCHAR(50)     NOT NULL
                        CHECK (prison_type IN ('Federal', 'Provincial', 'Military', 'Juvenile')),
    total_capacity  INT             NOT NULL CHECK (total_capacity > 0),
    contact_number  VARCHAR(20)     NOT NULL UNIQUE
);


--  TABLE 2 : BLOCK
--  A wing or section inside a prison (e.g., Block A, Block B).

CREATE TABLE BLOCK (
    block_id        INT             PRIMARY KEY,
    block_name      VARCHAR(50)     NOT NULL,
    block_type      VARCHAR(20)     NOT NULL
                        CHECK (block_type IN (
												'Male',
												'Female',
												'Juvenile',
												'High-Security',
                                                'Administrative',
												'Death Row',
                                                'Isolation',
                                                'Rehabilitation'
                                                )),
    total_capacity  INT             NOT NULL CHECK (total_capacity > 0),
    prison_id       INT             NOT NULL,

    FOREIGN KEY (prison_id) REFERENCES PRISON(prison_id)
);


--  TABLE 3 : CELL
--  Individual cells inside a block. Tracks occupancy in real time.

CREATE TABLE CELL (
    cell_id             INT             PRIMARY KEY,
    cell_number         VARCHAR(10)     NOT NULL UNIQUE,
    capacity            INT             NOT NULL CHECK (capacity > 0),
    current_occupancy   INT             NOT NULL DEFAULT 0
                            CHECK (current_occupancy >= 0),
    security_level      VARCHAR(20)     NOT NULL
                            CHECK (security_level IN ('Low', 'Medium', 'High', 'Maximum')),
    block_id            INT             NOT NULL,

    FOREIGN KEY (block_id) REFERENCES BLOCK(block_id)
);


--  TABLE 4 : STAFF
--  All prison employees - guards, wardens, doctors, admin staff.

CREATE TABLE STAFF (
    staff_id        INT             PRIMARY KEY,
    full_name       VARCHAR(100)    NOT NULL,
    gender          VARCHAR(10)     NOT NULL CHECK (gender IN ('Male', 'Female')),
    role            VARCHAR(30)     NOT NULL
                        CHECK (role IN (  
                        'Warden', 
                        'Guard', 
                        'Doctor', 
                        'Admin', 
                        'Counselor',
                        'Psychologist',
                        'Security Chief',
                        'Nurse',
                        'Probation Officer'
                        )),
    shift_timing    VARCHAR(20)     NOT NULL
                        CHECK (shift_timing IN ('Morning', 'Evening', 'Night')),
    date_of_joining DATE            NOT NULL,
    contact_number  VARCHAR(20)     NOT NULL UNIQUE,
    block_id        INT,           

    FOREIGN KEY (block_id) REFERENCES BLOCK(block_id)
);


--  TABLE 5 : INMATE
--  Every person currently or previously imprisoned.

CREATE TABLE INMATE (
    inmate_id       INT             PRIMARY KEY,
    full_name       VARCHAR(100)    NOT NULL,
    date_of_birth   DATE            NOT NULL,
    gender          VARCHAR(10)     NOT NULL CHECK (gender IN ('Male', 'Female')),
    national_id     VARCHAR(20)     NOT NULL UNIQUE,
    status          VARCHAR(20)     NOT NULL
                        CHECK (status IN (
                        'Active', 
                        'Released', 
                        'Transferred', 
                        'Deceased'
                        )),
    risk_level      VARCHAR(10)     NOT NULL
                        CHECK (risk_level IN ('Low', 'Medium', 'High', 'Maximum')),
    admission_date  DATE            NOT NULL,
    cell_id         INT,            -- NULL if released or transferred out

    FOREIGN KEY (cell_id) REFERENCES CELL(cell_id)
);


--  TABLE 6 : SENTENCE
--  Legal conviction details linked to each inmate.
--  One inmate can have multiple sentences (repeat offende

CREATE TABLE SENTENCE (
    sentence_id             INT             PRIMARY KEY,
    inmate_id               INT             NOT NULL,
    crime_type              VARCHAR(100)    NOT NULL,
    sentence_duration       VARCHAR(30)     NOT NULL,   -- e.g. '5 Years', 'Life'
    start_date              DATE            NOT NULL,
    expected_release_date   DATE            NOT NULL,
    actual_release_date     DATE,                       -- NULL until actually released
    court_name              VARCHAR(100)    NOT NULL,

    FOREIGN KEY (inmate_id) REFERENCES INMATE(inmate_id)
);


--  TABLE 7 : VISITOR
--  People approved to visit inmates (family, lawyers, etc.).

CREATE TABLE VISITOR (
    visitor_id          INT             PRIMARY KEY,
    full_name           VARCHAR(100)    NOT NULL,
    national_id         VARCHAR(20)     NOT NULL UNIQUE,
    relation_to_inmate  VARCHAR(50)     NOT NULL,
    contact_number      VARCHAR(20)     NOT NULL,
    address             VARCHAR(200)    NOT NULL,
    approved_status     VARCHAR(15)     NOT NULL
                            CHECK (approved_status IN ('Approved', 'Pending', 'Blacklisted')),
    inmate_id           INT             NOT NULL,

    FOREIGN KEY (inmate_id) REFERENCES INMATE(inmate_id)
);


--  TABLE 8 : VISIT
--  Scheduled and completed visitation records.

CREATE TABLE VISIT (
    visit_id            INT             PRIMARY KEY,
    visitor_id          INT             NOT NULL,
    inmate_id           INT             NOT NULL,
    visit_date          DATE            NOT NULL,
    duration_minutes    INT             NOT NULL CHECK (duration_minutes > 0),
    visit_type          VARCHAR(15)     NOT NULL
                            CHECK (visit_type IN (
                            'In-Person', 
                            'Virtual', 
                            'Legal',
                            'Emergency'
                            )),
    approved_by         INT             NOT NULL,   -- Staff who approved this visit

    FOREIGN KEY (visitor_id)  REFERENCES VISITOR(visitor_id),
    FOREIGN KEY (inmate_id)   REFERENCES INMATE(inmate_id),
    FOREIGN KEY (approved_by) REFERENCES STAFF(staff_id)
);


--  TABLE 9 : MEDICAL_RECORD
--  Health checkup and treatment history per inmate.

CREATE TABLE MEDICAL_RECORD (
    record_id       INT             PRIMARY KEY,
    inmate_id       INT             NOT NULL,
    staff_id        INT             NOT NULL,   -- Must be a Doctor
    diagnosis       VARCHAR(200)    NOT NULL,
    treatment       VARCHAR(200)    NOT NULL,
    date_of_checkup DATE            NOT NULL,

    FOREIGN KEY (inmate_id) REFERENCES INMATE(inmate_id),
    FOREIGN KEY (staff_id)  REFERENCES STAFF(staff_id)
);


--  TABLE 10 : DISCIPLINARY_RECORD
--  Violations and punishments assigned to inmates.

CREATE TABLE DISCIPLINARY_RECORD (
    disciplinary_id     INT             PRIMARY KEY,
    inmate_id           INT             NOT NULL,
    reported_by         INT             NOT NULL,   -- Staff who filed the report
    incident_type       VARCHAR(100)    NOT NULL,
    incident_date       DATE            NOT NULL,
    punishment_given    VARCHAR(150)    NOT NULL,

    FOREIGN KEY (inmate_id)   REFERENCES INMATE(inmate_id),
    FOREIGN KEY (reported_by) REFERENCES STAFF(staff_id)
);


--  TABLE 11 : TRANSFER
--  Records every time an inmate is moved between cells.

CREATE TABLE TRANSFER (
    transfer_id     INT             PRIMARY KEY,
    inmate_id       INT             NOT NULL,
    from_cell_id    INT             NOT NULL,
    to_cell_id      INT             NOT NULL,
    authorized_by   INT             NOT NULL,   -- Staff who authorized the move
    transfer_date   DATE            NOT NULL,
    reason          VARCHAR(200)    NOT NULL,

    FOREIGN KEY (inmate_id)     REFERENCES INMATE(inmate_id),
    FOREIGN KEY (from_cell_id)  REFERENCES CELL(cell_id),
    FOREIGN KEY (to_cell_id)    REFERENCES CELL(cell_id),
    FOREIGN KEY (authorized_by) REFERENCES STAFF(staff_id)
);


--  TABLE 12 : PAROLE
--  Early release applications linked to sentence and inmate.


CREATE TABLE PAROLE (
    parole_id           INT             PRIMARY KEY,
    inmate_id           INT             NOT NULL,
    sentence_id         INT             NOT NULL,
    reviewed_by         INT             NOT NULL,   -- Staff (Warden/Counselor) who reviewed
    application_date    DATE            NOT NULL,
    hearing_date        DATE,                       -- Scheduled hearing, may be pending
    status              VARCHAR(15)     NOT NULL
                            CHECK (status IN ('Pending', 'Approved', 'Rejected')),
    conditions          VARCHAR(300),               -- Conditions if approved

    FOREIGN KEY (inmate_id)   REFERENCES INMATE(inmate_id),
    FOREIGN KEY (sentence_id) REFERENCES SENTENCE(sentence_id),
    FOREIGN KEY (reviewed_by) REFERENCES STAFF(staff_id)
);
SHOW DATABASES;
USE PrisonManagementSystem;
SHOW TABLES;

-- Sample Data Insertion in the Tables

--  TABLE 1 : PRISON

INSERT INTO PRISON VALUES
(1, 'Adiala Central Prison',   'Rawalpindi, Punjab',   'Provincial', 3000, '051-5551234'),
(2, 'Camp Jail Lahore',        'Lahore, Punjab',        'Provincial', 2000, '042-5559876'),
(3, 'Karachi Central Prison',  'Karachi, Sindh',        'Federal',    4000, '021-5558765'),
(4, 'Peshawar District Jail',  'Peshawar, KPK',         'Provincial', 1500, '091-5554321'),
(5, 'Quetta Military Prison',  'Quetta, Balochistan',   'Military',   800,  '081-5556789');



--  TABLE 2 : BLOCK
--  Uses your updated block types

INSERT INTO BLOCK VALUES
(1,  'Block A',  'Male',            200, 1),
(2,  'Block B',  'Male',            200, 1),
(3,  'Block C',  'High-Security',   100, 1),
(4,  'Block D',  'Female',          150, 1),
(5,  'Block E',  'Death Row',        50, 1),
(6,  'Block F',  'Isolation',        40, 1),
(7,  'Block G',  'Rehabilitation',  120, 1),
(8,  'Block H',  'Administrative',   60, 1),
(9,  'Block I',  'Male',            200, 2),
(10, 'Block J',  'Female',          150, 2),
(11, 'Block K',  'Juvenile',        100, 3),
(12, 'Block L',  'High-Security',   100, 3);

--  TABLE 3 : CELL

INSERT INTO CELL VALUES
(1,  'A-101', 4, 3, 'Low',     1),
(2,  'A-102', 4, 4, 'Low',     1),
(3,  'A-103', 4, 2, 'Medium',  1),
(4,  'B-101', 4, 4, 'Medium',  2),
(5,  'B-102', 4, 1, 'Medium',  2),
(6,  'C-101', 2, 2, 'High',    3),
(7,  'C-102', 2, 1, 'Maximum', 3),
(8,  'D-101', 4, 3, 'Low',     4),
(9,  'D-102', 4, 2, 'Medium',  4),
(10, 'E-101', 1, 1, 'Maximum', 5),
(11, 'E-102', 1, 1, 'Maximum', 5),
(12, 'F-101', 1, 1, 'High',    6),
(13, 'G-101', 6, 3, 'Low',     7),
(14, 'K-101', 6, 4, 'Low',     11),
(15, 'L-101', 2, 1, 'Maximum', 12);

--  TABLE 4 : STAFF

INSERT INTO STAFF VALUES

(1,  'Muhammad Tariq',      'Male',   'Warden',            'Morning', '2015-03-10', '0300-1111111', NULL),
(2,  'Asif Mehmood',        'Male',   'Guard',             'Morning', '2018-06-15', '0300-2222222', 1),
(3,  'Kamran Ali',          'Male',   'Guard',             'Night',   '2019-01-20', '0300-3333333', 2),
(4,  'Dr. Sana Mirza',      'Female', 'Doctor',            'Morning', '2017-08-05', '0300-4444444', NULL),
(5,  'Rabia Noor',          'Female', 'Admin',             'Morning', '2020-02-14', '0300-5555555', NULL),
(6,  'Usman Ghani',         'Male',   'Guard',             'Evening', '2021-09-30', '0300-6666666', 3),
(7,  'Farhan Siddiqui',     'Male',   'Guard',             'Night',   '2022-04-11', '0300-7777777', 4),
(8,  'Dr. Imran Qureshi',   'Male',   'Doctor',            'Morning', '2016-11-22', '0300-8888888', NULL),
(9,  'Nida Hussain',        'Female', 'Counselor',         'Morning', '2019-07-17', '0300-9999999', NULL),
(10, 'Bilal Chaudhry',      'Male',   'Guard',             'Evening', '2023-01-05', '0301-1111111', 1),
(11, 'Dr. Ayesha Farooq',   'Female', 'Psychologist',      'Morning', '2018-03-22', '0301-2222222', NULL),
(12, 'Shahid Anwar',        'Male',   'Security Chief',    'Morning', '2014-07-01', '0301-3333333', NULL),
(13, 'Nurse Huma Baig',     'Female', 'Nurse',             'Evening', '2021-05-15', '0301-4444444', NULL),
(14, 'Adnan Malik',         'Male',   'Probation Officer', 'Morning', '2020-10-10', '0301-5555555', NULL),
(15, 'Zara Khalid',         'Female', 'Admin',             'Morning', '2022-08-19', '0301-6666666', 8);
 

--  TABLE 5 : INMATE

INSERT INTO INMATE VALUES
(1,  'Asad Naeem',        '1985-04-12', 'Male',   '35201-1234567-1', 'Active',      'High',    '2020-01-15', 6),
(2,  'Haseeb Amjid',       '1979-11-03', 'Male',   '35202-2345678-2', 'Active',      'Medium',  '2019-06-20', 4),
(3,  'Talha Zafar',     '1990-07-25', 'Male',   '35203-3456789-3', 'Active',      'Low',     '2021-03-10', 1),
(4,  'Arqam Waheed',     '1988-02-18', 'Male',   '35204-4567890-4', 'Active',      'Maximum', '2018-09-05', 10),
(5,  'Ashhad Siddique',        '1975-09-30', 'Male',   '35205-5678901-5', 'Active',      'Medium',  '2017-12-01', 2),
(6,  'Amna Shafiq',         '1993-05-14', 'Female', '35206-6789012-6', 'Active',      'Low',     '2022-07-19', 8),
(7,  'Minahil Fatima',      '1982-12-07', 'Female',   '35207-7890123-7', 'Released',    'Low',     '2016-04-22', NULL),
(8,  'Nafeesullah',      '1995-08-19', 'Male',   '35208-8901234-8', 'Active',      'Medium',  '2023-02-28', 3),
(9,  'Aymen Khatoon',   '1987-03-01', 'Female', '35209-9012345-9', 'Active',      'Medium',  '2021-10-15', 9),
(10, 'Ibrahim Awab',      '1991-06-23', 'Male',   '35210-0123456-0', 'Transferred', 'Maximum', '2020-08-11', NULL),
(11, 'Abdullah Hussain',        '2003-01-15', 'Male',   '35211-1234568-1', 'Active',      'Low',     '2022-11-05', 14),
(12, 'Mahnoor Muqarrab',      '1970-10-09', 'Female',   '35212-2345679-2', 'Active',      'Maximum', '2010-05-30', 11),
(13, 'Alveena Mumtaz',      '1995-06-30', 'Female', '35213-3456780-3', 'Active',      'Medium',  '2023-04-01', 9),
(14, 'Haroon',       '1968-12-01', 'Male',   '35214-4567891-4', 'Active',      'Maximum', '2005-08-15', 15),
(15, 'Rabiya Khalid',      '1989-09-09', 'Female', '35215-5678902-5', 'Active',      'Low',     '2023-07-20', 8);


--  TABLE 6 : SENTENCE

INSERT INTO SENTENCE VALUES
(1,  1,  'Armed Robbery',           '10 Years',  '2020-01-15', '2030-01-15', NULL,         'Rawalpindi Sessions Court'),
(2,  2,  'Drug Trafficking',        '7 Years',   '2019-06-20', '2026-06-20', NULL,         'Lahore High Court'),
(3,  3,  'Theft',                   '3 Years',   '2021-03-10', '2024-03-10', NULL,         'Islamabad District Court'),
(4,  4,  'Murder',                  'Life',      '2018-09-05', '2048-09-05', NULL,         'Rawalpindi Sessions Court'),
(5,  5,  'Fraud',                   '5 Years',   '2017-12-01', '2022-12-01', NULL,         'Karachi High Court'),
(6,  6,  'Possession of Drugs',     '2 Years',   '2022-07-19', '2024-07-19', NULL,         'Rawalpindi District Court'),
(7,  7,  'Petty Theft',             '2 Years',   '2016-04-22', '2018-04-22', '2018-04-22', 'Lahore District Court'),
(8,  8,  'Assault',                 '3 Years',   '2023-02-28', '2026-02-28', NULL,         'Faisalabad Sessions Court'),
(9,  9,  'Kidnapping',              '8 Years',   '2021-10-15', '2029-10-15', NULL,         'Multan High Court'),
(10, 10, 'Terrorism',               '15 Years',  '2020-08-11', '2035-08-11', NULL,         'Anti-Terrorism Court'),
(11, 11, 'Vandalism',               '1 Year',    '2022-11-05', '2023-11-05', NULL,         'Karachi Juvenile Court'),
(12, 12, 'Premeditated Murder',     'Life',      '2010-05-30', '2040-05-30', NULL,         'Supreme Court of Pakistan'),
(13, 13, 'Embezzlement',            '4 Years',   '2023-04-01', '2027-04-01', NULL,         'Lahore Banking Court'),
(14, 14, 'High Treason',            'Life',      '2005-08-15', '2035-08-15', NULL,         'Supreme Court of Pakistan'),
(15, 15, 'Domestic Violence',       '2 Years',   '2023-07-20', '2025-07-20', NULL,         'Rawalpindi Family Court'),
(16, 5,  'Money Laundering',        '3 Years',   '2023-01-01', '2026-01-01', NULL,         'Federal Investigation Court');


--  TABLE 7 : VISITOR

INSERT INTO VISITOR VALUES
(1,  'Fatima Raza',       '35201-9876543-1', 'Wife',       '0312-1111111', 'House 12, Satellite Town, Rawalpindi', 'Approved',    1),
(2,  'Adv. Khalid Mir',  '35202-8765432-2', 'Lawyer',     '0312-2222222', 'Office 5, Jinnah Road, Lahore',        'Approved',    2),
(3,  'Sobia Mahmood',    '35203-7654321-3', 'Sister',     '0312-3333333', 'Flat 3, Block 7, Islamabad',           'Approved',    3),
(4,  'Hina Hussain',     '35204-6543210-4', 'Mother',     '0312-4444444', 'Village Kot Lakhpat, Lahore',          'Approved',    4),
(5,  'Qasim Khan',       '35205-5432109-5', 'Brother',    '0312-5555555', 'House 88, Model Town, Karachi',        'Pending',     5),
(6,  'Adv. Sana Malik',  '35206-4321098-6', 'Lawyer',     '0312-6666666', 'Chamber 9, District Courts, RWP',     'Approved',    6),
(7,  'Hamza Nawaz',      '35207-3210987-7', 'Son',        '0312-7777777', 'House 22, Gulberg, Lahore',            'Approved',    7),
(8,  'Rizwan Bashir',    '35208-2109876-8', 'Father',     '0312-8888888', 'House 55, Johar Town, Lahore',         'Approved',    8),
(9,  'Nargis Khatoon',   '35209-1098765-9', 'Daughter',   '0312-9999999', 'Flat 11, Clifton, Karachi',            'Pending',     9),
(10, 'Adv. Tariq Shah',  '35210-0987654-0', 'Lawyer',     '0313-1111111', 'Office 3, High Court Road, Lahore',   'Blacklisted', 10),
(11, 'Zainab Ali',       '35211-9876542-1', 'Mother',     '0313-2222222', 'House 7, North Nazimabad, Karachi',    'Approved',    11),
(12, 'Adv. Rehan Shah',  '35212-8765431-2', 'Lawyer',     '0313-3333333', 'Chamber 2, Supreme Court Road, ISB',  'Approved',    12),
(13, 'Sara Akhtar',      '35213-7654320-3', 'Husband',    '0313-4444444', 'Flat 6, DHA Phase 2, Lahore',         'Approved',    13),
(14, 'Adv. Fawad Gill',  '35214-6543219-4', 'Lawyer',     '0313-5555555', 'Office 11, Bar Council Road, RWP',    'Approved',    14),
(15, 'Noman Jabeen',     '35215-5432108-5', 'Brother',    '0313-6666666', 'House 3, Westridge, Rawalpindi',       'Approved',    15);


--  TABLE 8 : VISIT

INSERT INTO VISIT VALUES
(1,  1,  1,  '2024-01-10', 30, 'In-Person', 2),
(2,  2,  2,  '2024-01-12', 60, 'Legal',     2),
(3,  3,  3,  '2024-01-15', 30, 'In-Person', 3),
(4,  4,  4,  '2024-01-18', 45, 'Legal',     6),
(5,  6,  6,  '2024-02-01', 45, 'Legal',     7),
(6,  7,  7,  '2024-02-05', 20, 'Virtual',   2),
(7,  8,  8,  '2024-02-10', 30, 'In-Person', 3),
(8,  9,  9,  '2024-02-14', 30, 'In-Person', 7),
(9,  1,  1,  '2024-03-01', 30, 'In-Person', 2),
(10, 2,  2,  '2024-03-05', 60, 'Legal',     2),
(11, 11, 11, '2024-03-10', 20, 'In-Person', 10),
(12, 12, 12, '2024-03-12', 60, 'Legal',     6),
(13, 13, 13, '2024-03-15', 30, 'In-Person', 7),
(14, 4,  4,  '2024-03-18', 15, 'Emergency', 12),
(15, 14, 14, '2024-03-20', 60, 'Legal',     6);


--  TABLE 9 : MEDICAL RECORD

INSERT INTO MEDICAL_RECORD VALUES
(1,  1,  4,  'Hypertension',              'Prescribed Amlodipine 5mg daily',         '2024-01-20'),
(2,  2,  4,  'Type 2 Diabetes',           'Diet plan + Metformin 500mg',              '2024-01-22'),
(3,  3,  8,  'Common Cold',               'Rest and Paracetamol 500mg',               '2024-01-25'),
(4,  4,  4,  'Depression',                'Referred to psychologist, therapy begun',  '2024-02-01'),
(5,  5,  8,  'Back Pain',                 'Physiotherapy sessions recommended',       '2024-02-05'),
(6,  6,  4,  'Anaemia',                   'Iron supplements and dietary changes',     '2024-02-10'),
(7,  8,  8,  'Fractured wrist (old)',     'X-ray done, no new fracture found',        '2024-02-15'),
(8,  9,  4,  'Anxiety Disorder',          'Counseling sessions + Alprazolam 0.5mg',  '2024-02-20'),
(9,  11, 8,  'Malnutrition',              'Nutritional supplements provided',         '2024-03-01'),
(10, 12, 4,  'Chronic Kidney Disease',    'Referred to external specialist',          '2024-03-05'),
(11, 13, 4,  'Migraine',                  'Sumatriptan prescribed, rest advised',     '2024-03-10'),
(12, 14, 8,  'Heart Disease',             'Referred to cardiologist immediately',     '2024-03-12'),
(13, 15, 4,  'PTSD',                      'Therapy sessions with psychologist',       '2024-03-15'),
(14, 10, 8,  'Severe Asthma',             'Inhaler prescribed, monitored daily',      '2024-03-18'),
(15, 4,  11, 'Psychological Evaluation',  'Ongoing therapy recommended',              '2024-03-20');

--  TABLE 10 : DISCIPLINARY RECORD

INSERT INTO DISCIPLINARY_RECORD VALUES
(1,  1,  2,  'Fighting with another inmate',   '2024-01-05', 'Solitary confinement for 7 days'),
(2,  4,  6,  'Threatening a guard',            '2024-01-10', 'Loss of privileges for 30 days'),
(3,  2,  3,  'Possession of contraband',       '2024-01-18', 'Cell search + written warning'),
(4,  5,  2,  'Refusing to follow orders',      '2024-02-02', 'Community service within prison'),
(5,  10, 6,  'Attempted escape',               '2024-02-07', 'Transferred to maximum security cell'),
(6,  8,  10, 'Verbal abuse toward staff',      '2024-02-12', 'Formal warning issued'),
(7,  12, 6,  'Organizing illegal activity',    '2024-02-20', 'Solitary confinement for 14 days'),
(8,  9,  7,  'Destroying prison property',     '2024-03-01', 'Repair cost deducted, warning'),
(9,  3,  10, 'Hoarding food items',            '2024-03-04', 'Verbal warning'),
(10, 11, 7,  'Bullying another inmate',        '2024-03-08', 'Mandatory counseling session'),
(11, 14, 12, 'Inciting other inmates',         '2024-03-10', 'Isolation cell for 10 days'),
(12, 1,  2,  'Damaging cell property',         '2024-03-12', 'Written warning + cost deducted'),
(13, 13, 3,  'Unauthorized item in cell',      '2024-03-14', 'Item confiscated + warning'),
(14, 5,  6,  'Assault on fellow inmate',       '2024-03-16', 'Solitary confinement for 5 days'),
(15, 15, 7,  'Refusing medical examination',   '2024-03-18', 'Formal warning + report filed');


--  TABLE 11 : TRANSFER

INSERT INTO TRANSFER VALUES
(1,  10, 4,  15, 1, '2024-02-08', 'Attempted escape — moved to maximum security'),
(2,  1,  1,  6,  1, '2020-06-01', 'Risk level reassessment — upgraded to high security'),
(3,  5,  2,  4,  1, '2022-01-15', 'Routine reallocation due to overcrowding'),
(4,  8,  5,  3,  1, '2023-05-10', 'Medical staff requested closer monitoring'),
(5,  4,  6,  10, 1, '2021-02-14', 'Escalating behaviour — moved to death row cell'),
(6,  14, 7,  15, 12,'2023-09-01', 'Security threat assessment — maximum security required'),
(7,  12, 3,  11, 12,'2022-06-10', 'Transferred to death row after final appeal rejected'),
(8,  9,  8,  9,  1, '2023-11-20', 'Block reallocation due to renovation'),
(9,  3,  2,  1,  1, '2023-08-05', 'Good behaviour — moved to lower security cell'),
(10, 13, 4,  9,  1, '2023-12-01', 'Consolidated female block reallocation');


--  TABLE 12 : PAROLE

INSERT INTO PAROLE VALUES
(1, 3,  3,  9,  '2023-10-01', '2023-11-15', 'Approved',  'Must report to local police weekly. No travel outside city.'),
(2, 5,  5,  9,  '2022-08-01', '2022-09-10', 'Approved',  'Regular check-ins with probation officer required.'),
(3, 2,  2,  9,  '2024-01-10', '2024-03-01', 'Pending',    NULL),
(4, 8,  8,  9,  '2024-02-01',  NULL,         'Pending',    NULL),
(5, 6,  6,  9,  '2023-12-01', '2024-01-20', 'Rejected',   NULL),
(6, 11, 11, 14, '2023-09-01', '2023-10-15', 'Approved',  'Community service 40 hours. School enrollment mandatory.'),
(7, 13, 13, 9,  '2024-01-15', '2024-02-28', 'Pending',    NULL),
(8, 15, 15, 14, '2024-03-01', '2024-04-10', 'Pending',    NULL),
(9, 7,  7,  9,  '2018-02-01', '2018-03-15', 'Approved',  'Reported to parole officer monthly for 6 months.'),
(10,9,  9,  9,  '2024-02-15',  NULL,         'Pending',    NULL);

-- INDEXES

-- Faster searching of inmate status
CREATE INDEX idx_inmate_status
ON INMATE(status);

-- Faster searching of risk levels
CREATE INDEX idx_inmate_risk
ON INMATE(risk_level);

-- Faster visit date filtering
CREATE INDEX idx_visit_date
ON VISIT(visit_date);

-- Faster release-date queries
CREATE INDEX idx_sentence_release
ON SENTENCE(expected_release_date);

-- Faster visitor approval searches
CREATE INDEX idx_visitor_status
ON VISITOR(approved_status);

-- Views

-- High Risk Inmates
CREATE VIEW high_risk_inmates_view AS
SELECT
    inmate_id,
    full_name,
    risk_level,
    admission_date
FROM INMATE
WHERE risk_level IN ('High', 'Maximum');

--  ACTIVE INMATES SUMMARY

CREATE VIEW active_inmates_view AS
SELECT
    i.inmate_id,
    i.full_name,
    i.risk_level,
    c.cell_number,
    b.block_name,
    p.prison_name
FROM INMATE i
JOIN CELL c   ON i.cell_id = c.cell_id
JOIN BLOCK b  ON c.block_id = b.block_id
JOIN PRISON p ON b.prison_id = p.prison_id
WHERE i.status = 'Active';

-- Triggers

--  Increase occupancy after inmate insertion

DELIMITER $$

CREATE TRIGGER trg_inmate_insert
AFTER INSERT ON INMATE
FOR EACH ROW
BEGIN

    IF NEW.cell_id IS NOT NULL THEN

        UPDATE CELL
        SET current_occupancy = current_occupancy + 1
        WHERE cell_id = NEW.cell_id;

    END IF;

END$$

DELIMITER ;

--  Decrease occupancy when inmate released

DELIMITER $$

CREATE TRIGGER trg_inmate_release
AFTER UPDATE ON INMATE
FOR EACH ROW
BEGIN

    IF OLD.cell_id IS NOT NULL
    AND NEW.cell_id IS NULL THEN

        UPDATE CELL
        SET current_occupancy = current_occupancy - 1
        WHERE cell_id = OLD.cell_id;

    END IF;

END$$

DELIMITER ;

 SHOW DATABASES;
 
 SHOW TABLES;
 
 SHOW FULL TABLES
WHERE TABLE_TYPE = 'VIEW';

SHOW CREATE VIEW active_inmates_view;

SHOW INDEX FROM INMATE;

SHOW TRIGGERS;

--  BASIC SELECT QUERIES

-- Q1: View all active inmates currently in prison
SELECT * FROM INMATE
WHERE status = 'Active';


-- Q2: Get all staff members along with their roles and shift timings
SELECT full_name, role, shift_timing, contact_number
FROM STAFF
ORDER BY role;


-- Q3: Find all high risk and maximum risk inmates
SELECT inmate_id, full_name, national_id, risk_level, admission_date
FROM INMATE
WHERE risk_level IN ('High', 'Maximum')
ORDER BY risk_level;


-- Q4: Get all visitors who are still pending approval
SELECT full_name, relation_to_inmate, contact_number, address
FROM VISITOR
WHERE approved_status = 'Pending';


-- Q5: Find all sentences that have not ended yet (inmate still serving)
SELECT sentence_id, inmate_id, crime_type, sentence_duration, expected_release_date
FROM SENTENCE
WHERE actual_release_date IS NULL
ORDER BY expected_release_date;


-- Q6: Find all cells that are completely full (occupancy = capacity)
SELECT cell_id, cell_number, capacity, current_occupancy, security_level
FROM CELL
WHERE current_occupancy = capacity;


-- Q7: Get all night shift guards specifically
SELECT full_name, contact_number, block_id
FROM STAFF
WHERE role = 'Guard' AND shift_timing = 'Night';


--  WHERE + FILTERING QUERIES

-- Q8: Find inmates admitted before 2020 (long term prisoners)
SELECT full_name, admission_date, status, risk_level
FROM INMATE
WHERE admission_date < '2020-01-01'
ORDER BY admission_date;


-- Q9: Find all legal visits that lasted more than 45 minutes
SELECT visit_id, inmate_id, visitor_id, visit_date, duration_minutes
FROM VISIT
WHERE visit_type = 'Legal' AND duration_minutes > 45;


-- Q10: Find all blacklisted visitors and why they matter
SELECT visitor_id, full_name, national_id, relation_to_inmate, contact_number
FROM VISITOR
WHERE approved_status = 'Blacklisted';


-- Q11: Get all parole applications that are still pending
SELECT parole_id, inmate_id, application_date, hearing_date
FROM PAROLE
WHERE status = 'Pending'
ORDER BY application_date;


-- Q12: Find all disciplinary incidents that happened in 2024
SELECT disciplinary_id, inmate_id, incident_type, incident_date, punishment_given
FROM DISCIPLINARY_RECORD
WHERE YEAR(incident_date) = 2024
ORDER BY incident_date;


--  JOIN QUERIES

-- Q13: Get each inmate with their cell number and block name
SELECT 
    i.inmate_id,
    i.full_name         AS inmate_name,
    i.risk_level,
    c.cell_number,
    c.security_level,
    b.block_name,
    b.block_type
FROM INMATE i
JOIN CELL c ON i.cell_id = c.cell_id
JOIN BLOCK b ON c.block_id = b.block_id
WHERE i.status = 'Active'
ORDER BY b.block_name;


-- Q14: Get full visit details - visitor name, inmate name, and which staff approved it
SELECT
    v.visit_id,
    vr.full_name        AS visitor_name,
    vr.relation_to_inmate,
    i.full_name         AS inmate_name,
    v.visit_date,
    v.duration_minutes,
    v.visit_type,
    s.full_name         AS approved_by
FROM VISIT v
JOIN VISITOR vr  ON v.visitor_id = vr.visitor_id
JOIN INMATE  i   ON v.inmate_id  = i.inmate_id
JOIN STAFF   s   ON v.approved_by = s.staff_id
ORDER BY v.visit_date;


-- Q15: Get each medical record with inmate name and treating doctor name
SELECT
    mr.record_id,
    i.full_name         AS inmate_name,
    s.full_name         AS doctor_name,
    mr.diagnosis,
    mr.treatment,
    mr.date_of_checkup
FROM MEDICAL_RECORD mr
JOIN INMATE i ON mr.inmate_id = i.inmate_id
JOIN STAFF  s ON mr.staff_id  = s.staff_id
ORDER BY mr.date_of_checkup;


-- Q16: Get disciplinary records showing inmate name and staff who reported it
SELECT
    dr.disciplinary_id,
    i.full_name         AS inmate_name,
    i.risk_level,
    s.full_name         AS reported_by,
    s.role              AS reporter_role,
    dr.incident_type,
    dr.incident_date,
    dr.punishment_given
FROM DISCIPLINARY_RECORD dr
JOIN INMATE i ON dr.inmate_id   = i.inmate_id
JOIN STAFF  s ON dr.reported_by = s.staff_id
ORDER BY dr.incident_date;


-- Q17: Get each inmate with their full sentence and which prison/block they are in
SELECT
    i.full_name         AS inmate_name,
    i.status,
    i.risk_level,
    s.crime_type,
    s.sentence_duration,
    s.start_date,
    s.expected_release_date,
    s.court_name,
    b.block_name,
    p.prison_name
FROM INMATE i
JOIN SENTENCE s  ON i.inmate_id  = s.inmate_id
JOIN CELL     c  ON i.cell_id    = c.cell_id
JOIN BLOCK    b  ON c.block_id   = b.block_id
JOIN PRISON   p  ON b.prison_id  = p.prison_id
WHERE i.status = 'Active'
ORDER BY s.expected_release_date;


-- SUBQUERY QUERIES


-- Q18: Find inmates who have NEVER received a visitor
SELECT inmate_id, full_name, admission_date, risk_level
FROM INMATE
WHERE inmate_id NOT IN (
    SELECT DISTINCT inmate_id FROM VISIT
);


-- Q19: Find inmates whose risk level is higher than the average
--      (we treat Low=1, Medium=2, High=3, Maximum=4 logically)
--      Here we just get all High and Maximum since they are above average
SELECT full_name, risk_level, admission_date
FROM INMATE
WHERE risk_level IN (
    SELECT DISTINCT risk_level FROM INMATE
    WHERE risk_level IN ('High', 'Maximum')
)
ORDER BY risk_level;


-- Q20: Get all staff who have approved at least one visit
SELECT DISTINCT s.full_name, s.role, s.shift_timing
FROM STAFF s
WHERE s.staff_id IN (
    SELECT DISTINCT approved_by FROM VISIT
);

-- Q21: Find inmates who have a pending parole application
SELECT i.full_name, i.risk_level, i.admission_date, p.application_date
FROM INMATE i
JOIN PAROLE p ON i.inmate_id = p.inmate_id
WHERE p.status = 'Pending'
ORDER BY p.application_date;


-- Q22: Get cells that are in blocks belonging to Adiala Central Prison only
SELECT c.cell_number, c.capacity, c.current_occupancy, c.security_level
FROM CELL c
WHERE c.block_id IN (
    SELECT block_id FROM BLOCK
    WHERE prison_id = (
        SELECT prison_id FROM PRISON
        WHERE prison_name = 'Adiala Central Prison'
    )
);



--  AGGREGATE QUERIES

-- Q23: Count total number of active inmates per block
SELECT
    b.block_name,
    b.block_type,
    COUNT(i.inmate_id)  AS total_inmates
FROM BLOCK b
JOIN CELL   c ON b.block_id  = c.block_id
JOIN INMATE i ON c.cell_id   = i.cell_id
WHERE i.status = 'Active'
GROUP BY b.block_name, b.block_type
ORDER BY total_inmates DESC;


-- Q24: Count how many visits each inmate has received
SELECT
    i.full_name         AS inmate_name,
    COUNT(v.visit_id)   AS total_visits
FROM INMATE i
LEFT JOIN VISIT v ON i.inmate_id = v.inmate_id
GROUP BY i.inmate_id, i.full_name
ORDER BY total_visits DESC;


-- Q25: Count disciplinary incidents per inmate - find the most problematic inmates
SELECT
    i.full_name             AS inmate_name,
    i.risk_level,
    COUNT(dr.disciplinary_id) AS total_incidents
FROM INMATE i
JOIN DISCIPLINARY_RECORD dr ON i.inmate_id = dr.inmate_id
GROUP BY i.inmate_id, i.full_name, i.risk_level
HAVING COUNT(dr.disciplinary_id) > 1
ORDER BY total_incidents DESC;


-- Q26: Find the total number of inmates each doctor has treated
SELECT
    s.full_name             AS doctor_name,
    COUNT(mr.record_id)     AS total_checkups
FROM STAFF s
JOIN MEDICAL_RECORD mr ON s.staff_id = mr.staff_id
WHERE s.role = 'Doctor'
GROUP BY s.staff_id, s.full_name
ORDER BY total_checkups DESC;


-- Q27: Get average visit duration per visit type
SELECT
    visit_type,
    COUNT(*)                        AS total_visits,
    AVG(duration_minutes)           AS avg_duration_minutes,
    MAX(duration_minutes)           AS longest_visit
FROM VISIT
GROUP BY visit_type;


-- Q28: Count total transfers per inmate - who gets moved around the most
SELECT
    i.full_name             AS inmate_name,
    COUNT(t.transfer_id)    AS total_transfers
FROM INMATE i
JOIN TRANSFER t ON i.inmate_id = t.inmate_id
GROUP BY i.inmate_id, i.full_name
ORDER BY total_transfers DESC;


--  UPDATE QUERIES

-- Q29: Release an inmate - update their status and remove cell assignment
UPDATE INMATE
SET status  = 'Released',
    cell_id = NULL
WHERE inmate_id = 3;


-- Q30: Approve a pending parole application
UPDATE PAROLE
SET status       = 'Approved',
    hearing_date = '2024-04-01',
    conditions   = 'Must report to probation officer every two weeks.'
WHERE parole_id = 3;


-- Q31: Update cell occupancy after a new inmate is added
UPDATE CELL
SET current_occupancy = current_occupancy + 1
WHERE cell_id = 1;


-- Q32: Approve a visitor who was previously pending
UPDATE VISITOR
SET approved_status = 'Approved'
WHERE visitor_id = 5;


-- Q33: Reassign a staff member to a different block
UPDATE STAFF
SET block_id = 2
WHERE staff_id = 10;


--  DELETE QUERIES


-- Q34: Remove a blacklisted visitor from the system
DELETE FROM VISITOR
WHERE approved_status = 'Blacklisted'
AND visitor_id = 10;


-- Q35: Delete a cancelled or mistakenly entered visit record
DELETE FROM VISIT
WHERE visit_id = 6;
