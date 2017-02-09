var HashMap = Java.type("java.util.HashMap");
var bindmap = new HashMap();

// We are expecting the filename as single argument
ctx.write("Lese Datei: "+ args[1] + "\n");
var filePath=args[1];

// This is for Clobs
var blob=conn.createClob();            // Blobs: var blob=conn.createBlob();
var bstream=blob.setAsciiStream(1);    //        var bstream=blob.setBitStream(1);
/* reading the blob utilizing java classes */
java.nio.file.Files.copy( java.nio.file.FileSystems.getDefault().getPath(filePath),
                          bstream );
bstream.flush();

bindmap.put("csv",  blob);
bindmap.put("pfad", filePath);
if(!util.execute( "insert into csv_tab(csv,pfad) values(:csv, :pfad)",
                 bindmap)
  ){ ctx.write("insert failed. exit.\n");
     exit(1);
}
sqlcl.setStmt( "commit; \n"                              +
               "set sqlformat ansiconsole \n"            +
               "select pfad,dbms_lob.getlength(csv) \n"  +
               "  from csv_tab;");
sqlcl.run();
