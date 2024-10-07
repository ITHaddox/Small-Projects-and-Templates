--This should work. I tested it in my local environment:

--Delete duplicate records with the same GUIDRef
WITH CTE AS(
  SELECT 
    ProcessID, 
    GUIDRef,
    RN = ROW_NUMBER()OVER(PARTITION BY ProcessID, GUIDRef ORDER BY CreateDateTime)
  FROM INTF_Exports
)
DELETE FROM CTE WHERE RN > 1
GO

----- Unique key
ALTER TABLE cat2.intf_exports ADD UNIQUE (processid, guidref)
GO

--That should delete the duplicates and then apply the UniqueKey on it.
