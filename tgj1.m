tgj1	; File convert ^changeset
	;
	s c=$g(^tgj1("changeset"))
	f count=1:1 d  i c="" q
	. s c=$o(^changeset(c),-1) i c="" q
	. s n=""
	. f  d  i n="" q
	. . s n=$o(^changeset(c,"n",n)) i n="" q
	. . s v=""
	. . f  d  i v="" q
	. . . s v=$o(^changeset(c,"n",n,"v",v)) i v="" q
	. . . i $d(^changeset(c,"n",n,"v",v,"a")) q
	. . . s uid=$g(^changeset(c,"n",n,"v",v,"t","@uid"))
	. . . s timestamp=$g(^changeset(c,"n",n,"v",v,"t","@timestamp"))
	. . . s visible=$g(^changeset(c,"n",n,"v",v,"t","@visible"))
	. . . s fork=$g(^changeset(c,"n",n,"v",v,"t","@fork"))
	. . . s a=v_$c(1)_c_$c(1)_timestamp_$c(1)_uid_$c(1)_visible_$c(1)_fork
	. . . s ^changeset(c,"n",n,"v",v,"a")=a
	. . . s t=""
	. . . f  d  i t="" q
	. . . . s t=$o(^changeset(c,"n",n,"v",v,"t",t)) i t="" q
	. . . . i $e(t,1)'="@" d
	. . . . . s u=$$tag(t)
	. . . . . s ^changeset(c,"n",n,"v",v,"u",u)=^changeset(c,"n",n,"v",v,"t",t)
	. . . . k ^changeset(c,"n",n,"v",v,"t",t)
	. i count#1000=0 s ^tgj1("changeset")=c
	q
	
	
	
	
	; Get internal value for the key or assign one
tag(key)	;
	n u
	s u=$g(^keyx(key))
	i u="" d
	. l +^key
	. s (u,^key)=^key+1
	. s ^key(u)=key
	. s ^keyx(key)=u
	. l -^key
	q u
	
	
	
nodes	; File convert nodes in ^element
	s qs=$g(^tgj1("qs"))
	s count=0,done=0
	f  d  i (qs="")!done q
	. s qs=$o(^element(qs)) i qs="" q
	. s n=""
	. f  d  i n="" q
	. . s n=$o(^element(qs,"n",n)) i n="" q
	. . s count=count+1
	. . i $d(^element(qs,"n",n,"a")) q
	. . s changeset=$g(^element(qs,"n",n,"t","@changeset"))
	. . s timestamp=$g(^element(qs,"n",n,"t","@timestamp"))
	. . s uid=$g(^element(qs,"n",n,"t","@uid"))
	. . s version=$g(^element(qs,"n",n,"t","@version"))
	. . s visible=$g(^element(qs,"n",n,"t","@visible"))
	. . s fork=$g(^element(qs,"n",n,"t","@fork"))
	. . s a=version_$c(1)_changeset_$c(1)_timestamp_$c(1)_uid_$c(1)_visible_$c(1)_fork
	. . s ^element(qs,"n",n,"a")=a
	. . s t=""
	. . f  d  i t="" q
	. . . s t=$o(^element(qs,"n",n,"t",t)) i t="" q
	. . . i $e(t,1)'="@" d
	. . . . s u=$$tag(t)
	. . . . s ^element(qs,"n",n,"u",u)=^element(qs,"n",n,"t",t)
	. . k ^element(qs,"n",n,"t")
	. i count#1000=0 s ^tgj1("qs")=qs
	q
	
integ	;
	; For the highest version of each node, check that all tags in ^element are also present in ^changeset
	; Any tag in ^element that is not in ^changeset should be deleted
	;
	s count=0,fixed=0
	s c=$g(^tgj1("changeset"))
	f  d  i c="" q
	. s c=$o(^changeset(c),-1) i c="" q
	. d integ1(c)
	. s count=count+1
	. i count#100=0 s ^tgj1("changeset")=c,^tgj1("fixed")=fixed
	s ^tgj1("done")=1
	s ^tgj1("fixed")=fixed
	q
	
	
integ1(c)	;
	d
	. s n=""
	. f  d  i n="" q
	. . s n=$o(^changeset(c,"n",n)) i n="" q
	. . s v=$o(^nodeVersion(n,"v",""),-1)
	. . i '$d(^changeset(c,"n",n,"v",v)) q  ; Not the latest version in this changeset
	. . s qs=^nodeVersion(n,"q")
	. . i '$d(^element(qs,"n",n)) q  ; Element missing, probably a deletion
	. . s u=""
	. . f  d  i u="" q
	. . . s u=$o(^element(qs,"n",n,"u",u)) i u="" q
	. . . i $d(^changeset(c,"n",n,"v",v,"u",u)) q  ; tag exists on latest version of element, so ok
	. . . ; w !,"Changeset: ",c,?20," Node: ",n,?40,^key(u),?60,^element(qs,"n",n,"u",u)
	. . . s fixed=fixed+1
	. . . s value=^element(qs,"n",n,"u",u)
	. . . i $l(value)>100 s value=$e(value,1,100)_".."
	. . . s k=^key(u)
	. . . k ^element(qs,"n",n,"u",u)
	. . . i value'="" k ^nodex(k,value,qs,n)
	. . . k ^nodex(k,"*",qs,n)
	q
	
	
	
nol	; Look for elements that have an a node but no l node
	s qs=$g(^tgj1("qs"))
	s count=0
	f  d  i qs="" q
	. s qs=$o(^element(qs)) i qs="" q
	. s n=""
	. f  d  i n="" q
	. . s n=$o(^element(qs,"n",n)) i n="" q
	. . s count=count+1
	. . i '$d(^element(qs,"n",n,"l")) s ^tgj1("nol",qs,n)=""
	. . i '$d(^element(qs,"n",n,"a")) s ^tgj1("noa",qs,n)=""
	. i count#1000=0 s ^tgj1("qs")=qs
	q
	
	
nolfix	;
	s qs=""
	f  d  i qs="" q
	. s qs=$o(^tgj1("nol",qs)) i qs="" q
	. s n=""
	. f  d  i n="" q
	. . s n=$o(^tgj1("nol",qs,n)) i n="" q
	. . i $d(^element(qs,"n",n,"a")),'$d(^element(qs,"n",n,"l")) k ^element(qs,"n",n,"a") w "."
	q
	
	
	
findDeletedNodes	;
	s w=$g(^tgj1("way"))
	s count=0
	f  d  i w="" q
	. s w=$o(^way(w)) i w="" q
	. s count=count+1 i count#1000=0 s ^tgj1("way")=w
	. s s=""
	. f  d  i s="" q
	. . s s=$o(^way(w,s)) i s="" q
	. . s n=^way(w,s)
	. . s v=$o(^nodeVersion(n,"v",""),-1) i v="" s ^tgjBad(w,n)="no versions" q
	. . s c=^nodeVersion(n,"v",v)
	. . i '$d(^changeset(c,"n",n)) s ^tgjBad(w,n)="Missing changeset "_c q
	. . i $p(^changeset(c,"n",n,"v",v,"a"),$c(1),5)="false" s ^tgjBad(w,n)="Deleted node in "_c q
	q
	
fixDeletedNodes	;
	s w=""
	f  d  i w="" q
	. s w=$o(^tgjBad(w)) i w="" q
	. s n=""
	. f  d  i n="" q
	. . s n=$o(^tgjBad(w,n)) i n="" q
	. . ;
	. . ; Remove deleted version
	. . s v=$o(^nodeVersion(n,"v",""),-1) i v="" q 
	. . s v1=$o(^nodeVersion(n,"v",v),-1) i v1="" q
	. . s c=^nodeVersion(n,"v",v)
	. . k ^nodeVersion(n,"c",c,v)
	. . k ^nodeVersion(n,"v",v)
	. . s c1=^nodeVersion(n,"v",v1)
	. . ;
	. . ; Reinstate prior version (v1)
	. . d addNodeFromChangeset^node(c1,n,v1)
	. . ;
	. . ; Remove from bad list
	. . k ^tgjBad(w,n)
	q
	
fixDeletedNodes1	; Fix deleted nodes with no predecessor
	s w=""
	f  d  i w="" q
	. s w=$o(^tgjBad(w)) i w="" q
	. s n=""
	. f  d  i n="" q
	. . s n=$o(^tgjBad(w,n)) i n="" q
	. . ;
	. . ; Remove deleted version
	. . s v=$o(^nodeVersion(n,"v",""),-1) i v="" q 
	. . s v1=$o(^nodeVersion(n,"v",v),-1) i v1'="" q
	. . s c=^nodeVersion(n,"v",v)
	. . s q=^nodeVersion(n,"q")
	. . ;
	. . ; Some nodes may already have been saved from deletion
	. . i $d(^element(q,"n",n)) s ^tgjBad(w,n,"status")="not deleted" q
	. . ;
	. . ; Reinstate deleted version
	. . d addNodeFromChangeset(c,n,v)
	. . ;
	. . ; Remove from bad list
	. . k ^tgjBad(w,n)
	q
	
addNodeFromChangeset(changeset,nodeId,version)	; Public ; Add a node from a changeset
	;
	n qsOld,a,timestamp,delete,qsNew,l
	n u,key,value,intValue
	;
	s qsOld=$g(^nodeVersion(nodeId,"q"))
	;
	s a=^changeset(changeset,"n",nodeId,"v",version,"a")
	s $p(a,$c(1),5)="" ; Unset the delete flag
	s timestamp=$p(a,$c(1),3)
	s delete=($p(a,$c(1),5)="false")
	s qsNew=$p(a,$c(1),7)
	s l=^changeset(changeset,"n",nodeId,"v",version,"l")
	;
	; Old changesets don't have the qs stored on them
	i qsNew="" s qsNew=$$llToQs^quadString($p(l,$c(1),1),$p(l,$c(1),2))
	;
	; Update - node
	i 'delete d
	. ;
	. ; If the qs key has changed then delete the old entries
	. i qsOld'="",qsOld'=qsNew d
	. . k ^element(qsOld,"n",nodeId,"l")
	. . k ^element(qsOld,"n",nodeId,"a")
	. ;
	. ; Update the node with new values
	. s ^element(qsNew,"n",nodeId,"l")=l
	. s ^element(qsNew,"n",nodeId,"a")=$p(a,$c(1),1,6)
	;
	; Update - changeset by version index
	s ^nodeVersion(nodeId,"q")=qsNew
	s ^nodeVersion(nodeId,"v",version)=changeset
	s ^nodeVersion(nodeId,"c",changeset,version)=""
	;
	; Update process <tag> elements
	s u=""
	f  d  i u="" q
	. s u=$o(^changeset(changeset,"n",nodeId,"v",version,"u",u)) i u="" q
	. s value=^changeset(changeset,"n",nodeId,"v",version,"u",u)
	. d addTagFromChangeset^node(qsOld,qsNew,nodeId,u,value,changeset,version,delete)
	;
	; Delete all tags that are not on the new version of the node
	s u=""
	i qsOld'="" f  d  i u="" q
	. s u=$o(^element(qsOld,"n",nodeId,"u",u)) i u="" q
	. s key=^key(u)
	. i 'delete,$d(^changeset(changeset,"n",nodeId,"v",version,"u",u)) q
	. s value=^element(qsOld,"n",nodeId,"u",u)
	. s intValue=value
	. i $l(intValue)>100 s intValue=$e(value,1,100)_".."
	. i intValue'="" k ^nodex(key,intValue,qsOld,nodeId)
	. k ^nodex(key,"*",qsOld,nodeId)
	. k ^element(qsOld,"n",nodeId,"u",u)
	;
	i delete,qsOld'="" k ^element(qsOld,"n",nodeId)
	;
	; Create export index
	s ^export(timestamp,"n",changeset,nodeId,version)=""
	;
	q

