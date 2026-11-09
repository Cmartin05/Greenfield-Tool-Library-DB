DROP TABLE IF EXISTS stg_loans;
DROP TABLE IF EXISTS stg_certifications;
DROP TABLE IF EXISTS stg_inventory;
DROP TABLE IF EXISTS stg_staff;
DROP TABLE IF EXISTS stg_members;
DROP TABLE IF EXISTS stg_categories;

-- Load every CSV into a text-only staging table.
CREATE TABLE stg_categories (
    category_id VARCHAR(20),
    name VARCHAR(100),
    daily_late_fee VARCHAR(40),
    max_loan_days VARCHAR(20),
    requires_cert VARCHAR(10)
);

CREATE TABLE stg_members (
    member_id VARCHAR(20),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(255),
    zip VARCHAR(10),
    joined VARCHAR(20),
    status VARCHAR(30)
);

CREATE TABLE stg_staff (
    staff_id VARCHAR(20),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(255)
);

CREATE TABLE stg_inventory (
    tool_id VARCHAR(20),
    name VARCHAR(150),
    brand VARCHAR(100),
    category VARCHAR(100),
    purchased VARCHAR(20),
    price VARCHAR(40),
    `condition` VARCHAR(40)
);

CREATE TABLE stg_certifications (
    member_email VARCHAR(255),
    category VARCHAR(100),
    certified_on VARCHAR(20)
);

CREATE TABLE stg_loans (
    loan_id VARCHAR(20),
    tool_id VARCHAR(20),
    tool_name VARCHAR(150),
    category VARCHAR(100),
    member_email VARCHAR(255),
    member_name VARCHAR(255),
    member_zip VARCHAR(10),
    out_date VARCHAR(20),
    due_date VARCHAR(20),
    back_date VARCHAR(20),
    staff_email VARCHAR(255),
    fee_charged VARCHAR(40)
);

-- Import the CSV files.
LOAD DATA LOCAL INFILE 'data/categories.csv'
INTO TABLE stg_categories
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'data/members.csv'
INTO TABLE stg_members
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'data/staff.csv'
INTO TABLE stg_staff
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'data/inventory.csv'
INTO TABLE stg_inventory
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'data/certifications.csv'
INTO TABLE stg_certifications
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'data/loans.csv'
INTO TABLE stg_loans
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- Fill independent tables first.
INSERT INTO category
    (category_id, name, daily_late_fee,
     max_loan_days, requires_cert)
SELECT
    CAST(category_id AS UNSIGNED),
    name,
    CAST(daily_late_fee AS DECIMAL(8, 2)),
    CAST(max_loan_days AS UNSIGNED),
    CASE
        WHEN UPPER(TRIM(requires_cert)) = 'Y'
        THEN TRUE
        ELSE FALSE
    END
FROM stg_categories;

INSERT INTO `member`
    (member_id, first_name, last_name,
     email, zip, joined, status)
SELECT
    CAST(m.member_id AS UNSIGNED),
    m.first_name,
    m.last_name,
    LOWER(TRIM(m.email)),
    LPAD(TRIM(m.zip), 5, '0'),
    CASE
        WHEN m.joined LIKE '%/%/%'
            THEN STR_TO_DATE(m.joined, '%m/%d/%Y')
        ELSE STR_TO_DATE(m.joined, '%Y-%m-%d')
    END,
    REPLACE(LOWER(TRIM(m.status)), ' ', '_')
FROM stg_members AS m
INNER JOIN (
    SELECT
        LOWER(TRIM(email)) AS cleaned_email,
        MIN(CAST(member_id AS UNSIGNED)) AS smallest_id
    FROM stg_members
    GROUP BY LOWER(TRIM(email))
) AS keep_row
    ON LOWER(TRIM(m.email)) = keep_row.cleaned_email
   AND CAST(m.member_id AS UNSIGNED) = keep_row.smallest_id;

INSERT INTO staff
    (staff_id, first_name, last_name, email)
SELECT
    CAST(staff_id AS UNSIGNED),
    first_name,
    last_name,
    LOWER(TRIM(email))
FROM stg_staff;

-- Fill tables with foreign keys.

INSERT INTO tool
    (tool_id, name, brand, category_id,
     purchased, price, `condition`)
SELECT
    CAST(i.tool_id AS UNSIGNED),
    i.name,
    i.brand,
    c.category_id,
    CASE
        WHEN i.purchased LIKE '%/%/%'
            THEN STR_TO_DATE(i.purchased, '%m/%d/%Y')
        ELSE STR_TO_DATE(i.purchased, '%Y-%m-%d')
    END,
    CAST(
        REPLACE(REPLACE(TRIM(i.price), '$', ''), ',', '')
        AS DECIMAL(10, 2)
    ),
    REPLACE(LOWER(TRIM(i.`condition`)), ' ', '_')
FROM stg_inventory AS i
INNER JOIN category AS c
    ON LOWER(TRIM(i.category)) = LOWER(TRIM(c.name));

INSERT INTO certification
    (member_id, category_id, certified_on)
SELECT
    m.member_id,
    c.category_id,
    CASE
        WHEN sc.certified_on LIKE '%/%/%'
            THEN STR_TO_DATE(sc.certified_on, '%m/%d/%Y')
        ELSE STR_TO_DATE(sc.certified_on, '%Y-%m-%d')
    END
FROM stg_certifications AS sc
INNER JOIN `member` AS m
    ON LOWER(TRIM(sc.member_email)) = m.email
INNER JOIN category AS c
    ON LOWER(TRIM(sc.category)) = LOWER(TRIM(c.name));

-- Convert valid, unique loans into checkouts.
-- Calculate late fees using the actual category fee.
-- Ignore the original fee_charged values.
INSERT INTO checkout
    (checkout_id, tool_id, member_id, staff_id,
     checkout_date, due_date, return_date, late_fee)
SELECT DISTINCT
    CAST(l.loan_id AS UNSIGNED),
    t.tool_id,
    m.member_id,
    s.staff_id,
    l.parsed_out_date,
    l.parsed_due_date,
    l.parsed_back_date,
    CASE
        WHEN l.parsed_back_date > l.parsed_due_date
            THEN DATEDIFF(
                l.parsed_back_date,
                l.parsed_due_date
            ) * c.daily_late_fee
        ELSE 0.00
    END
FROM (
    SELECT
        loan_id,
        tool_id,
        member_email,
        staff_email,
        CASE
            WHEN out_date LIKE '%/%/%'
                THEN STR_TO_DATE(out_date, '%m/%d/%Y')
            ELSE STR_TO_DATE(out_date, '%Y-%m-%d')
        END AS parsed_out_date,
        CASE
            WHEN due_date LIKE '%/%/%'
                THEN STR_TO_DATE(due_date, '%m/%d/%Y')
            ELSE STR_TO_DATE(due_date, '%Y-%m-%d')
        END AS parsed_due_date,
        CASE
            WHEN TRIM(back_date) = ''
                THEN NULL
            WHEN back_date LIKE '%/%/%'
                THEN STR_TO_DATE(back_date, '%m/%d/%Y')
            ELSE STR_TO_DATE(back_date, '%Y-%m-%d')
        END AS parsed_back_date
    FROM stg_loans
) AS l
INNER JOIN tool AS t
    ON t.tool_id = CAST(l.tool_id AS UNSIGNED)
INNER JOIN `member` AS m
    ON m.email = LOWER(TRIM(l.member_email))
INNER JOIN staff AS s
    ON s.email = LOWER(TRIM(l.staff_email))
INNER JOIN category AS c
    ON c.category_id = t.category_id
WHERE l.parsed_due_date >= l.parsed_out_date
  AND (
      l.parsed_back_date IS NULL
      OR l.parsed_back_date >= l.parsed_out_date
  );

-- Remove staging tables.
DROP TABLE IF EXISTS stg_loans;
DROP TABLE IF EXISTS stg_certifications;
DROP TABLE IF EXISTS stg_inventory;
DROP TABLE IF EXISTS stg_staff;
DROP TABLE IF EXISTS stg_members;
DROP TABLE IF EXISTS stg_categories;