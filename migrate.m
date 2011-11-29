migrate	; Migrate database
	;
	
	
	
wayByNode	;
	;
	n c,nodeId,wayId
	;
	s c=0
	s nodeId="",wayId=""
	f  d  i nodeId="" q
	. s nodeId=$o(^node(nodeId)) i nodeId="" q
	. f  d  i wayId="" q
	. . s wayId=$o(^node(nodeId,wayId)) i wayId="" q
	. . s ^wayByNode(nodeId,wayId)=""
	. . k ^node(nodeId,wayId)
	. . s c=c+1
	. . i c#10000=0 w "."
	w "Complete: ",c," records migrated",!
	q
	
	
nodekv	;
	w "." 
	m ^count("node")=^count("nodekv")
	k ^count("nodekv")
	;
	w "." 
	m ^count("node","@timestamp")=^count("node","osm:timestamp")
	k ^count("node","osm:timestamp")
	;
	w "." 
	m ^count("node","@user")=^count("node","osm:user")
	k ^count("node","osm:user")
	;
	w "." 
	m ^count("node","@xapi:users")=^count("node","osm:users")
	k ^count("node","osm:users")
	;
	w "." 
	m ^nodex("@timestamp")=^nodex("osm:timestamp")
	k ^nodex("osm:timestamp")
	;
	w "." 
	m ^nodex("@user")=^nodex("osm:user")
	k ^nodex("osm:user")
	;
	w "." 
	m ^nodex("@xapi:users")=^nodex("osm:users")
	k ^nodex("osm:users")
	q
	
	
	
waykv	;
	w "."
	m ^count("way")=^count("waykv")
	k ^count("waykv")
	;
	w "."
	m ^count("way","@timestamp")=^count("way","osm:timestamp")
	k ^count("way","osm:timestamp")
	;
	w "."
	m ^count("way","@user")=^count("way","osm:user")
	k ^count("way","osm:user")
	;
	w "."
	m ^count("way","@xapi:users")=^count("way","osm:users")
	k ^count("way","osm:users")
	;
	w "."
	m ^wayx("@timestamp")=^wayx("osm:timestamp")
	k ^wayx("osm:timestamp")
	;
	w "."
	m ^wayx("@user")=^wayx("osm:user")
	k ^wayx("osm:user")
	;
	w "."
	m ^wayx("@xapi:users")=^wayx("osm:users")
	k ^wayx("osm:users")
	q

	
relkv	;
	w "."
	m ^count("relation")=^count("relationkv")
	k ^count("relationkv")
	;
	w "."
	m ^count("relation","@timestamp")=^count("relation","osm:timestamp")
	k ^count("relation","osm:timestamp")
	;
	w "."
	m ^count("relation","@user")=^count("relation","osm:user")
	k ^count("relation","osm:user")
	;
	w "."
	m ^count("relation","@xapi:users")=^count("relation","osm:users")
	k ^count("relation","osm:users")
	;
	w "."
	m ^relationx("@timestamp")=^relationx("osm:timestamp")
	k ^relationx("osm:timestamp")
	;
	w "."
	m ^relationx("@user")=^relationx("osm:user")
	k ^relationx("osm:user")
	;
	w "."
	m ^relationx("@xapi:users")=^relationx("osm:users")
	k ^relationx("osm:users")
	q
	
nodetag	;
	s id="",c=0
	f  d  i id="" q
	. s id=$o(^nodetag(id)) i id="" q
	. i $d(^nodetag(id,"osm:timestamp")) s ^nodetag(id,"@timestamp")=^nodetag(id,"osm:timestamp") k ^nodetag(id,"osm:timestamp")
	. i $d(^nodetag(id,"osm:user")) s ^nodetag(id,"@user")=^nodetag(id,"osm:user") k ^nodetag(id,"osm:user")
	. i $d(^nodetag(id,"osm:users")) s ^nodetag(id,"@xapi:users")=^nodetag(id,"osm:users") k ^nodetag(id,"osm:users")
	. ; i $d(^nodetag(id,"osm:uid")) s ^nodetag(id,"@uid")=^nodetag(id,"osm:uid") k ^nodetag(id,"osm:uid")
	. s c=c+1 i c#1000000=0 w "."
	q
	
	
waytag	;
	s id="",c=0
	f  d  i id="" q
	. s id=$o(^waytag(id)) i id="" q
	. i $d(^waytag(id,"osm:timestamp")) s ^waytag(id,"@timestamp")=^waytag(id,"osm:timestamp") k ^waytag(id,"osm:timestamp")
	. i $d(^waytag(id,"osm:user")) s ^waytag(id,"@user")=^waytag(id,"osm:user") k ^waytag(id,"osm:user")
	. i $d(^waytag(id,"osm:users")) s ^waytag(id,"@xapi:users")=^waytag(id,"osm:users") k ^waytag(id,"osm:users")
	. ; i $d(^waytag(id,"osm:uid")) s ^waytag(id,"@uid")=^waytag(id,"osm:uid") k ^waytag(id,"osm:uid")
	. s c=c+1 i c#1000000=0 w "."
	q
	    
	
reltag	;
	s id="",c=0
	f  d  i id="" q
	. s id=$o(^relationtag(id)) i id="" q
	. i $d(^relationtag(id,"osm:timestamp")) s ^relationtag(id,"@timestamp")=^relationtag(id,"osm:timestamp") k ^relationtag(id,"osm:timestamp")
	. i $d(^relationtag(id,"osm:user")) s ^relationtag(id,"@user")=^relationtag(id,"osm:user") k ^relationtag(id,"osm:user")
	. i $d(^relationtag(id,"osm:users")) s ^relationtag(id,"@xapi:users")=^relationtag(id,"osm:users") k ^relationtag(id,"osm:users")
	. ; i $d(^relationtag(id,"osm:uid")) s ^relationtag(id,"@uid")=^relationtag(id,"osm:uid") k ^relationtag(id,"osm:uid")
	. s c=c+1 i c#1000000=0 w "."
	q


orderedMembers	; Delete all relation data and reload from a planet
	;
	k ^relation
	k ^relationMx
	k ^relationx
	k ^relationtag
	;
	; Now load from a planet file using loadPlanet.m
	q

