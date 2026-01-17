USE AuditLogDB;


-- CREATE Audit table
DROP TABLE IF EXISTS AuditTable;

-- affectedUserId - User whose data was changed
-- initiatedByDBUser - The DB User who performed the Change
-- auditEntryDate DEFAULT CURRENT_TIMESTAMP - Automatically Add the Value of the Current Local DateTime Stamp, no need to pass the Time Value
CREATE TABLE AuditTable
(
	auditEntryId INT PRIMARY KEY IDENTITY(1,2),
	dbName VARCHAR(50),
	tableName VARCHAR(50),
	operation VARCHAR(10),
	affectedUserId INT,
	initiatedByDBUser VARCHAR(50),
	systemName VARCHAR(50),
	appName VARCHAR(50),
	auditEntryDate DATETIME DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO AuditTable
	(dbName, tableName,operation,affectedUserId,initiatedByDBUser,systemName,appName,auditEntryDate) 
VALUES 
	('CompDB','Employee', 'INS', 1000, 'SQLAdmin','CA-Win11','SSMS','2024-02-12 12:54:14.230'),
	('CompDB','Employee', 'UPD', 1100, 'SQLAdmin','US-Win10','SSMS','2024-02-12 23:54:04.430'),
	('CompDB','Employee', 'DEL', 1100, 'SQLAdmin','US-Win11','SSMS','2024-02-13 00:00:29.020'),
	('CompDB','Department', 'INS', 125, 'SQLAdmin','CA-Win10','UMG-App','2024-02-13 00:04:07.957'),
	('CompanyDatabase','Employee', 'UPD', 150, 'SQLAdmin','CA-Win2K19','UMG-App','2024-02-13 00:04:26.890'),
	('CompanyDatabase','Employee', 'DEL', 175, 'SQLAdmin','CA-Win2K22','UMG-App','2024-02-13 00:05:53.137'),
	('ADUserDB','Employees', 'INS', 300, 'WindowsAdmin','CA-Win2K22','AD-App','2024-02-13 00:06:11.830'),
	('ADUserDB','Employees', 'UPD', 550, 'WindowsAdmin','CA-Win2K19','AD-App','2024-02-13 00:17:44.493'),
	('ADUserDB','Employees', 'DEL', 550, 'SQLAdmin','CA-Win2K22','Website','2024-02-13 00:19:04.127'),
	('ADUserDB','Employees', 'INS', 325, 'WindowsAdmin','PH-Win2K22','Website','2025-04-07 22:41:11.033'),
	('ADUserDB','EmpCountry', 'UPD', 105, 'WindowsAdmin','PH-Win2K19','MobileApp','2025-04-07 22:43:16.617');

-- Since we have a Default TimeStamp Set we don't need to specify as it will take the current Time
INSERT INTO AuditTable
	(dbName, tableName,operation,affectedUserId,initiatedByDBUser,systemName,appName) 
VALUES 
	('ADUserDB','EmpUserGroup', 'DEL', 250, 'SQLAdmin','SK-Win11','MobileApp');

SELECT * FROM AuditTable ORDER BY auditEntryDate DESC;