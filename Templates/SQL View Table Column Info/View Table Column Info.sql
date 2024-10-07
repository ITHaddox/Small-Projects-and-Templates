USE Database1

SELECT 
    @@SERVERNAME AS ServerName,
    DB_NAME() AS DatabaseName,
    s.name AS SchemaName,
    t.name AS TableName,
    c.name AS ColumnName,
    ty.name AS DataType,
    c.max_length AS Size,
    c.precision AS NumericPrecision,
    c.scale AS NumericScale,
    c.is_nullable AS IsNullable,
    c.is_identity AS IsIdentity,
    CASE WHEN pk.column_id IS NOT NULL THEN 1 ELSE 0 END AS IsPrimaryKey,
    CASE WHEN fk.parent_column_id IS NOT NULL THEN 1 ELSE 0 END AS IsForeignKey,
    OBJECT_DEFINITION(c.default_object_id) AS DefaultValue
FROM 
    sys.tables t
INNER JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN 
    sys.columns c ON t.object_id = c.object_id
INNER JOIN 
    sys.types ty ON c.user_type_id = ty.user_type_id
LEFT JOIN 
    sys.index_columns pk ON 
        t.object_id = pk.object_id 
        AND c.column_id = pk.column_id 
        AND pk.index_id = 1
LEFT JOIN 
    sys.foreign_key_columns fk ON 
        t.object_id = fk.parent_object_id 
        AND c.column_id = fk.parent_column_id
WHERE t.name IN ('ExampleTable1', 'ExampleTable2')
ORDER BY 
    s.name, t.name, c.column_id;


