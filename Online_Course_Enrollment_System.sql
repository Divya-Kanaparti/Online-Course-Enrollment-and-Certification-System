/* =====================================================================
   PROJECT 32 : ONLINE COURSE ENROLLMENT AND CERTIFICATION SYSTEM
   Database   : course_cert_db            
   Contents   : 1 Schema  2 Indexes  3 Triggers  4 Views  5 Procedures
                6 Sample data  7 Queries  8 Joins  9 Subqueries
                10 Business reports  11 Transactions  12 Procedure demos
                13 Index performance comparison
   How to run : Execute the sections in order in the MySQL CLI.
   
   ===================================================================== */


CREATE DATABASE IF NOT EXISTS course_cert_db;
USE course_cert_db;


/* =====================================================================
   1. DATABASE SCHEMA  (CREATE TABLE statements)
   ===================================================================== */

CREATE TABLE students (
    student_id     INT AUTO_INCREMENT PRIMARY KEY,
    first_name     VARCHAR(50)  NOT NULL,
    last_name      VARCHAR(50)  NOT NULL,
    email          VARCHAR(100) NOT NULL UNIQUE,
    phone          CHAR(10)     NOT NULL UNIQUE,
    gender         ENUM('Male','Female','Other') NOT NULL,
    date_of_birth  DATE         NOT NULL,
    city           VARCHAR(50)  NOT NULL,
    registered_on  DATE         NOT NULL DEFAULT (CURRENT_DATE),
    status         ENUM('Active','Inactive') NOT NULL DEFAULT 'Active',
    referred_by    INT          NULL,
    CONSTRAINT fk_students_referrer FOREIGN KEY (referred_by)
        REFERENCES students (student_id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT chk_students_email CHECK (email LIKE '%_@_%._%'),
    CONSTRAINT chk_students_phone CHECK (phone REGEXP '^[6-9][0-9]{9}$')
);

CREATE TABLE trainers (
    trainer_id        INT AUTO_INCREMENT PRIMARY KEY,
    trainer_name      VARCHAR(100) NOT NULL,
    email             VARCHAR(100) NOT NULL UNIQUE,
    phone             CHAR(10)     NOT NULL UNIQUE,
    specialization    VARCHAR(80)  NOT NULL,
    experience_years  TINYINT UNSIGNED NOT NULL DEFAULT 0,
    hire_date         DATE         NOT NULL,
    status            ENUM('Active','On Leave','Resigned') NOT NULL DEFAULT 'Active',
    CONSTRAINT chk_trainers_exp CHECK (experience_years <= 50)
);

CREATE TABLE courses (
    course_id        INT AUTO_INCREMENT PRIMARY KEY,
    course_name      VARCHAR(100)  NOT NULL UNIQUE,
    description      TEXT,
    category         VARCHAR(50)   NOT NULL,
    fee              DECIMAL(10,2) NOT NULL,
    duration_weeks   TINYINT UNSIGNED NOT NULL,
    pass_percentage  DECIMAL(5,2)  NOT NULL DEFAULT 50.00,
    is_active        BOOLEAN       NOT NULL DEFAULT TRUE,
    CONSTRAINT chk_courses_fee      CHECK (fee > 0),
    CONSTRAINT chk_courses_duration CHECK (duration_weeks > 0),
    CONSTRAINT chk_courses_pass     CHECK (pass_percentage BETWEEN 0 AND 100)
);

CREATE TABLE course_trainers (
    trainer_id   INT  NOT NULL,
    course_id    INT  NOT NULL,
    assigned_on  DATE NOT NULL DEFAULT (CURRENT_DATE),
    PRIMARY KEY (trainer_id, course_id),
    CONSTRAINT fk_ct_trainer FOREIGN KEY (trainer_id) REFERENCES trainers (trainer_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_ct_course  FOREIGN KEY (course_id)  REFERENCES courses (course_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE batches (
    batch_id       INT AUTO_INCREMENT PRIMARY KEY,
    batch_code     VARCHAR(20) NOT NULL UNIQUE,
    course_id      INT         NOT NULL,
    trainer_id     INT         NOT NULL,
    start_date     DATE        NOT NULL,
    end_date       DATE        NOT NULL,
    max_seats      TINYINT UNSIGNED NOT NULL DEFAULT 20,
    mode           ENUM('Online','Offline','Hybrid') NOT NULL DEFAULT 'Online',
    batch_status   ENUM('Upcoming','Ongoing','Completed','Cancelled') NOT NULL DEFAULT 'Upcoming',
    CONSTRAINT chk_batches_dates CHECK (end_date > start_date),
    CONSTRAINT chk_batches_seats CHECK (max_seats BETWEEN 1 AND 100),
    CONSTRAINT fk_batches_course  FOREIGN KEY (course_id)  REFERENCES courses (course_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_batches_trainer FOREIGN KEY (trainer_id) REFERENCES trainers (trainer_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    -- a batch may only be run by a trainer who is assigned to that course
    CONSTRAINT fk_batches_assignment FOREIGN KEY (trainer_id, course_id)
        REFERENCES course_trainers (trainer_id, course_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE enrollments (
    enrollment_id      INT AUTO_INCREMENT PRIMARY KEY,
    student_id         INT           NOT NULL,
    batch_id           INT           NOT NULL,
    enrollment_date    DATE          NOT NULL DEFAULT (CURRENT_DATE),
    fee_paid           DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    payment_status     ENUM('Pending','Partial','Paid') NOT NULL DEFAULT 'Pending',
    enrollment_status  ENUM('Enrolled','Completed','Failed','Dropped') NOT NULL DEFAULT 'Enrolled',
    CONSTRAINT uq_enrollment UNIQUE (student_id, batch_id),
    CONSTRAINT chk_enrollments_fee CHECK (fee_paid >= 0),
    CONSTRAINT fk_enroll_student FOREIGN KEY (student_id) REFERENCES students (student_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_enroll_batch   FOREIGN KEY (batch_id)   REFERENCES batches (batch_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE assessments (
    assessment_id    INT AUTO_INCREMENT PRIMARY KEY,
    batch_id         INT          NOT NULL,
    assessment_name  VARCHAR(100) NOT NULL,
    assessment_type  ENUM('Quiz','Mid-Term','Final Exam','Project') NOT NULL,
    max_marks        DECIMAL(5,2) NOT NULL,
    passing_marks    DECIMAL(5,2) NOT NULL,
    assessment_date  DATE         NOT NULL,
    CONSTRAINT uq_assessment UNIQUE (batch_id, assessment_name),
    CONSTRAINT chk_assess_max  CHECK (max_marks > 0),
    CONSTRAINT chk_assess_pass CHECK (passing_marks >= 0 AND passing_marks <= max_marks),
    CONSTRAINT fk_assess_batch FOREIGN KEY (batch_id) REFERENCES batches (batch_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE assessment_results (
    result_id       INT AUTO_INCREMENT PRIMARY KEY,
    assessment_id   INT          NOT NULL,
    enrollment_id   INT          NOT NULL,
    marks_obtained  DECIMAL(5,2) NOT NULL,
    result_status   ENUM('Pass','Fail') NOT NULL DEFAULT 'Fail',   -- set by trigger
    CONSTRAINT uq_result UNIQUE (assessment_id, enrollment_id),
    CONSTRAINT chk_result_marks CHECK (marks_obtained >= 0),
    CONSTRAINT fk_result_assess FOREIGN KEY (assessment_id) REFERENCES assessments (assessment_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_result_enroll FOREIGN KEY (enrollment_id) REFERENCES enrollments (enrollment_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE certificates (
    certificate_id    INT AUTO_INCREMENT PRIMARY KEY,
    certificate_no    VARCHAR(25)  NOT NULL UNIQUE,
    enrollment_id     INT          NOT NULL UNIQUE,
    issue_date        DATE         NOT NULL,
    final_percentage  DECIMAL(5,2) NOT NULL,
    grade             ENUM('A+','A','B+','B','C') NOT NULL,
    CONSTRAINT chk_cert_pct CHECK (final_percentage BETWEEN 0 AND 100),
    CONSTRAINT fk_cert_enroll FOREIGN KEY (enrollment_id) REFERENCES enrollments (enrollment_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE course_fee_audit (
    audit_id    INT AUTO_INCREMENT PRIMARY KEY,
    course_id   INT           NOT NULL,
    old_fee     DECIMAL(10,2) NOT NULL,
    new_fee     DECIMAL(10,2) NOT NULL,
    changed_on  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    changed_by  VARCHAR(100)  NOT NULL,
    CONSTRAINT fk_audit_course FOREIGN KEY (course_id) REFERENCES courses (course_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);


/* =====================================================================
   2. INDEXES
   ===================================================================== */

CREATE INDEX idx_students_city ON students (city);
CREATE INDEX idx_students_name ON students (last_name, first_name);
CREATE INDEX idx_batches_dates ON batches (start_date, end_date);
CREATE INDEX idx_batches_status ON batches (batch_status);
CREATE INDEX idx_enrollments_date ON enrollments (enrollment_date);
CREATE INDEX idx_enrollments_status ON enrollments (payment_status, enrollment_status);


/* =====================================================================
   3. TRIGGERS
   ===================================================================== */

DELIMITER $$

-- Trigger 1: validate marks and auto-compute Pass/Fail on INSERT
CREATE TRIGGER trg_results_before_insert
BEFORE INSERT ON assessment_results
FOR EACH ROW
BEGIN
    DECLARE v_max_marks  DECIMAL(5,2);
    DECLARE v_pass_marks DECIMAL(5,2);
    DECLARE v_batch_a    INT;
    DECLARE v_batch_e    INT;

    SELECT max_marks, passing_marks, batch_id
      INTO v_max_marks, v_pass_marks, v_batch_a
      FROM assessments WHERE assessment_id = NEW.assessment_id;
    SELECT batch_id INTO v_batch_e
      FROM enrollments WHERE enrollment_id = NEW.enrollment_id;

    IF NEW.marks_obtained > v_max_marks THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Marks obtained cannot exceed the maximum marks';
    END IF;
    IF v_batch_a <> v_batch_e THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Assessment does not belong to the student''s batch';
    END IF;
    SET NEW.result_status = IF(NEW.marks_obtained >= v_pass_marks, 'Pass', 'Fail');
END$$

-- Trigger 2: validate updated marks and confirm assessment/enrollment batch match
CREATE TRIGGER trg_results_before_update
BEFORE UPDATE ON assessment_results
FOR EACH ROW
BEGIN
    DECLARE v_max_marks  DECIMAL(5,2);
    DECLARE v_pass_marks DECIMAL(5,2);
    DECLARE v_batch_a    INT;
    DECLARE v_batch_e    INT;

    -- Get the assessment's maximum marks, pass marks and batch.
    SELECT max_marks, passing_marks, batch_id
      INTO v_max_marks, v_pass_marks, v_batch_a
      FROM assessments
     WHERE assessment_id = NEW.assessment_id;

    -- Get the batch in which this student is enrolled.
    SELECT batch_id
      INTO v_batch_e
      FROM enrollments
     WHERE enrollment_id = NEW.enrollment_id;

    IF NEW.marks_obtained < 0 OR NEW.marks_obtained > v_max_marks THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Marks must be between 0 and maximum marks';
    END IF;

    -- Do not allow a result from one batch to be assigned to another batch's student.
    IF v_batch_a <> v_batch_e THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Assessment does not belong to the student''s batch';
    END IF;

    SET NEW.result_status = IF(NEW.marks_obtained >= v_pass_marks, 'Pass', 'Fail');
END$$

-- Trigger 3: once a certificate is issued, mark the enrollment as Completed
CREATE TRIGGER trg_certificate_after_insert
AFTER INSERT ON certificates
FOR EACH ROW
BEGIN
    UPDATE enrollments
       SET enrollment_status = 'Completed'
     WHERE enrollment_id = NEW.enrollment_id;
END$$

-- Trigger 4: audit trail for every change of a course fee
CREATE TRIGGER trg_course_fee_audit
AFTER UPDATE ON courses
FOR EACH ROW
BEGIN
    IF OLD.fee <> NEW.fee THEN
        INSERT INTO course_fee_audit (course_id, old_fee, new_fee, changed_by)
        VALUES (NEW.course_id, OLD.fee, NEW.fee, CURRENT_USER());
    END IF;
END$$

DELIMITER ;


/* =====================================================================
   4. VIEWS
   ===================================================================== */

-- View 1: one row per enrollment with student, course, trainer and money details
CREATE OR REPLACE VIEW v_enrollment_details AS
SELECT e.enrollment_id,
       s.student_id,
       CONCAT(s.first_name, ' ', s.last_name) AS student_name,
       s.email,
       c.course_name,
       b.batch_code,
       b.batch_status,
       t.trainer_name,
       e.enrollment_date,
       c.fee AS course_fee,
       e.fee_paid,
       c.fee - e.fee_paid AS balance_due,
       e.payment_status,
       e.enrollment_status
FROM enrollments e
JOIN students s ON s.student_id = e.student_id
JOIN batches  b ON b.batch_id   = e.batch_id
JOIN courses  c ON c.course_id  = b.course_id
JOIN trainers t ON t.trainer_id = b.trainer_id;

-- View 2: batch dashboard (seats, enrolments, collections)
CREATE OR REPLACE VIEW v_batch_summary AS
SELECT b.batch_id,
       b.batch_code,
       c.course_name,
       t.trainer_name,
       b.mode,
       b.start_date,
       b.end_date,
       b.batch_status,
       b.max_seats,
       COUNT(CASE WHEN e.enrollment_status <> 'Dropped' THEN e.enrollment_id END) AS active_students,
       COUNT(CASE WHEN e.enrollment_status =  'Dropped' THEN e.enrollment_id END) AS dropped_students,
       b.max_seats - COUNT(CASE WHEN e.enrollment_status <> 'Dropped' THEN e.enrollment_id END) AS seats_available,
       COALESCE(SUM(e.fee_paid), 0.00) AS fees_collected
FROM batches b
JOIN courses  c ON c.course_id  = b.course_id
JOIN trainers t ON t.trainer_id = b.trainer_id
LEFT JOIN enrollments e ON e.batch_id = b.batch_id
GROUP BY b.batch_id, b.batch_code, c.course_name, t.trainer_name, b.mode,
         b.start_date, b.end_date, b.batch_status, b.max_seats;

-- View 3: certificate eligibility (excludes Dropped and Failed enrolments; checks marks and fees)
CREATE OR REPLACE VIEW v_certificate_eligibility AS
SELECT base.*,
       CASE
           WHEN base.enrollment_status = 'Dropped'  THEN 'Not Eligible - Dropped'
           WHEN base.enrollment_status = 'Failed'  THEN 'Not Eligible - Failed'
           WHEN base.batch_status <> 'Completed' THEN 'In Progress'
           WHEN base.total_assessments = 0
                OR base.attempted < base.total_assessments   THEN 'Not Eligible - Assessments Incomplete'
           WHEN base.final_percentage < base.pass_percentage   THEN 'Not Eligible - Below Pass %'
           WHEN base.payment_status <> 'Paid' THEN 'Not Eligible - Fee Not Cleared'
           ELSE 'Eligible'
       END AS eligibility
FROM (
    SELECT e.enrollment_id,
           s.student_id,
           CONCAT(s.first_name, ' ', s.last_name) AS student_name,
           b.batch_id,
           b.batch_code,
           b.batch_status,
           c.course_id,
           c.course_name,
           c.pass_percentage,
           e.payment_status,
           e.enrollment_status,
           COALESCE(a.total_assessments, 0) AS total_assessments,
           COALESCE(r.attempted, 0) AS attempted,
           COALESCE(r.obtained, 0) AS marks_obtained,
           COALESCE(a.total_max, 0) AS max_marks,
           ROUND(COALESCE(r.obtained, 0) * 100.0 / NULLIF(a.total_max, 0), 2) AS final_percentage,
           CASE WHEN cert.certificate_id IS NULL THEN 'No' ELSE 'Yes' END     AS certificate_issued
    FROM enrollments e
    JOIN students s ON s.student_id = e.student_id
    JOIN batches  b ON b.batch_id   = e.batch_id
    JOIN courses  c ON c.course_id  = b.course_id
    LEFT JOIN (SELECT enrollment_id, COUNT(*) AS attempted, SUM(marks_obtained) AS obtained
               FROM assessment_results GROUP BY enrollment_id) r ON r.enrollment_id = e.enrollment_id
    LEFT JOIN (SELECT batch_id, COUNT(*) AS total_assessments, SUM(max_marks) AS total_max
               FROM assessments GROUP BY batch_id) a ON a.batch_id = b.batch_id
    LEFT JOIN certificates cert ON cert.enrollment_id = e.enrollment_id
) base;


/* =====================================================================
   5. STORED PROCEDURES
   ===================================================================== */

DELIMITER $$

-- Procedure 1: safe enrolment (seat check + fee status) wrapped in a transaction
CREATE PROCEDURE sp_enroll_student (
    IN p_student_id INT,
    IN p_batch_id   INT,
    IN p_fee_paid   DECIMAL(10,2)
)
BEGIN
    DECLARE v_fee    DECIMAL(10,2);
    DECLARE v_seats  INT;
    DECLARE v_status VARCHAR(20);
    DECLARE v_taken  INT;
    DECLARE v_pay    VARCHAR(10);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT c.fee, b.max_seats, b.batch_status
      INTO v_fee, v_seats, v_status
      FROM batches b
      JOIN courses c ON c.course_id = b.course_id
     WHERE b.batch_id = p_batch_id
       FOR UPDATE;

    IF v_status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Batch not found';
    END IF;
    IF v_status NOT IN ('Upcoming', 'Ongoing') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Batch is not open for enrolment';
    END IF;

    SELECT COUNT(*) INTO v_taken
      FROM enrollments
     WHERE batch_id = p_batch_id AND enrollment_status <> 'Dropped';
    IF v_taken >= v_seats THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Batch is full';
    END IF;
    IF p_fee_paid IS NULL OR p_fee_paid < 0 OR p_fee_paid > v_fee THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid fee amount';
    END IF;

    SET v_pay = CASE WHEN p_fee_paid >= v_fee THEN 'Paid'
                     WHEN p_fee_paid > 0      THEN 'Partial'
                     ELSE 'Pending' END;

    INSERT INTO enrollments (student_id, batch_id, enrollment_date, fee_paid, payment_status)
    VALUES (p_student_id, p_batch_id, CURDATE(), p_fee_paid, v_pay);

    COMMIT;
    SELECT 'Enrolment successful' AS message, LAST_INSERT_ID() AS enrollment_id, v_pay AS payment_status;
END$$

-- Procedure 2: issue certificates to every eligible student (one batch, or all if NULL)
CREATE PROCEDURE sp_issue_certificates (
    IN p_batch_id   INT,
    IN p_issue_date DATE
)
BEGIN
    DECLARE v_count INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Stage the eligible enrolments first. The trigger on certificates updates
    -- enrollments, and MySQL does not allow a trigger to modify a table that the
    -- invoking statement is reading (error 1442), so the INSERT reads only this temp table.
    DROP TEMPORARY TABLE IF EXISTS tmp_eligible;
    CREATE TEMPORARY TABLE tmp_eligible AS
    SELECT v.enrollment_id,
           v.final_percentage,
           COALESCE(p_issue_date, LEAST(DATE_ADD(b.end_date, INTERVAL 7 DAY), CURDATE())) AS issue_date
    FROM v_certificate_eligibility v
    JOIN batches b ON b.batch_id = v.batch_id
    WHERE v.eligibility = 'Eligible'
      AND v.certificate_issued = 'No'
      AND (p_batch_id IS NULL OR v.batch_id = p_batch_id);

    INSERT INTO certificates (certificate_no, enrollment_id, issue_date, final_percentage, grade)
    SELECT CONCAT('CERT-', YEAR(x.issue_date), '-', LPAD(x.enrollment_id, 4, '0')),
           x.enrollment_id,
           x.issue_date,
           x.final_percentage,
           CASE WHEN x.final_percentage >= 90 THEN 'A+'
                WHEN x.final_percentage >= 80 THEN 'A'
                WHEN x.final_percentage >= 70 THEN 'B+'
                WHEN x.final_percentage >= 60 THEN 'B'
                ELSE 'C' END
    FROM tmp_eligible x;
    SET v_count = ROW_COUNT();
    DROP TEMPORARY TABLE IF EXISTS tmp_eligible;

    COMMIT;
    SELECT v_count AS certificates_issued;
END$$

-- Procedure 3: ranked performance sheet of one batch
CREATE PROCEDURE sp_batch_performance (IN p_batch_id INT)
BEGIN
    SELECT v.student_name,
           v.marks_obtained,
           v.max_marks,
           v.final_percentage,
           RANK() OVER (ORDER BY v.final_percentage DESC) AS batch_rank,
           v.eligibility
    FROM v_certificate_eligibility v
    WHERE v.batch_id = p_batch_id
      AND v.enrollment_status <> 'Dropped'
    ORDER BY batch_rank, v.student_name;
END$$

DELIMITER ;


/* =====================================================================
   6. SAMPLE DATA  (simulated)
   ===================================================================== */

INSERT INTO students (student_id, first_name, last_name, email, phone, gender, date_of_birth, city, registered_on, status, referred_by) VALUES
  (1, 'Aarav', 'Sharma', 'aarav.sharma@gmail.com', '9876500001', 'Male', '2000-03-14', 'Hyderabad', '2025-12-20', 'Active', NULL),
  (2, 'Priya', 'Reddy', 'priya.reddy@gmail.com', '9876500002', 'Female', '1999-07-22', 'Hyderabad', '2025-12-28', 'Active', 1),
  (3, 'Rohan', 'Verma', 'rohan.verma@outlook.com', '9876500003', 'Male', '2001-01-09', 'Bengaluru', '2026-01-05', 'Active', 1),
  (4, 'Ananya', 'Iyer', 'ananya.iyer@yahoo.com', '9876500004', 'Female', '1998-11-30', 'Chennai', '2026-01-06', 'Active', NULL),
  (5, 'Vikram', 'Singh', 'vikram.singh@gmail.com', '9876500005', 'Male', '1997-05-18', 'Delhi', '2026-01-08', 'Active', 2),
  (6, 'Sneha', 'Patil', 'sneha.patil@outlook.com', '9876500006', 'Female', '2000-09-02', 'Pune', '2026-01-20', 'Active', 3),
  (7, 'Mohammed', 'Faiz', 'mohammed.faiz@gmail.com', '9876500007', 'Male', '1999-12-25', 'Hyderabad', '2026-01-22', 'Active', 2),
  (8, 'Kavya', 'Nair', 'kavya.nair@yahoo.com', '9876500008', 'Female', '2001-04-11', 'Kochi', '2026-02-03', 'Active', 4),
  (9, 'Aditya', 'Rao', 'aditya.rao@gmail.com', '9876500009', 'Male', '2000-08-27', 'Bengaluru', '2026-02-05', 'Active', 3),
  (10, 'Ishita', 'Gupta', 'ishita.gupta@outlook.com', '9876500010', 'Female', '1998-02-16', 'Mumbai', '2026-02-10', 'Active', NULL),
  (11, 'Sanjay', 'Kumar', 'sanjay.kumar@gmail.com', '9876500011', 'Male', '1996-10-05', 'Hyderabad', '2026-04-15', 'Active', 7),
  (12, 'Neha', 'Joshi', 'neha.joshi@yahoo.com', '9876500012', 'Female', '2002-06-19', 'Pune', '2026-04-18', 'Active', 6),
  (13, 'Tarun', 'Bhatia', 'tarun.bhatia@gmail.com', '9876500013', 'Male', '1997-03-08', 'Delhi', '2026-05-12', 'Active', 5),
  (14, 'Lakshmi', 'Devi', 'lakshmi.devi@gmail.com', '9876500014', 'Female', '1995-01-29', 'Vijayawada', '2026-08-25', 'Inactive', 2),
  (15, 'Imran', 'Sheikh', 'imran.sheikh@outlook.com', '9876500015', 'Male', '2002-12-12', 'Mumbai', '2026-10-20', 'Active', 10);

INSERT INTO trainers (trainer_id, trainer_name, email, phone, specialization, experience_years, hire_date, status) VALUES
  (1, 'Ramesh Iyer', 'ramesh.iyer@brightlearn.in', '9810000001', 'Python & Data Analytics', 9, '2017-06-01', 'Active'),
  (2, 'Sunitha Reddy', 'sunitha.reddy@brightlearn.in', '9810000002', 'Full Stack Development', 7, '2019-02-15', 'Active'),
  (3, 'Karthik Narayanan', 'karthik.n@brightlearn.in', '9810000003', 'Machine Learning', 11, '2016-09-12', 'Active'),
  (4, 'Meera Nair', 'meera.nair@brightlearn.in', '9810000004', 'Cloud Computing', 8, '2018-04-23', 'Active'),
  (5, 'Arjun Mehta', 'arjun.mehta@brightlearn.in', '9810000005', 'Cyber Security', 6, '2020-01-10', 'Active'),
  (6, 'Divya Kapoor', 'divya.kapoor@brightlearn.in', '9810000006', 'UI/UX Design', 5, '2021-07-05', 'Active'),
  (7, 'Farhan Ali', 'farhan.ali@brightlearn.in', '9810000007', 'SQL & Databases', 4, '2022-03-14', 'Active'),
  (8, 'Suresh Babu', 'suresh.babu@brightlearn.in', '9810000008', 'Digital Marketing', 10, '2018-11-19', 'On Leave');

INSERT INTO courses (course_id, course_name, description, category, fee, duration_weeks, pass_percentage) VALUES
  (1, 'Python Programming for Beginners', 'Core Python, data structures, file handling and mini projects.', 'Programming', 12000, 8, 50),
  (2, 'Full Stack Web Development', 'HTML, CSS, JavaScript, Node.js, REST APIs and MySQL integration.', 'Web Development', 28000, 16, 55),
  (3, 'Data Analysis with Excel and SQL', 'Excel analytics, MySQL querying and dashboard building.', 'Data', 15000, 6, 50),
  (4, 'Machine Learning Fundamentals', 'Supervised and unsupervised learning with scikit-learn.', 'Data Science', 32000, 12, 60),
  (5, 'Cloud Computing with AWS', 'EC2, S3, IAM, VPC and serverless basics.', 'Cloud', 25000, 10, 55),
  (6, 'Cyber Security Essentials', 'Network security, threats, cryptography and ethical hacking basics.', 'Security', 22000, 8, 50),
  (7, 'UI/UX Design Basics', 'Design thinking, wireframing and prototyping.', 'Design', 14000, 6, 50),
  (8, 'Digital Marketing Fundamentals', 'SEO, social media, email and analytics.', 'Marketing', 10000, 4, 50);

INSERT INTO course_trainers (trainer_id, course_id, assigned_on) VALUES
  (1, 1, '2017-06-01'),
  (1, 3, '2018-01-10'),
  (7, 3, '2022-04-01'),
  (2, 2, '2019-03-01'),
  (3, 4, '2016-10-01'),
  (4, 5, '2018-05-15'),
  (5, 6, '2020-02-01'),
  (6, 7, '2021-08-01'),
  (8, 8, '2018-12-01'),
  (7, 1, '2022-06-15');

INSERT INTO batches (batch_id, batch_code, course_id, trainer_id, start_date, end_date, max_seats, mode, batch_status) VALUES
  (1, 'PY-JAN26', 1, 1, '2026-01-12', '2026-03-08', 20, 'Online', 'Completed'),
  (2, 'SQL-FEB26', 3, 7, '2026-02-02', '2026-03-15', 15, 'Offline', 'Completed'),
  (3, 'WEB-FEB26', 2, 2, '2026-02-16', '2026-06-07', 25, 'Hybrid', 'Completed'),
  (4, 'ML-APR26', 4, 3, '2026-04-06', '2026-06-28', 18, 'Online', 'Completed'),
  (5, 'AWS-MAY26', 5, 4, '2026-05-04', '2026-07-12', 20, 'Online', 'Completed'),
  (6, 'SEC-JUN26', 6, 5, '2026-06-01', '2026-07-26', 15, 'Hybrid', 'Completed'),
  (7, 'PY-AUG26', 1, 7, '2026-08-03', '2026-09-27', 20, 'Online', 'Completed'),
  (8, 'DA-SEP26', 3, 1, '2026-09-07', '2026-10-18', 15, 'Offline', 'Completed'),
  (9, 'WEB-SEP26', 2, 2, '2026-09-14', '2027-01-03', 25, 'Hybrid', 'Ongoing'),
  (10, 'ML-OCT26', 4, 3, '2026-10-05', '2026-12-27', 18, 'Online', 'Ongoing'),
  (11, 'AWS-NOV26', 5, 4, '2026-11-23', '2027-01-31', 20, 'Online', 'Upcoming'),
  (12, 'UX-DEC26', 7, 6, '2026-12-07', '2027-01-17', 12, 'Offline', 'Upcoming');

INSERT INTO enrollments (enrollment_id, student_id, batch_id, enrollment_date, fee_paid, payment_status, enrollment_status) VALUES
  (1, 1, 1, '2025-12-28', 12000, 'Paid', 'Enrolled'),
  (2, 2, 1, '2026-01-02', 12000, 'Paid', 'Enrolled'),
  (3, 3, 1, '2026-01-07', 12000, 'Paid', 'Enrolled'),
  (4, 4, 1, '2026-01-08', 12000, 'Paid', 'Failed'),
  (5, 5, 1, '2026-01-09', 6000, 'Partial', 'Enrolled'),
  (6, 2, 2, '2026-01-20', 15000, 'Paid', 'Enrolled'),
  (7, 6, 2, '2026-01-24', 15000, 'Paid', 'Enrolled'),
  (8, 7, 2, '2026-01-28', 15000, 'Paid', 'Failed'),
  (9, 1, 3, '2026-02-03', 28000, 'Paid', 'Enrolled'),
  (10, 8, 3, '2026-02-06', 28000, 'Paid', 'Enrolled'),
  (11, 9, 3, '2026-02-08', 28000, 'Paid', 'Enrolled'),
  (12, 10, 3, '2026-02-12', 14000, 'Partial', 'Dropped'),
  (13, 3, 4, '2026-03-25', 32000, 'Paid', 'Enrolled'),
  (14, 9, 4, '2026-03-28', 32000, 'Paid', 'Failed'),
  (15, 5, 4, '2026-03-30', 32000, 'Paid', 'Enrolled'),
  (16, 7, 5, '2026-04-20', 25000, 'Paid', 'Enrolled'),
  (17, 11, 5, '2026-04-22', 25000, 'Paid', 'Enrolled'),
  (18, 12, 5, '2026-04-25', 25000, 'Paid', 'Failed'),
  (19, 13, 6, '2026-05-18', 22000, 'Paid', 'Enrolled'),
  (20, 4, 6, '2026-05-20', 22000, 'Paid', 'Enrolled'),
  (21, 6, 7, '2026-07-20', 12000, 'Paid', 'Enrolled'),
  (22, 11, 7, '2026-07-22', 8000, 'Partial', 'Enrolled'),
  (23, 12, 7, '2026-07-25', 12000, 'Paid', 'Enrolled'),
  (24, 13, 7, '2026-07-27', 12000, 'Paid', 'Failed'),
  (25, 3, 8, '2026-08-25', 15000, 'Paid', 'Enrolled'),
  (26, 8, 8, '2026-08-28', 15000, 'Paid', 'Enrolled'),
  (27, 14, 8, '2026-08-30', 7500, 'Partial', 'Dropped'),
  (28, 2, 9, '2026-09-01', 28000, 'Paid', 'Enrolled'),
  (29, 7, 9, '2026-09-03', 14000, 'Partial', 'Enrolled'),
  (30, 6, 10, '2026-09-22', 32000, 'Paid', 'Enrolled'),
  (31, 10, 10, '2026-09-25', 32000, 'Paid', 'Enrolled'),
  (32, 3, 11, '2026-11-05', 0, 'Pending', 'Enrolled');

INSERT INTO assessments (assessment_id, batch_id, assessment_name, assessment_type, max_marks, passing_marks, assessment_date) VALUES
  (1, 1, 'Mid-Term Test', 'Mid-Term', 40, 16, '2026-02-09'),
  (2, 1, 'Final Exam', 'Final Exam', 60, 24, '2026-03-05'),
  (3, 2, 'Mid-Term Test', 'Mid-Term', 40, 16, '2026-02-23'),
  (4, 2, 'Final Exam', 'Final Exam', 60, 24, '2026-03-12'),
  (5, 3, 'Mid-Term Test', 'Mid-Term', 40, 16, '2026-03-16'),
  (6, 3, 'Capstone Project', 'Project', 60, 24, '2026-06-04'),
  (7, 4, 'Mid-Term Test', 'Mid-Term', 40, 16, '2026-05-04'),
  (8, 4, 'Capstone Project', 'Project', 60, 24, '2026-06-25'),
  (9, 5, 'Mid-Term Test', 'Mid-Term', 40, 16, '2026-06-01'),
  (10, 5, 'Final Exam', 'Final Exam', 60, 24, '2026-07-09'),
  (11, 6, 'Mid-Term Test', 'Mid-Term', 40, 16, '2026-06-29'),
  (12, 6, 'Final Exam', 'Final Exam', 60, 24, '2026-07-23'),
  (13, 7, 'Mid-Term Test', 'Mid-Term', 40, 16, '2026-08-31'),
  (14, 7, 'Final Exam', 'Final Exam', 60, 24, '2026-09-24'),
  (15, 8, 'Mid-Term Test', 'Mid-Term', 40, 16, '2026-09-28'),
  (16, 8, 'Final Exam', 'Final Exam', 60, 24, '2026-10-15'),
  (17, 9, 'Mid-Term Test', 'Mid-Term', 40, 16, '2026-10-12'),
  (18, 10, 'Mid-Term Test', 'Mid-Term', 40, 16, '2026-11-02');

-- result_status is not supplied: trigger trg_results_before_insert computes Pass/Fail
INSERT INTO assessment_results (result_id, assessment_id, enrollment_id, marks_obtained) VALUES
  (1, 1, 1, 34),
  (2, 2, 1, 51),
  (3, 1, 2, 36),
  (4, 2, 2, 55),
  (5, 1, 3, 28.5),
  (6, 2, 3, 41),
  (7, 1, 4, 15),
  (8, 2, 4, 22),
  (9, 1, 5, 30),
  (10, 2, 5, 44),
  (11, 3, 6, 33),
  (12, 4, 6, 49),
  (13, 3, 7, 25),
  (14, 4, 7, 38),
  (15, 3, 8, 18),
  (16, 4, 8, 30),
  (17, 5, 9, 32),
  (18, 6, 9, 46),
  (19, 5, 10, 37),
  (20, 6, 10, 54),
  (21, 5, 11, 24),
  (22, 6, 11, 35.5),
  (23, 5, 12, 20),
  (24, 7, 13, 30),
  (25, 8, 13, 42),
  (26, 7, 14, 26),
  (27, 8, 14, 33),
  (28, 7, 15, 35),
  (29, 8, 15, 50),
  (30, 9, 16, 29),
  (31, 10, 16, 40),
  (32, 9, 17, 34),
  (33, 10, 17, 52),
  (34, 9, 18, 21.5),
  (35, 10, 18, 30),
  (36, 11, 19, 31),
  (37, 12, 19, 45),
  (38, 11, 20, 27),
  (39, 12, 20, 38),
  (40, 13, 21, 38),
  (41, 14, 21, 56),
  (42, 13, 22, 29),
  (43, 14, 22, 43),
  (44, 13, 23, 22),
  (45, 14, 23, 33),
  (46, 13, 24, 17),
  (47, 14, 24, 25),
  (48, 15, 25, 35),
  (49, 16, 25, 51),
  (50, 15, 26, 30),
  (51, 16, 26, 46),
  (52, 15, 27, 14),
  (53, 17, 28, 31),
  (54, 17, 29, 26),
  (55, 18, 30, 33),
  (56, 18, 31, 22);

-- Issue certificates for every eligible student of all completed batches
-- (the procedure reads the view v_certificate_eligibility; trigger 3 then marks enrolments Completed)
CALL sp_issue_certificates(NULL, NULL);


/* ===============================================================
   7. BASIC SQL QUERIES
   ===================================================================== */

-- Q1. Display active students from Hyderabad
SELECT student_id, first_name, last_name, email, city
FROM students
WHERE city = 'Hyderabad' AND status = 'Active';

-- Q2. Display all different cities
SELECT DISTINCT city
FROM students
ORDER BY city;

-- Q3. Insert a new student (run inside a transaction for practice)
START TRANSACTION;
INSERT INTO students
(first_name, last_name, email, phone, gender, date_of_birth, city, referred_by)
VALUES
('Pooja', 'Menon', 'pooja.menon@gmail.com', '9876500016',
 'Female', '2001-08-21', 'Kochi', 4);
SELECT * FROM students WHERE email = 'pooja.menon@gmail.com';
ROLLBACK;

-- Q4. Increase the fee of Cloud courses by 10%
START TRANSACTION;
UPDATE courses
SET fee = fee * 1.10
WHERE category = 'Cloud';
SELECT course_name, fee FROM courses WHERE category = 'Cloud';
ROLLBACK;

-- Q5. Delete unpaid enrollments from upcoming batches (practice only)
START TRANSACTION;
DELETE FROM enrollments
WHERE payment_status = 'Pending'
  AND batch_id IN (
      SELECT batch_id FROM batches
      WHERE batch_status = 'Upcoming'
  );
SELECT * FROM enrollments WHERE payment_status = 'Pending';
ROLLBACK;

-- Q6. Display the lowest, highest and average course fee
SELECT MIN(fee) AS lowest_fee,
       MAX(fee) AS highest_fee,
       AVG(fee) AS average_fee
FROM courses;

-- Q7. Show courses having at least 3 enrollments
SELECT c.course_name, COUNT(e.enrollment_id) AS total_enrollments
FROM courses c
JOIN batches b ON c.course_id = b.course_id
JOIN enrollments e ON b.batch_id = e.batch_id
GROUP BY c.course_name
HAVING COUNT(e.enrollment_id) >= 3;

-- Q8. Display student names in uppercase
SELECT UPPER(CONCAT(first_name, ' ', last_name)) AS student_name
FROM students;

-- Q9. Display batch details with duration in days
SELECT batch_code, start_date, end_date,
       DATEDIFF(end_date, start_date) + 1 AS duration_days
FROM batches;

-- Q10. Display students and their age
SELECT first_name, last_name,
       TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) AS age
FROM students;

-- Q11. Display trainers with 5 or more years of experience
SELECT trainer_name, specialization, experience_years
FROM trainers
WHERE experience_years >= 5
ORDER BY experience_years DESC;

-- Q12. Display courses in ascending order of fees
SELECT course_name, category, fee
FROM courses
ORDER BY fee;

/* =====================================================================
   8. JOIN QUERIES
   ===================================================================== */

-- J1. INNER JOIN: Show each batch with its course
SELECT b.batch_code, c.course_name
FROM batches b
INNER JOIN courses c ON b.course_id = c.course_id;

-- J2. INNER JOIN: Show each batch with its trainer
SELECT b.batch_code, t.trainer_name
FROM batches b
INNER JOIN trainers t ON b.trainer_id = t.trainer_id;

-- J3. INNER JOIN: Show students and the batches they enrolled in
SELECT s.first_name, s.last_name, b.batch_code
FROM students s
INNER JOIN enrollments e ON s.student_id = e.student_id
INNER JOIN batches b ON e.batch_id = b.batch_id;

-- J4. INNER JOIN: Show students with their course names
SELECT s.first_name, s.last_name, c.course_name
FROM students s
JOIN enrollments e ON s.student_id = e.student_id
JOIN batches b ON e.batch_id = b.batch_id
JOIN courses c ON b.course_id = c.course_id;

-- J5. LEFT JOIN: Show all courses, including courses without batches
SELECT c.course_name, b.batch_code
FROM courses c
LEFT JOIN batches b ON c.course_id = b.course_id;

-- J6. LEFT JOIN: Show all trainers, including trainers without batches
SELECT t.trainer_name, b.batch_code
FROM trainers t
LEFT JOIN batches b ON t.trainer_id = b.trainer_id;

-- J7. RIGHT JOIN: Show all trainers and the batches they handle
SELECT t.trainer_name, b.batch_code
FROM batches b
RIGHT JOIN trainers t ON b.trainer_id = t.trainer_id;

-- J8. SELF JOIN: Show students and the students who referred them
SELECT s.first_name AS student,
       r.first_name AS referred_by
FROM students s
LEFT JOIN students r ON s.referred_by = r.student_id;

-- J9. JOIN: Show assessment marks with student names
SELECT s.first_name, s.last_name, a.assessment_name,
       ar.marks_obtained, ar.result_status
FROM assessment_results ar
JOIN enrollments e ON ar.enrollment_id = e.enrollment_id
JOIN students s ON e.student_id = s.student_id
JOIN assessments a ON ar.assessment_id = a.assessment_id;

-- J10. JOIN: Show trainer and course assignments
SELECT t.trainer_name, c.course_name
FROM course_trainers ct
JOIN trainers t ON ct.trainer_id = t.trainer_id
JOIN courses c ON ct.course_id = c.course_id;

-- J11. LEFT JOIN: Count students enrolled in each batch
SELECT b.batch_code, COUNT(e.enrollment_id) AS total_students
FROM batches b
LEFT JOIN enrollments e ON b.batch_id = e.batch_id
GROUP BY b.batch_code;

-- J12. LEFT JOIN: Find students who have not enrolled in any batch
SELECT s.student_id, s.first_name, s.last_name
FROM students s
LEFT JOIN enrollments e ON s.student_id = e.student_id
WHERE e.enrollment_id IS NULL;

/* =====================================================================
   9. SUBQUERIES
   ===================================================================== */

-- S1. Find courses with fees higher than the average course fee
SELECT course_name, fee
FROM courses
WHERE fee > (SELECT AVG(fee) FROM courses);

-- S2. Find students enrolled in the Python beginner course
SELECT first_name, last_name
FROM students
WHERE student_id IN (
    SELECT e.student_id
    FROM enrollments e
    JOIN batches b ON e.batch_id = b.batch_id
    JOIN courses c ON b.course_id = c.course_id
    WHERE c.course_name = 'Python Programming for Beginners'
);

-- S3. Find courses that do not have any batch
SELECT course_name
FROM courses
WHERE course_id NOT IN (
    SELECT course_id FROM batches
);

-- S4. Find the course with the highest fee
SELECT course_name, fee
FROM courses
WHERE fee = (SELECT MAX(fee) FROM courses);

-- S5. Find students who have not received a certificate
SELECT first_name, last_name
FROM students
WHERE student_id IN (
    SELECT e.student_id
    FROM enrollments e
    LEFT JOIN certificates cert ON e.enrollment_id = cert.enrollment_id
    WHERE cert.certificate_id IS NULL
);

-- S6. Find students who enrolled in more than one batch
SELECT first_name, last_name
FROM students
WHERE student_id IN (
    SELECT student_id
    FROM enrollments
    GROUP BY student_id
    HAVING COUNT(*) > 1
);

-- S7. Find batches that have more enrollments than the average batch
SELECT batch_code
FROM batches
WHERE batch_id IN (
    SELECT batch_id
    FROM enrollments
    GROUP BY batch_id
    HAVING COUNT(*) > (
        SELECT AVG(batch_count)
        FROM (
            SELECT COUNT(*) AS batch_count
            FROM enrollments
            GROUP BY batch_id
        ) AS batch_totals
    )
);

-- S8. Find students whose marks are above the average marks
SELECT DISTINCT s.first_name, s.last_name
FROM students s
JOIN enrollments e ON s.student_id = e.student_id
JOIN assessment_results ar ON e.enrollment_id = ar.enrollment_id
WHERE ar.marks_obtained > (
    SELECT AVG(marks_obtained) FROM assessment_results
);

/* =====================================================================
   10. BUSINESS REPORTS
   ===================================================================== */

-- R1. Number of students enrolled in each course
SELECT c.course_name, COUNT(e.enrollment_id) AS total_enrollments
FROM courses c
LEFT JOIN batches b ON c.course_id = b.course_id
LEFT JOIN enrollments e ON b.batch_id = e.batch_id
GROUP BY c.course_name
ORDER BY total_enrollments DESC;

-- R2. Total fees collected for each course
SELECT c.course_name, COALESCE(SUM(e.fee_paid), 0) AS fees_collected
FROM courses c
LEFT JOIN batches b ON c.course_id = b.course_id
LEFT JOIN enrollments e ON b.batch_id = e.batch_id
GROUP BY c.course_name;

-- R3. Count of students in each batch
SELECT b.batch_code, COUNT(e.enrollment_id) AS student_count
FROM batches b
LEFT JOIN enrollments e ON b.batch_id = e.batch_id
GROUP BY b.batch_code;

-- R4. Students who have not paid the full course fee
SELECT student_name, course_name, batch_code, course_fee,
       fee_paid, balance_due, payment_status
FROM v_enrollment_details
WHERE payment_status <> 'Paid';

-- R5. Students who passed each assessment
SELECT s.first_name, s.last_name, a.assessment_name, ar.marks_obtained
FROM assessment_results ar
JOIN enrollments e ON ar.enrollment_id = e.enrollment_id
JOIN students s ON e.student_id = s.student_id
JOIN assessments a ON ar.assessment_id = a.assessment_id
WHERE ar.result_status = 'Pass';

-- R6. Students who failed each assessment
SELECT s.first_name, s.last_name, a.assessment_name, ar.marks_obtained
FROM assessment_results ar
JOIN enrollments e ON ar.enrollment_id = e.enrollment_id
JOIN students s ON e.student_id = s.student_id
JOIN assessments a ON ar.assessment_id = a.assessment_id
WHERE ar.result_status = 'Fail';

-- R7. Trainer-wise batch count
SELECT t.trainer_name, COUNT(b.batch_id) AS batches_handled
FROM trainers t
LEFT JOIN batches b ON t.trainer_id = b.trainer_id
GROUP BY t.trainer_name;

-- R8. Course-wise average assessment marks
SELECT c.course_name, AVG(ar.marks_obtained) AS average_marks
FROM courses c
JOIN batches b ON c.course_id = b.course_id
JOIN assessments a ON b.batch_id = a.batch_id
JOIN assessment_results ar ON a.assessment_id = ar.assessment_id
GROUP BY c.course_name;

-- R9. Certificate details report
SELECT cert.certificate_no, s.first_name, s.last_name,
       c.course_name, cert.final_percentage, cert.grade
FROM certificates cert
JOIN enrollments e ON cert.enrollment_id = e.enrollment_id
JOIN students s ON e.student_id = s.student_id
JOIN batches b ON e.batch_id = b.batch_id
JOIN courses c ON b.course_id = c.course_id
ORDER BY cert.certificate_no;
/* =====================================================================
   11. TRANSACTIONS  (START TRANSACTION, COMMIT, ROLLBACK, SAVEPOINT)
   T1 makes a permanent change (a fee payment); T2 and T3 are rolled back.
   ===================================================================== */

-- ---- T1 | START TRANSACTION ... COMMIT : Student clears the balance fee; certificate is then issued
-- Purpose: Vikram Singh (enrolment 5) paid only half the Python fee. The payment update
            --is wrapped in a transaction and COMMITted (made permanent). Because he
            --already passed the course, the eligibility view now returns "Eligible" and
            --sp_issue_certificates issues his certificate.
START TRANSACTION;
UPDATE enrollments
SET fee_paid = fee_paid + 6000, payment_status = 'Paid'
WHERE enrollment_id = 5 AND payment_status = 'Partial';
SELECT enrollment_id, fee_paid, payment_status FROM enrollments WHERE enrollment_id = 5;
COMMIT;
CALL sp_issue_certificates(1, CURDATE());
SELECT certificate_no, final_percentage, grade, issue_date FROM certificates WHERE enrollment_id = 5;

-- ---- T2 | START TRANSACTION ... ROLLBACK : Accidental delete is undone with ROLLBACK
-- Purpose: A clerk deletes all enrolments of batch 9 by mistake. Because the delete ran
            --inside a transaction, ROLLBACK restores everything. Compare the three
            --counts.
SELECT COUNT(*) AS enrollments_before FROM enrollments WHERE batch_id = 9;
START TRANSACTION;
DELETE FROM enrollments WHERE batch_id = 9;
SELECT COUNT(*) AS enrollments_inside_transaction FROM enrollments WHERE batch_id = 9;
ROLLBACK;
SELECT COUNT(*) AS enrollments_after_rollback FROM enrollments WHERE batch_id = 9;

-- ---- T3 | SAVEPOINT and partial rollback : Rollback to a savepoint
-- Purpose: Two fee changes are made; ROLLBACK TO SAVEPOINT undoes only the second one,
            --then the whole transaction is rolled back so the sample data is unchanged.
START TRANSACTION;
UPDATE courses SET fee = fee - 1000 WHERE course_id = 1;
SAVEPOINT after_first_change;
UPDATE courses SET fee = fee - 1000 WHERE course_id = 2;
SELECT course_id, fee FROM courses WHERE course_id IN (1, 2) ORDER BY course_id;
ROLLBACK TO SAVEPOINT after_first_change;
SELECT course_id, fee FROM courses WHERE course_id IN (1, 2) ORDER BY course_id;
ROLLBACK;
SELECT course_id, fee FROM courses WHERE course_id IN (1, 2) ORDER BY course_id;


/* =====================================================================
   12. STORED PROCEDURE DEMOS
   ===================================================================== */

-- ---- P1 | Stored procedure sp_enroll_student : Enrol Imran Sheikh in the upcoming AWS batch
-- Purpose: Imran has registered but never enrolled. The procedure checks the batch is
          --  open, seats are free and the fee is valid, derives the payment status
           -- (Partial, because he pays 10,000 of 25,000) and inserts the enrolment inside
            --a transaction.
CALL sp_enroll_student(15, 11, 10000);
SELECT student_name, course_name, batch_code, fee_paid, balance_due, payment_status
FROM v_enrollment_details WHERE student_id = 15;

-- ---- P2 | Stored procedure sp_batch_performance : Ranked performance sheet of batch 1 (PY-JAN26)
-- Purpose: Returns the ranking of one batch with marks, percentage and eligibility. Run
           -- it for any batch id.
CALL sp_batch_performance(1);

-- Error demo (run separately, it fails on purpose):
--   CALL sp_enroll_student(15, 11, 5000);   -> ERROR 1062 duplicate entry (student already enrolled in batch)
--   INSERT INTO assessment_results (assessment_id, enrollment_id, marks_obtained) VALUES (1, 1, 75);
--                                          -> ERROR 1644 'Marks obtained cannot exceed the maximum marks'


/* =====================================================================
   13. INDEX CREATION AND PERFORMANCE COMPARISON
   ===================================================================== */

/* Create a 100,000-row practice table, measure a query WITHOUT an index,
   add an index, and measure again.  The table is dropped at the end. */
SET SESSION cte_max_recursion_depth = 100000;

DROP TABLE IF EXISTS perf_students;
CREATE TABLE perf_students (
    student_id     INT AUTO_INCREMENT PRIMARY KEY,
    full_name      VARCHAR(80) NOT NULL,
    city           VARCHAR(50) NOT NULL,
    registered_on  DATE        NOT NULL
);

INSERT INTO perf_students (full_name, city, registered_on)
WITH RECURSIVE seq AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM seq WHERE n < 100000
)
SELECT CONCAT('Student ', n),
       ELT(1 + MOD(n, 8), 'Hyderabad','Bengaluru','Chennai','Delhi','Mumbai','Pune','Kochi','Vijayawada'),
       DATE_ADD('2024-01-01', INTERVAL MOD(n, 1000) DAY)
FROM seq;

-- (a) BEFORE the index : expect type = ALL (full table scan), rows ~ 100000
EXPLAIN SELECT COUNT(*) FROM perf_students WHERE city = 'Hyderabad';
EXPLAIN ANALYZE SELECT COUNT(*) FROM perf_students WHERE city = 'Hyderabad';

-- (b) Create the index
CREATE INDEX idx_perf_city ON perf_students (city);
SHOW INDEX FROM perf_students;

-- (c) AFTER the index : expect type = ref, key = idx_perf_city, rows ~ 12500
EXPLAIN SELECT COUNT(*) FROM perf_students WHERE city = 'Hyderabad';
EXPLAIN ANALYZE SELECT COUNT(*) FROM perf_students WHERE city = 'Hyderabad';

-- (d) Indexes already present on the real project tables
SHOW INDEX FROM students;
EXPLAIN SELECT * FROM students WHERE city = 'Hyderabad';
EXPLAIN SELECT * FROM batches WHERE start_date BETWEEN '2026-09-01' AND '2026-10-31';

DROP TABLE perf_students;

-- END OF SCRIPT