relfix	; Fix up relation index
	;
	m status=^relationfix("status")
	i '$d(status("count")) s status("count")=0
	i '$d(status("good")) s status("good")=0
	i '$d(status("bad")) s status("bad")=0
	i '$d(status("tag")) s status("tag")=0
	i '$d(status("relationId")) s status("relationId")=""
	;
	s relationId=""
	f  d  i relationId="" q
	. s relationId=$o(^relation(relationId)) i relationId="" q
	. s status("count")=status("count")+1
	. i status("count")#1000=0 s status("relationId")=relationId m ^relationfix("status")=status
	. d bbox^relation(relationId,.a,.b,.c,.d)
	. s qsBox=$$bbox^quadString(a,b,c,d) i qsBox="" s qsBox="*"
	. i $o(^relation(relationId,""))="" s qsBox="#"
	. i qsBox=^relation(relationId) s status("good")=status("good")+1 q
	. s status("bad")=status("bad")+1
	. s oldQsBox=^relation(relationId)
	. ;
	. ; Delete old qsIndexes
	. s key=""
	. f  d  i key="" q
	. . s key=$o(^relationtag(relationId,key)) i key="" q
	. . s value=^relationtag(relationId,key)
	. . i value="" q
	. . i $l(value)>100 s value=$e(value,1,100)_".."
	. . k ^relationx(key,value,oldQsBox,relationId)
	. . s ^relationx(key,value,qsBox,relationId)=""
	. . ;
	. . k ^relationx(key,"*",oldQsBox,relationId)
	. . s ^relationx(key,"*",qsBox,relationId)=""
	. . ;
	. . s status("tag")=status("tag")+1
	. ;
	. k ^relationx("*","*",oldQsBox,relationId)
	. s ^relationx("*","*",qsBox,relationId)=""
	. ;
	. s ^relation(relationId)=qsBox
	q
	
