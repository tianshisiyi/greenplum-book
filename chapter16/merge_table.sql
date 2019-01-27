CREATE OR REPLACE FUNCTION merge_table(targettable character varying, srctable character varying) RETURNS bigint AS
$BOY$
DECLARE
   v_targettable varchar := $1;
   v_srctable varchar :=$2;
   v_left_join_sql varchar;
   v_left_join_condition varchar;
   v_insert_sql varchar;
   v_merge_sql varchar;
   v_insert_cnt bigint;
BEGIN
     set enable_hashjoin=off;
     set enable_nestloop=on;
     v_insert_sql :='insert into '||v_targettable||' select * from '||v_srctable;
     EXECUTE v_insert_sql;
     GET DIAGNOSTICS v_insert_cnt = ROW_COUNT;
     RETURN v_insert_cnt;
     EXCEPTION WHEN unique_violation THEN
     v_left_join_sql :=$$SELECT 'on (src.'||string_agg(a.attname::text,',src.')||')'||'='||'(target.'||string_agg(a.attname::text,',target.')||') where '||'(target.'||string_agg(a.attname::text,',target.')||') is null ' FROM   pg_index i JOIN   pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = ANY( i.indkey) WHERE  i.indrelid = '$$||v_targettable||$$'::regclass AND  i.indisprimary;$$;
      EXECUTE v_left_join_sql into v_left_join_condition;
      v_merge_sql :='insert into '||v_targettable||' select  distinct src.* from '||v_srctable||' as src left join '||v_targettable||' as target '||v_left_join_condition;
     EXECUTE v_merge_sql;
     GET DIAGNOSTICS v_insert_cnt = ROW_COUNT;
     RETURN v_insert_cnt;
END;
$BOY$
LANGUAGE plpgsql volatile;
