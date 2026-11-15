
USE course_cert_db;

-- TEST 1: Check all tables
SHOW TABLES;

-- TEST 2: Check student progress
SELECT * FROM v_student_progress;

-- TEST 3: Check certificate eligibility
SELECT
    student_name,
    course_name,
    final_percentage,
    eligibility
FROM v_certificate_eligibility;

-- TEST 4: Check batch capacity
SELECT
    batch_code,
    max_seats,
    active_students,
    seats_available
FROM v_batch_summary;

-- TEST 5: Check payment status
SELECT
    student_name,
    course_name,
    course_fee,
    fee_paid,
    balance_due,
    payment_status
FROM v_enrollment_details;

-- TEST 6: Check trainer assignments
SELECT
    trainer_name,
    assigned_courses
FROM (
    SELECT
        t.trainer_name,
        GROUP_CONCAT(c.course_name) AS assigned_courses
    FROM trainers t
    LEFT JOIN course_trainers ct
        ON t.trainer_id = ct.trainer_id
    LEFT JOIN courses c
        ON c.course_id = ct.course_id
    GROUP BY t.trainer_id, t.trainer_name
) AS trainer_report;

-- TEST 7: Check issued certificates
SELECT * FROM certificates;

-- TEST 8: Check assessment results
SELECT
    s.first_name,
    s.last_name,
    a.assessment_name,
    ar.marks_obtained,
    ar.result_status
FROM assessment_results ar
JOIN enrollments e
    ON e.enrollment_id = ar.enrollment_id
JOIN students s
    ON s.student_id = e.student_id
JOIN assessments a
    ON a.assessment_id = ar.assessment_id;
