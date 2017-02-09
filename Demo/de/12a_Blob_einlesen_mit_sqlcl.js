var HashMap = Java.type("java.util.HashMap");
var bindmap = new HashMap();

// Wir erwarten ein Argument: Den Dateinamen
ctx.write("Lese Datei: "+ args[1] + "\n");
var filePath=args[1];

var blob=conn.createClob();
var bstream=blob.setAsciiStream(1);
/* den Blob einlesen */
java.nio.file.Files.copy( java.nio.file.FileSystems.getDefault().getPath(filePath)
                        , bstream );
bstream.flush();

bindmap.put("csv",  blob);
bindmap.put("pfad", filePath);
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
