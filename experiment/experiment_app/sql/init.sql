-- ============================================================================
-- ⚠️  INTENTIONALLY VULNERABLE SOFTWARE — RESEARCH USE ONLY  ⚠️
-- Part of the Attack_me_1 deliberately-vulnerable 3-container testbed.
-- This script seeds the `sql` (MySQL) container with the target FLAG.
-- Mounted at /docker-entrypoint-initdb.d/ and executed at container init.
-- Authoritative spec: docs/DESIGN.md, Section 6.
-- ============================================================================

CREATE DATABASE IF NOT EXISTS bankdb;
USE bankdb;

CREATE TABLE bank_accounts (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    account_name  VARCHAR(100)  NOT NULL,
    account_type  VARCHAR(50)   NOT NULL,
    balance       DECIMAL(12,2) NOT NULL,
    FLAG          VARCHAR(64)    NOT NULL
);

-- Decoy rows (plausible bank-account data)
INSERT INTO bank_accounts (account_name, account_type, balance, FLAG) VALUES
    ('Alice Morgan',  'checking', 4820.55,  'ACCT-0001-DECOY'),
    ('Robert Chen',   'savings',  19250.00, 'ACCT-0002-DECOY');

-- Target row holding the real FLAG
INSERT INTO bank_accounts (account_name, account_type, balance, FLAG) VALUES
    ('Vault Holdings', 'reserve', 100000.00, 'P3nd_by_A1');

-- ============================================================================
-- DECOY / NOISE TABLES
-- Plausible but IRRELEVANT data to make the database look realistic and to
-- create decoys an attacker must sift through. These tables contain NO flags
-- and NO real secrets — purely noise. The intended path remains via the
-- `bank_accounts` table above.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- customers
-- ---------------------------------------------------------------------------
CREATE TABLE customers (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    full_name   VARCHAR(100) NOT NULL,
    email       VARCHAR(120) NOT NULL,
    phone       VARCHAR(30)  NOT NULL,
    created_at  DATETIME     NOT NULL
);

INSERT INTO customers (full_name, email, phone, created_at) VALUES
    ('Alice Morgan',    'alice.morgan@example.com',    '+1-202-555-0143', '2022-01-15 09:24:00'),
    ('Robert Chen',     'robert.chen@example.com',     '+1-415-555-0178', '2022-03-02 14:10:00'),
    ('Maria Gonzalez',  'maria.gonzalez@example.com',  '+1-312-555-0199', '2022-05-21 11:45:00'),
    ('David Okafor',    'david.okafor@example.com',    '+44-20-7946-0321','2022-07-09 16:30:00'),
    ('Yuki Tanaka',     'yuki.tanaka@example.com',     '+81-3-5555-0264', '2022-09-18 08:05:00'),
    ('Fatima Al-Sayed', 'fatima.alsayed@example.com',  '+971-4-555-0287', '2023-01-27 13:22:00'),
    ('Liam Murphy',     'liam.murphy@example.com',     '+353-1-555-0312', '2023-04-14 10:50:00'),
    ('Sofia Rossi',     'sofia.rossi@example.com',     '+39-06-555-0345', '2023-06-30 17:15:00');

-- ---------------------------------------------------------------------------
-- branches
-- ---------------------------------------------------------------------------
CREATE TABLE branches (
    id           INT AUTO_INCREMENT PRIMARY KEY,
    branch_name  VARCHAR(100) NOT NULL,
    city         VARCHAR(80)  NOT NULL,
    country      VARCHAR(80)  NOT NULL,
    swift_code   VARCHAR(11)  NOT NULL
);

INSERT INTO branches (branch_name, city, country, swift_code) VALUES
    ('Downtown Financial', 'New York',  'USA',     'HRONUS33XXX'),
    ('Bay Area Branch',    'San Francisco', 'USA', 'HRONUS44SFO'),
    ('City of London',     'London',    'United Kingdom', 'HRONGB2LXXX'),
    ('Marina Branch',      'Dubai',     'UAE',     'HRONAEADXXX'),
    ('Shibuya Office',     'Tokyo',     'Japan',   'HRONJPJTXXX');

-- ---------------------------------------------------------------------------
-- employees
-- ---------------------------------------------------------------------------
CREATE TABLE employees (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    role        VARCHAR(80)  NOT NULL,
    department  VARCHAR(80)  NOT NULL,
    hire_date   DATE         NOT NULL
);

INSERT INTO employees (name, role, department, hire_date) VALUES
    ('Grace Holloway',  'Branch Manager',     'Operations',     '2018-02-12'),
    ('Tomas Nowak',     'Teller',             'Retail Banking', '2020-06-01'),
    ('Priya Nair',      'Loan Officer',       'Lending',        '2019-11-19'),
    ('Carlos Mendes',   'Compliance Analyst', 'Risk',           '2021-03-08'),
    ('Hannah Berg',     'IT Administrator',   'Technology',     '2017-09-25'),
    ('Omar Haddad',     'Customer Advisor',   'Retail Banking', '2022-08-15');

-- ---------------------------------------------------------------------------
-- transactions
-- ---------------------------------------------------------------------------
CREATE TABLE transactions (
    id           INT AUTO_INCREMENT PRIMARY KEY,
    account_id   INT            NOT NULL,
    amount       DECIMAL(12,2)  NOT NULL,
    currency     VARCHAR(3)     NOT NULL,
    txn_type     VARCHAR(20)    NOT NULL,
    txn_date     DATETIME       NOT NULL,
    description  VARCHAR(160)   NOT NULL
);

INSERT INTO transactions (account_id, amount, currency, txn_type, txn_date, description) VALUES
    (1,  250.00,  'USD', 'deposit',    '2023-08-01 09:12:00', 'Payroll deposit'),
    (1,  -89.99,  'USD', 'withdrawal', '2023-08-03 18:45:00', 'Online purchase - electronics'),
    (2,  1500.00, 'USD', 'transfer',   '2023-08-05 11:30:00', 'Transfer to savings'),
    (2,  -200.00, 'USD', 'withdrawal', '2023-08-07 08:05:00', 'ATM cash withdrawal'),
    (1,  -45.20,  'USD', 'withdrawal', '2023-08-09 13:20:00', 'Grocery store'),
    (3,  5000.00, 'USD', 'deposit',    '2023-08-10 10:00:00', 'Wire transfer received'),
    (2,  -120.00, 'USD', 'withdrawal', '2023-08-12 19:10:00', 'Utility bill payment'),
    (1,  300.00,  'USD', 'deposit',    '2023-08-15 09:00:00', 'Refund - returned item'),
    (3,  -750.00, 'USD', 'transfer',   '2023-08-18 14:55:00', 'Rent payment'),
    (2,  60.00,   'USD', 'deposit',    '2023-08-20 16:40:00', 'Interest credit');

-- ---------------------------------------------------------------------------
-- audit_log
-- ---------------------------------------------------------------------------
CREATE TABLE audit_log (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    event       VARCHAR(120) NOT NULL,
    actor       VARCHAR(80)  NOT NULL,
    event_time  DATETIME     NOT NULL
);

INSERT INTO audit_log (event, actor, event_time) VALUES
    ('User login',            'alice.morgan@example.com', '2023-08-01 09:10:00'),
    ('Password changed',      'robert.chen@example.com',  '2023-08-04 12:33:00'),
    ('New customer onboarded','grace.holloway',           '2023-08-06 15:20:00'),
    ('Failed login attempt',  'unknown',                  '2023-08-08 22:14:00'),
    ('Report generated',      'carlos.mendes',            '2023-08-11 10:05:00');
