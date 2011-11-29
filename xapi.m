xapi	; OpenStreetMap API 0.6 with extensions 
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
	
	; Test
	s constraint("element")=ASTERISK
	;s constraint("kv",1,"key")="restriction"
	;s constraint("kv",1,"value")="no_right_turn"
	;s bllon=14.545898,bllat=50.559799,trlon=14.721680,trlat=50.634557
	;s bllon=-180,bllat=-90,trlon=180,trlat=90
	s bllon=12.01,bllat=12.01,trlon=12.02,trlat=12.02
	d bbox(bllat,bllon,trlat,trlon,.constraint,"")
	q
	
	
bbox(bllat,bllon,trlat,trlon,constraint,qualifiers)	; Public ; Returns an osm dataset for a bbox and tag selection
	;
	; Constraint object:
	; constraint("element") - which element to select
	; constraint("kv",keySeq,"key")=value
	; constraint("kv",keySeq,"value")=value
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
	;
	n e,k,v
	n gOrderedNodes
	n request,logId,qsRoot,bbox,gCount,itemCount,area,continue
	n indent,nodeId,wayId,relationId
	n i,j
	n subElement,gNodeElements,gWayElements,gRelationsElements
	n start,midpoint,end,logFile
	;
	s e=$g(constraint("element"))
	s k=$g(constraint("kv",1,"key")) ; First key if there is one
	s v=$g(constraint("kv",1,"value"))
	;
	; Normalise request
	i e="" s e=ASTERISK
	i k="" s k=ASTERISK
	i v="" s v=ASTERISK
	i bllat="" s bllat=-90
	i bllon="" s bllon=-180
	i trlat="" s trlat=90
	i trlon="" s trlon=180
	s bllat=+bllat
	s bllon=+bllon
	s trlat=+trlat
	s trlon=+trlon
	;
	s request=$$decode(e)_$$decodeKVs(.constraint)_"[bbox="_bllon_","_bllat_","_trlon_","_trlat_"]"
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
	s subElement=$p(qualifiers,SLASH,1)
	;
	; Always return the main element and it's attributes
	s gNodeElements="node|@*|"
	s gWayElements="way|@*|"
	s gRelationsElements="relation|@*|"
	;
	; Way qualifiers
	i e="way" d
	. i subElement="" d
	. . s gNodeElements=gNodeElements_"tag|"
	. . s gWayElements=gWayElements_"nd|tag|"
	. e  s gWayElements=gWayElements_subElement
	;
	; Node qualifiers
	i e="node" d
	. i subElement="" d
	. . s gNodeElements=gNodeElements_"tag" ; Default
	. e  s gNodeElements=gNodeElements_subElement
	;
	; Relation qualifiers
	i e="relation" d
	. i subElement="" d
	. . s gNodeElements=gNodeElements_"tag|"
	. . s gWayElements=gWayElements_"nd|tag|"
	. . s gRelationsElements=gRelationsElements_"member|tag|"
	. e  s gRelationsElements=gRelationsElements_subElement
	;
	; Relation qualifiers
	i e=ASTERISK d
	. i subElement="" d
	. . s gNodeElements=gNodeElements_"tag|"
	. . s gWayElements=gWayElements_"nd|tag|"
	. . s gRelationsElements=gRelationsElements_"member|tag|"
	. e  d
	. . s gNodeElements=gNodeElements_subElement
	. . s gWayElements=gWayElements_subElement
	. . s gRelationsElements=gRelationsElements_subElement
	;
	; Get the qs for the query
	s qsRoot=$$bbox^quadString(bllat,bllon,trlat,trlon)
	;
	; Log the start of the request
	s logId=$$logStart(request,qsRoot)
	;
	;
	k ^temp($j)
	s gCount=0
	;
	s bbox("bllat")=bllat
	s bbox("bllon")=bllon
	s bbox("trlat")=trlat
	s bbox("trlon")=trlon
	s bbox("root")=qsRoot
	;
	; Validate for blocked requests
	i '$$checkQuery($$decode(e),$$decode(k),$$decode(v),bllat,bllon,trlat,trlon,.reason) d  q
	. d error1(request,logId,"Your request is for "_reason_" which is too large or a bit silly. Sorry.")
	. d logEnd(logId,0,reason)
	;
	; Add to active request index
	d requestAdd(request,logId)
	;
	; Write headers
	s indent=""
	d osm(indent)
	w indent,"<bounds"
	w $$attribute^osmXml("minlat",bllat,"")
	w $$attribute^osmXml("minlon",bllon,"")
	w $$attribute^osmXml("maxlat",trlat,"")
	w $$attribute^osmXml("maxlon",trlon,"")
	w "/>",$c(13,10)
	;
	; Output nodes in order?
	s gOrderedNodes=0
	;
	s continue=1
	;
	; Hack for Potlatch - only serve main roads at low zoom levels
	;s potlatchHack=$g(%ENV("HTTP_HOST"))="potlatch.fosm.org"
	;i potlatchHack s e="node",k="place",v=ASTERISK ;_BAR_"trunk"_BAR_"primary" ;_BAR_"secondary"_BAR_"tertiary"
	;
	; If normal map request do it the traditional way
	i e=ASTERISK,k=ASTERISK,v=ASTERISK d
	. s continue=$$map(.bbox)
	e  d
	. i e=ASTERISK d
	. . f i=1:1:$l(k,BAR) f j=1:1:$l(v,BAR) s continue=$$elements("node",$$decode($p(k,BAR,i)),$$decode($p(v,BAR,j)),qsRoot,.bbox) i 'continue q
	. . i 'continue q
	. . f i=1:1:$l(k,BAR) f j=1:1:$l(v,BAR) s continue=$$elements("way",$$decode($p(k,BAR,i)),$$decode($p(v,BAR,j)),qsRoot,.bbox) i 'continue q
	. . i 'continue q
	. e  d
	. . f i=1:1:$l(k,BAR) f j=1:1:$l(v,BAR) s continue=$$elements($$decode(e),$$decode($p(k,BAR,i)),$$decode($p(v,BAR,j)),qsRoot,.bbox) i 'continue q
	. . i 'continue q
	;
	i 'continue d  
	. ; Generate error and deliberately incomplete xml document if element limit reached
	. w indent,"<error>Query limit of ",gCount," elements reached</error>",$c(13,10)
	. ;
	. ; Add to silly request list
	. s ^silly($$decode(e),$$decode(k),$$decode(v),bllat,bllon,trlat,trlon)="over "_gCount_" elements"
	;
	; If ordered nodes then write them all now
	s nodeId=""
	i continue,gOrderedNodes f  d  i nodeId="" q
	. s nodeId=$o(^temp($j,"node",nodeId)) i nodeId="" q
	. w $$xml^node(indent,nodeId,gNodeElements)
	;
	s wayId=""
	i continue f  d  i wayId="" q
	. s wayId=$o(^temp($j,"way",wayId)) i wayId="" q
	. w $$xml^way(indent,wayId,gWayElements,1)
	;
	s relationId=""
	i continue f  d  i relationId="" q
	. s relationId=$o(^temp($j,"relation",relationId)) i relationId="" q
	. w $$xml^relation(indent,relationId,gRelationsElements)
	;
	; Close xml document unless query aborted
	i continue w indent,"</osm>",$c(13,10)
	;
	k ^temp($j)
	;
	d logEnd(logId,gCount,"")
	;
	; Remove from request index
	d requestDelete(request,logId)
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
	n qsItem,continue
	;
	s continue=1
	;
	s qsItem=oBox("root")
	i qsItem'="" s continue=$$mapNode(qsItem,.oBox) i 'continue q 0
	;
	f  d  i qsItem="" q
	. s qsItem=$$nextNode(.oBox,qsItem,"*","*") i qsItem="" q
	. s continue=$$mapNode(qsItem,.oBox) i 'continue s qsItem="" q
	;
	i 'continue q 0
	q 1
	
	
mapNode(qsItem,bbox)	   ; Process a single quadtree
	;
	n nodeId,wayId,continue
	;
	s continue=1
	;
	s nodeId=""
	f  d  i nodeId="" q
	. s nodeId=$o(^e(qsItem,"n",nodeId)) i nodeId="" q
	. ;
	. ; Check that node is actually within bounding box
	. i '$$nodeInBox(qsItem,nodeId,.bbox) q
	. s continue=$$node(nodeId,"*","*",.bbox,1) i 'continue s nodeId="" q
	. ;
	. s wayId=""
	. f  d  i wayId="" q
	. . s wayId=$o(^wayByNode(nodeId,wayId)) I wayId="" q
	. . s continue=$$way(wayId,"*","*",.bbox,1) i 'continue s wayId="" q
	. i 'continue s nodeId="" q
	;
	i 'continue q 0
	q 1
	
	
checkQuery(e,k,v,bllat,bllon,trlat,trlon,reason)	; Check for silly requests
	;
	s reason=""
	i '$d(^silly(e,k,v,bllat,bllon,trlat,trlon)) q 1
	;
	s reason=$g(^silly(e,k,v,bllat,bllon,trlat,trlon))
	;
	q 0
	
	
elements(e,k,v,qsRoot,bbox)	;
	;
	n lat,lon,qsItem,x,continue
	;
	i k="" s k="*"
	i v="" s v="*"
	;
	; All data in the db is already xml escaped, including indexes, so escape k and v before we use them
	s k=$$xmlEscape(k)
	s v=$$xmlEscape(v)
	;
	s continue=1
	;
	; Nodes
	i e="node" d
	. s continue=$$elementNode(k,v,"*",.bbox) i 'continue q
	. f x=1:1:$l(qsRoot) s qsItem=$e(qsRoot,1,x) s continue=$$elementNode(k,v,qsItem,.bbox) i 'continue q
	. i 'continue q
	;
	i 'continue q 0
	;
	s qsItem=qsRoot
	i e="node" f  d  i qsItem="" q
	. i k="*",v="*" s qsItem=$o(^e(qsItem))
	. e  s qsItem=$o(^nodex(k,v,qsItem))
	. i qsItem="" q
	. i $e(qsItem,1,$l(qsRoot))'=qsRoot s qsItem="" q
	. i '$$bboxInQs^quadString(.bbox,qsItem) s qsItem=$$nextQs(.bbox,qsItem) i qsItem="" q
	. s continue=$$elementNode(k,v,qsItem,.bbox) i 'continue s qsItem="" q
	;
	i 'continue q 0
	;
	; Ways
	i e="way" d
	. s continue=$$elementWay(k,v,"*",.bbox) i 'continue q
	. f x=1:1:$l(qsRoot) s qsItem=$e(qsRoot,1,x) s continue=$$elementWay(k,v,qsItem,.bbox) i 'continue q
	. i 'continue q
	;
	i 'continue q 0
	;
	s qsItem=qsRoot
	i e="way" f  d  i qsItem="" q
	. s qsItem=$o(^wayx(k,v,qsItem)) i qsItem="" q
	. i $e(qsItem,1,$l(qsRoot))'=qsRoot s qsItem="" q
	. i '$$bboxInQs^quadString(.bbox,qsItem) s qsItem=$$nextQs(.bbox,qsItem) i qsItem="" q
	. s continue=$$elementWay(k,v,qsItem,.bbox) i 'continue s qsItem="" q
	;
	i 'continue q 0
	;
	; Relations
	i e="relation" d
	. s continue=$$elementRelation(k,v,"*",.bbox) i 'continue q
	. f x=1:1:$l(qsRoot) s qsItem=$e(qsRoot,1,x) s continue=$$elementRelation(k,v,qsItem,.bbox) i 'continue q
	;
	i 'continue q 0
	;
	s qsItem=qsRoot
	i e="relation" f  d  i qsItem="" q
	. s qsItem=$o(^relationx(k,v,qsItem)) i qsItem="" q
	. i $e(qsItem,1,$l(qsRoot))'=qsRoot s qsItem="" q
	. i '$$bboxInQs^quadString(.bbox,qsItem) s qsItem=$$nextQs(.bbox,qsItem) i qsItem="" q
	. s continue=$$elementRelation(k,v,qsItem,.bbox) i 'continue s qsItem="" q
	;
	i 'continue q 0
	q 1
	
	
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
	n i,done,qsLast
	;
	s done=0
	f  d  i done q
	. i k="*",v="*" s qsItem=$o(^e(qsItem))
	. e  s qsItem=$o(^nodex(k,v,qsItem)) 
	. i qsItem="" s done=1 q
	. ;
	. ; If we are not still inside the bbox root area then we are done
	. i $e(qsItem,1,$l(oBox("root")))'=oBox("root") s qsItem="",done=1 q
	. ;
	. ; If we are still inside the bbox area then we have the next tile
	. i $$bboxInQs^quadString(.oBox,qsItem) s done=1 q
	. ;
	. ; Split off the last quad
	. s qsLast=$e(qsItem,$l(qsItem)),qsItem=$e(qsItem,1,$l(qsItem)-1)
	. ;
	. ; Iterate through the remaining tiles at this level
	. i "a"[qsLast,$$bboxInQs^quadString(.oBox,qsItem_"b") s qsItem=qsItem_"b",done=1 q
	. i "ab"[qsLast,$$bboxInQs^quadString(.oBox,qsItem_"c") s qsItem=qsItem_"c",done=1 q
	. i "abc"[qsLast,$$bboxInQs^quadString(.oBox,qsItem_"d") s qsItem=qsItem_"d",done=1 q
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
	n id,relationId,continue
	;
	s continue=1
	;
	s id=""
	f  d  i id="" q
	. i k="*",v="*" s id=$o(^e(qsItem,"n",id))
	. e  s id=$o(^nodex(k,v,qsItem,id))
	. i id="" q
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
	. i '$$nodeInBox(qsItem,id,.bbox) q
	. ;
	. ; Does node satisfy all predicates
	. i '$$nodePredicates(qsItem,id,.constraint) q
	. ;
	. s continue=$$node(id,k,v,.bbox,1) i 'continue s id="" q
	;
	i 'continue q 0
	q 1
	
	
node(nodeId,k,v,bbox,relations)	; Add node and all it's relations to workfile
	;
	n relationId,continue
	;
	i $d(^temp($j,"node",nodeId)) q 1
	i 'gOrderedNodes w $$xml^node(indent,nodeId,gNodeElements)
	s ^temp($j,"node",nodeId)=""
	;
	s continue=$$elementCounter i 'continue q 0
	;
	; Optionally select any relations that belong to this node
	s relationId=""
	i relations f  d  i relationId="" q
	. s relationId=$o(^relationMx("node",nodeId,relationId)) i relationId="" q
	. i $d(^temp($j,"relation",relationId)) q
	. s ^temp($j,"relation",relationId)=""
	. s continue=$$elementCounter i 'continue s relationId="" q
	;
	i 'continue q 0
	q 1
	
	
elementCounter()	; Private ; Count number of elements selected and abort if limit exceeded
	;
	s gCount=gCount+1 i gCount>9999999 q 0 ; Abort
	i gCount#100=0 d
	. s ^log(logId,"count")=gCount
	. i gCount=5000 d renice(5)
	. i gCount=50000 d renice(10)
	. i gCount=500000 d renice(15)
	. ;
	. ; Pause to allow quick queries to complete
	. i gCount>500,gCount#500=0 h 2
	. i gCount>5000,gCount#100=0 h 4
	. i gCount>50000,gCount#100=0 h 8
	q 1
	
	
elementWay(k,v,qsItem,bbox)	; Process a single quadtree
	;
	n id,continue
	;
	s continue=1
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
	. ; Does way satisfy all predicates
	. i '$$wayPredicates(id,.constraint) q
	. ;
	. ; Check that the way is actually within the bounding box
	. i '$$wayInBox(id,.bbox) q
	. ;
	. s continue=$$way(id,k,v,.bbox,1) i 'continue s id="" q
	;
	i 'continue q 0
	q 1
	
	
way(wayId,k,v,bbox,relations)	; Add way and all it's nodes and relations to workfile
	;
	n ndSeq,nodeId,relationId
	;
	; Has the way already been selected?
	i $d(^temp($j,"way",wayId)) q 1
	s ^temp($j,"way",wayId)=""
	;
	s continue=$$elementCounter i 'continue q 0
	;
	; Add all nodes that belong to this way
	s ndSeq=""
	f  d  i ndSeq="" q
	. s ndSeq=$o(^way(wayId,ndSeq)) i ndSeq="" q
	. s nodeId=^way(wayId,ndSeq)
	. i $d(^temp($j,"node",nodeId)) q
	. i 'gOrderedNodes w $$xml^node(indent,nodeId,gNodeElements) 
	. s ^temp($j,"node",nodeId)=""
	. s continue=$$elementCounter i 'continue s ndSeq="" q
	. ;
	. ; Optionally select any relations that belong to this node
	. s relationId=""
	. i relations f  d  i relationId="" q
	. . s relationId=$o(^relationMx("node",nodeId,relationId)) i relationId="" q
	. . i $d(^temp($j,"relation",relationId)) q
	. . s ^temp($j,"relation",relationId)=""
	. . s continue=$$elementCounter i 'continue s relationId="" q
	;
	i 'continue q 0
	;
	; Optionally, add all relations that belong to this way
	s relationId=""
	i relations f  d  i relationId="" q
	. s relationId=$o(^relationMx("way",wayId,relationId)) i relationId="" q
	. i $d(^temp($j,"relation",relationId)) q
	. s ^temp($j,"relation",relationId)=""
	. s continue=$$elementCounter i 'continue s relationId="" q
	;
	i 'continue q 0
	q 1
	
	
elementRelation(k,v,qsItem,bbox)	; Process a single quadtree
	;
	n id,continue
	;
	s continue=1
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
	. ; Does relation satisfy all predicates
	. i '$$relationPredicates(id,.constraint) q
	. ;
	. ; Check that the way is actually within the bounding box
	. i '$$relationInBox(id,.bbox) q
	. s continue=$$relation(id,k,v,.bbox) i 'continue s id="" q
	;
	i 'continue q 0
	q 1
	
	
relation(relationId,k,v,bbox)	; Add relation and all it's constituent elements to workfile
	;
	n seq,type,ref,continue
	;
	; Has the relation already been selected?
	i $d(^temp($j,"relation",relationId)) q 1
	s ^temp($j,"relation",relationId)=""
	s continue=$$elementCounter i 'continue q 0
	;
	; Add all elements that belong to this relation
	s seq=""
	f  d  i seq="" q
	. s seq=$o(^relation(relationId,"seq",seq)) i seq="" q
	. s ref=$g(^relation(relationId,"seq",seq,"ref"))
	. s type=$g(^relation(relationId,"seq",seq,"type"))
	. ;
	. ; If it's a relation then add the relation recursively
	. i type="relation" s continue=$$relation(ref,k,v,.bbox) i 'continue s seq="" q
	. ;
	. ; If it's a node then add the node, but not the node's relations
	. i type="node" s continue=$$node(ref,k,v,.bbox,0) i 'continue s seq="" q
	. ;
	. ; If it's a way then add the way's nodes, but not its relations
	. i type="way" s continue=$$way(ref,k,v,.bbox,0) i 'continue s seq="" q
	;
	i 'continue q 0
	q 1
	
	
nodeInBox(qsItem,nodeId,bbox)	 ; Is a node within the bbox?
	;
	n lat,lon,latlon
	;
	; Coarse check, is the item within the qsBox of the bbox?
	; If it isn't then it is definitely not in the bbox.
	i $e(qsItem,1,$l(bbox("root")))'=bbox("root") q 0
	;
	; Precise check
	s latlon=$g(^e(qsItem,"n",nodeId,"l")) i latlon="" q 0
	s lat=$p(latlon,$c(1),1)
	i lat<bbox("bllat") q 0
	i lat>bbox("trlat") q 0
	;
	s lon=$p(latlon,$c(1),2)
	i lon<bbox("bllon") q 0
	i lon>bbox("trlon") q 0
	q 1
	
	
wayInBox(wayId,bbox)	; Is a way within the bbox?
	; Stop looking as soon as we find one node that is actually within the bbox
	;
	n wayInBox,ndSeq,nodeId
	;
	; Coarse check, does the qsBox of the way overlap with the qsBox of the bbox
	; If it doesn't then the way cannot be in the bbox.
	i '$$qsOverlap(^way(wayId),bbox("root")) q 0
	; 
	s wayInBox=0
	s ndSeq=""
	f  d  i ndSeq="" q
	. s ndSeq=$o(^way(wayId,ndSeq)) i ndSeq="" q
	. s nodeId=^way(wayId,ndSeq) 
	. i $$nodeInBox($$qsBox^node(nodeId),nodeId,.bbox) s wayInBox=1,ndSeq="" q
	;
	q wayInBox
	
	
qsOverlap(qsBox1,qsBox2)	; Do two qsBoxes overlap?
	;
	i qsBox1=qsBox2 q 1
	i $l(qsBox1)>$l(qsBox2),$e(qsBox1,1,$l(qsBox2))=qsBox2 q 1
	i $l(qsBox2)>$l(qsBox1),$e(qsBox2,1,$l(qsBox1))=qsBox1 q 1
	q 0
	
	
relationInBox(relationId,bbox)	; Is a relation within the bbox?
	;
	; Iterate through all elements of the relation and test whether any of them
	; are in the bbox.  It only needs one.
	;
	n ok,seq,ref,type
	;
	s ok=0
	s seq=""
	f  d  i seq="" q
	. s seq=$o(^relation(relationId,"seq",seq)) i seq="" q
	. s ref=$g(^relation(relationId,"seq",seq,"ref"))
	. s type=$g(^relation(relationId,"seq",seq,"type"))
	. ;
	. ; If it's a relation, then check that recursively
	. i type="relation",$$relationInBox(ref,.bbox) s ok=1,seq="" q
	. ;
	. ; If it's a node then check if it's in the box
	. i type="node",$$nodeInBox($$qsBox^node(ref),ref,.bbox) s ok=1,seq="" q
	. ;
	. ; If it's a way then check if it's in the box
	. i type="way",$$wayInBox(ref,.bbox) s ok=1,seq="" q
	;
	i ok q 1
	q 0
	
	
nodePredicates(qsItem,id,constraint)	; Check whether a node satisfies all predicates
	;
	n keyOk,valueOk,keySeq,cKey,cValue,key,u,value,i,j
	;
	; Need to get a match on all keys
	s keyOk=1
	s keySeq=1 ; Skip first constraint as that must already be satisfied
	f  d  i keySeq="" q
	. s keySeq=$o(constraint("kv",keySeq)) i keySeq="" q
	. s cKey=constraint("kv",keySeq,"key")
	. s cValue=constraint("kv",keySeq,"value")
	. ;
	. ; For this key constraint check whether any values match
	. s valueOk=0
	. f i=1:1:$l(cKey,BAR) s key=$p(cKey,BAR,i) d  i valueOk=1 q
	. . ;
	. . s u=^keyx(key) ; TODO: do this earlier, maybe make constraint("uv",...) also what if key="@timestamp" need a solution...
	. . ;
	. . ; Need to match any one of the alternate values
	. . f j=1:1:$l(cValue,BAR) s value=$p(cValue,BAR,j) d  i valueOk q
	. . . i value=$g(^e(qsItem,"n",id,"t",key)) s valueOk=1 q
	. . . i value=ASTERISK,$d(^e(qsItem,"n",id,"t",key)) s valueOk=1 q
	. . . i value=$g(^e(qsItem,"n",id,"u",u)) s valueOk=1 q
	. . . i value=ASTERISK,$d(^e(qsItem,"n",id,"u",u)) s valueOk=1 q
	. i 'valueOk s keyOk=0,cKey="" q
	;
	q keyOk
	
	
wayPredicates(id,constraint)	; Check whether a way satisfies all predicates
	;
	n keyOk,valueOk,keySeq,cKey,cValue,key,value,i,j
	;
	; Need to get a match on all keys
	s keyOk=1
	s keySeq=1 ; Skip first constraint as that must already be satisfied
	f  d  i keySeq="" q
	. s keySeq=$o(constraint("kv",keySeq)) i keySeq="" q
	. s cKey=constraint("kv",keySeq,"key")
	. s cValue=constraint("kv",keySeq,"value")
	. ;
	. ; For this key constraint check whether any values match
	. s valueOk=0
	. f i=1:1:$l(cKey,BAR) s key=$p(cKey,BAR,i) d  i valueOk=1 q
	. . ;
	. . ; Need to match any one of the alternate values
	. . f j=1:1:$l(cValue,BAR) s value=$p(cValue,BAR,j) d  i valueOk q
	. . . i value=$g(^waytag(id,key)) s valueOk=1 q
	. . . i value=ASTERISK,$d(^waytag(id,key)) s valueOk=1 q
	. i 'valueOk s keyOk=0,cKey="" q
	;
	q keyOk
	
	
relationPredicates(id,constraint)	; Check whether a way satisfies all predicates
	;
	n keyOk,valueOk,keySeq,cKey,cValue,key,value,i,j
	;
	; Need to get a match on all keys
	s keyOk=1
	s keySeq=1 ; Skip first constraint as that must already be satisfied
	f  d  i keySeq="" q
	. s keySeq=$o(constraint("kv",keySeq)) i keySeq="" q
	. s cKey=constraint("kv",keySeq,"key")
	. s cValue=constraint("kv",keySeq,"value")
	. ;
	. ; For this key constraint check whether any values match
	. s valueOk=0
	. f i=1:1:$l(cKey,BAR) s key=$p(cKey,BAR,i) d  i valueOk=1 q
	. . ;
	. . ; Need to match any one of the alternate values
	. . f j=1:1:$l(cValue,BAR) s value=$p(cValue,BAR,j) d  i valueOk q
	. . . i value=$g(^relationtag(id,key)) s valueOk=1 q
	. . . i value=ASTERISK,$d(^relationtag(id,key)) s valueOk=1 q
	. i 'valueOk s keyOk=0,cKey="" q
	;
	q keyOk
	
	
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
	
	
fixApostrophe(string)	; Private ; Temporarily fix up apostrophes until the data is all fixed
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
	
	
renice(nice)	; Private ; Increase the niceness of this process
	;
	zsystem "renice +"_nice_" -p "_$j_" >/dev/null"
	q
	
	
decodeKVs(constraint)	; Private ; Decode key/value constraints
	;
	n request,keySeq,key,value
	;
	s request=""
	s keySeq=""
	f  d  i keySeq="" q
	. s keySeq=$o(constraint("kv",keySeq)) i keySeq="" q
	. s key=constraint("kv",keySeq,"key")
	. s value=constraint("kv",keySeq,"value")
	. s request=request_"["_$$decode(key)_"="_$$decode(value)_"]"
	;
	q request
	
	
decode(string)	; Public ; Decode a query string
	q $tr(string,EQUALS_LEFTBRACKET_RIGHTBRACKET_BAR_SLASH_ASTERISK,"=[]|/*")
	
	
encode(string)	; Public ; Encode a query string
	q $tr(string,"=[]|/*",EQUALS_LEFTBRACKET_RIGHTBRACKET_BAR_SLASH_ASTERISK)
	
	
osm(indent)	; Public ; Generate <osm> element
	;
	; Note: We need to keep the headers all on one line as t@h can't cope
	;       with a multi-line header.  It assumes just one line.
	; 
	w indent,"<osm"
	w $$attribute^osmXml("version","0.6",indent)
	w $$attribute^osmXml("generator","FOSM API 0.6",indent)
	w $$attribute^osmXml("copyright",$e(^osmPlanet("date"),1,4)_" FOSM contributors, OpenStreetMap contributors",indent)
	w $$attribute^osmXml("attribution","http://www.fosm.org/attribution",indent)
	w $$attribute^osmXml("license","Creative commons CC-BY-SA 2.0",indent)
	w indent,">",$c(13,10)
	;
	q
	
osmChange(indent)	; Public ; Generate <osmChange> element
	;
	; Note: We need to keep the headers all on one line as t@h can't cope
	;       with a multi-line header.  It assumes just one line.
	; 
	w indent,"<osmChange"
	w $$attribute^osmXml("version","0.6",indent)
	w $$attribute^osmXml("generator","FOSM API 0.6",indent)
	w $$attribute^osmXml("copyright",$e(^osmPlanet("date"),1,4)_" FOSM contributors, OpenStreetMap contributors",indent)
	w $$attribute^osmXml("attribution","http://www.fosm.org/attribution",indent)
	w $$attribute^osmXml("license","Creative commons CC-BY-SA 2.0",indent)
	w indent,">",$c(13,10)
	;
	q
	
	
logStart(request,qsRoot)	; Public ; Log the start of a query
	;
	n logId
	;
	l +^log
	s logId=$g(^log)+1
	s ^log=logId
	l -^log
	;
	s ^log(logId,"start")=$h
	s ^log(logId,"pid")=$j
	s ^log(logId,"ip")=$g(%ENV("REMOTE_ADDR"))
	s ^log(logId,"userAgent")=$g(%ENV("HTTP_USER_AGENT"))
	;
	s ^log(logId,"request")=request
	s ^log(logId,"qs")=qsRoot
	;
	q logId
	
	
logEnd(logId,count,error)	; Public ; Log the end of a query
	;
	n start,end
	;
	s ^log(logId,"count")=count
	s ^log(logId,"end")=$h
	i error'="" s ^log(logId,"error")=error
	;
	; Calculate duration
	s start=^log(logId,"start")
	s end=^log(logId,"end")
	s start=$p(start,",",1)*86400+$p(start,",",2)
	s end=$p(end,",",1)*86400+$p(end,",",2)
	s ^log(logId,"duration")=end-start
	;
	; Update munin counts
	l +^munin
	s ^munin("apiCalls")=$g(^munin("apiCalls"))+1
	s ^munin("responseTotal")=$g(^munin("responseTotal"))+^log(logId,"duration")
	l -^munin
	q
	
