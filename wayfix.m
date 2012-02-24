wayfix	; Fix up way index
	;
	m status=^wayfix("status")
	i '$d(status("count")) s status("count")=0
	i '$d(status("good")) s status("good")=0
	i '$d(status("bad")) s status("bad")=0
	i '$d(status("tag")) s status("tag")=0
	i '$d(status("wayId")) s status("wayId")=""
	;
	s wayId=status("wayId")
	f  d  i wayId="" q
	. ;s wayId=$o(^way(wayId)) i wayId="" q
	. s wayId=$o(^wayx("*","*","*",wayId)) i wayId="" q
	. s status("count")=status("count")+1
	. i status("count")#1000=0 s status("wayId")=wayId m ^wayfix("status")=status
	. d bbox^way(wayId,.a,.b,.c,.d,1)
	. s qsBox=$$bbox^quadString(a,b,c,d) i qsBox="" s qsBox="*"
	. ;i qsBox=^way(wayId) s status("good")=status("good")+1 q
	. s status("bad")=status("bad")+1
	. s oldQsBox=$p(^way(wayId),$c(1),1)
	. ;
	. ; Delete old qsIndexes
	. s key=""
	. f  d  i key="" q
	. . s key=$o(^waytag(wayId,key)) i key="" q
	. . s value=^waytag(wayId,key)
	. . i value="" q
	. . i $l(value)>100 s value=$e(value,1,100)_".."
	. . k ^wayx(key,value,oldQsBox,wayId)
	. . s ^wayx(key,value,qsBox,wayId)=""
	. . ;
	. . k ^wayx(key,"*",oldQsBox,wayId)
	. . s ^wayx(key,"*",qsBox,wayId)=""
	. . ;
	. . s status("tag")=status("tag")+1
	. ;
	. k ^wayx("*","*",oldQsBox,wayId)
	. s ^wayx("*","*",qsBox,wayId)=""
	. ;
	. s ^way(wayId)=qsBox_$c(1)_a_$c(1)_b_$c(1)_c_$c(1)_d
	q
	
