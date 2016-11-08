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
select zeile, spalte1, spalte2, spalte3
  from jsn3
     , json_table( blb
                 , '$[*]'
                 columns ( spalte1 varchar2 PATH '$[0]'
                         , spalte2 varchar2 PATH '$[1]'
                         , spalte3 varchar2 PATH '$[2]'
                         , zeile for ordinality
                         )
                 );
