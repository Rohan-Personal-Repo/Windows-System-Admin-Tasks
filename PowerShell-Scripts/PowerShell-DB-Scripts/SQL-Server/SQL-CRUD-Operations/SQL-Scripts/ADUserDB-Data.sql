Use ADUserDB;

-- Drop Table to have Fresh Data
DROP TABLE IF EXISTS EmpCountry;
DROP TABLE IF EXISTS EmpUserGroup;
DROP TABLE IF EXISTS Employees;

-- Country Table 
CREATE TABLE EmpCountry
(
	empCountryId INT IDENTITY(100,5) PRIMARY KEY,
	empCountryName VARCHAR(50) NOT NULL
);

INSERT INTO EmpCountry( empCountryName ) VALUES ( 'Canada' ), ('India'), ('Philippines'), ( 'South-Korea' );

SELECT * FROM EmpCountry;

-- UserGroup Table 
CREATE TABLE EmpUserGroup
(
	empUserGroupId INT IDENTITY(200,10) PRIMARY KEY,
	empUserGroupName VARCHAR(50) NOT NULL
);

INSERT INTO EmpUserGroup( empUserGroupName ) VALUES ( 'Project-Manager' ), ('Developer'), ('Tester'), ( 'Team-Lead' ), ('SystemAdmin'), ( 'Support' ), ( 'Sales' );

SELECT * FROM EmpUserGroup;

-- Employees Table
CREATE TABLE Employees
(
	empId INT IDENTITY(300,25) PRIMARY KEY,
	empFirstName VARCHAR(50) NOT NULL,
	empLastName VARCHAR(50) NOT NULL,
	empFullName VARCHAR(100) NOT NULL,
	empUserName VARCHAR(100) NOT NULL,
	empEmailId VARCHAR(100) NOT NULL,
	empIsEnabled BIT NOT NULL,
	empUsrGrp INT,
	CONSTRAINT FK_UsrGrpEmp
	FOREIGN KEY (empUsrGrp) REFERENCES EmpUserGroup(empUserGroupId),
	empCountry INT,
	CONSTRAINT FK_CountryEmp
	FOREIGN KEY (empCountry) REFERENCES EmpCountry(empCountryId)
);

INSERT INTO Employees( empFirstName,empLastName,empFullName,empUserName,empEmailId,empIsEnabled,empUsrGrp,empCountry ) VALUES
( 'Chandler', 'Bing', 'Chandler Muriel Bing', 'chandler.m.bing', 'chandler.m.bing@easysystems.in', 1, 200, 100 ),
( 'Ross', 'Geller', 'Ross Eustace Geller', 'ross.e.geller', 'ross.e.geller@easysystems.in', 1, 210, 105 ),
( 'Phoebe', 'Buffay', 'Phoebe Pamela Buffay', 'phoebe.p.buffay', 'phoebe.p.buffay@easysystems.in', 0, 220, 105 ),
( 'Monica', 'Geller', 'Monica Elizabeth Geller', 'monica.e.geller', 'monica.e.geller@easysystems.in', 0, 230, 100 ),
( 'Joey', 'Tribbiani', 'Joseph Francis Tribbiani', 'joey.f.tribbiani', 'joey.f.tribbiani@easysystems.in', 1, 240, 110 ),
( 'Rachel', 'Greene', 'Rachel Karen Greene', 'rachel.k.greene', 'rachel.k.greene@easysystems.in', 0, 250, 110 ),
( 'Gunther', 'Central Perk', 'Gunther Central Perk', 'gunther.cp', 'gunther.cp@easysystems.in', 0, 260, 115 );

SELECT * FROM Employees;

SELECT 
	empFirstName,empLastName,empFullName,empUserName,empEmailId, empUserGroupName,empCountryName,
	empIsEnabled = 
	CASE empIsEnabled
		WHEN '1' THEN 'True'
		WHEN '0' THEN 'False'
	END
FROM
	Employees, EmpCountry, EmpUserGroup 
WHERE 
	Employees.empUsrGrp = EmpUserGroup.empUserGroupId 
AND
	Employees.empCountry = EmpCountry.empCountryId;

-- Above Query in a single line
SELECT empFirstName,empLastName,empFullName,empUserName,empEmailId, empUserGroupName,empCountryName, empIsEnabled = CASE empIsEnabled WHEN '1' THEN 'True' WHEN '0' THEN 'False' END FROM Employees, EmpCountry, EmpUserGroup WHERE Employees.empUsrGrp = EmpUserGroup.empUserGroupId AND Employees.empCountry = EmpCountry.empCountryId;