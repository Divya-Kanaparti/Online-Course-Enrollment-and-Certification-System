# Online Course Enrollment and Certification System

## Project Overview

The Online Course Enrollment and Certification System is a MySQL-based database management system designed to manage students, trainers, courses, batches, enrollments, assessments, payments, and certificates.

This project demonstrates practical SQL concepts through a real-world course management scenario.

## Technologies Used

- SQL
- MySQL Workbench / MySQL CLI

## Database Tables

The database `course_cert_db` contains 10 main tables:

1. Students
2. Trainers
3. Courses
4. Course Trainers
5. Batches
6. Enrollments
7. Assessments
8. Assessment Results
9. Certificates
10. Course Fee Audit

## Key Features

- Student and trainer management
- Course and batch management
- Student enrollment and fee tracking
- Assessment and examination management
- Automatic Pass/Fail calculation using triggers
- Certificate eligibility validation
- Certificate generation through stored procedures
- Course fee audit tracking
- Transaction management
- Indexing and query performance comparison

## SQL Concepts Covered

- Database and table creation
- Primary Keys and Foreign Keys
- NOT NULL, UNIQUE, DEFAULT and CHECK constraints
- INSERT, UPDATE and DELETE operations
- Aggregate functions
- GROUP BY and HAVING
- INNER JOIN, LEFT JOIN, RIGHT JOIN and SELF JOIN
- Subqueries
- Views
- Stored Procedures
- Triggers
- Transactions: COMMIT, ROLLBACK and SAVEPOINT
- Indexing 

## Project Structure

```text
Online-Course-Enrollment-and-Certification-System/
│
├── ER_DIAGRAM/
│   └── ER_diagram.png
│
├── Online_Course_Enrollment_System.sql
├── queries.sql
├── reports.sql
├── test.sql
└── README.md
```

## Project Files

| File | Description |
|---|---|
| Online_Course_Enrollment_System.sql | Main database schema, sample data and advanced SQL implementation |
| queries.sql | Practical SQL queries and JOIN operations |
| reports.sql | Business reporting queries |
| test.sql | Certificate eligibility test cases |
| ER_DIAGRAM/ | Database entity relationship diagram |

## How to Run the Project

1. Install MySQL 
2. Open MySQL Workbench or MySQL Command Line Client.
3. Open the `Online_Course_Enrollment_System.sql` file.
4. Execute the script section by section in the given order.
5. Execute `queries.sql`, `reports.sql` and `test.sql` to explore the project functionality.

**Important:** Run the main SQL script on a fresh database. Do not execute it again on an already populated database without resetting it or using a separate database.
