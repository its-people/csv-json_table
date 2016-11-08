select wert
  from json_table( '["Eins", "Zwei", "Drei",
                     "Vier", "Fünf", "Sechs"]'
                 , '$[*]'
                 columns wert varchar2 path '$'
                 )
;
