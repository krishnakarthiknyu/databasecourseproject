# Creating database

DROP DATABASE IF EXISTS Rentaldb;
CREATE DATABASE Rentaldb;

USE Rentaldb;

# Creating tables for entities

CREATE TABLE Customer (
    CustomerID          INTEGER NOT NULL UNIQUE AUTO_INCREMENT,
    FirstName           VARCHAR(255) NOT NULL,
    LastName            VARCHAR(255) NOT NULL,
    Contact             VARCHAR(255) NOT NULL,
    CustomerStatus      ENUM('GOOD', 'BAD') NOT NULL,

    PRIMARY KEY(CustomerID)
    
);

CREATE TABLE Penalty (
    PenaltyID           INTEGER NOT NULL UNIQUE AUTO_INCREMENT,
    Fee                 DECIMAL(8, 2) NOT NULL,
    CustomerID          INTEGER NOT NULL,
    DueDate             DATE NOT NULL,
    PenaltyStatus       ENUM('PENDING', 'DONE') NOT NULL,

    PRIMARY KEY(PenaltyID),
    FOREIGN KEY(CustomerID) REFERENCES Customer(CustomerID) ON DELETE CASCADE
);

CREATE TABLE Manufacturer (
    ManufacturerID		INTEGER NOT NULL UNIQUE AUTO_INCREMENT,
    ManufacturerName	VARCHAR(255) NOT NULL,

    PRIMARY KEY(ManufacturerID)
);

CREATE TABLE ElectronicType (
    TypeID              INTEGER NOT NULL UNIQUE AUTO_INCREMENT,
    Kind                ENUM('LAPTOP', 'PHONE', 'CONSOLE') NOT NULL,

    PRIMARY KEY(TypeID)
);

CREATE TABLE Electronic (
    ElectronicID        INTEGER NOT NULL UNIQUE AUTO_INCREMENT,
    ElectronicName      VARCHAR(255) NOT NULL,
    ReleaseYear         YEAR,
    Count               INTEGER,
    TotalCount          INTEGER NOT NULL,
    Rating              ENUM('GOOD', 'AVERAGE', 'BAD') NOT NULL,
    ManufacturerID      INTEGER,
    TypeID              INTEGER,

    PRIMARY KEY(ElectronicID),
    FOREIGN KEY(ManufacturerID) REFERENCES Manufacturer(ManufacturerID) ON DELETE CASCADE,
    FOREIGN KEY(TypeID) REFERENCES ElectronicType(TypeID) ON DELETE CASCADE
);

CREATE TABLE OperatingSystem (
    OperatingSystemID       INTEGER NOT NULL UNIQUE AUTO_INCREMENT,
    OSName                  ENUM('WINDOWS', 'LINUX', 'IOS', 'NO OS') NOT NULL,

    PRIMARY KEY(OperatingSystemID)
);

# Creating tables for relations

CREATE TABLE Loans (
    CustomerID		    INTEGER NOT NULL,
    ElectronicID		INTEGER NOT NULL,
    StartDate   	    DATE NOT NULL,
    DueDate   	        DATE NOT NULL,
    Amount	            DECIMAL(8, 2) NOT NULL,
    LoanStatus 	        ENUM('PENDING', 'DONE', 'FINED') NOT NULL,

    PRIMARY KEY(CustomerID, ElectronicID, StartDate),
    FOREIGN KEY(CustomerID) REFERENCES Customer(CustomerID) ON DELETE CASCADE,
    FOREIGN KEY(ElectronicID) REFERENCES Electronic(ElectronicID) ON DELETE CASCADE
);

CREATE TABLE Notifies (
    CustomerID		    INTEGER NOT NULL,
    ElectronicID		INTEGER NOT NULL,

    PRIMARY KEY(CustomerID, ElectronicID),
    FOREIGN KEY(CustomerID) REFERENCES Customer(CustomerID) ON DELETE CASCADE,
    FOREIGN KEY(ElectronicID) REFERENCES Electronic(ElectronicID) ON DELETE CASCADE
);

CREATE TABLE OSInstalled (
    ElectronicID		    INTEGER NOT NULL,
    OperatingSystemID	    INTEGER NOT NULL,

    PRIMARY KEY(ElectronicID, OperatingSystemID),
    FOREIGN KEY(ElectronicID) REFERENCES Electronic(ElectronicID) ON DELETE CASCADE,
    FOREIGN KEY(OperatingSystemID) REFERENCES OperatingSystem(OperatingSystemID) ON DELETE CASCADE
);

# Creating views
DROP VIEW IF EXISTS ElectronicOSView;
DROP VIEW IF EXISTS TotalPenaltyView;

CREATE VIEW ElectronicOSView AS
    SELECT E.ElectronicID, E.ElectronicName, GROUP_CONCAT(O.OSName) AS OperatingSystem
    FROM Electronic E
        NATURAL JOIN OSInstalled I
        NATURAL JOIN OperatingSystem O
    GROUP BY E.ElectronicID;

CREATE VIEW TotalPenaltyView AS
    SELECT C.CustomerID, CONCAT(C.FirstName, ' ', C.LastName) AS CustomerName, SUM(P.Fee) AS Total
    FROM Customer C
        NATURAL JOIN Penalty P
    WHERE P.PenaltyStatus = 'PENDING'
    GROUP BY C.CustomerID;