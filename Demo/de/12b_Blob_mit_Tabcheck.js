var HashMap = Java.type("java.util.HashMap");
var bindmap = new HashMap();

ctx.write("Los geht's.\n");

/* Test ob die Zieltabelle vorhanden ist */
var tabCnt = util.executeReturnOneCol('select count(*) ' +
                                      '  from tabs '     +
                                      " where table_name = 'CSV_TAB'"
                                      );

if (tabCnt == 0){
    ctx.write("Tabelle CSV_TAB nicht vorhanden, lege sie an.\n");
    if ( !util.execute('create table CSV_TAB(csv clob, pfad varchar2(255))')
       ) {
        ctx.write("Tabelle anlegen fehlgeschlagen exit.\n");
        exit;
        }
}

ctx.write("Tabelle OK.\n");

/* Das erste Agrgument ist der Dateiname des Clobs */
ctx.write("arg(1): "+ args[1] + "\n");
var filePath=args[1];
/*
Für  Blob:
*/
//var blob=conn.createBlob();
//var bstream=blob.setBinaryStream(1);

var blob=conn.createClob();
var bstream=blob.setAsciiStream(1);
/* den Blob einlesen */
java.nio.file.Files.copy( java.nio.file.FileSystems.getDefault().getPath(filePath)
                        , bstream );
bstream.flush();
bindmap.put("csv",  blob);
bindmap.put("pfad", filePath);

ctx.write("Blob eingelesen.\n");

if(!util.execute( "insert into csv_tab(csv,pfad) values(:csv, :pfad)"
                , bindmap)
  ){ ctx.write("insert fehlgeschlagen exit.\n");
     exit;
}
sqlcl.setStmt( "commit; \n"
             + "set sqlformat ansiconsole \n"
             + " select pfad,dbms_lob.getlength(csv) "
             + "from csv_tab;");
sqlcl.run();
