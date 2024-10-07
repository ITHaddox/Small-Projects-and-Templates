-- 1. Create a Table
CREATE TABLE Employees (
    EmployeeID INT PRIMARY KEY IDENTITY(1,1),
    FirstName NVARCHAR(50),
    LastName NVARCHAR(50),
    Department NVARCHAR(50),
    HireDate DATE
);

-- 2. Insert Data
INSERT INTO Employees (FirstName, LastName, Department, HireDate)
VALUES 
    ('John', 'Doe', 'IT', '2022-01-15'),
    ('Jane', 'Smith', 'HR', '2021-11-01'),
    ('Mike', 'Johnson', 'Sales', '2023-03-10');

-- 3. Select Data with Filtering and Sorting
SELECT FirstName, LastName, Department
FROM Employees
WHERE HireDate >= '2022-01-01'
ORDER BY LastName ASC;

-- 4. Update Data
UPDATE Employees
SET Department = 'Marketing'
WHERE EmployeeID = 3;

-- 5. Delete Data
DELETE FROM Employees
WHERE EmployeeID = 2;

-- 6. Create a Stored Procedure
CREATE PROCEDURE usp_GetEmployeesByDepartment
    @Department NVARCHAR(50)
AS
BEGIN
    SELECT FirstName, LastName, HireDate
    FROM Employees
    WHERE Department = @Department
    ORDER BY HireDate DESC;
END;

-- 7. Execute the Stored Procedure
EXEC usp_GetEmployeesByDepartment @Department = 'IT';

-- 8. Create a View
CREATE VIEW vw_EmployeeSummary AS
SELECT 
    Department,
    COUNT(*) AS EmployeeCount,
    AVG(DATEDIFF(YEAR, HireDate, GETDATE())) AS AvgYearsOfService
FROM Employees
GROUP BY Department;

-- 9. Query the View
SELECT * FROM vw_EmployeeSummary;

-- 10. Create an Index
CREATE NONCLUSTERED INDEX IX_Employees_Department
ON Employees (Department);

-- 11. Transaction Example
BEGIN TRANSACTION;

INSERT INTO Employees (FirstName, LastName, Department, HireDate)
VALUES ('Alice', 'Williams', 'Finance', '2023-06-01');

-- Simulating a condition to rollback
IF (SELECT COUNT(*) FROM Employees WHERE Department = 'Finance') > 5
BEGIN
    ROLLBACK;
    PRINT 'Transaction rolled back: Too many employees in Finance.';
END
ELSE
BEGIN
    COMMIT;
    PRINT 'Transaction committed successfully.';
END;

-- 12. Common Table Expression (CTE)
WITH DepartmentCTE AS (
    SELECT Department, COUNT(*) AS EmpCount
    FROM Employees
    GROUP BY Department
)
SELECT Department, EmpCount
FROM DepartmentCTE
WHERE EmpCount > 1;