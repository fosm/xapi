xapi	; OpenStreetMap API 0.5 with extensions 
	; Copyright (C) 2008  Etienne Cherdlu <80n80n@gmail.com>
	;
	; This program is free software: you can redistribute it and/or modify
	; it under the terms of the GNU Affero General Public License as
	; published by the Free Software Foundation, either version 3 of the
	; License, or (at your option) any later version.
	;
	; This program is distributed in the hope that it will be useful,
	; but WITHOUT ANY WARRANTY; without even the implied warranty of
	; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	; GNU Affero General Public License for more details.
	;
	; You should have received a copy of the GNU Affero General Public License
	; along with this program.  If not, see <http://www.gnu.org/licenses/>.
	
	
bbox(bllat,bllon,trlat,trlon,constraint,qualifiers)	; Public ; Returns an osm dataset for a bbox and tag selection
	;
	; Constraint object:
	; constraint("element") - which element to select
	; constraint("key",key,"value")=value
	; constraint("way/nd") - if undefined select all ways. If true select ways with at least one node, if false select ways
	;                        with no nodes.
	; constraint("way/tag") - if undefined select all ways. If true select all ways with at least one tag. If false select
	;                         all ways with no tags.
	; constraint("node/way") - if undefined select all nodes.  If true select just nodes with ways. If false select just
	;                          nodes without ways.
	; constraint("relation/node")
	; constraint("relation/way")
	; constraint("relation/relation")
	; constraint("relation/tag")

	n gOrderedNodes
	n request,logId,qsRoot,bbox,gCount,itemCount
	n indent,nodeId,wayId,relationId
	n i,j
	n subElements,gNodeElements,gWayElements,gRelationsElements
	;
	s e=$g(constraint("element"))
	s k=$o(constraint("key","")) ; First key only for now
	s v="" i k'="" s v=constraint("key",k,"value")
	;
	; Normalise request
	i e="" s e="*"
	i k="" s k="*"
	i v="" s v="*"
	;
	l +^log
	s ^log=$g(^log)+1
	s logId=^log
	l -^log
	;
	;
	s request=e_"["_k_"="_v_"][bbox="_bllon_","_bllat_","_trlon_","_trlat_"]"
	i $g(constraint("way/nd"))=1 s request=request_"[nd]"
	i $g(constraint("way/nd"))=0 s request=request_"[not(nd)]"
	i $g(constraint("node/tag"))=1 s request=request_"[tag]" ; Applies to ways and relations as well
	i $g(constraint("node/tag"))=0 s request=request_"[not(tag)]" ; Applies to ways and relations as well
	i $g(constraint("node/way"))=1 s request=request_"[way]"
	i $g(constraint("node/way"))=0 s request=request_"[not(way)]"
	i $g(constraint("relation/node"))=1 s request=request_"[node]"
	i $g(constraint("relation/node"))=0 s request=request_"[not(node)]"
	i $g(constraint("relation/way"))=1 s request=request_"[way]"
	i $g(constraint("relation/way"))=0 s request=request_"[not(way)]"
	i $g(constraint("relation/relation"))=1 s request=request_"[relation]"
	i $g(constraint("relation/relation"))=0 s request=request_"[not(relation)]"	
	;
	; Qualifiers
	s subElement=$p(qualifiers,"/",1)
	;
	; Way qualifiers  - can be e|e|e
	s gWayElements="way|@*|"
	i e="*"!(e["way") d
	. i subElement="" s gWayElements=gWayElements_"nd|tag" ; Default
	. e  s gWayElements=gWayElements_subElements
	;
	; Node qualifiers
	s gNodeElements="node|@*|"
	i e="*"!(e["node") d
	. i subElement="" s gNodeElements=gNodeElements_"tag" ; Default
	. e  s gNodeElements=gNodeElements_subElement
	;
        ; Relation qualifiers
	s gRelationsElements="relation|@*|"
	i e="*"!(e["relation") d
	. i subElement="" s gRelationsElements=gRelationsElements_"member|tag" ; Default
	. e  s gRelationsElements=gRelationsElements_subElement
	;
	s ^log(logId,"request")=request
	s ^log(logId,"start")=$h
	s ^log(logId,"pid")=$j
	s ^log(logId,"ip")=$g(%ENV("REMOTE_ADDR"))
	s ^log(logId,"userAgent")=$g(%ENV("HTTP_USER_AGENT"))
	;
	s qsRoot=$$bbox^quadString(bllat,bllon,trlat,trlon)
	s ^log(logId,"qs")=qsRoot
	;
	;
	k ^osmTemp($j)
	s gCount=0
	s gNodeHit=0 ; In bbox
	s gNodeMiss=0 ; Not in bbox
	;
	s qsRoot=$$bbox^quadString(bllat,bllon,trlat,trlon)
	;
	s bbox("bllat")=bllat
	s bbox("bllon")=bllon
	s bbox("trlat")=trlat
	s bbox("trlon")=trlon
	s bbox("root")=qsRoot
	;
	s ^log(logId,"qs")=qsRoot
	;
	; Validate request size
	i k'["!",'$$checkSize(e,k,v,.bbox,.itemCount,.area) d  q
	. d error(e,k,v,.bbox,itemCount,area,logId)
	. s ^log(logId,"error")=e_" "_k_" "_v_" "_qsRoot_" "_itemCount_" "_area
	. d requestDelete(request,logId)
	;
	; Check for duplicate request
	i $d(^requestx(request)) d  q
	. d error1(request,logId,"Duplicate request.  You or someone else already made this request recently and it is still being processed.  Please try later.")
	. s ^log(logId,"error")="Duplicate "_request
	;
	; Add to active request index
	d requestAdd(request,logId)
	;
	; Write headers
	; Need to keep the headers all on one line as t@h can't cope with a multi-line header.  It assumes just one line.
        s indent=""
	w indent,"<osm"
	w $$attribute^osmXml("version","0.6",indent)
	w $$attribute^osmXml("generator","xapi: OSM Extended API 2.0",indent)
	; w $$attribute^osmXml("xmlns","http://wiki.openstreetmap.org/index.php/OSM_Protocol_Version_0.5",indent) ; This breaks stuff
	w $$attribute^osmXml("xmlns:xapi","http://www.informationfreeway.org/xapi/0.6",indent)
	w $$attribute^osmXml("xapi:uri",$$unescape^rest($g(%ENV("REQUEST_URI"))),indent)
	w $$attribute^osmXml("xapi:planetDate",$g(^osmPlanet("date")),indent)
	w $$attribute^osmXml("xapi:copyright",$e(^osmPlanet("date"),1,4)_" OpenStreetMap contributors",indent)
	w $$attribute^osmXml("xapi:instance",$g(^osmPlanet("instance")),indent)
	w indent,">",$c(13,10)
	;
	; Output nodes in order?
	s gOrderedNodes=0
	;
	; If normal map request do it the traditional way
	i e="*",k="*",v="*" d
	. d map(.bbox)
	e  d
	. i e="*" d
	. . f i=1:1:$l(k,"|") f j=1:1:$l(v,"|") d elements("node",$p(k,"|",i),$p(v,"|",j),qsRoot,.bbox)
	. . f i=1:1:$l(k,"|") f j=1:1:$l(v,"|") d elements("way",$p(k,"|",i),$p(v,"|",j),qsRoot,.bbox)
	. . ;f i=1:1:$l(k,"|") f j=1:1:$l(v,"|") d elements("relation",$p(k,"|",i),$p(v,"|",j),qsRoot,.bbox)
	. e  f i=1:1:$l(k,"|") f j=1:1:$l(v,"|") d elements(e,$p(k,"|",i),$p(v,"|",j),qsRoot,.bbox)
	;
	s ^log(logId,"midpoint")=$h
	;
	; If ordered nodes then write them all now
	i gOrderedNodes s nodeId="" f  d  i nodeId="" q
	. s nodeId=$o(^osmTemp($j,"node",nodeId)) i nodeId="" q
	. w $$xml^node(indent,nodeId,gNodeElements)
	;
	s wayId=""
	f  d  i wayId="" q
	. s wayId=$o(^osmTemp($j,"way",wayId)) i wayId="" q
	. w $$xml^way(indent,wayId,gWayElements)
	;
	s relationId=""
	f  d  i relationId="" q
	. s relationId=$o(^osmTemp($j,"relation",relationId)) i relationId="" q
	. w $$xml^relation(indent,relationId,gRelationsElements)
	;
	; Generate error and deliberately incomplete xml document if element limit reached
	i gCount>1000000 w indent,"<error>Query limit of 1,000,000 elements reached</error>",$c(13,10)
	e  w indent,"</osm>",$c(13,10)
	;
	k ^osmTemp($j)
	;
	s ^log(logId,"end")=$h
	s start=^log(logId,"start")
	s midpoint=^log(logId,"midpoint")
	s end=^log(logId,"end")
	s start=$p(start,",",2)
	s midpoint=$p(midpoint,",",2)
	s end=$p(end,",",2)
	i midpoint<start s midpoint=midpoint+86400
	i end<start s end=end+86400
	s ^log(logId,"duration")=end-start
	s ^log(logId,"duration1")=midpoint-start
	s ^log(logId,"duration2")=end-midpoint
	s ^log(logId,"count")=gCount
	s ^log(logId,"nodeHit")=gNodeHit
	s ^log(logId,"nodeMiss")=gNodeMiss
	;
	; Remove from request index
	d requestDelete(request,logId)
	;
	l +^munin
	s ^munin("apiCalls")=$g(^munin("apiCalls"))+1
	s ^munin("responseTotal")=$g(^munin("responseTotal"))+^log(logId,"duration")
	s ^munin("responseDB")=$g(^munin("responseDB"))+^log(logId,"duration1")
	s ^munin("responseIO")=$g(^munin("responseIO"))+^log(logId,"duration2")
	l -^log
	;
	s logFile="muninRequests.log"
	o logFile:NEW u logFile w ^munin("apiCalls"),! c logFile
	;
	s logFile="muninResponseTotal.log"
	o logFile:NEW u logFile w ^munin("responseTotal"),! c logFile
	;
	s logFile="muninResponseDB.log"
	o logFile:NEW u logFile w ^munin("responseDB"),! c logFile
	;
	s logFile="muninResponseIO.log"
	o logFile:NEW u logFile w ^munin("responseIO"),! c logFile
	;
	q


map(oBox)	; Private ; Process a map request
	;
	n qsItem
	;
	s qsItem=oBox("root")
	f  d  i qsItem="" q
	. s qsItem=$$nextNode(.oBox,qsItem,"*","*") i qsItem="" q
	. d mapNode(qsItem,.oBox)
	. i gCount>1000000 s qsItem="" q  ; Abort
	q


mapNode(qsItem,bbox)    ; Process a single quadtree
        ;
	n nodeId,wayId
	;
	s nodeId=""
	f  d  i nodeId="" q
	. s nodeId=$o(^nodex("*","*",qsItem,nodeId)) i nodeId="" q
	. ;
	. s gCount=gCount+1
	. i gCount#1000=0 s ^log(logId,"count")=gCount i gCount>1000000 s nodeId="" q  ; Abort
	. ;
	. ; Check that node is actually within bounding box
	. i '$$nodeInBox(nodeId,.bbox) s gNodeMiss=gNodeMiss+1 q
	. d node(nodeId,"*","*",.bbox,1)
	. s gNodeHit=gNodeHit+1
	. ;
        . s wayId=""
	. f  d  i wayId="" q
	. . s wayId=$o(^wayByNode(nodeId,wayId)) I wayId="" q
	. . d way(wayId,"*","*",.bbox,1)
	q

	
checkSize(e,k,v,bbox,itemCount,area)	; Check the size of the request
	;
	n lat,lon
	n i,j,k1,v1
	;
	; Normalise arguments
	i k="" s k="*"
	i v="" s v="*"
	;
	; Calculate area of bbox
	s lat=(bbox("trlat")+90)-(bbox("bllat")+90) 
	s lon=(bbox("trlon")+180)-(bbox("bllon")+180)
	s area=lat*lon
	;
	; Count nodes (divide by 20 as they are less expensive than ways)
	s itemCount=0
	i (e="node")!(e="*") f i=1:1:$l(k,"|") d
	. s k1=$p(k,"|",i)
	. i k1="" q
	. f j=1:1:$l(v,"|") d
	. . s v1=$p(v,"|",j)
	. . i v1="" q
	. . s itemCount=itemCount+($g(^count("nodekv",k1,v1))/20)
	;
	; Count ways
	i (e="way")!(e="*") f i=1:1:$l(k,"|") d
	. s k1=$p(k,"|",i)
	. i k1="" q
	. f j=1:1:$l(v,"|") d
	. . s v1=$p(v,"|",j)
	. . i v1="" q
	. . s itemCount=itemCount+$g(^count("waykv",k1,v1))
	;
	; Allow requests for small areas even if the count is large
	i itemCount>1000000,area>100 q 0
	i itemCount>100000,area>1000 q 0
	;
	; Check bbox for [*=*] requests, * is not yet in ^count
	i k="*",v="*",area>100 q 0
	;
	q 1
	
	
elements(e,k,v,qsRoot,bbox)	;
	;
	n lat,lon,qsItem,x
	;
	i k="" s k="*"
	i v="" s v="*"
	;
	; All data in the db is already xml escaped, including indexes, so escape k and v before we use them
	s k=$$xmlEscape(k)
	s v=$$xmlEscape(v)
	;
	; Nodes
	i e="node" d
	. d elementNode(k,v,"*",.bbox)
	. f x=1:1:$l(qsRoot) s qsItem=$e(qsRoot,1,x) d elementNode(k,v,qsItem,.bbox)
	;
	s qsItem=qsRoot
	i e="node" f  d  i qsItem="" q
	. s qsItem=$o(^nodex(k,v,qsItem)) i qsItem="" q
	. i $e(qsItem,1,$l(qsRoot))'=qsRoot s qsItem="" q
	. i '$$bboxInQs^quadString(.bbox,qsItem) s qsItem=$$nextQs(.bbox,qsItem) i qsItem="" q
	. d elementNode(k,v,qsItem,.bbox)
	. s gCount=gCount+1
	. i gCount#10000=0 s ^log(logId,"count")=gCount i gCount>1000000 s qsItem="" q  ; Abort
	;
	; Ways
	i e="way" d
	. d elementWay(k,v,"*",.bbox)
	. f x=1:1:$l(qsRoot) s qsItem=$e(qsRoot,1,x) d elementWay(k,v,qsItem,.bbox)
	;
	s qsItem=qsRoot
	i e="way" f  d  i qsItem="" q
	. s qsItem=$o(^wayx(k,v,qsItem)) i qsItem="" q
	. i $e(qsItem,1,$l(qsRoot))'=qsRoot s qsItem="" q
	. i '$$bboxInQs^quadString(.bbox,qsItem) s qsItem=$$nextQs(.bbox,qsItem) i qsItem="" q
	. d elementWay(k,v,qsItem,.bbox)
	. s gCount=gCount+1
	. i gCount#10000=0 s ^log(logId,"count")=gCount i gCount>1000000 s qsItem="" q  ; Abort
	;
	;
	; Relations
	i e="relation" d
	. d elementRelation(k,v,"*",.bbox)
	. f x=1:1:$l(qsRoot) s qsItem=$e(qsRoot,1,x) d elementRelation(k,v,qsItem,.bbox)
	;
	s qsItem=qsRoot
	i e="relation" f  d  i qsItem="" q
	. s qsItem=$o(^relationx(k,v,qsItem)) i qsItem="" q
	. i $e(qsItem,1,$l(qsRoot))'=qsRoot s qsItem="" q
	. i '$$bboxInQs^quadString(.bbox,qsItem) s qsItem=$$nextQs(.bbox,qsItem) i qsItem="" q
	. d elementRelation(k,v,qsItem,.bbox)
	. s gCount=gCount+1
	. i gCount#10000=0 s ^log(logId,"count")=gCount i gCount>1000000 s qsItem="" q  ; Abort
	;
	q
	
	
nextQs(bbox,qsItem)	; Get the next quad tree that is actually in the bbox
	;
	n x,nextQs
	;
	s nextQs=qsItem
	f x=1:1:$l(qsItem) i '$$bboxInQs^quadString(.bbox,$e(qsItem,1,x)) s nextQs=$$incrementQs^quadString($e(qsItem,1,x)) q
	;
	q nextQs
	

nextNode(oBox,qsItem,k,v)	; Private ; get the next tile containing a node of the right kind within the bounding box
	;
	n i,done
	;
	s done=0
	f  d  i done q
	. s qsItem=$o(^nodex(k,v,qsItem)) i qsItem="" s done=1 q
	. ;
	. ; If we are not still inside the bbox root area then we are done
	. i $e(qsItem,1,$l(oBox("root")))'=oBox("root") s qsItem="",done=1 q
	. ;
	. ; If we are still inside the bbox area then we have the next tile
	. i $$bboxInQs^quadString(.oBox,qsItem) s done=1 q
	. ;
	. ; Walk down the tree until we find a tile that is not in the bbox area
	. ; This potentially skips large parts of the tree that are outside the box
	. f i=1:1:$l(qsItem) i '$$bboxInQs^quadString(.oBox,$e(qsItem,1,i)) q
	. ;
	. ; Increment to the next tile, then rinse and repeat
	. s qsItem=$$incrementQs^quadString($e(qsItem,1,i)) i qsItem="" s done=1 q
	;
	q qsItem


elementNode(k,v,qsItem,bbox)	; Process a single quadtree
	;
	n id,relationId
	;
	s id=""
	f  d  i id="" q
	. s id=$o(^nodex(k,v,qsItem,id)) i id="" q
	. ;
	. ; Check the node/way constraint
	. ;
	. i $g(constraint("node/way"))=1,$d(^wayByNode(id))\10=0 q
	. i $g(constraint("node/way"))=0,$d(^wayByNode(id))\10=1 q
	. ;
	. ; Check the node/tag constraint
	. i $g(constraint("node/tag"))=1,$$hasRealTag^node(id)=0 q
	. i $g(constraint("node/tag"))=0,$$hasRealTag^node(id)=1 q
	. ;
	. ; Check that node is actually within bounding box
	. i $$nodeInBox(id,.bbox) d node(id,k,v,.bbox,1)
	q
	
	
node(nodeId,k,v,bbox,relations)	; Add node and all it's relations to workfile
	;
	n relationId
	;
	i $d(^osmTemp($j,"node",nodeId)) q
	i 'gOrderedNodes w $$xml^node(indent,nodeId,gNodeElements)
	s ^osmTemp($j,"node",nodeId)=""
	;
	; Optionally select any relations that belong to this node
	s relationId=""
	i relations f  d  i relationId="" q
	. s relationId=$o(^relationMx("node",nodeId,relationId)) i relationId="" q
	. i '$d(^osmTemp($j,"relation",relationId)) s ^osmTemp($j,"relation",relationId)=""
	;
	q
	
	
elementWay(k,v,qsItem,bbox)	; Process a single quadtree
	;
	n id
	;
	s id=""
	f  d  i id="" q
	. s id=$o(^wayx(k,v,qsItem,id)) i id="" q
	. ;
	. ; Check the way/nd constraint
	. i $g(constraint("way/nd"))=0,$d(^way(id))\10=1 q
	. i $g(constraint("way/nd"))=1,$d(^way(id))\10=0 q
	. ;
	. ; Check the way/tag constraint
	. i $g(constraint("way/tag"))=0,$$hasRealTag^way(id)=1 q
	. i $g(constraint("way/tag"))=1,$$hasRealTag^way(id)=0 q
	. ;
	. ; Check that the way is actually within the bounding box
	. i $$wayInBox(id,.bbox) d way(id,k,v,.bbox,1)
	q
	
	
way(wayId,k,v,bbox,relations)	; Add way and all it's nodes and relations to workfile
	;
	n ndSeq,nodeId,relationId
	;
	; Has the way already been selected?
	i $d(^osmTemp($j,"way",wayId)) q
	s ^osmTemp($j,"way",wayId)=""
	;
	; Add all nodes that belong to this way
	s ndSeq=""
	f  d  i ndSeq="" q
	. s ndSeq=$o(^way(wayId,ndSeq)) i ndSeq="" q
	. s nodeId=^way(wayId,ndSeq)
	. i $d(^osmTemp($j,"node",nodeId)) q
	. i 'gOrderedNodes w $$xml^node(indent,nodeId,gNodeElements) 
	. s ^osmTemp($j,"node",nodeId)=""
	;
	; Optionally, add all relations that belong to this way
	s relationId=""
	i relations f  d  i relationId="" q
	. s relationId=$o(^relationMx("way",wayId,relationId)) i relationId="" q
	. i '$d(^osmTemp($j,"relation",relationId)) s ^osmTemp($j,"relation",relationId)=""
	;
	q
	
	
elementRelation(k,v,qsItem,bbox)	; Process a single quadtree
	;
	n id
	;
	s id=""
	f  d  i id="" q
	. s id=$o(^relationx(k,v,qsItem,id)) i id="" q
	. ;
	. ; Check the relation/node constraint
	. i $g(constraint("relation/node"))=0,$d(^relation(id,"node"))\10=1 q
	. i $g(constraint("relation/node"))=1,$d(^relation(id,"node"))\10=0 q
	. ;
	. ; Check the relation/way constraint
	. i $g(constraint("relation/way"))=0,$d(^relation(id,"way"))\10=1 q
	. i $g(constraint("relation/way"))=1,$d(^relation(id,"way"))\10=0 q
	. ;
	. ; Check the relation/relation constraint
	. i $g(constraint("relation/relation"))=0,$d(^relation(id,"relation"))\10=1 q
	. i $g(constraint("relation/relation"))=1,$d(^relation(id,"relation"))\10=0 q
	. ;
	. ; Check the relation/tag constraint
	. i $g(constraint("relation/tag"))=0,$$hasRealTag^relation(id)=1 q
	. i $g(constraint("relation/tag"))=1,$$hasRealTag^relation(id)=0 q
	. ;
	. ; Check that the way is actually within the bounding box
	. i $$relationInBox(id,.bbox) d relation(id,k,v,.bbox)
	q
	
	
relation(relationId,k,v,bbox)	; Add relation and all it's constituent elements to workfile
	;
	n type,rel
	;
	; Has the relation already been selected?
	i $d(^osmTemp($j,"relation",relationId)) q
	s ^osmTemp($j,"relation",relationId)=""
	;
	; Add all elements that belong to this relation
	s type=""
	f  d  i type="" q
	. s type=$o(^relation(relationId,type)) i type="" q
	. s rel=""
	. f  d  i rel="" q
	. . s rel=$o(^relation(relationId,type,rel)) i rel="" q
	. . ;
	. . ; If it's a relation then add the relation recursively
	. . i type="relation" d relation(rel,k,v,.bbox)
	. . ;
	. . ; If it's a node then add the node, but not the node's relations
	. . i type="node" d node(rel,k,v,.bbox,0)
	. . ;
	. . ; If it's a way then add the way's nodes, but not its relations
	. . i type="way" d way(rel,k,v,.bbox,0) 	
	;
	q
	
	
nodeInBox(nodeId,bbox)	; Is a node within the bbox?
	;
	n lat,lon,latlon
	;
	s latlon=$g(^node(nodeId))
	i latlon="" q 0
	s lat=$p(latlon,$c(0),1)
	i lat<bbox("bllat") q 0
	i lat>bbox("trlat") q 0
	;
	s lon=$p(latlon,$c(0),2)
	i lon<bbox("bllon") q 0
	i lon>bbox("trlon") q 0
	q 1
	
	
wayInBox(wayId,bbox)	; Is a way within the bbox?
	; Stop looking as soon as we find one node that is actually within the bbox
	;
	n wayInBox,ndSeq,nodeId
	;
	s wayInBox=0
	s ndSeq=""
	f  d  i ndSeq="" q
	. s ndSeq=$o(^way(wayId,ndSeq)) i ndSeq="" q
	. s nodeId=^way(wayId,ndSeq)
	. i $$nodeInBox(nodeId,.bbox) s wayInBox=1,ndSeq="" q
	;
	q wayInBox
	
	
relationInBox(relationId,bbox)	; Is a relation within the bbox?
	;
	n qsItem
	;
	s qsItem=^relation(relationId)
	i $$bboxInQs^quadString(.bbox,qsItem) q 1
	;
	q 0
	
	
requestAdd(request,job)	; Add request to request index
	;
	s ^requestx(request,job)=""
	q
	
	
requestDelete(request,job)	; Delete request from request index
	;
	k ^requestx(request,job)
	q
	
	
error(e,k,v,bbox,itemCount,area,logId)	; Error response
	;
	n f
	;
	; Round the item count to avoid being too precise about it all
	s f=10**($l($j(itemCount,0,0))-2)
	s itemCount=itemCount\f*f
	;
	w "<error>",!
	w "BETA: we are testing a request validation mechanism to filter out silly requests.  If you have made",!
	w " what you think is a sensible request that is being rejected please let me know (80n80n@gmail.com).  ",!
	w !
	w "Your request (",e,"/",k,"/",v,") "
	i itemCount>0 w "would select about ",itemCount," elements and "
	w "spans ",$j(area/64800*100,0,2),"% of the planet, which is too large.  Please check your request.  ",!
	w "If you really do need this data then it may be better to get it directly from a planet file.",!
	w " Log ID=",logId,"  ",!
	w "</error>",!
	q
	
	
error1(request,logId,message)	; Generate an error response
	;
	w "<error>",$c(13,10)
	w "Request: ",request,$c(13,10)
	w message,$c(13,10)
	w "LogId: ",logId,$c(13,10)
	w "Contact: 80n80n@gmail.com for assistance",$c(13,10)
	w "</error>",$c(13,10)
	q


fixApostrophe(string) ; Private ; Temporarily fix up apostrophes until the data is all fixed
        ; Usage:
        ;  s xmlString=$$fixApostrophe(string)
        ; Inputs:
        ;  string  = string to be escaped
        ; Outputs:
        ;  $$toXml = escaped string
        ;
        n out,x,c
        ;
        s out=""
        f x=1:1:$l(string) d
        . s c=$e(string,x)
        . i "'"[c s out=out_"&apos;" q
        . s out=out_c
        q out


xmlEscape(string)	; Private ; Escape a string using character entities
	; Usage:
	;  s xmlString=$$xmlEscape(string)
	; Inputs:
	;  string  = string to be escaped
	; Output:
	;  $$xmlEscape = escaped string
	;
	n out,x,c
	;
	s out=""
	f x=1:1:$l(string) d
	. s c=$e(string,x)
	. i c="'" s out=out_"&apos;" q
	. i c="""" s out=out_"&quot;" q
	. i c="&" s out=out_"&amp;" q
	. i c="<" s out=out_"&lt;" q
	. i c=">" s out=out_"&gt;" q
	. s out=out_c
	q out


renice	; Private ; Increase the niceness of this process
	;
	zsystem "renice +1 -p "_$j ">/dev/null"
	q
