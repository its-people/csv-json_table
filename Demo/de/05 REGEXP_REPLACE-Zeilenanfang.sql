with
  csv as (
           select to_clob( '"eins", "zwei", "drei"'||chr(10)
                        || '"vier", "fünf", "sechs"'||chr(10)
                        || '"sieben", "acht", "neun"'||chr(10)
                         ) blb
             from dual
          )
select * from csv;

with
  csv as (
           select to_clob( '"eins", "zwei", "drei"'||chr(10)
                        || '"vier", "fünf", "sechs"'||chr(10)
                        || '"sieben", "acht", "neun"'||chr(10)
                         ) blb
             from dual
          )
, jsn1 as ( -- Zeilenanfang
            select regexp_replace( blb
                                 , '^'
                                 ,'['
                                 ,1,0,'m'
                                 ) blb
              from csv
          )
select * from jsn1;
