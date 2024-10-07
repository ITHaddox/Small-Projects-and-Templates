


--Search for procedures 
USE OK
SELECT Name
FROM sys.procedures
WHERE OBJECT_DEFINITION(OBJECT_ID) LIKE '%SearchForStuff%'


--Search for triggers
USE OK
SELECT Name
FROM sys.triggers
WHERE OBJECT_DEFINITION(OBJECT_ID) LIKE '%SearchForStuff%'



--Search for code inside triggers and procedures.
USE OK
EXEC sp_search_code 'INTF_ProdOrdTrans'


--Search for emails. 
Select *
From OKAppsSecurity..OKEmail e
Where e.[Subject] = 'In 3 days these products will go on hold due to Ship By Date (Item Status 6)'
Order By EmailDate Desc