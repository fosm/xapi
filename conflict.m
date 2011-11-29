conflict	; Conflict Class
	
log(type,id,uid,a,reason)	; Public ; Log a conflict
	;
	n seq
	;
	s seq=$g(^conflict(uid))+1
	s ^conflict(uid)=seq
	s ^conflict(uid,seq,"@type")=type
	s ^conflict(uid,seq,"@id")=id
	s ^conflict(uid,seq,"a")=a
	s ^conflict(uid,seq,"reason")=reason
	q
	
