#  Prison Management System (PMS)

![Java](https://img.shields.io/badge/Java-17-orange)

![MySQL](https://img.shields.io/badge/MySQL-8-blue)

![JDBC](https://img.shields.io/badge/JDBC-Database-success)

![Swing](https://img.shields.io/badge/Java-Swing-red)

![License](https://img.shields.io/badge/License-MIT-green)

A comprehensive Prison Management System developed as a semester Database Systems project.

The system combines a **MySQL relational database** with a **Java Swing desktop application** connected through **JDBC**, providing an intuitive interface for managing correctional facility records.

# 📌 Overview

Managing correctional facilities involves handling large amounts of interconnected data such as inmates, prison staff, cells, visitors, parole applications, medical records,parole, disciplinary history and much more.

This project provides a centralized database solution that maintains data integrity while allowing administrators to efficiently manage prison operations through an interactive graphical interface.


# ✨ Features

- Prison Management
- Block Management
- Cell Management
- Staff Records
- Inmate Management
- Sentence Tracking
- Visitor Management
- Visit Scheduling
- Medical Records
- Disciplinary Records
- Transfer History
- Parole Management



#  Dashboard

The application provides a real-time dashboard displaying:

- Total Prisons
- Total Blocks
- Total Cells
- Total Staff
- Total Inmates
- Active Inmates

Dashboard statistics are refreshed directly from the database.

---

# 🖥 GUI Features

### Dashboard

Live prison statistics.

### Table Manager

- Browse any table
- Search records
- Add records
- Update records
- Delete records

### Custom SQL

Execute custom SQL queries directly inside the application.

Supports:

- SELECT
- INSERT
- UPDATE
- DELETE

---

# 🗄 Database Design

The database consists of **12 relational tables**:

- PRISON
- BLOCK
- CELL
- STAFF
- INMATE
- SENTENCE
- VISITOR
- VISIT
- MEDICAL_RECORD
- DISCIPLINARY_RECORD
- TRANSFER
- PAROLE

The schema follows **Third Normal Form (3NF)** to minimize redundancy and maintain consistency.


# 🔑 Database Concepts Used

- Entity Relationship Modeling
- Normalization (3NF)
- Primary Keys
- Foreign Keys
- Constraints
- Indexes
- CRUD Operations
- Joins
- Aggregate Functions
- Nested Queries
- Relational Algebra

---

# 💻 Technologies Used

| Technology | Purpose |
| Java | Desktop Application |
| Java Swing | GUI |
| JDBC | Database Connectivity |
| MySQL | Relational Database |
| SQL | Database Operations |

---

# 📸 Screenshots

## Dashboard
<img width="975" height="512" alt="image" src="https://github.com/user-attachments/assets/e37bfd89-d8e3-4d00-9655-c499e6928a98" />

---

## Table Manager
<img width="975" height="473" alt="image" src="https://github.com/user-attachments/assets/0c5576c2-4e70-4486-86a4-665ec8be5925" />



## Custom SQL Execution
<img width="975" height="514" alt="image" src="https://github.com/user-attachments/assets/324a92bb-2065-40f3-bfeb-9f6d1b4f5fe7" />


## ER Diagram
<img width="975" height="1138" alt="image" src="https://github.com/user-attachments/assets/03202bb1-1647-4d81-9bfa-d5f202cbeb93" />


# 🚀 Getting Started

## Clone Repository

```bash
git clone https://github.com/aymenfaisal30/prisonmanagementsystem.git
```


## Requirements

- Java JDK 17+
- MySQL 8+
- MySQL Connector/J
- IntelliJ IDEA or Eclipse or VS code

---

## Database Setup

1. Create a MySQL database.

2. Import

```
database/prison_management.sql
```

3. Update the database credentials inside

```
PrisonManagementApp.java
```

```java
DB_URL
DB_USER
DB_PASSWORD
```

4. Run the application.

---

# 📂 Project Structure

```
Prison-Management-System

├── src
├── database
├── screenshots
├── report
└── README.md
```


# 📈 Learning Outcomes

This project strengthened practical understanding of:

- Database Design
- Database Normalization
- SQL Query Writing
- JDBC Programming
- Java Swing GUI Development
- Relational Database Modeling
- Data Integrity
- Software Architecture

---

# 🔮 Future Improvements

- User Authentication
- Role-Based Access Control
- Audit Logging
- Password Encryption
- Report Generation
- Analytics Dashboard
- Biometric Integration
- Cloud Database Support

---


# 📄 Documentation

The complete project report is available in the **report** folder.

---

⭐ If you found this project interesting, feel free to star the repository!
