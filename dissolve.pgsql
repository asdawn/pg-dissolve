/**
Dissolve for PostGIS
    Here we use  'GP_' as the prefix, which means geo-processing. 
**/


/**
GP_Dissolve
    Merge adjacent geometries into one geometry. The algorithm is:
    1. Create a copy of tableIn, note it as tIN, and create index  
    2. Read a record from tIN, query all records intersect with it (and fullfil condition, for example has the same name, id, etc.)
    3. Insert this record into the output table (note it as tOUT), and update the geometry to the union of the geometries.
    4. Delete used records from tIN.
    5. while tIN is not empty LOOP 2.
    6. Drop table IN, of course it will be delete automatically.
    tableName - the table to process

IMPORTANT: IT WILL DROP TEMP TABLE  tableName||'_tmp'
**/
DROP FUNCTION if exists GP_Dissolve();
CREATE FUNCTION GP_Dissolve(tableIn text, tableOut text, condition text[] default NULL, geomIn text default 'geom', geomOut text default 'geom') RETURNS boolean AS $$
DECLARE
    sql text;
    tIN text;
    field text;
    n int;
    cur refCursor;
	version CONSTANT text := '1.0.0';
BEGIN
	IF tableIn is NULL OR tableOut is NULL OR trim(tableIn) ='' OR trim(tableOut) THEN
        raise notice '%', 'Invalid input/output table name.';
        return false;
    END IF;
    tIN := tableName || '_tmp';
    --1. create temp table IN
    sql := 'drop table if exists ' || tIN;
    execute sql;
    sql := 'create temp table ' || tIN || ' as select * from ' || tableIn; 
    execute sql;
    --1.1 create index for condition fields
    IF condition is not null THEN
        n := array_length(condition, 1);
        FOR i IN 1 .. n LOOP
            field := condition[i];
            sql := 'create index ' || tIN || 'idx' || field || ' on ' || tIN || '(' || field || ');';
            execute sql; 
        END LOOP;

    END IF;

END;
$$ LANGUAGE plpgsql;