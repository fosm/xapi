purgeJournal	; Purge Journal files
	; Purge all files except the last one for each database
	
	n f,file,list,database,lastDatabase,lastFile
	;
	s f="/tmp/purgeJournal_"_$j_".tmp"
	zsystem "ls -b1 ../journal/*.mjl_* > "_f
	;
	o f
	f  d  i $zeof q
	. u f r file i $zeof q
	. i file'="" s list(file)=""
	;
	c f:DELETE
	;
	s lastDatabase=""
	s lastFile=""
	s file=""
	f  d  i file="" q
	. s file=$o(list(file))
	. s database=$p(file,".mjl",1)
	. i database=lastDatabase zsystem "rm "_lastFile
	. ;
	. i file="" q
	. s lastDatabase=database
	. s lastFile=file
	q
