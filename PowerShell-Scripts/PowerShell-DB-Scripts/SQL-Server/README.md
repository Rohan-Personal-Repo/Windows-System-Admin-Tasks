# PowerShell + SQL Server Samples

PowerShell samples for working with SQL Server: shared helper modules, connection patterns, CRUD operations, and audit logging, structured to be reusable across environments.

---

## 1. Common PowerShell Modules

**Folder:** `SQL-Server/Common-PowerShell-Modules`  
Reusable building blocks that other samples import:

- Connection helpers for SQL Server (centralized server, database, and credential handling).  
- Wrapper functions around common T‑SQL execution patterns (e.g., “run a query and return objects/DataTable”).  
- Utility functions for logging, error handling, and configuration so demo scripts stay focused on their core scenario.

Use these modules as the foundation for your own SQL Server automation instead of duplicating boilerplate code.

---

## 2. Connect to SQL Server (Auth Patterns)

**Folder:** `SQL-Server/Connect-To-SQL-Server`  
Shows how to connect to SQL Server from PowerShell using both:

- **Windows Authentication**  
  - Uses your current Windows identity (Integrated Security / Trusted_Connection).  
  - No username/password in the script; ideal for on‑prem or domain‑joined scenarios.  

- **SQL Server Authentication**  
  - Uses explicit SQL logins (username/password) in the connection string or credential object.  
  - Suitable for shared accounts, non‑domain clients, or when you must separate SQL security from Windows identities.

Typical patterns demonstrated:

- Building connection strings for both auth types.  
- Testing connectivity with a simple `SELECT 1` or similar query.  
- Handling errors when authentication or connectivity fails (e.g., wrong login, disabled account, unreachable server).

---

## 3. Audit Logging Demo

**Folder:** `SQL-Server/Audit-Logging-Demo`  
End‑to‑end example of **audit logging** for SQL Server:

- T‑SQL objects (tables, triggers, or procedures) that capture who changed what and when at the database level. 
- PowerShell scripts that:
  - Execute changes against business tables.  
  - Read and analyze the corresponding audit rows.  
  - Surface activity via grids or exports (e.g., `Out-GridView` or CSV).  

Use this folder to understand how to wire up an audit trail and validate it via PowerShell.

---

## 4. SQL CRUD Operations (+ Audit)

**Folder:** `SQL-Server/SQL-CRUD-Operations`  
Focuses on **Create, Read, Update, Delete** patterns from PowerShell:

- Scripts that connect to SQL Server and run parameterized T‑SQL for:
  - **Create** – inserting new rows into a sample table.  
  - **Read** – selecting data with filters, sorting, and projections.  
  - **Update** – modifying specific columns for targeted rows.  
  - **Delete** – removing rows safely using WHERE clauses.

Some scripts combine **CRUD + Audit Logging**:

- Perform standard CRUD operations.  
- Rely on database audit logic (from the Audit Logging demo) to record each change.  
- Query both the main table and audit table to prove that every modification is tracked.

Use this folder as a template when building your own PowerShell‑driven CRUD tools over SQL Server, with or without auditing.

---

## 5. How to use these samples

1. Clone the repo and go to the `SQL-Server` folder.  
2. Start with **Common-PowerShell-Modules** to see how connections and helpers are structured.  
3. Use **Connect-To-SQL-Server** to test both Windows and SQL authentication against your own instance.  
4. Explore **SQL-CRUD-Operations** for data‑manipulation patterns.  
5. Layer in **Audit-Logging-Demo** when you need change tracking and history.

This structure gives you a clear progression: connect → run queries → build CRUD → add auditing, all driven from PowerShell.