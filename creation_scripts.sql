CREATE DATABASE UniSafety;
USE UniSafety;
CREATE TYPE zip  FROM SMALLINT NOT NULL;

/* Execute the above 3 lines one line at a time. 
 Then cut the 3 lines and execute the whole file*/
 

CREATE TABLE Uni_Community(
    UC_ID int NOT NULL,
    UC_Name varchar (30),
	UC_AddressLine1 varchar(50),
	UC_AddressLine2 varchar(50),
	UC_City varchar(20),
	UC_State varchar(20),
	UC_Zipcode ZIP CONSTRAINT UCZip_CHK CHECK (UC_Zipcode BETWEEN 501 AND 99950),
    UC_Phone char (10),
    UC_Email varchar (35),
    UC_Type varchar(10)  CONSTRAINT UCType_CHK CHECK ( UC_Type IN ('Student',
                                                     'Staff', 'Faculty') ),
    Constraint Uni_Community_PK primary key (UC_ID));
	-- The university students and staff

CREATE TABLE Anti_Theft_Registration (
    Registration_ID int NOT NULL,
    UC_ID int NOT NULL,
    Registration_Datetime Datetime,
    Registration_Property_Type varchar(12),
    Registration_Property_SerialNo varchar (15),
	CONSTRAINT RegPropType_CHK CHECK ( Registration_Property_Type IN ('Laptop','Calculator', 'Hard Drive', 'Bike', 'Skateboard') ),
    CONSTRAINT Anti_Theft_Reg_PK PRIMARY KEY (Registration_ID,UC_ID),
    CONSTRAINT Anti_Theft_Reg_FK1 FOREIGN KEY (UC_ID) REFERENCES Uni_Community (UC_ID),
    );
-- The devices for which faculty/staff register so that they can be tracked.

CREATE NONCLUSTERED INDEX UcIdATR
ON Anti_Theft_Registration(UC_ID)
/*Creating a Nonclustered index for this table to supplement faster searching of 
registrations in the event of an incident.*/ 

CREATE TABLE Unit(
    UnitID int NOT NULL,
    UnitName varchar (40),
    CONSTRAINT Unit_PK primary key (UnitID),
);
	-- Unit or different divisions in the safety department

CREATE TABLE Unit_Duty(
    DutyID int NOT NULL,
    DutyType varchar(75),
	Unit_Incharge int NOT NULL,
    CONSTRAINT UnitDuty_PK primary key (DutyID),
	CONSTRAINT UnitDuty_fk FOREIGN KEY (Unit_Incharge) REFERENCES Unit (UnitID)
    );
	-- The duties of different units
CREATE TABLE [Service](
    ServiceID int NOT NULL,
    ServiceName varchar (40),
    UnitID int NOT NULL,
    CONSTRAINT Service_PK PRIMARY KEY (ServiceID),
    CONSTRAINT Service_FK FOREIGN KEY (UnitID) REFERENCES Unit(UnitID)
    );
-- The services provided by various units/divisions of the department.

CREATE TABLE [Shift](
	Shift_Number int NOT NULL,
	Shift_StartTime time,
	Shift_EndTime time,
	CONSTRAINT Shift_pk PRIMARY KEY (Shift_Number)
 );
 -- The different shifts that can be assigned to an employee

CREATE TABLE Responsibility(
	Responsibility_ID int IDENTITY(1,1) NOT NULL,
	Responsibility_Type varchar(50),
	CONSTRAINT Res_pk PRIMARY KEY (Responsibility_ID)
 );
 -- Responsibilities of different employees

CREATE TABLE Employee(
	Employee_ID int IDENTITY(1,1) NOT NULL,
	Unit_ID int,
	Emp_Name varchar(30),
	Emp_BloodGroup varchar(5),
	Emp_AddressLine varchar(50),
	Emp_City varchar(20),
	Emp_State varchar(25),
	Emp_Zipcode ZIP CONSTRAINT EmpZip_CHK CHECK (Emp_Zipcode BETWEEN 501 AND 99950),
    Emp_Phone char(15),
	Emp_SSN VARBINARY(400),
	Emp_DateHired date,
	Emp_Type varchar(10) NOT NULL,
	Shift_Number int,
	Emp_SupervisorID int,
	Responsibility_ID int,
	CONSTRAINT Emp_pk PRIMARY KEY (Employee_ID),
	CONSTRAINT Bgroup_chk CHECK (Emp_BloodGroup IN ('O+ve','O-ve','AB+ve','AB-ve','A+ve','A-ve','B+ve','B-ve')),
	CONSTRAINT unitemp_fk FOREIGN KEY (Unit_ID) REFERENCES Unit(UnitID),
	CONSTRAINT emptypecons CHECK (Emp_Type IN ('CIVILIAN','STUDENT','OFFICER')),
	CONSTRAINT emp_uniquetype UNIQUE (Employee_ID,Emp_Type),
	CONSTRAINT ShiftEmp_fk FOREIGN KEY (Shift_Number) REFERENCES [Shift](Shift_Number),
	CONSTRAINT Responsibilityemp_fk FOREIGN KEY (Responsibility_ID) REFERENCES Responsibility(Responsibility_ID)
 );

---creating master key fordatabase

create MASTER KEY
ENCRYPTION BY PASSWORD = 'datadiggers';

--creating certificate

CREATE CERTIFICATE EmployeeSSN 
   WITH SUBJECT = 'Employee SSN Password';  
GO  
---creating symmetric key
CREATE SYMMETRIC KEY Employee_SYMMETRIC_SSN
    WITH ALGORITHM = AES_256  
    ENCRYPTION BY CERTIFICATE EmployeeSSN;  

OPEN SYMMETRIC KEY Employee_SYMMETRIC_SSN 
   DECRYPTION BY CERTIFICATE EmployeeSSN 


CREATE TABLE Civilian(
	Civilian_ID int NOT NULL,
	Emp_Type varchar(10) DEFAULT 'CIVILIAN' NOT NULL,
	JobType char(2),
	Civilian_Salarypm int,
	YearlySalary AS CASE WHEN JobType = 'FT' THEN 12 * Civilian_Salarypm ELSE NULL END PERSISTED,
	CONSTRAINT civ_pk PRIMARY KEY (Civilian_ID),
	CONSTRAINT civ_chk CHECK(Emp_Type = 'CIVILIAN'),
	CONSTRAINT civ_unq UNIQUE (Civilian_ID,Emp_Type),
	CONSTRAINT Jtype_chk CHECK(JobType in ('PT','FT')),
	CONSTRAINT civ_fk FOREIGN KEY (Civilian_ID,Emp_Type) REFERENCES Employee(Employee_ID,Emp_Type)
	ON UPDATE CASCADE ON DELETE CASCADE
 );
-- Civilian table with conditional computed column for full time employees


CREATE TABLE Student(
	Std_ID int NOT NULL,
	Emp_Type varchar(10) DEFAULT 'STUDENT' NOT NULL,
	UC_ID int,
	Student_Wageph int DEFAULT 16,
	CONSTRAINT std_pk PRIMARY KEY (Std_ID),
	CONSTRAINT ucstd_fk FOREIGN KEY (UC_ID) REFERENCES Uni_Community(UC_ID),
	CONSTRAINT std_chk CHECK(Emp_Type = 'STUDENT'),
	CONSTRAINT std_unq UNIQUE (Std_ID,Emp_Type),
	CONSTRAINT std_fk FOREIGN KEY (Std_ID,Emp_Type) REFERENCES Employee(Employee_ID,Emp_Type)
	ON UPDATE CASCADE ON DELETE CASCADE
 );
 
CREATE TABLE Officer(
	Officer_ID int NOT NULL,
	Emp_Type varchar(10) DEFAULT 'OFFICER' NOT NULL,
	[Rank] varchar(20),
	Officer_Salarypm int,
	YearlySalary AS 12*Officer_Salarypm PERSISTED,
	CONSTRAINT off_pk PRIMARY KEY (Officer_ID),
	CONSTRAINT off_chk CHECK(Emp_Type = 'OFFICER'),
	CONSTRAINT off_unq UNIQUE (Officer_ID,Emp_Type),
	CONSTRAINT off_fk FOREIGN KEY (Officer_ID,Emp_Type) REFERENCES Employee(Employee_ID,Emp_Type)
	ON UPDATE CASCADE ON DELETE CASCADE
 );
-- Officer column with computed column yearly salary 

CREATE TABLE Service_Enrollment(
    Service_ID int NOT NULL,
    UC_ID int NOT NULL,
    Date_Enrolled Date,
    Emp_Incharge int NOT NULL,
    Service_Location varchar(25),
    CONSTRAINT Service_Enrollment_PK PRIMARY KEY (Service_ID,UC_ID,Date_Enrolled),
    CONSTRAINT Service_Enrollment_FK1 FOREIGN KEY (Service_ID) references [Service] (ServiceID),
    CONSTRAINT Service_Enrollment_FK2 FOREIGN KEY (UC_ID) references Uni_Community (UC_ID),
    CONSTRAINT Service_Enrollment_FK3 FOREIGN KEY (Emp_Incharge) references Employee (Employee_ID)
);

CREATE TABLE [Notification](
	Notification_ID int identity(1,1) NOT NULL,
	Notification_Type varchar(10),
	Notification_Time DateTime,
	Notification_Details varchar(75),
	App_Officer int NOT NULL,
	CONSTRAINT notif_pk PRIMARY KEY (Notification_ID),
	CONSTRAINT notift_chk CHECK (Notification_Type IN ('Alert','Advisory','Warning')),
	CONSTRAINT notifoff_fk FOREIGN KEY (App_Officer) REFERENCES Officer( Officer_ID)
);

CREATE TABLE Incident(
	Incident_ID int IDENTITY(1,1) NOT NULL,
	Incident_Reportee varchar(30),
	Incident_Type varchar(20),
	Incident_Location varchar(40),
	Incident_Timestamp datetime,
	Incident_Status varchar(15),
	Officer_Incharge int NOT NULL,
	Incident_RequiresReport char(1),
	CONSTRAINT inc_pk PRIMARY KEY (Incident_ID),
	CONSTRAINT inceoff_fk FOREIGN KEY (Officer_Incharge) REFERENCES Officer(Officer_ID),
	CONSTRAINT Incident_RequiresReport_CHK CHECK (Incident_RequiresReport IN ('Y','N'))
);

CREATE TABLE Report(	
	Report_ID int IDENTITY(1,1) NOT NULL,
	Incident_ID int NOT NULL,
	Report_Details varchar(75),
	CONSTRAINT rep_pk PRIMARY KEY (Report_ID,Incident_ID),
	CONSTRAINT rep_fk FOREIGN KEY (Incident_ID) REFERENCES Incident(Incident_ID)
);


CREATE TABLE EmployeeResponsibility(
	Emp_Id int NOT NULL,
	ResponsibilityID int NOT NULL,
	Responsibility_StartDate Date,
	Responsibility_EndDate Date,
	CONSTRAINT EmpRes_pk PRIMARY KEY (Emp_Id,ResponsibilityID),
	CONSTRAINT Emp_Fk FOREIGN KEY (Emp_ID) REFERENCES Employee(Employee_ID) ON UPDATE CASCADE ON DELETE CASCADE,
	CONSTRAINT Resp_fk FOREIGN KEY (ResponsibilityID) REFERENCES Responsibility(Responsibility_ID) ON UPDATE CASCADE ON DELETE CASCADE
);
GO

CREATE TRIGGER InsertEmpTrig 
ON Employee
AFTER INSERT,UPDATE
AS
BEGIN
	SET NOCOUNT ON;
	INSERT INTO Civilian(Civilian_ID) SELECT i.Employee_ID FROM inserted as i WHERE i.Emp_Type = 'CIVILIAN'
	INSERT INTO Student(Std_ID) SELECT i.Employee_ID FROM inserted as i WHERE i.Emp_Type = 'STUDENT'
	INSERT INTO Officer(Officer_ID) SELECT i.Employee_ID FROM inserted as i WHERE i.Emp_Type = 'OFFICER'
END 
GO
/*The above trigger is used to insert data into subtype tables Student,
 Civilian and Officer when data is inserted into Employee supertype table.*/

CREATE TRIGGER InsEmpRes
ON Employee
AFTER INSERT,UPDATE
AS
BEGIN
	SET NOCOUNT ON;
	INSERT INTO EmployeeResponsibility(Emp_Id,ResponsibilityID,Responsibility_StartDate) 
	SELECT Employee_ID,Responsibility_ID,Emp_DateHired FROM inserted 
END
GO
/*The above trigger fires on employee table and inserts data 
into EmployeeResponsibility Table.*/


CREATE TRIGGER OffcSalarypm
ON Officer
AFTER UPDATE
AS
BEGIN
	IF UPDATE([RANK])
	BEGIN
	UPDATE Officer SET Officer_Salarypm = 8000 WHERE [Rank] = 'Chief'
	UPDATE Officer SET Officer_Salarypm = 7500 WHERE [Rank] = 'Deputy Chief'
	UPDATE Officer SET Officer_Salarypm = 7000 WHERE [Rank] IN ('Staff Sergeant','Sergeant')
	UPDATE Officer SET Officer_Salarypm = 6500 WHERE [Rank] IN ('Detective','Lieutanant')
	UPDATE Officer SET Officer_Salarypm = 6000 WHERE [Rank] = 'Officer'
	END
END
GO
/* The above trigger fires when Officer Rank is Updated and updates salaries
 based on their ranks.*/

GO
CREATE TRIGGER InsRepInc
ON Incident
AFTER INSERT,UPDATE
AS
BEGIN
	IF (SELECT Incident_RequiresReport FROM inserted) = 'Y'
	BEGIN
		INSERT INTO Report(Incident_ID,Report_Details) 
		SELECT Incident_ID,Incident_Type FROM inserted
	END
END
GO
/* The above trigger fires if the incident requires report and inserts the
 data into the report table.*/


GO
CREATE PROCEDURE ATR @Ucid int
AS
BEGIN
	SELECT * FROM Anti_Theft_Registration WHERE UC_ID=@Ucid
END
GO
/* The above procedure is used to search for any registrations quickly, by making use 
 of the non-clustered index that was created.*/


CREATE PROCEDURE Insstducid @EmplID int
AS
BEGIN
	UPDATE Student 
	SET UC_ID =	(SELECT UC_ID FROM Uni_Community WHERE UC_Name = (SELECT Emp_Name FROM Employee WHERE Employee_ID = @EmplID))
	WHERE Std_ID = @EmplID
END
GO
-- The above Procedure inserts UC_ID to Student table


CREATE PROCEDURE CivSalaryJobtype @EmpID int, @JobType char (2), @Salary int
AS 
BEGIN
	UPDATE Civilian 
	SET JobType = @JobType, Civilian_Salarypm  = @Salary
	WHERE Civilian_ID = @EmpID
END
GO
 /*The above procedure is used to add JobTpe (Parttime 'PT',FullTime 'FT) and salaries
to Civilian table.*/


CREATE PROCEDURE OfficRank @EmpId int, @rank varchar(20)
AS 
BEGIN
	UPDATE Officer
	SET [Rank] = @rank
	WHERE Officer_ID = @EmpId
END
GO
-- This procedure is used to insert ranks to Officers.
CREATE PROCEDURE NumOfEnrollDay @Date DATE 
AS
BEGIN
	SELECT SE.Service_ID,S.ServiceName,COUNT(*) AS NoOfEnrollments 
	FROM Service_Enrollment AS SE JOIN Service AS S ON SE.Service_ID = S.ServiceID  
	GROUP BY SE.Service_ID,S.ServiceName,SE.Date_Enrolled HAVING SE.Date_Enrolled = @Date ORDER BY NoOfEnrollments DESC
	
END
GO
/*This procedure gives details about the number of enrollments for a particular date
 by taking in the date as the input parameter.*/ 


CREATE VIEW EmployeeStudentDetails
AS
SELECT E.Employee_ID,E.Emp_Name,E.Emp_City,E.Emp_Phone,E.Emp_DateHired,E.Emp_SupervisorID,S.UC_ID 
FROM Employee AS E JOIN Student AS S ON E.Employee_ID = S.Std_ID;
GO
--The view gives student employee details.

CREATE VIEW EmpUnitDetails
AS
SELECT e.Employee_ID,e.Emp_Name,e.Emp_Phone,u.UnitID,u.UnitName FROM Employee as e JOIN Unit as u on e.Unit_ID = u.UnitID
GO
/* This view gives the employee and Unit details together, 
just to make it easier to understand which employee belongs to which unit.*/

CREATE VIEW NumOfEmpperUnit
AS
SELECT UnitID,UnitName,Count(*) as NumberOfEmployees FROM EmpUnitDetails GROUP BY UnitID,UnitName
GO
 -- This view gives the count of number of employees in a Unit.
