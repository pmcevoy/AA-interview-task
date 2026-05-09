-- 002_seed_data.sql
-- Populates reference and test data. Idempotent: all inserts use MERGE on natural keys.

USE SmrScheduler;
GO

-- ============================================================
-- Branches
-- ============================================================

MERGE dbo.Branch AS target
USING (VALUES
    (N'Dublin', N'12 Pearse Street, Dublin 2'),
    (N'Cork',   N'45 Patrick Street, Cork'),
    (N'Galway', N'8 Shop Street, Galway')
) AS source (Name, Address)
ON target.Name = source.Name
WHEN NOT MATCHED BY TARGET THEN
    INSERT (Name, Address) VALUES (source.Name, source.Address);
GO

-- ============================================================
-- ServiceTypes
-- ============================================================

MERGE dbo.ServiceType AS target
USING (VALUES
    (N'Inspection',  30),
    (N'Service',     60),
    (N'Repair',      90),
    (N'Diagnostics', 45)
) AS source (Name, DurationMinutes)
ON target.Name = source.Name
WHEN NOT MATCHED BY TARGET THEN
    INSERT (Name, DurationMinutes) VALUES (source.Name, source.DurationMinutes)
WHEN MATCHED AND target.DurationMinutes <> source.DurationMinutes THEN
    UPDATE SET DurationMinutes = source.DurationMinutes;
GO

-- ============================================================
-- Mechanics
-- ============================================================

MERGE dbo.Mechanic AS target
USING (
    SELECT source.Name, b.Id AS BranchId
    FROM (VALUES
        (N'Sean Murphy',   N'Dublin'),
        (N'Aoife Kelly',   N'Dublin'),
        (N'Ciarán O''Brien', N'Cork'),
        (N'Niamh Walsh',   N'Galway')
    ) AS source (Name, BranchName)
    INNER JOIN dbo.Branch b ON b.Name = source.BranchName
) AS source
ON target.Name = source.Name
WHEN NOT MATCHED BY TARGET THEN
    INSERT (Name, BranchId) VALUES (source.Name, source.BranchId)
WHEN MATCHED AND target.BranchId <> source.BranchId THEN
    UPDATE SET BranchId = source.BranchId;
GO

-- ============================================================
-- AppointmentSlots
-- For each mechanic × service type × next 7 days (from today),
-- generate slots from 09:00–17:00 in duration-sized increments.
--
-- SlotNums covers indices 0–15 (max 16 slots for a 30-min service
-- in an 8-hour day); the WHERE clause filters to only valid indices
-- per service type: n < FLOOR(480 / DurationMinutes).
-- ============================================================

WITH
SlotNums AS (
    SELECT n FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12),(13),(14),(15)) AS v(n)
),
DayOffsets AS (
    SELECT d FROM (VALUES (0),(1),(2),(3),(4),(5),(6)) AS v(d)
),
SlotDefs AS (
    SELECT
        m.Id        AS MechanicId,
        m.BranchId,
        st.Id       AS ServiceTypeId,
        st.DurationMinutes,
        dn.d        AS DayOffset,
        sn.n        AS SlotIndex
    FROM       dbo.Mechanic    m
    CROSS JOIN dbo.ServiceType st
    CROSS JOIN DayOffsets      dn
    CROSS JOIN SlotNums        sn
    WHERE sn.n < FLOOR(480.0 / st.DurationMinutes)
),
GeneratedSlots AS (
    SELECT
        MechanicId,
        BranchId,
        ServiceTypeId,
        DATEADD(MINUTE,  SlotIndex      * DurationMinutes,
            DATEADD(HOUR, 9, CAST(CAST(DATEADD(DAY, DayOffset, GETUTCDATE()) AS DATE) AS DATETIME2))
        ) AS StartTime,
        DATEADD(MINUTE, (SlotIndex + 1) * DurationMinutes,
            DATEADD(HOUR, 9, CAST(CAST(DATEADD(DAY, DayOffset, GETUTCDATE()) AS DATE) AS DATETIME2))
        ) AS EndTime
    FROM SlotDefs
)
MERGE dbo.AppointmentSlot AS target
USING GeneratedSlots AS source
    ON  target.MechanicId    = source.MechanicId
    AND target.ServiceTypeId = source.ServiceTypeId
    AND target.StartTime     = source.StartTime
WHEN NOT MATCHED BY TARGET THEN
    INSERT (BranchId, MechanicId, ServiceTypeId, StartTime, EndTime, IsAvailable)
    VALUES (source.BranchId, source.MechanicId, source.ServiceTypeId, source.StartTime, source.EndTime, 1);
GO
