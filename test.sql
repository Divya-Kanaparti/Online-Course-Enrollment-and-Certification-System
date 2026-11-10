USE course_cert_db;

(
    SELECT
        enrollment_id,
        student_id,
        student_name,
        course_name,
        final_percentage,
        payment_status,
        batch_status,
        eligibility,
        certificate_issued,
        'Pass' AS result,
        'Certificate Required' AS certificate_decision
    FROM v_certificate_eligibility
    WHERE eligibility = 'Eligible'
    ORDER BY enrollment_id
    LIMIT 3
)

UNION ALL

(
    SELECT
        enrollment_id,
        student_id,
        student_name,
        course_name,
        final_percentage,
        payment_status,
        batch_status,
        eligibility,
        certificate_issued,
        'Fail' AS result,
        'Certificate Not Required' AS certificate_decision
    FROM v_certificate_eligibility
    WHERE eligibility = 'Not Eligible - Failed'
    ORDER BY enrollment_id
    LIMIT 2
);