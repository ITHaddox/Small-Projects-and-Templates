USE OK

DECLARE @UserID int = 35607 

--WarehouseAccess
MERGE INTO WarehouseAccess AS target
USING (SELECT Warehouse As WarehouseID FROM Warehouse Where ActiveFlag = 'A') AS source
ON target.Warehouse = source.WarehouseID AND target.UserID = @UserID
WHEN MATCHED AND target.ActiveFlag = 'I' THEN
    UPDATE SET ActiveFlag = 'A'
WHEN NOT MATCHED BY TARGET THEN
    INSERT (Warehouse, UserID, ActiveFlag)
    VALUES (source.WarehouseID, @UserID, 'A');

--ItemStatusResolvers
MERGE INTO ItemStatusResolvers AS target
USING (SELECT ItemStatus FROM ItemStatus Where ActiveFlag = 'A') AS source
ON target.ItemStatus = source.ItemStatus AND target.UserID = @UserID
WHEN MATCHED AND target.ActiveFlag = 'I' THEN
    UPDATE SET ActiveFlag = 'A'
WHEN NOT MATCHED BY TARGET THEN
    INSERT (ItemStatus, UserID, ActiveFlag)
    VALUES (source.ItemStatus, @UserID, 'A');


--Declare @UserName varchar(20) = 'TylerHadd'
----Scan Station Access
--MERGE INTO ScanStationAccess AS target
--USING (SELECT ScanStationKey FROM ScanStation) AS source
--ON target.ScanStationKey = source.ScanStationKey AND target.UserID = @UserName
--WHEN MATCHED AND target.ActiveFlag = 'I' THEN
--    UPDATE SET ActiveFlag = 'A'
--WHEN NOT MATCHED BY TARGET THEN
--    INSERT (ScanStationKey, UserID, ActiveFlag)
--    VALUES (source.ScanStationKey, @UserName, 'A');


