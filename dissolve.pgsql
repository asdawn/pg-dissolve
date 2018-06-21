/**
Dissolve for PostGIS
    Here we use  'GP_' as the prefix, which means geo-processing. 
**/


/**
GP_Dissolve
    Merge adjacent geometries into one geometry. The algorithm is:
    1. Create a copy of tableIn, note it as tIN, and create index; create empty tableOut.
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
    id tid;
    geom geometry;
	version CONSTANT text := '1.0.0';
BEGIN
	IF tableIn is NULL OR tableOut is NULL OR trim(tableIn) ='' OR trim(tableOut) THEN
        raise notice '%', 'Invalid input/output table name.';
        return false;
    END IF;
    IF geomIn is null OR geomOut is null THEN
        raise notice '%', 'Invalid geometry field name.';
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
    --1.2 create tOUT
    sql := 'create table ' || tableOut || ' as select * from ' || tIN || ' limit 0;';
    execute sql; 
    --2. read and write loop
    --2.0 clean null objects
    sql := 'delete from ' || tIN || ' where ' || geomIn || ' is null;';
    execute sql;
    --2.1 read a record
    sql := 'select ctid from ' || tIN || ' limit 1;'; 
    OPEN cur FOR execute sql;
    WHILE FOUND LOOP
        fetch id from cur;
        close cur;
        --2.2 query intersecting records
        sql := 'select st_union(' || geomIn || ') from ' || tIN || ' where st_intersects(' || geomIn || ', (select ' || geomIn || ' from ' || tIN || ' where ctid=' || id || '));';
        OPEN cur for execute sql;
        IF FOUND THEN
            fetch geom from cur;
            --2.6 update this record, set geom = union 
            sql := 'update ' || tIN || ' set ' || geomIN || '=''' || geom::text || '''::geometry where ctid=' || id || ';';
            execute sql;
            --2.7 insert this record into tOUT
            sql := 'insert into ' || tableOUT || ' select * from ' || tIN || ' where ctid=' || id || ';'
            --2.8 delete intersecting records from tIN
            sql := 'delete from ' || tIN ||  ' where st_intersects(' || geomIn || ', (select ' || geomIn || ' from ' || tIN || ' where ctid=' || id || '));';
        END IF;
        close cur;
    --2.9 go to next record
        sql := 'select ctid from ' || tIN || ' limit 1;'; 
        OPEN cur FOR execute sql;
    END LOOP;
    close cur;
    --5. read and write loop end
    --6. drop temp table tIN 
    sql := 'drop table ' || tIN || ';';
    execute sql;
    --fix geomOut
    IF geomIN<>geomOut THEN
        sql := 'alter table ' || tableOut || ' rename ' || geomIn || ' to ' || geomOut || ');';
        execute sql;
    END IF;
    return true;
END;
$$ LANGUAGE plpgsql;


**/
DROP FUNCTION if exists _GP_Dissolve_where();
CREATE FUNCTION _GP_Dissolve_where(tableIn text, condition text[], geomIn text default 'geom') RETURNS text AS $$
DECLARE
    whereClause text;
BEGIN
    whereClause := 
    return true;
END;
$$ LANGUAGE plpgsql;