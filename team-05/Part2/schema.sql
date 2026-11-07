CREATE TABLE category (
    category_id INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    daily_late_fee DECIMAL(8,2) NOT NULL,
    max_loan_days INT NOT NULL,
    requires_cert BOOLEAN NOT NULL,
    PRIMARY KEY (category_id),
    UNIQUE (name),
    CONSTRAINT chk_category_late_fee
        CHECK (daily_late_fee >= 0),
    CONSTRAINT chk_category_max_days
        CHECK (max_loan_days >= 1)
);

CREATE TABLE `member` (
    member_id INT NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
    zip CHAR(5) NOT NULL,
    joined DATE NOT NULL,
    status ENUM('active', 'suspended') NOT NULL,
    PRIMARY KEY (member_id),
    UNIQUE (email)
);

CREATE TABLE staff (
    staff_id INT NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
    PRIMARY KEY (staff_id),
    UNIQUE (email)
);

CREATE TABLE tool (
    tool_id INT NOT NULL,
    name VARCHAR(150) NOT NULL,
    brand VARCHAR(100) NOT NULL,
    category_id INT NOT NULL,
    purchased DATE NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    `condition` ENUM(
        'good', 'fair', 'needs_repair', 'retired'
    ) NOT NULL,
    PRIMARY KEY (tool_id),
    CONSTRAINT fk_tool_category
        FOREIGN KEY (category_id)
        REFERENCES category(category_id),
    CONSTRAINT chk_tool_price
        CHECK (price >= 0)
);

CREATE TABLE certification (
    member_id INT NOT NULL,
    category_id INT NOT NULL,
    certified_on DATE NOT NULL,
    PRIMARY KEY (member_id, category_id),
    CONSTRAINT fk_certification_member
        FOREIGN KEY (member_id)
        REFERENCES `member`(member_id),
    CONSTRAINT fk_certification_category
        FOREIGN KEY (category_id)
        REFERENCES category(category_id)
);

CREATE TABLE checkout (
    checkout_id INT NOT NULL,
    tool_id INT NOT NULL,
    member_id INT NOT NULL,
    staff_id INT NOT NULL,
    checkout_date DATE NOT NULL,
    due_date DATE NOT NULL,
    return_date DATE NULL,
    late_fee DECIMAL(8,2) NOT NULL,
    PRIMARY KEY (checkout_id),
    CONSTRAINT fk_checkout_tool
        FOREIGN KEY (tool_id)
        REFERENCES tool(tool_id),
    CONSTRAINT fk_checkout_member
        FOREIGN KEY (member_id)
        REFERENCES `member`(member_id),
    CONSTRAINT fk_checkout_staff
        FOREIGN KEY (staff_id)
        REFERENCES staff(staff_id),
    CONSTRAINT chk_checkout_due_date
        CHECK (due_date >= checkout_date),
    CONSTRAINT chk_checkout_return_date
        CHECK (
            return_date IS NULL
            OR return_date >= checkout_date
        ),
    CONSTRAINT chk_checkout_late_fee
        CHECK (late_fee >= 0)
);
