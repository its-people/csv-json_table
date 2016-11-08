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
select * from jsn3;
