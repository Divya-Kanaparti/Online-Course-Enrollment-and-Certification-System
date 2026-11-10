/*
===============================================================================
ONLINE COURSE ENROLLMENT AND CERTIFICATION SYSTEM
SQL QUERIES WITH EXPLANATIONS
===============================================================================

Database: course_cert_db
MySQL: 8.0+

Contents:
  1. Basic SQL Queries (Q1-Q12)
  2. JOIN Queries (J1-J12)
  3. Subqueries (S1-S8)

How to run:
  1. Make sure course_cert_db and its tables already exist.
  2. Open this file in MySQL Workbench or the MySQL command-line client.
  3. Execute one query at a time or execute a selected section.
  4. Q3, Q4 and Q5 intentionally end with ROLLBACK. They are practice
     demonstrations and do not permanently change the sample data.

Important:
  - This is a query-only companion file. It does not create or populate tables.
  - Query outputs depend on the current contents of your database.
  - Do not rerun the full database setup script on a populated database.

===============================================================================
*/

USE course_cert_db;

/* ===============================================================
   7. BASIC SQL QUERIES
   ===================================================================== */

-- Explanation: Displays students whose city is Hyderabad and whose status is Active. AND requires both conditions to be true.
-- Project purpose: Identifies active students from Hyderabad.
-- Q1. Display active students from Hyderabad
SELECT student_id, first_name, last_name, email, city
FROM students
WHERE city = 'Hyderabad' AND status = 'Active';

-- Explanation: DISTINCT removes duplicate city names, and ORDER BY sorts the city names alphabetically.
-- Project purpose: Shows the different cities represented in the student records.
-- Q2. Display all different cities
SELECT DISTINCT city
FROM students
ORDER BY city;

-- Explanation: START TRANSACTION begins a transaction. INSERT adds a practice student, SELECT verifies the row, and ROLLBACK cancels the insertion.
-- Project purpose: Demonstrates inserting and checking a record without permanently changing the database.
-- Q3. Insert a new student (run inside a transaction for practice)
START TRANSACTION;
INSERT INTO students
(first_name, last_name, email, phone, gender, date_of_birth, city, referred_by)
VALUES
('Pooja', 'Menon', 'pooja.menon@gmail.com', '9876500016',
 'Female', '2001-08-21', 'Kochi', 4);
SELECT * FROM students WHERE email = 'pooja.menon@gmail.com';
ROLLBACK;

-- Explanation: UPDATE increases fees for Cloud courses by 10%. SELECT verifies the changed fees, and ROLLBACK restores the original values.
-- Project purpose: Demonstrates a conditional fee update safely.
-- Q4. Increase the fee of Cloud courses by 10%
START TRANSACTION;
UPDATE courses
SET fee = fee * 1.10
WHERE category = 'Cloud';
SELECT course_name, fee FROM courses WHERE category = 'Cloud';
ROLLBACK;

-- Explanation: DELETE targets pending enrollments belonging to upcoming batches. The subquery identifies upcoming batch IDs. ROLLBACK cancels the deletion after verification.
-- Project purpose: Demonstrates a conditional deletion without permanently removing sample records.
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

-- Explanation: MIN, MAX and AVG calculate the lowest, highest and average course fees.
-- Project purpose: Summarizes the fee range across all courses.
-- Q6. Display the lowest, highest and average course fee
SELECT MIN(fee) AS lowest_fee,
       MAX(fee) AS highest_fee,
       AVG(fee) AS average_fee
FROM courses;

-- Explanation: The joins connect courses to batches and enrollments. GROUP BY creates one group per course, and HAVING keeps groups with at least three enrollments.
-- Project purpose: Identifies courses with at least three enrollments.
-- Q7. Show courses having at least 3 enrollments
SELECT c.course_name, COUNT(e.enrollment_id) AS total_enrollments
FROM courses c
JOIN batches b ON c.course_id = b.course_id
JOIN enrollments e ON b.batch_id = e.batch_id
GROUP BY c.course_name
HAVING COUNT(e.enrollment_id) >= 3;

-- Explanation: CONCAT combines first and last names, and UPPER converts the combined name to uppercase.
-- Project purpose: Displays student names in uppercase.
-- Q8. Display student names in uppercase
SELECT UPPER(CONCAT(first_name, ' ', last_name)) AS student_name
FROM students;

-- Explanation: DATEDIFF calculates the difference between end_date and start_date. Adding 1 includes both dates in the duration.
-- Project purpose: Displays each batch's duration in days.
-- Q9. Display batch details with duration in days
SELECT batch_code, start_date, end_date,
       DATEDIFF(end_date, start_date) + 1 AS duration_days
FROM batches;

-- Explanation: TIMESTAMPDIFF with YEAR calculates completed years between date_of_birth and the current date.
-- Project purpose: Displays each student's age in completed years.
-- Q10. Display students and their age
SELECT first_name, last_name,
       TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) AS age
FROM students;

-- Explanation: WHERE filters trainers with at least five years of experience. ORDER BY sorts from greatest experience to least.
-- Project purpose: Identifies experienced trainers.
-- Q11. Display trainers with 5 or more years of experience
SELECT trainer_name, specialization, experience_years
FROM trainers
WHERE experience_years >= 5
ORDER BY experience_years DESC;

-- Explanation: ORDER BY fee sorts courses by fee. The default order is ascending because DESC is not specified.
-- Project purpose: Compares course fees from lowest to highest.
-- Q12. Display courses in ascending order of fees
SELECT course_name, category, fee
FROM courses
ORDER BY fee;

/* =====================================================================
   8. JOIN QUERIES
   ===================================================================== */

-- Explanation: INNER JOIN matches each batch with its course using course_id. Only matching records are returned.
-- Project purpose: Displays the course assigned to each batch.
-- J1. INNER JOIN: Show each batch with its course
SELECT b.batch_code, c.course_name
FROM batches b
INNER JOIN courses c ON b.course_id = c.course_id;

-- Explanation: INNER JOIN matches each batch with its trainer using trainer_id.
-- Project purpose: Displays the trainer responsible for each batch.
-- J2. INNER JOIN: Show each batch with its trainer
SELECT b.batch_code, t.trainer_name
FROM batches b
INNER JOIN trainers t ON b.trainer_id = t.trainer_id;

-- Explanation: The joins connect students to enrollments and then to batches. Only students with matching enrollment records appear.
-- Project purpose: Shows the batches in which students are enrolled.
-- J3. INNER JOIN: Show students and the batches they enrolled in
SELECT s.first_name, s.last_name, b.batch_code
FROM students s
INNER JOIN enrollments e ON s.student_id = e.student_id
INNER JOIN batches b ON e.batch_id = b.batch_id;

-- Explanation: The joins connect students, enrollments, batches and courses through their related key columns.
-- Project purpose: Displays each enrolled student's course name.
-- J4. INNER JOIN: Show students with their course names
SELECT s.first_name, s.last_name, c.course_name
FROM students s
JOIN enrollments e ON s.student_id = e.student_id
JOIN batches b ON e.batch_id = b.batch_id
JOIN courses c ON b.course_id = c.course_id;

-- Explanation: LEFT JOIN returns every course. If a course has no matching batch, batch_code is NULL.
-- Project purpose: Shows all courses, including those without batches.
-- J5. LEFT JOIN: Show all courses, including courses without batches
SELECT c.course_name, b.batch_code
FROM courses c
LEFT JOIN batches b ON c.course_id = b.course_id;

-- Explanation: LEFT JOIN returns every trainer. Trainers without a matching batch still appear, with NULL for batch_code.
-- Project purpose: Shows all trainers, including those not assigned to a batch.
-- J6. LEFT JOIN: Show all trainers, including trainers without batches
SELECT t.trainer_name, b.batch_code
FROM trainers t
LEFT JOIN batches b ON t.trainer_id = b.trainer_id;

-- Explanation: RIGHT JOIN preserves every trainer in the right-side table and matches any batches assigned to that trainer.
-- Project purpose: Displays all trainers and their batches, including trainers without batches.
-- J7. RIGHT JOIN: Show all trainers and the batches they handle
SELECT t.trainer_name, b.batch_code
FROM batches b
RIGHT JOIN trainers t ON b.trainer_id = t.trainer_id;

-- Explanation: The students table is joined to itself using aliases s and r. LEFT JOIN keeps students even when referred_by is NULL.
-- Project purpose: Displays student referral relationships.
-- J8. SELF JOIN: Show students and the students who referred them
SELECT s.first_name AS student,
       r.first_name AS referred_by
FROM students s
LEFT JOIN students r ON s.referred_by = r.student_id;

-- Explanation: The joins connect assessment_results with enrollments, students and assessments to show student details and assessment performance together.
-- Project purpose: Displays marks and Pass/Fail status with student and assessment names.
-- J9. JOIN: Show assessment marks with student names
SELECT s.first_name, s.last_name, a.assessment_name,
       ar.marks_obtained, ar.result_status
FROM assessment_results ar
JOIN enrollments e ON ar.enrollment_id = e.enrollment_id
JOIN students s ON e.student_id = s.student_id
JOIN assessments a ON ar.assessment_id = a.assessment_id;

-- Explanation: course_trainers is the linking table between trainers and courses. The joins retrieve the corresponding names.
-- Project purpose: Displays trainer-course assignments.
-- J10. JOIN: Show trainer and course assignments
SELECT t.trainer_name, c.course_name
FROM course_trainers ct
JOIN trainers t ON ct.trainer_id = t.trainer_id
JOIN courses c ON ct.course_id = c.course_id;

-- Explanation: LEFT JOIN keeps every batch, including batches without enrollments. COUNT counts matching enrollment IDs; batches without enrollments show zero.
-- Project purpose: Counts students enrolled in each batch.
-- J11. LEFT JOIN: Count students enrolled in each batch
SELECT b.batch_code, COUNT(e.enrollment_id) AS total_students
FROM batches b
LEFT JOIN enrollments e ON b.batch_id = e.batch_id
GROUP BY b.batch_code;

-- Explanation: LEFT JOIN keeps all students, then IS NULL selects rows with no matching enrollment.
-- Project purpose: Finds students who have not enrolled in any batch.
-- J12. LEFT JOIN: Find students who have not enrolled in any batch
SELECT s.student_id, s.first_name, s.last_name
FROM students s
LEFT JOIN enrollments e ON s.student_id = e.student_id
WHERE e.enrollment_id IS NULL;

/* =====================================================================
   9. SUBQUERIES
   ===================================================================== */

-- Explanation: The subquery calculates the average fee of all courses. The outer query returns courses whose fee is greater than that average.
-- Project purpose: Finds courses priced above the overall average fee.
-- S1. Find courses with fees higher than the average course fee
SELECT course_name, fee
FROM courses
WHERE fee > (SELECT AVG(fee) FROM courses);

-- Explanation: The subquery finds student IDs enrolled in the specified Python beginner course. IN returns the matching student names.
-- Project purpose: Lists students enrolled in Python Programming for Beginners.
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

-- Explanation: The subquery returns course IDs that have batches. NOT IN returns courses whose IDs are not in that list.
-- Project purpose: Finds courses without any batch.
-- S3. Find courses that do not have any batch
SELECT course_name
FROM courses
WHERE course_id NOT IN (
    SELECT course_id FROM batches
);

-- Explanation: The subquery calculates the maximum course fee. The outer query returns the course or courses with that fee.
-- Project purpose: Identifies the highest-priced course.
-- S4. Find the course with the highest fee
SELECT course_name, fee
FROM courses
WHERE fee = (SELECT MAX(fee) FROM courses);

-- Explanation: The subquery finds enrollments without a matching certificate, then returns the associated students' names.
-- Project purpose: Finds students with at least one enrollment that has no certificate.
-- S5. Find students who have not received a certificate
SELECT first_name, last_name
FROM students
WHERE student_id IN (
    SELECT e.student_id
    FROM enrollments e
    LEFT JOIN certificates cert ON e.enrollment_id = cert.enrollment_id
    WHERE cert.certificate_id IS NULL
);

-- Explanation: The subquery groups enrollments by student_id and HAVING COUNT(*) > 1 keeps students enrolled in more than one batch.
-- Project purpose: Identifies students enrolled in multiple batches.
-- S6. Find students who enrolled in more than one batch
SELECT first_name, last_name
FROM students
WHERE student_id IN (
    SELECT student_id
    FROM enrollments
    GROUP BY student_id
    HAVING COUNT(*) > 1
);

-- Explanation: The nested query counts enrollments in each batch and calculates the average of those counts. The outer query returns batches above that average.
-- Project purpose: Finds batches with more enrollments than the average batch count.
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

-- Explanation: The subquery calculates the average marks across assessment results. The outer query returns students with marks above that average; DISTINCT avoids duplicate student rows.
-- Project purpose: Finds students whose marks are above the overall average.
-- S8. Find students whose marks are above the average marks
SELECT DISTINCT s.first_name, s.last_name
FROM students s
JOIN enrollments e ON s.student_id = e.student_id
JOIN assessment_results ar ON e.enrollment_id = ar.enrollment_id
WHERE ar.marks_obtained > (
    SELECT AVG(marks_obtained) FROM assessment_results
);
