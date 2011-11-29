changeset	; Changeset Class
	; Copyright (C) 2009,2011  Etienne Cherdlu <80n80n@gmail.com>

	
add(sChangeset,delete)	; Public ; Add a changeset
	; #sChangeset = stream object containing changeset
	;
	n line,changesetId
	;
	s line=sChangeset("current")
	;
	s changesetId=$$getAttribute^osmXml(line,"id")
	d delete(changesetId)
	;
	s ^c(changesetId)=line
	;
	q
	
	
delete(changesetId)	; Public ; Delete a changeset
	;
	k ^c(changesetId)
	q
	
	
xml(indent,changesetId,full)	  ; Public ; Generate xml for changeset
	;
	n user,uid,timestamp,version,changeset
	n q,bllat,bllon,trlat,trlon
	n xml
	;
	s xml=""
	;
	s indent=indent_"  "
	;
	s uid=$g(^c(changesetId,"t","@uid"))
	s user="" i $g(uid)'="" s user=$g(^user(uid,"name"))
	s timestamp=$g(^c(changesetId,"t","@timestamp"))
	;
	; Create the q node if it is not present
	i '$d(^c(changesetId,"q")) d
	. d bbox(changesetId,.bllat,.bllon,.trlat,.trlon)
	. s qsBox=$$bbox^quadString(bllat,bllon,trlat,trlon)
	. s ^c(changesetId,"q")=qsBox_$c(1)_bllat_$c(1)_bllon_$c(1)_trlat_$c(1)_trlon
	;
	s q=$g(^c(changesetId,"q"))
	s bllat=$p(q,$c(1),2) i bllat=999999 s bllat=""
	s bllon=$p(q,$c(1),3) i bllon=999999 s bllon=""
	s trlat=$p(q,$c(1),4) i trlat=-999999 s trlat=""
	s trlon=$p(q,$c(1),5) i trlon=-999999 s trlon=""
	;
	s xml=indent_"<changeset"
	s xml=xml_$$attribute^osmXml("id",changesetId)
	i user'="" s xml=xml_$$attribute^osmXml("user",user)
	i uid'="" s xml=xml_$$attribute^osmXml("uid",uid)
	i timestamp'="" s xml=xml_$$attribute^osmXml("created_at",timestamp)
	i timestamp'="" s xml=xml_$$attribute^osmXml("closed_at",timestamp)
	i bllon'="" s xml=xml_$$attribute^osmXml("min_lon",bllon)
	i bllat'="" s xml=xml_$$attribute^osmXml("min_lat",bllat)
	i trlon'="" s xml=xml_$$attribute^osmXml("max_lon",trlon)
	i trlat'="" s xml=xml_$$attribute^osmXml("max_lat",trlat)
	s xml=xml_$$attribute^osmXml("open","false")
	;
	s xml=xml_">"_$c(13,10)
	;
	s key=""
	f  d  i key="" q
	. s key=$o(^c(changesetId,"t",key)) i key="" q
	. i $e(key,1)="@" q
	. s value=^c(changesetId,"t",key)
	. s xml=xml_indent_"<tag"
	. s xml=xml_$$attribute^osmXml("k",key)
	. s xml=xml_$$attribute^osmXml("v",value)
	. s xml=xml_"/>"_$c(13,10)
	;
	s xml=xml_indent_"</changeset>"_$c(13,10)
	;
	q xml
	
	
query	; Public ; Generate a list of the last 100 changesets
	;
	n changesetId,i,uid,user,timestamp
	n q,bllat,bllon,trlat,trlon
	;
	d header^http("text/xml")
	d xmlProlog^rest("")
	d osm^xapi("")
	;
	s changesetId=""
	f i=1:1:100 d  i changesetId="" q
	. s changesetId=$o(^c(changesetId),-1) i changesetId="" q
	. s uid=$g(^c(changesetId,"t","@uid")) i uid="" q
	. s user=$g(^user(uid,"name"))
	. s timestamp=$g(^c(changesetId,"t","@timestamp"))
	. ;
	. ; Create the q node if it is not present
	. i '$d(^c(changesetId,"q")) d
	. . d bbox(changesetId,.bllat,.bllon,.trlat,.trlon)
	. . s qsBox=$$bbox^quadString(bllat,bllon,trlat,trlon)
	. . s ^c(changesetId,"q")=qsBox_$c(1)_bllat_$c(1)_bllon_$c(1)_trlat_$c(1)_trlon
	. ;
	. s q=$g(^c(changesetId,"q"))
	. s bllat=$p(q,$c(1),2) i bllat=999999 s bllat=""
	. s bllon=$p(q,$c(1),3) i bllon=999999 s bllon=""
	. s trlat=$p(q,$c(1),4) i trlat=-999999 s trlat=""
	. s trlon=$p(q,$c(1),5) i trlon=-999999 s trlon=""
	. ;
	. w "<changeset"
	. w $$attribute^osmXml("id",changesetId,"")
	. w $$attribute^osmXml("user",user,"")
	. w $$attribute^osmXml("uid",uid,"")
	. w $$attribute^osmXml("created_at",timestamp,"")
	. w $$attribute^osmXml("closed_at",timestamp,"")
	. w $$attribute^osmXml("open","false","")
	. i bllon'="" w $$attribute^osmXml("min_lon",bllon,"")
	. i bllat'="" w $$attribute^osmXml("min_lat",bllat,"")
	. i trlon'="" w $$attribute^osmXml("max_lon",trlon,"")
	. i trlat'="" w $$attribute^osmXml("max_lat",trlat,"")
	. w ">",$c(13,10)
	. ;
	. s k=""
	. f  d  i k="" q
	. . s k=$o(^c(changesetId,"t",k)) i k="" q
	. . i $e(k,1)="@" q
	. . s v=^c(changesetId,"t",k)
	. . w "  ","<tag"
	. . w $$attribute^osmXml("k",k,"  ")
	. . w $$attribute^osmXml("v",v,"  ")
	. . w "/>",$c(13,10)
	. w "</changeset>",$c(13,10)
	w "</osm>",$c(13,10)
	q
	
	
upload(changesetId)	; Public ; Upload a single changeset via the API
	; The payload should be an <osmChange> file
	;
	k ^response($j)
	k ^temp($j)
	;
	n sFile,line,indent,rSeq,logId
	n element,oldId,newId,version,ok
	;
	; Get the authenticated user (will return a 401) if no authentication provided
	i '$$authenticated^user(.uid,.user) q
	;
	; The upload is via the API so the XML content is part of the http payload.
	d openPayload^stream(.sFile)
	;
	s line=$$read^stream(.sFile)
	; i line'["<osmChange" d error^http q
	;
	s logId=$$logStart^xapi($g(%ENV("REQUEST_URI"))_" by "_user,"")
	;
	; TODO: Start a transaction here
	s ok=1
	f  d  i line["</osmChange"!('ok) q
	. s line=$$read^stream(.sFile)
	. i line["<delete" s ok=$$uploadDelete(changesetId) q
	. i line["<modify" s ok=$$uploadModify(changesetId) q
	. i line["<create" s ok=$$uploadModify(changesetId) q
	;
	d close^stream(.sFile)
	;
	i 'ok q
	;
	; Everything went ok, generate response
	d header^http("text/xml")
	d xmlProlog^rest("")
	;
	s indent=""
	w indent,"<diffResult"
	w $$attribute^osmXml("version","0.6",indent)
	w $$attribute^osmXml("generator","FOSM API 0.6",indent)
	w indent,">",$c(13,10)
	;
	s rSeq=""
	f i=1:1 d  i rSeq="" q
	. s rSeq=$o(^response($j,rSeq)) i rSeq="" q
	. s element=^response($j,rSeq,"element")
	. s oldId=^response($j,rSeq,"oldId")
	. s newId=^response($j,rSeq,"newId")
	. s version=^response($j,rSeq,"version")
	. w indent,"<"_element
	. i oldId'="" w $$attribute^osmXml("old_id",oldId,indent)
	. i newId'="" w $$attribute^osmXml("new_id",newId,indent)
	. i version'="" w $$attribute^osmXml("new_version",version,indent)
	. w "/>",$c(13,10)
	w "</diffResult>",$c(13,10)
	;
	d logEnd^xapi(logId,i,"")
	;
	q
	
	
uploadModify(changesetId)	 ; Create or modify stuff, read all lines until end of modify or create element
	; TODO: Need to pass uid to these methods for authentication
	;
	n ok
	s ok=1
	;
	f  d  i (line["</modify>")!(line["</create>")!('ok) q
	. s line=$$read^stream(.sFile)
	. i line["<node" s ok=$$addDiff^node(.sFile,0,changesetId) q
	. i line["<way" s ok=$$addDiff^way(.sFile,0,changesetId) q
	. i line["<relation" s ok=$$addDiff^relation(.sFile,0,changesetId) q
	;
	q ok
	
	
uploadDelete(changesetId)	 ; Delete some stuff, read all lines until end of delete element
	;
	n ok
	s ok=1
	;
	f  d  i line["</delete>"!('ok) q
	. s line=$$read^stream(.sFile)
	. i line["<node" s ok=$$addDiff^node(.sFile,1,changesetId) q
	. i line["<way" s ok=$$addDiff^way(.sFile,1,changesetId) q
	. i line["<relation" s ok=$$addDiff^relation(.sFile,1,changesetId) q
	;
	q ok
	
	
close(changesetId)	; Public ; Close a changeset
	; Do nothing, nada.
	;
	n logId
	;
	s logId=$$logStart^xapi("/changeset/close/"_changesetId,"")
	d header^http("text/xml")
	d logEnd^xapi(logId,0,"")
	q
	
	
create	; Public ; Create a new changeset via the API
	; Assign a changeset ID, store timestamp, user id and any tags.  Return changeset ID in http 200 response
	;
	n logId,changesetId,user,uid,sFile,line,key,value
	;
	; Get the authenticated user (will return a 401) if no authentication provided
	i '$$authenticated^user(.uid,.user) q
	;
	; Allocate a changeset ID
	l +^id("changeset")
	s changesetId=$g(^id("changeset"))+1
	s ^id("changeset")=changesetId
	l -^id("changeset")
	;
	s logId=$$logStart^xapi("/changeset/create/"_changesetId_" by "_user,"")
	;
	s ^c(changesetId,"t","@timestamp")=$$nowZulu^date
	;
	s ^c(changesetId,"t","@uid")=uid
	;
	d openPayload^stream(.sFile)
	s line=$$read^stream(.sFile) ; Read <osm> tag
	s line=$$read^stream(.sFile) ; Read <changeset> tag
	;
	f i=1:1 d  i line="</osm>" q
	. s line=$$read^stream(.sFile) i line="</osm>" q
	. i sFile("i")="" s line="</osm>" q
	. i line?.e1"<tag".e d
	. . s key=$$getAttribute^osmXml(line,"k")
	. . s value=$$getAttribute^osmXml(line,"v")
	. . i $l(key)>100 s key=$e(key,1,100)_".."
	. . i $l(value)>4000 s value=$e(v,1,4000)_".."
	. . i key'="" s ^c(changesetId,"t",key)=value
	;
	d header^http("text/plain")
	w changesetId
	;
	d logEnd^xapi(logId,i,"")
	q
	
	
update(changesetId)	; Public ; Update a single changeset via the API (just the tags get updated using this method)
	; The payload is an <osm> file
	;
	n uid,user,sFile,key,i,line,value,indent
	;
	; Get the authenticated user (will return a 401) if no authentication provided
	i '$$authenticated^user(.uid,.user) q
	;
	s logId=$$logStart^xapi($g(%ENV("REQUEST_URI"))_" by "_user,"")
	;
	i '$d(^c(changesetId)) d notFound^http,logEnd^xapi(logId,0,"404 Not found") q
	;
	; Check that it's the same user
	i $g(^c(changesetId,"t","@uid"))'=uid d error409^http("UserId mismatch: Provided "_uid_", server expected: "_$g(^c(changesetId,"t","@uid"))_" for changeset "_changesetId) q
	;
	d openPayload^stream(.sFile)
	s line=$$read^stream(.sFile) ; Read <osm> tag
	s line=$$read^stream(.sFile) ; Read <changeset> tag
	;
	; Delete all old tags on the changeset
	s key=""
	f  d  i key="" q
	. s key=$o(^c(changesetId,"t",key)) i key="" q
	. i $e(key,1)="@" q
	. k ^c(changesetId,"t",key)
	;
	; Add new tags
	f i=1:1 d  i line="</osm>" q
	. s line=$$read^stream(.sFile) i line="</osm>" q
	. i sFile("i")="" s line="</osm>" q
	. i line?.e1"<tag".e d
	. . s key=$$getAttribute^osmXml(line,"k")
	. . s value=$$getAttribute^osmXml(line,"v")
	. . i $l(key)>100 s key=$e(key,1,100)_".."
	. . i $l(value)>4000 s value=$e(v,1,4000)_".."
	. . i key'="" s ^c(changesetId,"t",key)=value
	;
	d close^stream(.sFile)
	;
	d header^http("text/xml")
	d xmlProlog^rest("")
	;
	s indent=""
	d osm^xapi(indent)
	;
	w $$xml(indent,changesetId,0)
	;
	w indent,"</osm>",$c(13,10)
	;
	d logEnd^xapi(logId,i,"")
	;
	q
	
	
restChangeset(changesetId)	; Public ; Single changeset query
	;
	n logId
	;
	;
	s logId=$$logStart^xapi($$decode^xapi("changeset/"_changesetId),"")
	;
	; Bad query?
	i changesetId'?1.n d notFound^http,logEnd^xapi(logId,0,"404 Not found") q
	;
	; Is it there?
	i '$d(^c(changesetId)) d gone^http,logEnd^xapi(logId,0,"410 Gone") q
	;
	d header^http("text/xml")
	d xmlProlog^rest("")
	;
	s indent=""
	d osm^xapi(indent)
	;
	w $$xml(indent,changesetId,0)
	;
	w indent,"</osm>",$c(13,10)
	;
	d logEnd^xapi(logId,1,"")
	;
	q
	
	
download(changesetId)	; Public ; Single changeset query with full content
	;
	n logId
	n state,nodeId,wayId,relationId,version,a,visible
	;
	s logId=$$logStart^xapi($$decode^xapi("changeset/"_changesetId_"/download"),"")
	;
	; Bad query?
	i changesetId'?1.n d notFound^http,logEnd^xapi(logId,0,"404 Not found") q
	;
	; Is it there?
	i '$d(^c(changesetId)) d gone^http,logEnd^xapi(logId,0,"410 Gone") q
	;
	d header^http("text/xml")
	d xmlProlog^rest("")
	;
	s indent=""
	d osmChange^xapi(indent)
	;
	s state=""
	s nodeId=""
	f  d  i nodeId="" q
	. s nodeId=$o(^c(changesetId,"n",nodeId)) i nodeId="" q
	. s version=""
	. f  d  i version="" q
	. . s version=$o(^c(changesetId,"n",nodeId,"v",version)) i version="" q
	. . s a=^c(changesetId,"n",nodeId,"v",version,"a")
	. . s visible=$p(a,$c(1),5)
	. . i visible="false" d setState(indent_"  ",.state,"delete")
	. . i visible="",version=1 d setState(indent_"  ",.state,"create")
	. . i visible="",version'=1 d setState(indent_"  ",.state,"modify")
	. . w $$xml^nodeVersion(indent_"  ",nodeId,changesetId,version,"*")
	;
	s wayId=""
	f  d  i wayId="" q
	. s wayId=$o(^c(changesetId,"w",wayId)) i wayId="" q
	. s version=""
	. f  d  i version="" q
	. . s version=$o(^c(changesetId,"w",wayId,"v",version)) i version="" q
	. . s visible=$g(^c(changesetId,"w",wayId,"v",version,"t","@visible"))
	. . i visible="false" d setState(indent_"  ",.state,"delete")
	. . i visible="",version=1 d setState(indent_"  ",.state,"create")
	. . i visible="",version'=1 d setState(indent_"  ",.state,"modify")
	. . w $$xml^wayVersion(indent_"  ",wayId,changesetId,version,"way|nd|@*")
	;
	s relationId=""
	f  d  i relationId="" q
	. s relationId=$o(^c(changesetId,"r",relationId)) i relationId="" q
	. s version=""
	. f  d  i version="" q
	. . s version=$o(^c(changesetId,"r",relationId,"v",version)) i version="" q
	. . s visible=$g(^c(changesetId,"r",relationId,"v",version,"t","@visible"))
	. . i visible="false" d setState(indent_"  ",.state,"delete")
	. . i visible="",version=1 d setState(indent_"  ",.state,"create")
	. . i visible="",version'=1 d setState(indent_"  ",.state,"modify")
	. . w $$xml^relationVersion(indent_"  ",relationId,changesetId,version,"relation|@*|member|tag|")
	;
	d setState(indent_"  ",.state,"")
	;
	w indent,"</osmChange>",$c(13,10)
	;
	d logEnd^xapi(logId,1,"")
	;
	q
	
	
setState(indent,oldState,newState)	;
	;
	i oldState=newState q
	;
	i oldState="create" w indent,"</create>",$c(13,10)
	i oldState="modify" w indent,"</modify>",$c(13,10)
	i oldState="delete" w indent,"</delete>",$c(13,10)
	;
	i newState="create" w indent,"<create>",$c(13,10)
	i newState="modify" w indent,"<modify>",$c(13,10)
	i newState="delete" w indent,"<delete>",$c(13,10)
	;
	s oldState=newState
	q
	
	
bbox(changesetId,bllat,bllon,trlat,trlon,recalculate)	; Public ; Get the bbox for a changeset
	;
	; Inputs:
	;  recalculate - 0 = used stored value if available (default).  The stored value may be wrong if elements have been moved subsequently.
	;                1 = recalculate from scratch (slower).
	;
	n seq,ref,type,relation
	n bllat1,bllon1,trlat1,trlon1
	;
	s recalculate=$g(recalculate)=1
	;
	; Use previously calculated values if present
	i 'recalculate d  i bllat'="" q
	. s q=$g(^c(changesetId,"q"))
	. s bllat=$p(q,$c(1),2)
	. s bllon=$p(q,$c(1),3)
	. s trlat=$p(q,$c(1),4)
	. s trlon=$p(q,$c(1),5)
	;
	s bllat=999999,bllon=999999,trlat=-999999,trlon=-999999
	s bllat1=999999,bllon1=999999,trlat1=-999999,trlon1=-999999
	s nodeId=""
	f  d  i nodeId="" q
	. s nodeId=$o(^c(changesetId,"n",nodeId)) i nodeId="" q
	. s version=""
	. f  d  i version="" q
	. . s version=$o(^c(changesetId,"n",nodeId,"v",version)) i version="" q
	. . d bbox^nodeVersion(nodeId,version,.bllat1,.bllon1,.trlat1,.trlon1)
	. . i trlat1>trlat s trlat=trlat1
	. . i bllat1<bllat s bllat=bllat1
	. . i trlon1>trlon s trlon=trlon1
	. . i bllon1<bllon s bllon=bllon1
	;
	s wayId=""
	f  d  i wayId="" q
	. s wayId=$o(^c(changesetId,"w",wayId)) i wayId="" q
	. d bbox^way(wayId,.bllat1,.bllon1,.trlat1,.trlon1)
	. i bllat1="" q  ; If way has been deleted then location is null
	. i trlat1>trlat s trlat=trlat1
	. i bllat1<bllat s bllat=bllat1
	. i trlon1>trlon s trlon=trlon1
	. i bllon1<bllon s bllon=bllon1
	;
	s relationId=""
	f  d  i relationId="" q
	. s relationId=$o(^c(changesetId,"r",relationId)) i relationId="" q
	. d bbox^relation(relationId,.bllat1,.bllon1,.trlat1,.trlon1)
	. i bllat1="" q  ; If relation has been deleted then location is null
	. i trlat1>trlat s trlat=trlat1
	. i bllat1<bllat s bllat=bllat1
	. i trlon1>trlon s trlon=trlon1
	. i bllon1<bllon s bllon=bllon1
	q
