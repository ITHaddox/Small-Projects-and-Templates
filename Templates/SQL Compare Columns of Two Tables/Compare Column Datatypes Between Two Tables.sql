/********************************************************************************************************************
This script will compare all columns on two tables and tell you 4 things.
1. If the column is missing from either table. 
2. If the column's data type does not match.
3. If the size of the data type does not match. (Ex: varchar(10) vs varchar(12))
4. If the columns match. Meaning they passed the previous 3 checks.  

NOTE: You will always have results, otherwise check the declared varables are correct.
      Linked servers work here. So keep this in mind when you're connected to a server.

This is useful for integration between systems and helps with finding why records might not be transferring. 
  Visually comparing each column is terrible. It happened to me with CAT2 integration 
  going down in the past where I compared all columns in 10 tables.
*********************************************************************************************************************/

DECLARE @TableName NVARCHAR(128) = 'INTF_ProdOrdTrans';           
DECLARE @Server1 NVARCHAR(128) = QUOTENAME('OKSQL01T');
DECLARE @Database1 NVARCHAR(128) = QUOTENAME('OK');
DECLARE @Server2 NVARCHAR(128) = QUOTENAME('OKSQL01D'); --'FSP1P2CAT2SQL';
DECLARE @DataBase2 NVARCHAR(128) = QUOTENAME('OK'); --'[ODS-FSM]';     
DECLARE @Query NVARCHAR(MAX);

SET @Query = 'SELECT 
                  COALESCE(rs1.COLUMN_NAME, rs2.COLUMN_NAME) As COLUMN_NAME,
                  ''Data Type S1'' = rs1.DATA_TYPE + '' '' + COALESCE(CAST(rs1.CHARACTER_MAXIMUM_LENGTH AS varchar), ''''),
                  ''Data Type S2'' = rs2.DATA_TYPE + '' '' + COALESCE(CAST(rs2.CHARACTER_MAXIMUM_LENGTH AS varchar), ''''),
                  ComparisonResult = 
                      CASE 
                          WHEN rs1.DATA_TYPE IS NULL THEN ''Only in ' + @Server2 + '''
                          WHEN rs2.DATA_TYPE IS NULL THEN ''Only in ' + @Server1 + '''
                          WHEN rs1.DATA_TYPE <> rs2.DATA_TYPE THEN ''Mismatch''
                          WHEN rs1.CHARACTER_MAXIMUM_LENGTH <> rs2.CHARACTER_MAXIMUM_LENGTH THEN ''Size Mismatch''
                          ELSE ''Match''
                      END
                  FROM 
                      (
                        SELECT c.COLUMN_NAME, c.DATA_TYPE, c.CHARACTER_MAXIMUM_LENGTH
                        FROM ' + @Server1 + '.' + @Database1 + '.[INFORMATION_SCHEMA].[COLUMNS] c 
                        WHERE c.TABLE_NAME = ''' + @TableName + ''' 
                      ) AS rs1
                  FULL OUTER JOIN 
                      (SELECT c.COLUMN_NAME, c.DATA_TYPE, c.CHARACTER_MAXIMUM_LENGTH
                        FROM ' + @Server2 + '.' + @Database2 + '.[INFORMATION_SCHEMA].[COLUMNS] c 
                        WHERE c.TABLE_NAME = ''' + @TableName + '''
                      ) AS rs2 
                      ON rs1.COLUMN_NAME = rs2.COLUMN_NAME;
';

EXEC sp_executesql @Query;


/*********** Add/remove column to table for testing mismatches. ************/
  
  ----OKSQL01T
  --Alter Table INTF_ProdOrdTrans Add TestTMH int
  --Alter Table INTF_ProdOrdTrans Add TestTMH_3 varchar(10)

  ----OKSQL01D
  --Alter Table INTF_ProdOrdTrans Add TestTMH_2 int
  --Alter Table INTF_ProdOrdTrans Add TestTMH_3 int




