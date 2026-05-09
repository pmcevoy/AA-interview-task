-- 001_create_schema.sql
-- Creates the SmrScheduler database, all tables, constraints, and database users.
-- Idempotent: safe to re-run.
-- Requires sqlcmd variables: $(AA_TASK_MIGRATOR_PASSWORD), $(AA_TASK_APP_PASSWORD)

USE master;
GO

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'SmrScheduler')
    CREATE DATABASE SmrScheduler;
GO

USE SmrScheduler;
GO

-- ============================================================
-- Tables
-- ============================================================

IF OBJECT_ID('dbo.Branch', 'U') IS NULL
    CREATE TABLE dbo.Branch (
        Id      INT           NOT NULL IDENTITY(1,1),
        Name    NVARCHAR(100) NOT NULL,
        Address NVARCHAR(255) NOT NULL,
        CONSTRAINT PK_Branch      PRIMARY KEY (Id),
        CONSTRAINT UQ_Branch_Name UNIQUE      (Name)
    );
GO

IF OBJECT_ID('dbo.ServiceType', 'U') IS NULL
    CREATE TABLE dbo.ServiceType (
        Id              INT           NOT NULL IDENTITY(1,1),
        Name            NVARCHAR(100) NOT NULL,
        DurationMinutes INT           NOT NULL,
        CONSTRAINT PK_ServiceType      PRIMARY KEY (Id),
        CONSTRAINT UQ_ServiceType_Name UNIQUE      (Name)
    );
GO

IF OBJECT_ID('dbo.Mechanic', 'U') IS NULL
    CREATE TABLE dbo.Mechanic (
        Id       INT           NOT NULL IDENTITY(1,1),
        Name     NVARCHAR(100) NOT NULL,
        BranchId INT           NOT NULL,
        CONSTRAINT PK_Mechanic        PRIMARY KEY (Id),
        CONSTRAINT FK_Mechanic_Branch FOREIGN KEY (BranchId) REFERENCES dbo.Branch (Id)
    );
GO

IF OBJECT_ID('dbo.AppointmentSlot', 'U') IS NULL
    CREATE TABLE dbo.AppointmentSlot (
        Id            INT       NOT NULL IDENTITY(1,1),
        BranchId      INT       NOT NULL,
        MechanicId    INT       NOT NULL,
        ServiceTypeId INT       NOT NULL,
        StartTime     DATETIME2 NOT NULL,
        EndTime       DATETIME2 NOT NULL,
        IsAvailable   BIT       NOT NULL CONSTRAINT DF_AppointmentSlot_IsAvailable DEFAULT (1),
        CONSTRAINT PK_AppointmentSlot             PRIMARY KEY (Id),
        CONSTRAINT FK_AppointmentSlot_Branch      FOREIGN KEY (BranchId)      REFERENCES dbo.Branch (Id),
        CONSTRAINT FK_AppointmentSlot_Mechanic    FOREIGN KEY (MechanicId)    REFERENCES dbo.Mechanic (Id),
        CONSTRAINT FK_AppointmentSlot_ServiceType FOREIGN KEY (ServiceTypeId) REFERENCES dbo.ServiceType (Id)
    );
GO

IF OBJECT_ID('dbo.Appointment', 'U') IS NULL
    CREATE TABLE dbo.Appointment (
        Id              INT           NOT NULL IDENTITY(1,1),
        SlotId          INT           NOT NULL,
        ReferenceNumber NVARCHAR(50)  NOT NULL,
        CustomerName    NVARCHAR(100) NOT NULL,
        CustomerPhone   NVARCHAR(20)  NOT NULL,
        VehicleReg      NVARCHAR(20)  NOT NULL,
        ServiceTypeId   INT           NOT NULL,
        Notes           NVARCHAR(MAX) NULL,
        Status          NVARCHAR(20)  NOT NULL CONSTRAINT DF_Appointment_Status    DEFAULT ('Scheduled'),
        CreatedAt       DATETIME2     NOT NULL CONSTRAINT DF_Appointment_CreatedAt DEFAULT SYSUTCDATETIME(),
        CONSTRAINT PK_Appointment             PRIMARY KEY (Id),
        CONSTRAINT UQ_Appointment_SlotId      UNIQUE      (SlotId),
        CONSTRAINT UQ_Appointment_Reference   UNIQUE      (ReferenceNumber),
        CONSTRAINT FK_Appointment_Slot        FOREIGN KEY (SlotId)        REFERENCES dbo.AppointmentSlot (Id),
        CONSTRAINT FK_Appointment_ServiceType FOREIGN KEY (ServiceTypeId) REFERENCES dbo.ServiceType (Id),
        CONSTRAINT CK_Appointment_Status      CHECK       (Status IN ('Scheduled', 'InProgress', 'Completed', 'NoShow'))
    );
GO

IF OBJECT_ID('dbo.WorkNote', 'U') IS NULL
    CREATE TABLE dbo.WorkNote (
        Id            INT           NOT NULL IDENTITY(1,1),
        AppointmentId INT           NOT NULL,
        NoteText      NVARCHAR(MAX) NOT NULL,
        CreatedAt     DATETIME2     NOT NULL CONSTRAINT DF_WorkNote_CreatedAt DEFAULT SYSUTCDATETIME(),
        CONSTRAINT PK_WorkNote            PRIMARY KEY (Id),
        CONSTRAINT FK_WorkNote_Appointment FOREIGN KEY (AppointmentId) REFERENCES dbo.Appointment (Id)
    );
GO

-- ============================================================
-- Indexes
-- ============================================================

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.AppointmentSlot') AND name = 'IX_AppointmentSlot_MechanicId_StartTime')
    CREATE INDEX IX_AppointmentSlot_MechanicId_StartTime ON dbo.AppointmentSlot (MechanicId, StartTime);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.AppointmentSlot') AND name = 'IX_AppointmentSlot_BranchId_StartTime')
    CREATE INDEX IX_AppointmentSlot_BranchId_StartTime ON dbo.AppointmentSlot (BranchId, StartTime);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.Appointment') AND name = 'IX_Appointment_CreatedAt')
    CREATE INDEX IX_Appointment_CreatedAt ON dbo.Appointment (CreatedAt);
GO

-- ============================================================
-- Database users
-- Passwords supplied as sqlcmd variables by the migrator:
--   sqlcmd -v AA_TASK_MIGRATOR_PASSWORD=<pwd> -v AA_TASK_APP_PASSWORD=<pwd>
-- ============================================================

USE master;
GO

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'smr_migrator')
    CREATE LOGIN smr_migrator WITH PASSWORD = '$(AA_TASK_MIGRATOR_PASSWORD)';
GO

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'smr_app')
    CREATE LOGIN smr_app WITH PASSWORD = '$(AA_TASK_APP_PASSWORD)';
GO

USE SmrScheduler;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'smr_migrator')
BEGIN
    CREATE USER smr_migrator FOR LOGIN smr_migrator;
    ALTER ROLE db_ddladmin  ADD MEMBER smr_migrator;
    ALTER ROLE db_datareader ADD MEMBER smr_migrator;
    ALTER ROLE db_datawriter ADD MEMBER smr_migrator;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'smr_app')
BEGIN
    CREATE USER smr_app FOR LOGIN smr_app;
    ALTER ROLE db_datareader ADD MEMBER smr_app;
    ALTER ROLE db_datawriter ADD MEMBER smr_app;
END
GO
