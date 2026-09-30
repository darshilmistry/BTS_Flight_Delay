CREATE OR ALTER PROCEDURE dbo.usp_drop_objects
    @Target  SYSNAME,
    @Confirm VARCHAR(300) = NULL,
    @DryRun  BIT          = 1     -- only applies to ALL
AS
BEGIN
    SET NOCOUNT ON;

    -- Registry: whitelist + drop order (fact first, it holds the FKs)
    DECLARE @Objects TABLE (DropOrder INT PRIMARY KEY, ObjName SYSNAME NOT NULL);
    INSERT INTO @Objects VALUES
        (1, 'warehouse.fact_flight'),
        (2, 'warehouse.dim_airframe'),
        (3, 'warehouse.dim_carrier'),
        (4, 'warehouse.dim_airport'),
        (5, 'warehouse.dim_route'),
        (6, 'warehouse.dim_date'),
        (7, 'staging.raw_flights_landing'),
        (8, 'quarantine.bad_rows');

    -- Whitelist
    IF @Target <> 'ALL' AND NOT EXISTS (SELECT 1 FROM @Objects WHERE ObjName = @Target)
        THROW 50100, 'Target not on the whitelist. Use ALL or a listed schema.table.', 1;

    -- Red cap: mode-specific phrase
    DECLARE @Expected VARCHAR(300) =
        CASE WHEN @Target = 'ALL'
             THEN 'NUKE ' + DB_NAME()
             ELSE 'DROP ' + @Target + ' ' + DB_NAME()
        END;

    IF @Confirm IS NULL OR @Confirm <> @Expected
    BEGIN
        DECLARE @Hint NVARCHAR(400) = 'Aborted. Expected @Confirm = ''' + @Expected + '''.';
        THROW 50101, @Hint, 1;
    END;

    DECLARE @Sql NVARCHAR(400), @Obj SYSNAME;

    /* ---------- SINGLE TABLE ---------- */
    IF @Target <> 'ALL'
    BEGIN
        IF OBJECT_ID(@Target, N'U') IS NULL
        BEGIN
            PRINT @Target + ' does not exist. Nothing dropped.';
            RETURN;
        END;

        DECLARE @Referencers NVARCHAR(MAX);
        SELECT @Referencers = STRING_AGG(
                   OBJECT_SCHEMA_NAME(fk.parent_object_id) + '.' + OBJECT_NAME(fk.parent_object_id), ', ')
        FROM sys.foreign_keys fk
        WHERE fk.referenced_object_id = OBJECT_ID(@Target)
          AND fk.parent_object_id <> fk.referenced_object_id;

        IF @Referencers IS NOT NULL
        BEGIN
            DECLARE @Msg NVARCHAR(2048) =
                'Aborted. ' + @Target + ' is referenced by: ' + @Referencers + '. Drop those first.';
            THROW 50102, @Msg, 1;
        END;

        SET @Sql = N'DROP TABLE ' + QUOTENAME(PARSENAME(@Target, 2)) + N'.' + QUOTENAME(PARSENAME(@Target, 1)) + N';';
        EXEC sp_executesql @Sql;
        PRINT @Target + ' dropped. Run dbo.usp_setup_objects to recreate.';
        RETURN;
    END;

    /* ---------- ALL ---------- */
    IF @DryRun = 1
    BEGIN
        DECLARE @List NVARCHAR(MAX);
        SELECT @List = STRING_AGG(CAST('  ' + ObjName AS NVARCHAR(MAX)), CHAR(10))
                       WITHIN GROUP (ORDER BY DropOrder)
        FROM @Objects;

        PRINT 'DRY RUN. Nothing dropped. Would drop, in order:';
        PRINT @List;
        PRINT 'Rerun with @DryRun = 0 to launch.';
        RETURN;
    END;

    DECLARE @i INT = 1, @Max INT = (SELECT MAX(DropOrder) FROM @Objects);
    WHILE @i <= @Max
    BEGIN
        SELECT @Obj = ObjName FROM @Objects WHERE DropOrder = @i;
        SET @Sql = N'DROP TABLE IF EXISTS ' + QUOTENAME(PARSENAME(@Obj, 2)) + N'.' + QUOTENAME(PARSENAME(@Obj, 1)) + N';';
        EXEC sp_executesql @Sql;
        PRINT 'Dropped ' + @Obj;
        SET @i += 1;
    END;

    PRINT 'Warehouse nuked. Run dbo.usp_setup_objects to rebuild.';
END;