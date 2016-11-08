drop table csv_perf_source purge;
drop table csv_perf_steps purge;
drop table csv_perf_results purge;

create table csv_perf_source
  ( linecnt     number
  , size_bytes  number
  , csv         clob
  );

create table csv_perf_steps
 ( step   number
 , stmt   clob
 );

create table csv_perf_results
( runno   number
, linecnt     number
, step    number
, runtime number
, result  clob
);

/* Create Source Testcases */

declare
  v     varchar2(32000) := '"Eins","Zwei","Drei", "Vier", "Fünf", "Sechs", "Sieben", "Acht", "Neun", "Zehn"'||chr(10);
  v2    varchar2(32000);
  ctemp clob;
  testcases dbms_sql.number_table ;
begin
  testcases(1) := 10;
  testcases(2) := 100;
  testcases(3) := 500;
  testcases(4) := 1000;
  testcases(5) := 10000;
  dbms_lob.createtemporary(ctemp,true);
  for i in testcases.first .. testcases.last loop
    for j in 1 .. testcases(i) loop
      v2 := '"'||to_char(j, '0000000009')||'", '||v;
      dbms_lob.writeappend(ctemp,length(v2),v2);
    end loop;
    insert into csv_perf_source(linecnt,size_bytes, csv) values (testcases(i),dbms_lob.getlength(ctemp), ctemp);
    commit;
  end loop;
end;
/

delete CSV_PERF_STEPS;

/* Insert Steps */
insert into CSV_PERF_STEPS(STEP,stmt)
values (1,q'<
insert into csv_perf_results ( runno, result)
with
  csv as (select csv blb
             from csv_perf_source
             where linecnt = :linecnt
          )
, jsn1 as ( -- Zeilenanfang
            select regexp_replace( blb
                                 , '^'
                                 ,'['
                                 ,1,0,'m'
                                 ) blb
              from csv
          )
select :runno, blb
  from jsn1
>')
;

insert into CSV_PERF_STEPS(STEP,stmt)
values (2,q'<
insert into csv_perf_results ( runno, result)
with
  csv as (select csv blb
             from csv_perf_source
             where linecnt = :linecnt
          )
, jsn1 as ( -- Zeilenanfang
            select regexp_replace( blb
                                 , '^'
                                 ,'['
                                 ,1,0,'m'
                                 ) blb
              from csv
          )
, jsn2 as ( -- Zeilenende
            select regexp_replace( blb
                                 , '$'
                                 ,']'
                                 ,1,0,'m'
                                 ) blb
              from jsn1
           )
select :runno, blb
  from jsn2
>')
;

insert into CSV_PERF_STEPS(STEP,stmt)
values (3,q'<
insert into csv_perf_results ( runno, result)
with
  csv as (select csv blb
             from csv_perf_source
             where linecnt = :linecnt
          )
, jsn1 as ( -- Zeilenanfang
            select regexp_replace( blb
                                 , '^'
                                 ,'['
                                 ,1,0,'m'
                                 ) blb
              from csv
          )
, jsn2 as ( -- Zeilenende
            select regexp_replace( blb
                                 , '$'
                                 ,']'
                                 ,1,0,'m'
                                 ) blb
              from jsn1
           )
, jsn3 as ( -- Kommas zwischen Zeilen
            select regexp_replace('['||blb||']'
                                 , '\]'||chr(10)||'\['
                                 , '],['
                                 ,1,0,''
                                 ) blb
              from jsn2
          )
select :runno, blb
  from jsn3
>')
;

insert into CSV_PERF_STEPS(STEP,stmt)
values (4,q'<
insert into csv_perf_results ( runno, result)
with
  csv as (select csv blb
             from csv_perf_source
             where linecnt = :linecnt
          )
, jsn1 as ( -- Zeilenanfang
            select regexp_replace( blb
                                 , '^'
                                 ,'['
                                 ,1,0,'m'
                                 ) blb
              from csv
          )
, jsn2 as ( -- Zeilenende
            select regexp_replace( blb
                                 , '$'
                                 ,']'
                                 ,1,0,'m'
                                 ) blb
              from jsn1
           )
, jsn3 as ( -- Kommas zwischen Zeilen
            select regexp_replace('['||blb||']'
                                 , '\]'||chr(10)||'\['
                                 , '],['
                                 ,1,0,''
                                 ) blb
              from jsn2
          )
select :runno, max(zeile||' - '||spalte00)
  from jsn3
     , json_table( blb
                 , '$[*]'
                 columns ( zeile for ordinality
                         , spalte00 varchar2 PATH '$[0]'
                         , spalte01 varchar2 PATH '$[1]'
                         , spalte02 varchar2 PATH '$[2]'
                         , spalte03 varchar2 PATH '$[3]'
                         , spalte04 varchar2 PATH '$[4]'
                         , spalte05 varchar2 PATH '$[5]'
                         , spalte06 varchar2 PATH '$[6]'
                         , spalte07 varchar2 PATH '$[7]'
                         , spalte08 varchar2 PATH '$[8]'
                         , spalte09 varchar2 PATH '$[9]'
                         , spalte10 varchar2 PATH '$[10]'
                         )
                 )
>')
;


commit;

/* run the tests */
set serveroutput on size unl

declare
  l_runno  number := 0;
  time1 timestamp;
  time2 timestamp;
  durat  number;
begin
  for tc in (select linecnt, size_bytes, csv from csv_perf_source)
  loop
    for tstep in (select step, stmt from csv_perf_steps)
    loop
      l_runno := l_runno +1;
      time1 := systimestamp;
      begin
        EXECUTE IMMEDIATE tstep.stmt using tc.linecnt, l_runno;
      exception
        when others
          then dbms_output.put_line(sqlerrm||' - '||tstep.stmt);
      end;
      time2 := systimestamp;
      durat := ((extract(DAY FROM    time2-time1)*24*60*60)+
                (extract(HOUR FROM   time2-time1)*60*60)+
                (extract(MINUTE FROM time2-time1)*60)+
                 extract(SECOND FROM time2-time1));
      update csv_perf_results r
         set runtime = durat
           , linecnt = tc.linecnt
           , step    = tstep.step
       where r.runno = l_runno;
       commit;
    end loop;
  end loop;
end;
/


commit;

select linecnt, step, runtime from CSV_PERF_RESULTS
order by step, linecnt;


