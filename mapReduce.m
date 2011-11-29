mapReduce	; Map reduce
	
	
map(class)	; Public ; Map something
	d @("mapInit^"_class)
	d @("mapMain^"_class)
	d @("mapFinal^"_class)
	q
	
	; Usage:
	;  d map^mapReduce(class,[taskId])
	;
	n root,length,key,global
	;
	s taskId=$g(taskId)
	;
	d @("mapInit^"_class_"(taskId)")
	;
	; Iterate through all mapped instances of this class (globals prefixed with % and the class name are considered to be instances)
	s root="^%"_class,length=$l(root)
	s global=root
	f  d  i global="" q
	. s global=$o(@global) i global="" q
	. i $e(global,1,length)'=root s global="" q
	. s key=$e(global,length+1,$l(global))
	. d @("mapMain^"_class_"(key,global,taskId)")
	;
	d @("mapFinal^"_class_"(taskId)")
	q
	
	
reduce(class)	; Public ; Reduce something
	;
	n root,length,key,global
	;
	d @("reduceInit^"_class)
	;
	; Iterate through all mapped instances of this class (globals prefixed with % and the class name are considered to be instances)
	s root="^%"_class,length=$l(root)
	s global=root
	f  d  i global="" q
	. s global=$o(@global) i global="" q
	. i $e(global,1,length)'=root s global="" q
	. s key=$e(global,length+1,$l(global))
	. d @("reduceMain^"_class_"(key,global)")
	;
	d @("reduceFinal^"_class)
	;
	q
	
	
	
restMap(string)	; Public ; Map request for a class
	;
	n step,nodeId,full,logId,indent
	;
	; Get next step (class)
	s step=$p(string,SLASH,1),string=$p(string,SLASH,2,$l(string))
	s class=step
	;
	; Get next step (token)
	s step=$p(string,SLASH,1),string=$p(string,SLASH,2,$l(string))
	s taskId=step
	;
	; One choices here:
	; /map/<class>/<taskId> - Send a map task to a class
	;
	d map(class,taskId)
	;
	; Send 200 response
	d header^http("text/xml")
	;
	q
