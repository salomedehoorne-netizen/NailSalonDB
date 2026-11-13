-- NailSalonDB | Database schema and reporting views
-- Public portfolio edition. Derived from SSMS Generate Scripts (schema only).
-- SQL Server T-SQL. Intended for a NEW SQL Server database.
-- Does not include customer data, payment records, or test data.
-- Important: do not execute this file against your existing NailSalonDB;
-- CREATE DATABASE will fail if that database already exists.

USE [master];
GO
CREATE DATABASE [NailSalonDB];
GO

USE [NailSalonDB]
GO
-- Table: [dbo].[Clients]
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Clients](
	[ClientID] [int] IDENTITY(1,1) NOT NULL,
	[FirstName] [varchar](50) NOT NULL,
	[LastName] [varchar](50) NOT NULL,
	[Phone] [varchar](20) NULL,
	[Email] [varchar](100) NULL,
PRIMARY KEY CLUSTERED 
(
	[ClientID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
-- Table: [dbo].[Employees]
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Employees](
	[EmployeeID] [int] IDENTITY(1,1) NOT NULL,
	[FirstName] [varchar](50) NOT NULL,
	[LastName] [varchar](50) NOT NULL,
	[Phone] [varchar](20) NULL,
PRIMARY KEY CLUSTERED 
(
	[EmployeeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
-- Table: [dbo].[Services]
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Services](
	[ServiceID] [int] IDENTITY(1,1) NOT NULL,
	[ServiceName] [varchar](100) NOT NULL,
	[Price] [decimal](10, 2) NOT NULL,
	[Duration] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ServiceID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
-- Table: [dbo].[Appointments]
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Appointments](
	[AppointmentID] [int] IDENTITY(1,1) NOT NULL,
	[ClientID] [int] NOT NULL,
	[EmployeeID] [int] NOT NULL,
	[AppointmentDate] [datetime2](7) NOT NULL,
	[Status] [varchar](20) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[AppointmentID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
-- Table: [dbo].[AppointmentServices]
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AppointmentServices](
	[AppointmentID] [int] NOT NULL,
	[ServiceID] [int] NOT NULL,
 CONSTRAINT [PK_AppointmentServices] PRIMARY KEY CLUSTERED 
(
	[AppointmentID] ASC,
	[ServiceID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
-- View: [dbo].[vw_AppointmentReport]
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vw_AppointmentReport]
AS

WITH AppointmentDetails AS (
    SELECT
        aps.AppointmentID,
        SUM(s.Duration) AS TotalMinutes,
        SUM(s.Price) AS BookedValue
    FROM dbo.AppointmentServices AS aps
    INNER JOIN dbo.Services AS s
        ON aps.ServiceID = s.ServiceID
    GROUP BY aps.AppointmentID
)

SELECT
    a.AppointmentID,
    c.FirstName + ' ' + c.LastName
        AS Customer,
    e.FirstName + ' ' + e.LastName
        AS Employee,
    a.AppointmentDate AS StartTime,
    DATEADD(
        MINUTE,
        ad.TotalMinutes,
        a.AppointmentDate
    ) AS EstimatedEndTime,
    ad.TotalMinutes,
    ad.BookedValue,
    a.Status
FROM dbo.Appointments AS a
INNER JOIN dbo.Clients AS c
    ON a.ClientID = c.ClientID
INNER JOIN dbo.Employees AS e
    ON a.EmployeeID = e.EmployeeID
INNER JOIN AppointmentDetails AS ad
    ON a.AppointmentID = ad.AppointmentID;
GO
-- Table: [dbo].[Payments]
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Payments](
	[PaymentID] [int] IDENTITY(1,1) NOT NULL,
	[AppointmentID] [int] NOT NULL,
	[Amount] [decimal](10, 2) NOT NULL,
	[PaymentMethod] [varchar](30) NOT NULL,
	[PaymentDate] [datetime2](7) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[PaymentID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
-- View: [dbo].[vw_FinancialReport]
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vw_FinancialReport]
AS

WITH PaymentTotals AS (
    SELECT
        AppointmentID,
        SUM(Amount) AS TotalPaid
    FROM dbo.Payments
    GROUP BY AppointmentID
)

SELECT
    ar.AppointmentID,
    ar.Customer,
    ar.Employee,
    ar.StartTime,
    ar.Status,
    ar.BookedValue,
    COALESCE(pt.TotalPaid, 0) AS TotalPaid,
    ar.BookedValue
        - COALESCE(pt.TotalPaid, 0) AS Difference
FROM dbo.vw_AppointmentReport AS ar
LEFT JOIN PaymentTotals AS pt
    ON ar.AppointmentID = pt.AppointmentID;
GO
-- View: [dbo].[vw_ServicePerformance]
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vw_ServicePerformance]
AS

SELECT
    s.ServiceID,
    s.ServiceName,
    s.Price,
    s.Duration,
    COUNT(aps.AppointmentID) AS TotalBookings,
    COUNT(aps.AppointmentID) * s.Price
        AS TotalBookedValue
FROM dbo.Services AS s
LEFT JOIN dbo.AppointmentServices AS aps
    ON s.ServiceID = aps.ServiceID
GROUP BY
    s.ServiceID,
    s.ServiceName,
    s.Price,
    s.Duration;
GO
ALTER TABLE [dbo].[Appointments] ADD  DEFAULT ('Scheduled') FOR [Status]
GO
ALTER TABLE [dbo].[Appointments]  WITH CHECK ADD FOREIGN KEY([ClientID])
REFERENCES [dbo].[Clients] ([ClientID])
GO
ALTER TABLE [dbo].[Appointments]  WITH CHECK ADD FOREIGN KEY([EmployeeID])
REFERENCES [dbo].[Employees] ([EmployeeID])
GO
ALTER TABLE [dbo].[AppointmentServices]  WITH CHECK ADD  CONSTRAINT [FK_AS_Appointments] FOREIGN KEY([AppointmentID])
REFERENCES [dbo].[Appointments] ([AppointmentID])
GO
ALTER TABLE [dbo].[AppointmentServices] CHECK CONSTRAINT [FK_AS_Appointments]
GO
ALTER TABLE [dbo].[AppointmentServices]  WITH CHECK ADD  CONSTRAINT [FK_AS_Services] FOREIGN KEY([ServiceID])
REFERENCES [dbo].[Services] ([ServiceID])
GO
ALTER TABLE [dbo].[AppointmentServices] CHECK CONSTRAINT [FK_AS_Services]
GO
ALTER TABLE [dbo].[Payments]  WITH CHECK ADD  CONSTRAINT [FK_Payments_Appointments] FOREIGN KEY([AppointmentID])
REFERENCES [dbo].[Appointments] ([AppointmentID])
GO
ALTER TABLE [dbo].[Payments] CHECK CONSTRAINT [FK_Payments_Appointments]
GO
ALTER TABLE [dbo].[Payments]  WITH CHECK ADD  CONSTRAINT [CK_Payments_Amount] CHECK  (([Amount]>(0)))
GO
ALTER TABLE [dbo].[Payments] CHECK CONSTRAINT [CK_Payments_Amount]
GO
