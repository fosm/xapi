relation	; Relation Class
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
	
	
	
	
add(sRelation,delete)	 ; Public ; Add a relation
	; #sRelation = stream object containing a relation in osm xml format
	;
	n line,relationId,users,lat,lon,timestamp,user,qsBox,uid,version,changeset
	n bllat,bllon,trlat,trlon
	n currentUid,a,blockedByUid
	;
	s line=sRelation("current")
	;
	s relationId=$$getAttribute^osmXml(line,"id")
	s version=$$getAttribute^osmXml(line,"version")
	s changeset=$$getAttribute^osmXml(line,"changeset")
	s timestamp=$$getAttribute^osmXml(line,"timestamp")
	s user=$$getAttribute^osmXml(line,"user")
	s uid=$$getAttribute^osmXml(line,"uid")
	;
	; Don't load older versions
	i ($g(^relationtag(relationId,"@version"))>version) d  q
	. ;
	. ; Skip the rest of the element
	. i line["/>" q
	. f  d  i line["</relation>" q
	. . s line=$$read^stream(.sRelation)
	;
	; Conflict checks
	s currentUid=$g(^relationtag(relationId,"@uid"),0)
	s a=version_$c(1)_changeset_$c(1)_timestamp_$c(1)_uid
	;
	; Don't load forked elements
	i ($d(^relationtag(relationId,"@fork"))) d  q
	. ;
	. ; Log conflict
	. d log^conflict("relation",relationId,currentUid,a,"Edited in fosm")
	. ;
	. ; Skip the rest of the element
	. i line["/>" q
	. f  d  i line["</relation>" q
	. . s line=$$read^stream(.sRelation)
	;
	; Don't load edits from blocked users
	i uid'="",$g(^user(uid,"osmImport"))="block" d  q
	. s blockedByUid=$g(^user(uid,"blockedByUid"),uid)
	. ;
	. ; Log conflict
	. d log^conflict("relation",relationId,blockedByUid,a,"User #"_uid_" ("_^user(uid,"name")_") blocked by "_blockedByUid)
	. ;
	. ; Skip the rest of the element
	. i line["/>" q
	. f  d  i line["</relation>" q
	. . s line=$$read^stream(.sRelation)
	;
	d delete(relationId,delete)
	;
	d setTag(relationId,"@timestamp",timestamp,changeset,version,delete)
	d setTag(relationId,"@user",user,changeset,version,delete)
	d setTag(relationId,"@uid",uid,changeset,version,delete)
	d setTag(relationId,"@version",version,changeset,version,delete)
	d setTag(relationId,"@changeset",changeset,changeset,version,delete)
	i delete d setTag(relationId,"@visible","false",changeset,version,delete)
	;
	; Changeset by version index
	s ^relationVersion(relationId,"v",version)=changeset
	s ^relationVersion(relationId,"c",changeset,version)=""
	;
	; Changeset headers
	s ^c(changeset)=""
	s ^c(changeset,"r",relationId)=""
	s ^c(changeset,"r",relationId,"v",version)=""
	;
	s sequenceNo=0
	i line'["/>" f  d  i line["</relation>" q
	. s line=$$read^stream(.sRelation)
	. i line["<member" s sequenceNo=sequenceNo+1 d addMember(.sRelation,relationId,sequenceNo,changeset,version,delete)
	. i line["<tag" d addTag(.sRelation,relationId,changeset,version,delete)
	;
	i 'delete d indexTags(relationId)
	;
	; Create export index
	s ^export($$nowZulu^date(),"r",changeset,relationId,version)=""
	;
	; Update user class
	d add^user(uid,user)
	;
	d onEdit^user(uid)
	q
	
	
addDiff(sRelation,delete,changeset)	 ; Public ; Add a relation
	; #sRelation = stream object containing a relation in osm xml format
	;
	n line,relationId,users,lat,lon,timestamp,user,qsBox,uid,version,ok
	n bllat,bllon,trlat,trlon
	;
	s line=sRelation("current")
	;
	s relationId=$$getAttribute^osmXml(line,"id")
	s timestamp=$$nowZulu^date()
	;
	; New relations
	i relationId<0 d
	. s oldId=relationId
	. l +^id("relation")
	. s relationId=^id("relation")+1
	. s ^id("relation")=relationId
	. l -^id("relation")
	. s newId=relationId
	. s version=1
	. ;
	. ; Add to new item map
	. s ^temp($j,"relation",oldId)=newId
	;
	; Existing relations
	s ok=1
	e  d  i 'ok q 0
	. s version=$$getAttribute^osmXml(line,"version")
	. ; check version match
	. i $$currentVersion(relationId)'=version d error409^http("Version mismatch: Provided "_version_", server had: "_$$currentVersion(relationId)_" of Relation "_relationId) s ok=0 q  ; Version mismatch
	. s oldId=relationId
	. s newId=relationId
	. s version=version+1
	. d delete(relationId,delete)
	;
	s uid=^c(changeset,"t","@uid")
	s user=^user(uid,"name")
	i user["'" s user=$$xmlEscapeApostrophe(user)
	;
	d setTag(relationId,"@timestamp",timestamp,changeset,version,delete)
	d setTag(relationId,"@user",user,changeset,version,delete)
	d setTag(relationId,"@uid",uid,changeset,version,delete)
	d setTag(relationId,"@version",version,changeset,version,delete)
	d setTag(relationId,"@changeset",changeset,changeset,version,delete)
	d setTag(relationId,"@fork",1,changeset,version,delete)
	i delete d setTag(relationId,"@visible","false",changeset,version,delete)
	;
	; Changeset by version index
	s ^relationVersion(relationId,"v",version)=changeset
	s ^relationVersion(relationId,"c",changeset,version)=""
	;
	; Changeset headers
	s ^c(changeset)=""
	s ^c(changeset,"r",relationId)=""
	s ^c(changeset,"r",relationId,"v",version)=""
	;
	s sequenceNo=0
	i line'["/>" f  d  i line["</relation>" q
	. s line=$$read^stream(.sRelation)
	. i line["<member" s sequenceNo=sequenceNo+1 d addMember(.sRelation,relationId,sequenceNo,changeset,version,delete)
	. i line["<tag" d addTag(.sRelation,relationId,changeset,version,delete)
	;
	i 'delete d indexTags(relationId)
	;
	; Create export index (uses the same timestamp as the element just created)
	s ^export(timestamp,"r",changeset,relationId,version)=""
	;
	s rSeq=$g(^response($j))+1
	s ^response($j)=rSeq
	;
	i delete s newId="",version=""
	;
	s ^response($j,rSeq,"oldId")=oldId
	s ^response($j,rSeq,"newId")=newId
	s ^response($j,rSeq,"version")=version
	s ^response($j,rSeq,"element")="relation"
	;
	d onEdit^user(uid)
	q 1
	
	
addMember(sRelation,relationId,sequenceNo,changeset,version,delete)	     ; Private ; Add a member to a relation
	;
	n line,type,role,ref
	;
	s line=sRelation("current")
	i line'["/>" f  d  i line["/>" q
	. s line=line_$$read^stream(.sRelation)
	;
	s type=$$getAttribute^osmXml(line,"type") i type="" q
	s role=$$getAttribute^osmXml(line,"role") ; null roles are permitted
	s ref=$$getAttribute^osmXml(line,"ref") i ref="" q
	i ref<0 s ref=$g(^temp($j,type,ref)) ; TODO: This could be a forward reference - if undef then allocate at this point and use when we get to it.
	;
	i type'="" d
	. i 'delete s ^relation(relationId,"seq",sequenceNo,"type")=type
	. s ^c(changeset,"r",relationId,"v",version,"s",sequenceNo,"t")=type
	;
	i ref'="" d
	. i 'delete s ^relation(relationId,"seq",sequenceNo,"ref")=ref
	. s ^c(changeset,"r",relationId,"v",version,"s",sequenceNo,"i")=ref
	;
	i 'delete s ^relation(relationId,"seq",sequenceNo,"role")=role
	s ^c(changeset,"r",relationId,"v",version,"s",sequenceNo,"r")=role
	;
	i 'delete s ^relationMx(type,ref,relationId)=""
	q
	
	
addTag(sRelation,relationId,changeset,version,delete)	   ; Private ; Load a tag and add it
	;
	n line,k,v
	;
	s line=sRelation("current")
	i line'["/>" f  d  i line["/>" q
	. s line=line_$$read^stream(.sRelation)
	;
	s k=$$getAttribute^osmXml(line,"k") i k="" q
	i $l(k)>100 s k=$e(k,1,100)_".."
	s v=$$getAttribute^osmXml(line,"v")
	i v["'" s v=$$xmlEscapeApostrophe(v)
	i $l(v)>4000 s v=$e(v,1,4000)_".."
	d setTag(relationId,k,v,changeset,version,delete)
	q
	
	
setTag(relationId,k,v,changeset,version,delete)	 ; Private ; Add a tag
	;
	i k="" q
	i 'delete s ^relationtag(relationId,k)=v
	s ^c(changeset,"r",relationId,"v",version,"t",k)=v
	q
	
	
getTag(relationId,tag)	 ; Public ; Get the value of a tag for a relation
	;
	i relationId="" q ""
	;
	q $g(^relationtag(relationId,tag))
	
	
indexTags(relationId)	  ; Private ; Create index entries for a single relation
	;
	n k,v
	n bllat,bllon,trlat,trlon
	;
	d bbox(relationId,.bllat,.bllon,.trlat,.trlon)
	s qsBox=$$bbox^quadString(bllat,bllon,trlat,trlon)
	i qsBox="" s qsBox="*"
	;
	; If a relation has no members, then it will not have any spatial extent.  Use # to indicate this.
	i $o(^relation(relationId,""))="" s qsBox="#"
	;
	s k=""
	f  d  i k="" q
	. s k=$o(^relationtag(relationId,k)) i k="" q
	. i k="@xapi:users" q
	. i k="@version" q
	. i k="@timestamp" q
	. i k="@fork" q
	. s v=^relationtag(relationId,k)
	. i $l(v)>100 s v=$e(v,1,100)_".."
	. i v="" q
	. s ^relationx(k,v,qsBox,relationId)=""
	. s ^relationx(k,"*",qsBox,relationId)=""
	;
	s ^relation(relationId)=qsBox_$c(1)_bllat_$c(1)_bllon_$c(1)_trlat_$c(1)_trlon ; Save the qsBox because a member might get moved independently
	s ^relationx("*","*",qsBox,relationId)=""
	;
	q
	
	
xml(indent,relationId,select)	  ; Public ; Generate xml for a relation
	;
	;
	n user,uid,uidUser,timestamp,version,changeset
	n xml
	;
	s xml=""
	;
	i '$$select^osmXml(select,"relation") q ""
	;
	s indent=indent_"  "
	;
	s user=$g(^relationtag(relationId,"@user"))
	s uid=$g(^relationtag(relationId,"@uid"))
	s timestamp=$g(^relationtag(relationId,"@timestamp"))
	s version=$g(^relationtag(relationId,"@version"))
	s changeset=$g(^relationtag(relationId,"@changeset"))
	;
	s xml=indent_"<relation"
	s xml=xml_$$attribute^osmXml("id",relationId)
	s xml=xml_$$attribute^osmXml("visible","true")
	i timestamp'="" s xml=xml_$$attribute^osmXml("timestamp",timestamp)
	i version'="" s xml=xml_$$attribute^osmXml("version",version)
	i changeset'="" s xml=xml_$$attribute^osmXml("changeset",changeset)
	i user'="" s xml=xml_$$attribute^osmXml("user",user)
	i uid'="" s xml=xml_$$attribute^osmXml("uid",uid)
	;
	s xml=xml_">"_$c(13,10)
	w xml
	s xml=""
	;
	d xmlMembers(relationId,indent,select)
	;
	d xmlTags(relationId,indent,select)
	s xml=xml_indent_"</relation>"_$c(13,10)
	w xml
	s xml=""
	;
	q xml
	
	
xmlMembers(wayId,indent,select)	; Public ; Generate xml for a relation's members
	;
	n seq,xml,type,ref,role
	;
	s xml=""
	;
	i '$$select^osmXml(select,"member") q ""
	;
	s indent=indent_"  "
	;
	s seq=""
	f  d  i seq="" q
	. s seq=$o(^relation(relationId,"seq",seq)) i seq="" q
	. s xml=xml_indent_"<member"
	. s type=$g(^relation(relationId,"seq",seq,"type"))
	. s ref=$g(^relation(relationId,"seq",seq,"ref"))
	. s role=$g(^relation(relationId,"seq",seq,"role"))
	. i type'="" s xml=xml_$$attribute^osmXml("type",type)
	. i ref'="" s xml=xml_$$attribute^osmXml("ref",ref)
	. s xml=xml_$$attribute^osmXml("role",role)
	. s xml=xml_"/>"_$c(13,10)
	. w xml
	. s xml=""
	q
	
	
xmlTags(id,indent,select)	      ; Public ; Generate xml for a relation's tags
	;
	n k,xml
	;
	s xml=""
	;
	i '$$select^osmXml(select,"tag") q ""
	;
	s indent=indent_"  "
	;
	s k=""
	f  d  i k="" q
	. s k=$o(^relationtag(id,k)) i k="" q
	. i $e(k,1)="@" s k="@zzzzzzzzzzzzzzzzzz" q  ; Skip attributes
	. i $d(^relationtag(id,k))#10=0 q
	. s xml=xml_indent_"<tag"
	. s xml=xml_$$attribute^osmXml("k",k)
	. s xml=xml_" v='"_^relationtag(id,k)_"'" ; Tags are stored as escaped strings
	. s xml=xml_"/>"_$c(13,10)
	. w xml
	. s xml=""
	q
	
	
bbox(relationId,bllat,bllon,trlat,trlon,parents,recalculate)	; Public ; Get the bbox for a relation
	;
	; Inputs:
	;  recalculate - 0 = used stored value if available (default).  The stored value may be wrong if nodes have been moved subsequently.
	;                1 = recalculate from current node locations (slow).
	;
	n seq,ref,type,relation
	n bllat1,bllon1,trlat1,trlon1
	;
	s recalculate=$g(recalculate)=1
	;
	; Use previously calculated values if present
	i 'recalculate d  i bllat'="" q
	. s relation=$g(^relation(relationId))
	. s bllat=$p(relation,$c(1),2)
	. s bllon=$p(relation,$c(1),3)
	. s trlat=$p(relation,$c(1),4)
	. s trlon=$p(relation,$c(1),5)
	;
	; Create list of parents to handle recursive relations
	s parents=$g(parents)_"|"_relationId
	;
	s bllat=999999,bllon=999999,trlat=-999999,trlon=-999999
	s bllat1=999999,bllon1=999999,trlat1=-999999,trlon1=-999999
	s seq=""
	f  d  i seq="" q
	. s seq=$o(^relation(relationId,"seq",seq)) i seq="" q
	. s ref=$g(^relation(relationId,"seq",seq,"ref"))
	. s type=$g(^relation(relationId,"seq",seq,"type")) i type="" q
	. i type="node" d bbox^node(ref,.bllat1,.bllon1,.trlat1,.trlon1)
	. i type="way" d bbox^way(ref,.bllat1,.bllon1,.trlat1,.trlon1)
	. i type="relation",parents_"|"'[("|"_ref_"|") d bbox^relation(ref,.bllat1,.bllon1,.trlat1,.trlon1,parents,recalculate)
	. i trlat1>trlat s trlat=trlat1
	. i bllat1<bllat s bllat=bllat1
	. i trlon1>trlon s trlon=trlon1
	. i bllon1<bllon s bllon=bllon1
	q
	
	
delete(relationId,delete)	     ; Public ; Delete a relation
	;
	n qsBox
	;
	i relationId="" q
	i '$d(^relation(relationId)) q
	;
	s qsBox=$p($g(^relation(relationId)),$c(1),1)
	;
	d deleteMembers(relationId)
	i qsBox'="" d deleteTags(relationId,qsBox)
	;
	i qsBox'="" k ^relationx("*","*",qsBox,relationId)
	k ^relation(relationId)
	;
	q
	
	
deleteMembers(relationId)	      ; Private ; Delete all members of a relation
	;
	n seq,ref,type
	;
	s seq=""
	f  d  i seq="" q
	. s seq=$o(^relation(relationId,"seq",seq)) i seq="" q
	. s ref=$g(^relation(relationId,"seq",seq,"ref"))
	. s type=$g(^relation(relationId,"seq",seq,"type"))
	. i type'="",ref'="" k ^relationMx(type,ref,relationId)
	. k ^relation(relationId,"seq",seq)
	;
	q
	
	
deleteTags(relationId,qsBox)	   ; Private ; Delete all tags and tag indices for a relation
	;
	n key,value
	;
	s key=""
	f  d  i key="" q
	. s key=$o(^relationtag(relationId,key)) i key="" q
	. s value=^relationtag(relationId,key)
	. i value="" q
	. i $l(value)>100 s value=$e(value,1,100)_".."
	. k ^relationx(key,value,qsBox,relationId)
	. k ^relationx(key,"*",qsBox,relationId)
	;
	k ^relationtag(relationId)
	;
	q
	
	
appendUser(users,user)	 ; Private ; Append a user to a list of users
	;
	s user=$tr(user,",","") ; Remove commas from name
	;
	i $$contains^string(users,user,",") q users
	;
	i users="" s users=user
	e  s users=users_","_user
	q users
	
	
xmlEscapeApostrophe(string)	    ; Private ; Escape apostrophe
	;
	n out,x,c
	;
	s out=""
	f x=1:1:$l(string) d
	. s c=$e(string,x)
	. i "'"[c s out=out_"&apos;" q
	. s out=out_c
	q out
	
	
hasRealTag(id)	  ; Public ; Does this way have a real tag?
	;
	n hasRealTag,tag
	;
	s hasRealTag=0
	s tag="@zzzzzzzzzzzzzzzz"
	f  d  i tag="" q
	. s tag=$o(^relationtag(id,tag)) i tag="" q
	. s hasRealTag=1,tag=""
	;
	q hasRealTag
	
	
versionAtChangeset(relationId,changeset,relationChangeset,relationVersion)	; Public ; Get the changeset and version that was current at a given changeset time
	;
	; Usage:
	;  d versionAtChangeset^relation(relationId,changeset,.relationChangeset,.relationVersion)
	; Output:
	;  relationChangeset - null if not found
	;  relationVersion - null if not found
	;
	s relationChangeset=changeset
	s relationVersion=""
	i '$d(^relationVersion(relationId,"c",relationChangeset)) s relationChangeset=$o(^relationVersion(relationId,"c",relationChangeset),-1) i relationChangeset="" q
	s relationVersion=$o(^relationVersion(relationId,"c",relationChangeset,""),-1) i relationVersion="" s relationChangeset="" q
	;
	q
	
	
restRelation(string)	; Public ; Single relation query
	;
	; Inputs:
	;   string - relationId[ /full | /version/full ]
	;
	n step,relationId,full,logId,indent
	n seq,nodeId,wayId,ndSeq,subRelationId
	n count
	;
	; Get next step
	s step=$p(string,SLASH,1),string=$p(string,SLASH,2,$l(string))
	s relationId=step
	;
	; Get next step
	s step=$p(string,SLASH,1),string=$p(string,SLASH,2,$l(string))
	;
	; Three choices here:
	; /              - current relation only
	; /history       - all versions of relation
	; /full          - current relation plus current members
	; /#version/full - historic way plus historic nodes
	s full=0
	i step="" s full=0
	i step="full" s full=1
	i step="history" d restRelationHistory(relationId) q
	i step?1.n d restRelation^relationVersion(relationId,step,string) q
	;
	k ^temp($j)
	s count=0
	;	
	s logId=$$logStart^xapi("relation/"_relationId_$s(full:"/full",1:""),"")
	;
	; Bad query?
	i relationId'?1.n d notFound^http,logEnd^xapi(logId,0,"404 Not found") q
	;
	; Is it there?
	i '$d(^relation(relationId)) d gone^http,logEnd^xapi(logId,0,"410 Gone") q
	;
	d header^http("text/xml")
	d xmlProlog^rest("")
	;
	s indent=""
	d osm^xapi(indent)
	;
	; Select all nodes that belong to this relation and all nodes that belong to
	; ways that belong to this relation
	s seq=""
	i full f  d  i seq="" q
	. s seq=$o(^relation(relationId,"seq",seq)) i seq="" q
	. ;
	. ; Nodes
	. i ^relation(relationId,"seq",seq,"type")="node" d  q
	. . s nodeId=^relation(relationId,"seq",seq,"ref")
	. . i $d(^temp($j,"node",nodeId)) q
	. . s ^temp($j,"node",nodeId)=""
	. . w $$xml^node(indent,nodeId,"node|@*|tag|")
	. . s count=count+1
	. ;
	. ; Nodes within ways
	. i ^relation(relationId,"seq",seq,"type")="way" d  q
	. . s wayId=^relation(relationId,"seq",seq,"ref")
	. . s ndSeq=""
	. . f  d  i ndSeq="" q
	. . . s ndSeq=$o(^way(wayId,ndSeq)) i ndSeq="" q
	. . . s nodeId=^way(wayId,ndSeq)
	. . . i $d(^temp($j,"node",nodeId)) q
	. . . s ^temp($j,"node",nodeId)=""
	. . . w $$xml^node(indent,nodeId,"node|@*|tag|")
	. . . s count=count+1
	;
	; Select all ways that belong to this relation
	s seq=""
	i full f  d  i seq="" q
	. s seq=$o(^relation(relationId,"seq",seq)) i seq="" q
	. i ^relation(relationId,"seq",seq,"type")'="way" q
	. s wayId=^relation(relationId,"seq",seq,"ref")
	. w $$xml^way(indent,wayId,"way|@*|nd|tag|")
	. s count=count+1
	;
	; Select this relation
	w $$xml(indent,relationId,"relation|@*|member|tag|")
	s count=count+1
	;
	; Select all relations that belong to this relation
	s seq=""
	i full f  d  i seq="" q
	. s seq=$o(^relation(relationId,"seq",seq)) i seq="" q
	. i ^relation(relationId,"seq",seq,"type")'="relation" q
	. s subRelationId=^relation(relationId,"seq",seq,"ref")
	. w $$xml(indent,subRelationId,"relation|@*|member|tag|")
	. s count=count+1
	;
	w indent,"</osm>",$c(13,10)
	;
	d logEnd^xapi(logId,count,"")
	;
	q
	
	
restRelations(step,string)	; Public ; Multi node query
	;
	n logId,relationIds,ok,i,relationId,indent
	;
	s logId=$$logStart^xapi($$decode^xapi(step),"")
	;
	s relationIds=$p(step,EQUALS,2)
	;
	; Validate query
	s ok=1
	f i=1:1:$l(relationIds,",") d  i 'ok q
	. s relationId=$p(relationIds,",",i)
	. i relationId'?1.n d notFound^http,logEnd^xapi(logId,0,"404 Not found") s ok=0 q
	. i '$d(^relation(relationId)) d gone^http,logEnd^xapi(logId,0,"410 Gone") s ok=0 q
	i 'ok q
	;
	d header^http("text/xml")
	d xmlProlog^rest("")
	;
	s indent=""
	d osm^xapi(indent)
	;
	f i=1:1:$l(relationIds,",") w $$xml(indent,$p(relationIds,",",i),"relation|@*|member|tag|")
	;
	w indent,"</osm>",$c(13,10)
	;
	d logEnd^xapi(logId,i,"")
	;
	q
	
	
restRelationHistory(relationId)	; Public ; All versions of relation
	;
	n logId,count,indent
	n version,changeset
	;
	s count=0
	s logId=$$logStart^xapi("relation/"_relationId_"/history","")
	;
	; Bad query?
	i relationId'?1.n d notFound^http,logEnd^xapi(logId,0,"404 Not found") q
	;
	; Is it there?
	i '$d(^relationVersion(relationId)) d notFound^http,logEnd^xapi(logId,0,"404 Not found") q
	;
	d header^http("text/xml")
	d xmlProlog^rest("")
	;
	s indent=""
	d osm^xapi(indent)
	;
	; Iterate all changesets
	s version=""
	f  d  i version="" q
	. s version=$o(^relationVersion(relationId,"v",version)) i version="" q
	. s changeset=^relationVersion(relationId,"v",version)
	. ;
	. w $$xml^relationVersion(indent,relationId,changeset,version,"relation|@*|member|tag|")
	. s count=count+1
	;
	w indent,"</osm>",$c(13,10)
	;
	d logEnd^xapi(logId,count,"")
	;
	q
	
	
currentVersion(relationId)	; Public ; Return the current version number of a relation
	;
	; Usage: s currentVersion=$$currentVersion^relation(relationId)
	; Input:
	;   relationId - relation id, must not be null
	; Output:
	;   currentVersion - if the relation does not exists then null is returned
	;
	n version
	;
	s version=$o(^relationVersion(relationId,"v",""),-1)
	i version="" s version=$g(^relationtag(relationId,"@version"))
	q version
	
