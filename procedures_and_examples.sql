USE Rentaldb;

# Hey I want to know what electronics are avaliable and their operating systems
SELECT GROUP_CONCAT(OperatingSystem.OperatingSystemID SEPARATOR ', ') AS OperatingSystemIds,
       GROUP_CONCAT(OSName SEPARATOR ', ') AS OperatingSystemNames,
       OSInstalled.ElectronicID,
       Electronic.ElectronicName ElectronicName
FROM OSInstalled
JOIN OperatingSystem on OSInstalled.OperatingSystemID = OperatingSystem.OperatingSystemID
JOIN Electronic on OSInstalled.ElectronicID = Electronic.ElectronicID
GROUP BY OSInstalled.ElectronicID;

# To see how many devices have particular Operating system installed
SELECT   OperatingSystem.OperatingSystemID, OperatingSystem.OSName,
         COUNT(*) AS NumberOfDevices
FROM     OperatingSystem
JOIN     OSInstalled ON OperatingSystem.OperatingSystemID = OSInstalled.OperatingSystemID
GROUP BY OperatingSystem.OperatingSystemID
ORDER BY NumberOfDevices DESC;

# Check loan status for each customer

SELECT Customer.CustomerID,
        CONCAT(Customer.FirstName,' ', Customer.LastName) AS FullName,
       SUM(LoanStatus LIKE 'PENDING') AS ActiveLoans,
       SUM(LoanStatus LIKE 'DONE') AS Returned,
       SUM(LoanStatus LIKE 'FINED') AS Fined,
       COUNT(*) AS Total
FROM Customer
JOIN Loans on Customer.CustomerID = Loans.CustomerID
GROUP BY CustomerID;

DROP PROCEDURE IF EXISTS LoanDevice;

CREATE PROCEDURE LoanDevice(IN vCustomerID INTEGER, IN vElectronicID INTEGER)
BEGIN
    INSERT Loans(CustomerID, ElectronicID, StartDate, DueDate, Amount, LoanStatus)
        VALUES (vCustomerID, vElectronicID, NOW(), ADDDATE(CURDATE(), INTERVAL 30 DAY), 150.00, 'PENDING');
END ;

# Testing the procedure:

# BEFORE:
SELECT E.ElectronicName, L.StartDate, L.DueDate, L.LoanStatus
FROM Electronic E
NATURAL JOIN Loans L
WHERE L.CustomerID = 2;

# CALLING THE PROCEDURE:
CALL LoanDevice(2, 1);

# AFTER:
SELECT E.ElectronicName, L.StartDate, L.DueDate, L.LoanStatus
FROM Electronic E
NATURAL JOIN Loans L
WHERE L.CustomerID = 2;


# When this procedure is caled it looks into all the loans and their due dates. If any loan is past due date
# it creates a penalty

DROP PROCEDURE IF EXISTS CreatePenalty;

CREATE PROCEDURE CreatePenalty()
BEGIN
    START TRANSACTION;
        INSERT INTO Penalty (CustomerID, Fee, DueDate, PenaltyStatus)
            SELECT CustomerID, 100.00, CURDATE(), 'PENDING' FROM Loans L
            WHERE L.LoanStatus = 'PENDING' AND DATEDIFF(L.DueDate, CURDATE()) < 0;

        UPDATE Loans L SET LoanStatus = 'FINED'
        WHERE L.LoanStatus = 'PENDING' AND DATEDIFF(L.DueDate, CURDATE()) < 0;
    COMMIT;
END;

# Testing the procedure with transaction:

# BEFORE:
SELECT E.ElectronicName, L.StartDate, L.DueDate, L.LoanStatus
FROM Electronic E
NATURAL JOIN Loans L
WHERE L.CustomerID = 1;

SELECT * FROM Penalty P WHERE P.CustomerID = 1;

# CREATE TEST CONDITIONS:
UPDATE Loans L SET L.StartDate = ADDDATE(CURDATE(), -40)
WHERE L.CustomerID = 1 AND L.ElectronicID = 3;

UPDATE Loans L SET L.DueDate = ADDDATE(CURDATE(), -10)
WHERE L.CustomerID = 1 AND L.ElectronicID = 3;

# CALLING THE PROCEDURE:
CALL CreatePenalty();

# AFTER:
SELECT E.ElectronicName, L.StartDate, L.DueDate, L.LoanStatus
FROM Electronic E
NATURAL JOIN Loans L
WHERE L.CustomerID =1;

SELECT * FROM Penalty P WHERE P.CustomerID = 1;

# Cases when customer has pending loans and request for new device for loan or device out of stock

DROP TRIGGER IF EXISTS Check_loans_before_granting;

CREATE TRIGGER Check_loans_before_granting
BEFORE INSERT ON Loans FOR EACH ROW
BEGIN
	DECLARE LoanedCount, TotalCount, ActiveLoansOfDevice INTEGER DEFAULT 0;
    SELECT COUNT(*) INTO LoanedCount FROM Loans L
    WHERE L.ElectronicID = NEW.ElectronicID AND L.LoanStatus != 'DONE' 
    GROUP BY ElectronicID;
	SELECT E.TotalCount INTO TotalCount FROM Electronic E WHERE E.ElectronicID = NEW.ElectronicID;
	IF (LoanedCount >= TotalCount)
		THEN SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Device out of stock';
	END IF;
	SELECT COUNT(*) INTO ActiveLoansOfDevice FROM Loans L
	WHERE L.ElectronicID = NEW.ElectronicID AND L.CustomerID = NEW.CustomerID AND L.LoanStatus != 'DONE'
	GROUP BY L.ElectronicID;
	IF (ActiveLoansOfDevice != 0)
		THEN SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Customer already loaned device';
	END IF;
END;

CALL LoanDevice(2, 1); 

UPDATE Electronic E SET E.TotalCount = 0
WHERE E.ElectronicID = 5;
CALL LoanDevice(1, 5);

# Schedule create penalties at end of each DAY

SET GLOBAL event_scheduler = 1;
DROP EVENT IF EXISTS CreateFinesEvent;

CREATE EVENT CreateFinesEvent ON SCHEDULE EVERY 1 DAY 
DO
BEGIN
	CALL CreatePenalty();
END;

SET SQL_SAFE_UPDATES = 0;

# BEFORE:
SELECT * FROM Electronic Limit 5;

UPDATE Electronic SET TotalCount = 25
WHERE ElectronicID = 4;

# AFTER:
SELECT * FROM Electronic Limit 5;