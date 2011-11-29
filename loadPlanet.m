loadPlanet	     ; Load from planet.osm
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
	
	
	; Loads nodes and segments from a planet.osm.  Replaces any existing nodes and segments
	; Deletes any nodes and segments that are not in planet.osm.
	
	d add("all")
	;d delete
	q
	
loadNodes	d add("node")
	q
	
loadWays	d add("way")
	q
	
loadRelations	d add("relation")
	q
	
	
add(session)	    ; Look for things that need to be added
	;
	n q,ccyymmdd
	n sPipe,line
	n gNodeCount,gNodeAdd,gNodeModified
	n gWayCount,gWayAdd,gWayModified
	n gRelCount,gRelAdd,gRelModified
	n gNodeUser
	;
	s q=""""
	s gNodeCount=0
	s gNodeAdd=0 ; Count of missing nodes added
	s gNodeModified=0 ; Count of nodes added that had different timestamps
	s gWayCount=0
	s gWayAdd=0 ; Count of missing ways added
	s gWayModified=0 ; Count of ways added that had different timestamps
	s gRelCount=0
	s gRelAdd=0 ; Count of missing ways added
	s gRelModified=0 ; Count of ways added that had different timestamps
	s gNodeUser=0
	;
	;k ^loadPlanet("element","node")
	;k ^loadPlanet("element","way")
	;k ^loadPlanet("element","relation")
	k ^loadPlanet(session)
	;
	s ^loadPlanet(session,"start")=$h
	s ^loadPlanet(session,"pid")=$j
	;
	;
	; Read the file
	s pipename="planet.pipe"
	i session="node" s pipename="node.pipe"
	i session="way" s pipename="way.pipe"
	i session="relation" s pipename="relation.pipe"
	d openPipe^stream(.sPipe,pipename)
	s line=$$read^stream(.sPipe) ; prolog
	s line=$$read^stream(.sPipe) ; <osm...>
	;
	f  d  i line="</osm>" q
	. s line=$$read^stream(.sPipe)
	. i sPipe("recordCount")#100000=0 d
	. . s ^loadPlanet(session,"currentLineCount")=sPipe("recordCount")
	. . s ^loadPlanet(session,"currentNodeCount")=gNodeCount
	. . s ^loadPlanet(session,"currentNodesAdded")=gNodeAdd
	. . s ^loadPlanet(session,"currentNodesModified")=gNodeModified
	. . s ^loadPlanet(session,"currentWayCount")=gWayCount
	. . s ^loadPlanet(session,"currentWaysAdded")=gWayAdd
	. . s ^loadPlanet(session,"currentWaysModified")=gWayModified
	. . s ^loadPlanet(session,"currentRelCount")=gRelCount
	. . s ^loadPlanet(session,"currentRelationsAdded")=gRelAdd
	. . s ^loadPlanet(session,"currentRelationsModified")=gRelModified
	. . s ^loadPlanet(session,"currentNodeUser")=gNodeUser
	. i line["<node" s gNodeCount=gNodeCount+1 i (session="all")!(session="node") d addNode q
	. i line["<way" s gWayCount=gWayCount+1 i (session="all")!(session="way") d addWay q
	. i line["<relation" s gRelCount=gRelCount+1 i (session="all")!(session="relation") d addRelation q
	;
	s ^loadPlanet(session,"end")=$h
	s ^loadPlanet(session,"totalLines")=sPipe("recordCount")
	s ^loadPlanet(session,"totalNodes")=gNodeCount
	s ^loadPlanet(session,"nodesAdded")=gNodeAdd
	s ^loadPlanet(session,"nodesModified")=gNodeModified
	s ^loadPlanet(session,"totalWays")=gWayCount
	s ^loadPlanet(session,"waysAdded")=gWayAdd
	s ^loadPlanet(session,"waysModified")=gWayModified
	s ^loadPlanet(session,"totalRelations")=gRelCount
	s ^loadPlanet(session,"relationsAdded")=gRelAdd
	s ^loadPlanet(session,"relationsModified")=gRelModified
	s ^loadPlanet(session,"duration")=$p(^loadPlanet(session,"end"),",",2)-$p(^loadPlanet(session,"start"),",",2)
	;
	d close^stream(.sPipe)
	;
	q
	
	
addNode	; Private ; Check for nodes that need to be added
	;
	n id,user,oldUser,timestamp,oldTimestamp
	n usersExists,users
	;
	s id=$p($p(line,"id="_q,2),q,1)
	i id="" q
	;
	; ; Patch to add version tag
	; ; **********************************
	; i '$d(^node(id)) q
	; i $d(^nodetag(id,"@version")) q
	; s gNodeAdd=gNodeAdd+1
	; s lat=$p(^node(id),$c(0),1),lon=$p(^node(id),$c(0),2)
	; s version=$p($p(line,"version=""",2),"""",1) i version="" q
	; s ^nodetag(id,"@version")=version
	; s ^count("node","@version","*")=$g(^count("node","@version","*"))+1
	; s ^count("node","@version",version)=$g(^count("node","@version",version))+1
	; s qsBox=$$llToQs^quadString(lat,lon)
	; s ^nodex("@version",version,qsBox,id)=""
	; s ^nodex("@version","*",qsBox,id)=""
	; s ^nodex("*",version,qsBox,id)=""
	; i line["/>" q
	; ;
	; f  d  i line["</node>" q
	; . s line=$$read^stream(.sPipe)
	; q
	; ;
	; ; **********************************
	s timestamp=$p($p(line,"timestamp="_q,2),q,1)
	; s ^loadPlanet("element","node",id)=timestamp
	i '$d(^nodeVersion(id)) s gNodeAdd=gNodeAdd+1 d add^node(.sPipe) q
	;
	s qsBox=$$qsBox^node(id)
	s oldTimestamp=$p($g(^e(qsBox,"n",id,"a")),$c(1),3)
	i oldTimestamp="" s oldTimestamp=$g(^e(qsBox,"n",id,"t","@timestamp"))
	i $$toNumber^date(timestamp)>$$toNumber^date(oldTimestamp) s gNodeModified=gNodeModified+1 d add^node(.sPipe) q
	;
	i line["/>" q
	;
	f  d  i line["</node>" q
	. s line=$$read^stream(.sPipe)
	q
	
	
addWay	 ; Private ; Check for ways that need to be added
	;
	n id,timestamp,oldTimestamp
	;
	s id=$p($p(line,"id="_q,2),q,1)
	i id="" q
	;
	; ; Patch to add version tag
	; ; **********************************
	; i '$d(^way(id)) q
	; i $d(^waytag(id,"@version")) q
	; s gWayAdd=gWayAdd+1
	; s version=$p($p(line,"version=""",2),"""",1) i version="" q
	; s ^waytag(id,"@version")=version
	; s ^count("way","@version","*")=$g(^count("way","@version","*"))+1
	; s ^count("way","@version",version)=$g(^count("way","@version",version))+1
	; s qsBox=^way(id)
	; s ^wayx("@version",version,qsBox,id)=""
	; s ^wayx("@version","*",qsBox,id)=""
	; s ^wayx("*",version,qsBox,id)=""
	; i line["/>" q
	; ;
	; f  d  i line["</way>" q
	; . s line=$$read^stream(.sPipe)
	; q
	; ;
	; ; **********************************
	s timestamp=$p($p(line,"timestamp="_q,2),q,1)
	;s ^loadPlanet("element","way",id)=timestamp
	i '$d(^way(id)) s gWayAdd=gWayAdd+1 d add^way(.sPipe) q
	;
	s oldTimestamp=$g(^waytag(id,"@timestamp"))
	i $$toNumber^date(timestamp)>$$toNumber^date(oldTimestamp) s gWayModified=gWayModified+1 d add^way(.sPipe) q
	;
	i line["/>" q
	;
	f  d  i line["</way>" q
	. s line=$$read^stream(.sPipe)
	q
	
	
addRelation	    ; Private ; Check for relations that need to be added
	;
	n id,timestamp,oldTimestamp
	;
	s id=$p($p(line,"id="_q,2),q,1)
	i id="" q
	;
	; ; Patch to add version tag
	; ; **********************************
	; i '$d(^relation(id)) q
	; i $d(^relationtag(id,"@version")) q
	; s gRelAdd=gRelAdd+1
	; s version=$p($p(line,"version=""",2),"""",1) i version="" q
	; s ^relationtag(id,"@version")=version
	; s ^count("relation","@version","*")=$g(^count("relation","@version","*"))+1
	; s ^count("relation","@version",version)=$g(^count("relation","@version",version))+1
	; s qsBox=^relation(id)
	; s ^relationx("@version",version,qsBox,id)=""
	; s ^relationx("@version","*",qsBox,id)=""
	; s ^relationx("*",version,qsBox,id)=""
	; i line["/>" q
	; ;
	; f  d  i line["</relation>" q
	; . s line=$$read^stream(.sPipe)
	; q
	; ;
	; ; **********************************
	s timestamp=$p($p(line,"timestamp="_q,2),q,1)
	;s ^loadPlanet("element","relation",id)=timestamp
	i '$d(^relation(id)) s gRelAdd=gRelAdd+1 d add^relation(.sPipe) q
	;
	s oldTimestamp=$g(^relationtag(id,"@timestamp"))
	i $$toNumber^date(timestamp)>$$toNumber^date(oldTimestamp) s gRelModified=gRelModified+1 d add^relation(.sPipe) q
	;
	i line["/>" q
	;
	f  d  i line["</relation>" q
	. s line=$$read^stream(.sPipe)
	q
	
	
delete	 ; Check for deletions
	;
	n planetDate
	n itemCount,deleteCount,id,itemDate,date
	;
	w !,"Planet date ccyymmdd: " r planetDate i planetDate'?8n q
	w !
	;
	; Delete nodes
	s itemCount=0,deleteCount=0
	s id=""
	f  d  i id="" q
	. s id=$o(^nodeVersion(id)) i id="" q
	. s itemCount=itemCount+1 i itemCount#1000000=0 w "#"
	. i $d(^loadPlanet("element","node",id)) q
	. s itemDate=$p($g(^e($$qsBox^node(id),"n",id,"a")),$c(1),3)
	. i itemDate="" s itemDate=$g(^e($$qsBox^node(id),"n",id,"t","@timestamp"))
	. i itemDate="" q
	. s date=$tr($e(itemDate,1,10),"-","")
	. i date<planetDate d delete^node(id) s deleteCount=deleteCount+1 i deleteCount#1000=0 w "."
	;
	w !,"Nodes:     ",itemCount," items checked, ",deleteCount," items deleted."
	;
	; Delete ways
	s itemCount=0,deleteCount=0
	s id=""
	f  d  i id="" q
	. s id=$o(^waytag(id)) i id="" q
	. s itemCount=itemCount+1 i itemCount#1000000=0 w "#"
	. i $d(^loadPlanet("element","way",id)) q
	. s itemDate=$g(^waytag(id,"@timestamp"))
	. i itemDate="" q
	. s date=$tr($e(itemDate,1,10),"-","")
	. i date<planetDate d delete^way(id) s deleteCount=deleteCount+1 i deleteCount#1000=0 w "."
	;
	w !,"Ways:      ",itemCount," items checked, ",deleteCount," items deleted."
	;
	; Delete relations
	s itemCount=0,deleteCount=0
	s id=""
	f  d  i id="" q
	. s id=$o(^relationtag(id)) i id="" q
	. s itemCount=itemCount+1 i itemCount#1000000=0 w "#"
	. i $d(^loadPlanet("element","relation",id)) q
	. s itemDate=$g(^relationtag(id,"@timestamp"))
	. i itemDate="" q
	. s date=$tr($e(itemDate,1,10),"-","")
	. i date<planetDate d delete^relation(id) s deleteCount=deleteCount+1 i deleteCount#1000=0 w "."
	;
	w !,"Relations: ",itemCount," items checked, ",deleteCount," items deleted."
	;
	q
