USE Rentaldb;


# insert data into db
# Customer and other data -> manually insert few into db
INSERT Customer (CustomerID, FirstName, LastName, Contact, CustomerStatus) VALUES
(1, 'Kaladin', 'Stormblessed', '3471234567', 'GOOD'),
(2, 'Dalinar', 'Kholin', '3471234568', 'GOOD'),
(3, 'Odium', 'Shard', '3470000000', 'BAD');

INSERT ElectronicType (TypeID, Kind) VALUES
(1, 'LAPTOP'),
(2, 'PHONE'),
(3, 'CONSOLE');

INSERT OperatingSystem (OperatingSystemID, OSName) VALUES
(1, 'WINDOWS'),
(2, 'LINUX'),
(3, 'IOS'),
(4, 'NO OS');

SELECT * FROM Customer LIMIT 10;
SELECT * FROM ElectronicType LIMIT 10;
SELECT * FROM OperatingSystem LIMIT 10;



# Electronic dataset -> python script to clean up the data -> sql script to load data into db
# dataset for laptops https://www.kaggle.com/code/danielbethell/laptop-prices-prediction/data
-- SHOW VARIABLES LIKE "secure_file_priv";

LOAD DATA INFILE '/var/lib/mysql-files/manufacturers.csv' INTO TABLE Manufacturer
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(ManufacturerID, ManufacturerName);

LOAD DATA INFILE '/var/lib/mysql-files/electronics.csv' INTO TABLE Electronic
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(ElectronicID, ElectronicName, ReleaseYear, Count, TotalCount, Rating, ManufacturerID, TypeID);

LOAD DATA INFILE '/var/lib/mysql-files/osinstalled.csv' INTO TABLE OSInstalled
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(ElectronicID, OperatingSystemID);

SELECT * FROM Manufacturer LIMIT 10;
SELECT * FROM Electronic LIMIT 10;
SELECT * FROM OSInstalled LIMIT 10;

INSERT Penalty (PenaltyID, Fee, CustomerID, DueDate, PenaltyStatus) VALUES
(1, 30.00, 3, '2022-10-18', 'PENDING');

INSERT Loans (CustomerID, ElectronicID, StartDate, DueDate, Amount, LoanStatus) VALUES
(2, 6, '2022-10-08', TIMESTAMPADD(DAY, 30, '2022-10-08'), 150.00, 'DONE'),
(3, 2, '2022-09-18', TIMESTAMPADD(DAY, 30, '2022-09-18'), 175.00, 'FINED'),
(1, 3, '2022-12-08', TIMESTAMPADD(DAY, 30, '2022-12-08'), 200.00, 'PENDING');

INSERT Notifies (CustomerID, ElectronicID) VALUES
(1, 2);

SELECT * FROM Penalty LIMIT 10;
SELECT * FROM Loans LIMIT 10;
SELECT * FROM Notifies LIMIT 10;

SELECT * FROM ElectronicOSView LIMIT 10;
SELECT * FROM TotalPenaltyView LIMIT 10;