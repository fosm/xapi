way	; Way Class
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
	
	
add(sWay,delete)	; Public ; Add a way
	; #sWay = stream object containing way
	;
	n line,wayId,ndSeq,timestamp,user,uid,version,changeset
	n a,currentUid,blockedByUid
	;
	s line=sWay("current")
	;
	s wayId=$$getAttribute^osmXml(line,"id")
	s version=$$getAttribute^osmXml(line,"version")
	s changeset=$$getAttribute^osmXml(line,"changeset")
	s timestamp=$$getAttribute^osmXml(line,"timestamp")
	s user=$$getAttribute^osmXml(line,"user")
	i user["'" s user=$$xmlEscapeApostrophe(user)
	s uid=$$getAttribute^osmXml(line,"uid")
	;
	;
	; Don't load older versions
	i $g(^waytag(wayId,"@version"))>version d  q
	. ;
	. ; Skip the rest of the element
	. i line["/>" q
	. f  d  i line["</way>" q
	. . s line=$$read^stream(.sWay)
	;
	; Conflict checks
	s currentUid=$g(^waytag(wayId,"@uid"),0)
	s a=version_$c(1)_changeset_$c(1)_timestamp_$c(1)_uid
	;
	; Don't load forked elements
	i $d(^waytag(wayId,"@fork")) d  q
	. ;
	. ; Log conflict
	. d log^conflict("way",wayId,currentUid,a,"Edited in fosm")
	. ;
	. ; Skip the rest of the element
	. i line["/>" q
	. f  d  i line["</way>" q
	. . s line=$$read^stream(.sWay)
	;
	; Don't load edits from blocked users
	i uid'="",$g(^user(uid,"osmImport"))="block" d  q
	. s blockedByUid=$g(^user(uid,"blockedByUid"),uid)
	. ;
	. ; Log conflict
	. d log^conflict("way",wayId,blockedByUid,a,"User #"_uid_" ("_^user(uid,"name")_") blocked by "_blockedByUid)
	. ;
	. ; Skip the rest of the element
	. i line["/>" q
	. f  d  i line["</way>" q
	. . s line=$$read^stream(.sWay)
	;
	d delete(wayId,changeset,delete)
	;
	;
	; Way attributes
	d setTag(wayId,"@timestamp",timestamp,changeset,version,delete)
	d setTag(wayId,"@user",user,changeset,version,delete)
	d setTag(wayId,"@uid",uid,changeset,version,delete)
	d setTag(wayId,"@version",version,changeset,version,delete)
	d setTag(wayId,"@changeset",changeset,changeset,version,delete)
	i delete d setTag(wayId,"@visible","false",changeset,version,delete)
	;
	; Changeset by version index
	s ^wayVersion(wayId,"v",version)=changeset
	s ^wayVersion(wayId,"c",changeset,version)=""
	;
	; Changeset headers
	s ^c(changeset)=""
	s ^c(changeset,"w",wayId)=""
	s ^c(changeset,"w",wayId,"v",version)=""
	;
	; If there are nodes and/or tags then process these
	i line'["/>" d
	. ;
	. s ndSeq=0
	. ;
	. f  d  i line["</way>" q
	. . s line=$$read^stream(.sWay)
	. . i line["<nd" s ndSeq=ndSeq+1 d nd(wayId,ndSeq,line,changeset,version,delete) q
	. . i line["<tag" d addTag(.sWay,wayId,changeset,version,delete) q
	;
	; Index the tags for this way
	i 'delete d indexTags(wayId)
	;
	; Create export index
	s ^export($$nowZulu^date(),"w",changeset,wayId,version)=""
	;
	; Update user class
	d add^user(uid,user)
	;
	d onEdit^user(uid)
	q
	
	
import(sWay,delete)	; Public ; Import a way, add to changeset only at this point
	; #sWay = stream object containing way
	;
	n line,wayId,ndSeq,timestamp,user,uid,version,changeset
	;
	s line=sWay("current")
	;
	s wayId=$$getAttribute^osmXml(line,"id")
	s version=$$getAttribute^osmXml(line,"version")
	s changeset=$$getAttribute^osmXml(line,"changeset")
	;
	; Update - changeset
	s ^c(changeset)=""
	s ^c(changeset,"w",wayId)=""
	s ^c(changeset,"w",wayId,"v",version)=""
	;
	s timestamp=$$getAttribute^osmXml(line,"timestamp")
	s user=$$getAttribute^osmXml(line,"user")
	i user["'" s user=$$xmlEscapeApostrophe(user)
	s uid=$$getAttribute^osmXml(line,"uid")
	;
	; Update - way attributes
	s visible="" i delete s visible="false"
	s a=version_$c(1)_changeset_$c(1)_timestamp_$c(1)_uid_$c(1)_visible_$c(1)_$c(1)	
	s ^c(changeset,"w",wayId,"v",version,"a")=a
	s ^temp($j,"loadDiff","w",wayId,"a")=a
	;
	; If there are nodes and/or tags then process these
	i line'["/>" d
	. ;
	. s ndSeq=0
	. ;
	. f  d  i line["</way>" q
	. . s line=$$read^stream(.sWay)
	. . i line["<nd" s ndSeq=ndSeq+1 d importNode(wayId,ndSeq,line,changeset,version,delete) q
	. . i line["<tag" d importTag(.sWay,wayId,changeset,version,delete) q
	;
	; Update user class
	d add^user(uid,user)
	;
	d onEdit^user(uid)
	q
	
	
importNode(wayId,ndSeq,line,changeset,version,delete)	; Private ; Load a way node
	;
	n nodeId
	;
	s nodeId=$$getAttribute^osmXml(line,"ref")
	; i nodeId<0 s nodeId=$g(^temp($j,"node",nodeId)) ; Get allocated id from new element map
	;
	s ^c(changeset,"w",wayId,"v",version,"n",ndSeq)=nodeId
	;
	q
	
	
importTag(sWay,wayId,changeset,version,delete)	; Private ; Load a tag and add it
	;
	n k,u,v
	;
	s line=sWay("current")
	i line'["/>" f  d  i line["/>" q
	. s line=line_$$read^stream(.sWay)
	;
	s k=$$getAttribute^osmXml(line,"k") i k="" q
	;
	; Get internal value for the key or assign one
	s u=$g(^keyx(key))
	i u="" d
	. l +^key
	. s (u,^key)=^key+1
	. s ^key(u)=key
	. s ^keyx(key)=u
	. l -^key
	;
	i $l(k)>100 s k=$e(k,1,100)_".."
	s v=$$getAttribute^osmXml(line,"v")
	i v["'" s v=$$xmlEscapeApostrophe(v) ; The planet export doesn't escape apostrophes
	i $l(v)>4000 s v=$e(v,1,4000)_".."
	;
	s ^c(changeset,"w",wayId,"v",version,"u",u)=v
	;
	q
	
	
apply(changeset,wayId,version)	; Public ; Apply a way from a changeset to the active database
	;
	; TODO: This looks rubbish...
	; Where's ^way(id,seq) get updated?
	; Should update first then calculate bbox after all nodes have been added
	; Should not be writing to ^e(qs,"w"...)
	; Other?
	;
	n qsOld,a,delete,qsNew,l
	n u,key,value,intValue
	;
	s qsOld=$p($g(^way(wayId)),$c(1),1)
	;
	s a=^c(changeset,"n",wayId,"v",version,"a")
	s delete=($p(a,$c(1),5)="false")
	d bbox(wayId,.bllat,.bllon,.trlat,.trlon)
	s qsNew=$$bbox^quadString(bllat,bllon,trlat,trlon)
	i qsNew="" s qsNew="*"
	s $p(a,$c(1),6)=qsNew
	;
	; Update - node
	i 'delete d
	. ;
	. ; If the qs key has changed then delete the old entries
	. i qsOld'="",qsOld'=qsNew d
	. . k ^e(qsOld,"w",nodeId,"a")
	. ;
	. ; Update the node with new values
	. s ^e(qsNew,"n",nodeId,"a")=$p(a,$c(1),1,6)
	;
	; Update - changeset by version index
	s ^wayVersion(wayId,"q")=qsNew
	s ^wayVersion(wayId,"v",version)=changeset
	s ^wayVersion(wayId,"c",changeset,version)=""
	;
	; Update process <tag> elements
	s u=""
	f  d  i u="" q
	. s u=$o(^c(changeset,"w",wayId,"v",version,"u",u)) i u="" q
	. s value=^c(changeset,"w",wayId,"v",version,"u",u)
	. d applyTag(qsOld,qsNew,wayId,u,value,changeset,version,delete)
	;
	; Delete all tags that are not on the new version of the way
	s u=""
	i qsOld'="" f  d  i u="" q
	. s u=$o(^e(qsOld,"w",wayId,"u",u)) i u="" q
	. s key=^key(u)
	. i 'delete,$d(^c(changeset,"w",wayId,"v",version,"u",u)) q
	. s value=^e(qsOld,"w",wayId,"u",u)
	. s intValue=value
	. i $l(intValue)>100 s intValue=$e(value,1,100)_".."
	. i intValue'="" k ^wayx(key,intValue,qsOld,wayId)
	. k ^wayx(key,"*",qsOld,wayId)
	. k ^e(qsOld,"w",wayId,"u",u)
	;
	i delete,qsOld'="" k ^e(qsOld,"w",wayId)
	;
	; Create export index
	s ^export($$nowZulu^date(),"w",changeset,wayId,version)=""
	;
	q
	
	
addTagFromChangeset(qsOld,qsNew,nodeId,u,newValue,changeset,version,delete)	; Private ; Update (add/modify/delete) a key/value pair for a node
	;
	; Usage:
	; d updateTag(qsOld,qsNew,nodeId,key,newValue,newChangeset,newVersion,delete)
	;  qsOld        - qs of the old node. Null if this is a new node with no previous version
	;  qsNew        - qs of the new node. Null if this tag is to be deleted
	;  nodeId       - id of the node in question
	;  key          - the tag's key
	;  newValue     - the new value of the tag, may be null
	;  newChangeset - the id of the changeset for this update
	;  newVersion   - the version number of the node being updated
	;  delete       - 1 if the whole node is being deleted, 0 if this is an update
	;
	n key,oldValue,intNewValue,intOldValue
	;
	s key=^key(u)
	;
	s oldValue=""
	i qsOld'="" s oldValue=$g(^e(qsOld,"n",nodeId,"u",u))
	;
	s intNewValue=newValue
	i $l(newValue)>100 s intNewValue=$e(newValue,1,100)_".."
	;
	s intOldValue=oldValue
	i $l(oldValue)>100 s intOldValue=$e(oldValue,1,100)_".."
	;
	; Delete the tag and it's indexes if the node is being deleted
	i delete d
	. ; k ^e(qsOld,"n",nodeId,"u",u) ; Don't actually need to do this becaue the whole node will be deleted anyway
	. i intOldValue'="" k ^nodex(key,intOldValue,qsOld,nodeId)
	. k ^nodex(key,"*",qsOld,nodeId)
	;
	; Add/Update the tag for the element
	e  d
	. i (oldValue'=newValue)!(qsOld'=qsNew) d  ; Optimisation, can be used when all t tags have gone
	. . i qsOld'="",qsOld'=qsNew k ^e(qsOld,"n",nodeId,"u",u)
	. . i qsNew'="" s ^e(qsNew,"n",nodeId,"u",u)=newValue
	. ;
	. ; Update the two key/value indexes
	. i (intOldValue'=intNewValue)!(qsOld'=qsNew) d
	. . i qsOld'="",intOldValue'="" k ^nodex(key,intOldValue,qsOld,nodeId)
	. . i qsNew'="",intNewValue'="" s ^nodex(key,intNewValue,qsNew,nodeId)=""
	. . i qsOld'="" k ^nodex(key,"*",qsOld,nodeId)
	. . i qsNew'="" s ^nodex(key,"*",qsNew,nodeId)=""
	;
	q
	
	
	
	
	
addDiff(sWay,delete,changeset)	; Public ; Add a way
	; #sWay = stream object containing way
	;
	n line,wayId,ndSeq,timestamp,user,uid,version,ok,predecessors
	;
	s line=sWay("current")
	;
	s wayId=$$getAttribute^osmXml(line,"id")
	s timestamp=$$nowZulu^date()
	;
	; New ways
	i wayId<0 d
	. s oldId=wayId
	. l +^id("way")
	. s wayId=^id("way")+1
	. s ^id("way")=wayId
	. l -^id("way")
	. s newId=wayId
	. s version=1
	. ;
	. ; Add to new item map
	. s ^temp($j,"way",oldId)=newId
	;
	; Existing ways
	s ok=1
	e  d  i 'ok q 0
	. s version=$$getAttribute^osmXml(line,"version")
	. ; check version match
	. i $$currentVersion(wayId)'=version d error409^http("Version mismatch: Provided "_version_", server had: "_$$currentVersion(wayId)_" of Way "_wayId) s ok=0 q  ; Version mismatch
	. s oldId=wayId
	. s newId=wayId
	. s version=version+1
	. d delete(wayId,changeset,delete)
	;
	s uid=^c(changeset,"t","@uid")
	s user=^user(uid,"name")
	i user["'" s user=$$xmlEscapeApostrophe(user)
	;
	; Way attributes
	d setTag(wayId,"@timestamp",timestamp,changeset,version,delete)
	d setTag(wayId,"@user",user,changeset,version,delete)
	d setTag(wayId,"@uid",uid,changeset,version,delete)
	d setTag(wayId,"@version",version,changeset,version,delete)
	d setTag(wayId,"@changeset",changeset,changeset,version,delete)
	d setTag(wayId,"@fork",1,changeset,version,delete)
	i delete d setTag(wayId,"@visible","false",changeset,version,delete)
	;
	; Changeset by version index
	s ^wayVersion(wayId,"v",version)=changeset
	s ^wayVersion(wayId,"c",changeset,version)=""
	;
	; Changeset headers
	s ^c(changeset)=""
	s ^c(changeset,"w",wayId)=""
	s ^c(changeset,"w",wayId,"v",version)=""
	;
	; If there are nodes and/or tags then process these
	i line'["/>" d
	. ;
	. s ndSeq=0
	. ;
	. s predecessors=""
	. f  d  i line["</way>" q
	. . s line=$$read^stream(.sWay)
	. . i line["<nd" s ndSeq=ndSeq+1 d nd(wayId,ndSeq,line,changeset,version,delete) q
	. . i line["<tag" d addTag(.sWay,wayId,changeset,version,delete,.predecessors) q
	. ;
	. ; Inject a meta:predecessors tag if there are any predecessors for this version
	. i predecessors'="" d
	. . s k="meta:predecessors"
	. . s v=$e(predecessors,2,$l(predecessors))
	. . i 'delete s ^waytag(wayId,k)=v
	. . s ^c(changeset,"w",wayId,"v",version,"t",k)=v
	;
	;
	; Index the tags for this way
	i 'delete d indexTags(wayId)
	;
	; Create export index (uses the same timestamp as the element just created)
	s ^export(timestamp,"w",changeset,wayId,version)=""
	;
	s rSeq=$g(^response($j))+1
	s ^response($j)=rSeq
	;
	i delete s newId="",version=""
	;
	s ^response($j,rSeq,"oldId")=oldId
	s ^response($j,rSeq,"newId")=newId
	s ^response($j,rSeq,"version")=version
	s ^response($j,rSeq,"element")="way"
	;
	d onEdit^user(uid)
	q 1
	
	
nd(wayId,ndSeq,line,changeset,version,delete)	; Private ; Load a way node
	;
	n nodeId
	;
	s nodeId=$$getAttribute^osmXml(line,"ref")
	i nodeId<0 s nodeId=$g(^temp($j,"node",nodeId)) ; Get allocated id from new element map
	;
	i 'delete s ^way(wayId,ndSeq)=nodeId
	s ^c(changeset,"w",wayId,"v",version,"n",ndSeq)=nodeId
	;
	i 'delete,nodeId'="" s ^wayByNode(nodeId,wayId)=""
	i nodeId'="" s ^nodeVersion(nodeId,"c",changeset,"w",wayId)=""	
	q
	
	
addTag(sWay,wayId,changeset,version,delete,predecessors)	; Private ; Load a tag and add it
	;
	n k,v,i
	;
	s line=sWay("current")
	i line'["/>" f  d  i line["/>" q
	. s line=line_$$read^stream(.sWay)
	;
	s k=$$getAttribute^osmXml(line,"k") i k="" q
	i $l(k)>100 s k=$e(k,1,100)_".."
	s v=$$getAttribute^osmXml(line,"v")
	i v["'" s v=$$xmlEscapeApostrophe(v) ; The planet export doesn't escape apostrophes
	i $l(v)>4000 s v=$e(v,1,4000)_".."
	;
	; Swallow meta:lastEdit tag
	i k="meta:lastEdit" q
	;
	; Process meta:id tag
	; If the meta:id is the same as the element's id then swallow it
	i k="meta:id",v=wayId q
	;
	; If the meta:id is different then it means that the way has been either merged or split
	; In both cases we add the original id value to this way's predecessor list
	i k="meta:id" d  q
	. f i=1:1:$l(v,";") s predecessorId=$p(v,";",i) i predecessorId'=wayId s predecessors=predecessors_";"_predecessorId
	;
	; Swallow any meta:predecessors tags as these apply only to one version
	i k="meta:predecessors" q
	;
	i 'delete s ^waytag(wayId,k)=v
	s ^c(changeset,"w",wayId,"v",version,"t",k)=v
	;
	q
	
	
indexTags(wayId)	; Private ; Create index entries for a single way
	;
	n qsBox,bllat,bllon,trlat,trlon,k,v
	;
	; Calculate the qsRoot for this way
	d bbox(wayId,.bllat,.bllon,.trlat,.trlon)
	s qsBox=$$bbox^quadString(bllat,bllon,trlat,trlon)
	i qsBox="" s qsBox="*"
	;
	s k=""
	f  d  i k="" q
	. s k=$o(^waytag(wayId,k)) i k="" q
	. i k="@xapi:users" q
	. i k="@version" q
	. i k="@timestamp" q
	. i k="@fork" q
	. s v=^waytag(wayId,k)
	. i v="" q
	. i $l(v)>100 s v=$e(v,1,100)_".."
	. s ^wayx(k,v,qsBox,wayId)=""
	. s ^wayx(k,"*",qsBox,wayId)=""
	;
	; Add a quad string index for the way itself
	s ^wayx("*","*",qsBox,wayId)=""
	;
	; Save the qsBox because a node might get moved independently
	s ^way(wayId)=qsBox_$c(1)_bllat_$c(1)_bllon_$c(1)_trlat_$c(1)_trlon
	q
	
	
getTag(wayId,tag)	; Public ; Get the value of a tag for a way
	;
	i wayId="" q ""
	;
	q $g(^waytag(wayId,tag))
	
	
setTag(wayId,k,v,changeset,version,delete)	 ; Private ; Add a tag
	;
	i k="" q
	i 'delete s ^waytag(wayId,k)=v
	s ^c(changeset,"w",wayId,"v",version,"t",k)=v
	;
	q
	
	
xml(indent,wayId,select,meta)	    ; Public ; Generate xml for a way
	;
	n user,uid,timestamp,version,changeset
	n xml
	;
	s xml=""
	;
	i '$$select^osmXml(select,"way") q ""
	;
	s indent=indent_"  "
	;
	s user=$g(^waytag(wayId,"@user"))
	s uid=$g(^waytag(wayId,"@uid"))
	s timestamp=$g(^waytag(wayId,"@timestamp"))
	s version=$g(^waytag(wayId,"@version"))
	s changeset=$g(^waytag(wayId,"@changeset"))
	;
	s xml=indent_"<way"
	s xml=xml_$$attribute^osmXml("id",wayId)
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
	d xmlNodes(wayId,indent,select)
	;
	; Inject meta:id tag
	i $g(meta) d
	. s xml=xml_indent_"<tag k='meta:id' v='"_wayId_"'/>"
	. s xml=xml_indent_"<tag k='meta:lastEdit' v='"_timestamp_"'/>"
	. w xml
	. s xml=""
	;
	d xmlTags(wayId,indent,select)
	s xml=xml_indent_"</way>"_$c(13,10)
	w xml
	s xml=""
	;
	q xml
	
	
xmlNodes(wayId,indent,select)	; Public ; Generate xml for a way's nodes
	;
	n ndSeq,xml
	;
	s xml=""
	;
	i '$$select^osmXml(select,"nd") q ""
	;
	s indent=indent_"  "
	;
	s ndSeq=""
	f  d  i ndSeq="" q
	. s ndSeq=$o(^way(wayId,ndSeq)) i ndSeq="" q
	. s xml=xml_indent_"<nd"
	. s xml=xml_$$attribute^osmXml("ref",^way(wayId,ndSeq))
	. s xml=xml_"/>"_$c(13,10)
	. w xml
	. s xml=""
	q
	
	
xmlTags(id,indent,select)	; Public ; Generate xml for a way's tags
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
	. s k=$o(^waytag(id,k)) i k="" q
	. i $e(k,1)="@" s k="@zzzzzzzzzzzzzzzzzz" q  ; Skip attributes
	. i $d(^waytag(id,k))#10=0 q
	. s xml=xml_indent_"<tag"
	. s xml=xml_$$attribute^osmXml("k",k)
	. s xml=xml_" v='"_^waytag(id,k)_"'" ; Tags are stored as escaped strings
	. s xml=xml_"/>"_$c(13,10)
	. w xml
	. s xml=""
	q
	
	
bbox(wayId,bllat,bllon,trlat,trlon,recalculate)	; Public ; Calculate the bbox for a way
	;
	; Inputs:
	;  recalculate - 0 = used store value if available (default).  The stored value may be wrong if nodes have been moved subsequently.
	;                1 = recalculate from current node locations (slow).
	;
	n ndSeq,nodeId,latlon,lat,lon,qsBox,way
	;	
	s recalculate=$g(recalculate)=1
	;
	; Use previously calculated values if present
	i 'recalculate d  i bllat'="" q
	. s way=$g(^way(wayId))
	. s bllat=$p(way,$c(1),2)
	. s bllon=$p(way,$c(1),3)
	. s trlat=$p(way,$c(1),4)
	. s trlon=$p(way,$c(1),5)
	;
	s bllat=999999,bllon=999999,trlat=-999999,trlon=-999999
	s ndSeq=""
	f  d  i ndSeq="" q
	. s ndSeq=$o(^way(wayId,ndSeq)) i ndSeq="" q
	. s nodeId=^way(wayId,ndSeq)
	. ;
	. ; Ignore if node does not exist (which is possible)
	. s qsBox=$$qsBox^node(nodeId) i qsBox="" q  
	. s latlon=$g(^e(qsBox,"n",nodeId,"l")) i latlon="" q
	. ;
	. s lat=$p(latlon,$c(1),1)
	. s lon=$p(latlon,$c(1),2)
	. i lat>trlat s trlat=lat
	. i lat<bllat s bllat=lat
	. i lon>trlon s trlon=lon
	. i lon<bllon s bllon=lon
	;
	q
	
	
	
	
	
	
delete(wayId,newChangeset,delete)	; Public ; Delete a way
	;
	n bllat,bllon,trlat,trlon,qsBox,ndSeq,nodeId
	n oldChangeset
	n key,value
	;
	s qsBox=$p($g(^way(wayId)),$c(1),1) i qsBox="" q
	;
	; Get changeset of way being deleted
	s oldChangeset=$g(^waytag(wayId,"@changeset"))
	;
	; Delete all tags
	s key=""
	f  d  i key="" q
	. s key=$o(^waytag(wayId,key)) i key="" q
	. s value=^waytag(wayId,key)
	. i value="" q
	. i $l(value)>100 s value=$e(value,1,100)_".."
	. k ^wayx(key,value,qsBox,wayId)
	. k ^wayx(key,"*",qsBox,wayId)
	;
	k ^waytag(wayId)
	;
	; Delete node index
	s ndSeq=""
	f  d  i ndSeq="" q
	. s ndSeq=$o(^way(wayId,ndSeq)) i ndSeq="" q
	. s nodeId=^way(wayId,ndSeq)
	. i nodeId="" q
	. k ^wayByNode(nodeId,wayId)
	. i oldChangeset'="" s ^nodeVersion(nodeId,"c",oldChangeset,"w",wayId)=newChangeset
	;
	; Delete way
	k ^wayx("*","*",qsBox,wayId)
	k ^way(wayId)
	;
	q
	
	
appendUser(users,user)	; Private ; Add user to list of users
	;
	s user=$tr(user,",","") ; Remove commas from name
	;
	i $$contains^string(users,user,",") q $e(users,1,100)
	;
	i users="" s users=user
	e  s users=users_","_user
	q $e(users,1,100)
	
	
xmlEscapeApostrophe(string)	; Private ; Escape apostrophe
	;
	n out,x,c
	;
	s out=""
	f x=1:1:$l(string) d
	. s c=$e(string,x)
	. i "'"[c s out=out_"&apos;" q
	. s out=out_c
	q out
	
	
hasRealTag(id)	; Public ; Does this way have a real tag?
	;
	n hasRealTag,tag
	;
	s hasRealTag=0
	s tag="@zzzzzzzzzzzzzz"
	f  d  i tag="" q
	. s tag=$o(^waytag(id,tag)) i tag="" q
	. s hasRealTag=1,tag=""
	;
	q hasRealTag
	
	
versionAtChangeset(wayId,changeset,wayChangeset,wayVersion)	; Public ; Get the changeset and version that was current at a given changeset time
	;
	; Usage:
	;  d versionAtChangeset^way(wayId,changeset,.wayChangeset,.wayVersion)
	; Output:
	;  wayChangeset - null if not found
	;  wayVersion - null if not found
	;
	s wayChangeset=changeset
	s wayVersion=""
	i '$d(^wayVersion(wayId,"c",wayChangeset)) s wayChangeset=$o(^wayVersion(wayId,"c",wayChangeset),-1) i wayChangeset="" q
	s wayVersion=$o(^wayVersion(wayId,"c",wayChangeset,""),-1) i wayVersion="" s wayChangeset="" q
	;
	q
	
	
restWay(string)	; Public ; Single way query
	;
	n logId
	;
	; Get next step
	s step=$p(string,SLASH,1),string=$p(string,SLASH,2,$l(string))
	s wayId=step
	;
	; Get next step
	s step=$p(string,SLASH,1),string=$p(string,SLASH,2,$l(string))
	;
	; Four choices here:
	; /              - current way only
	; /full          - current way plus current nodes
	; /history       - all versions of current way
	; /#version/full - historic way plus historic nodes
	s full=0
	i step="" s full=0
	i step="full" s full=1
	i step="history" d restWayHistory(wayId) q
	i step?1.n d restWay^wayVersion(wayId,step,string) q
	;
	s logId=$$logStart^xapi($$decode^xapi("way/"_wayId_$s(full:"/full",1:"")),"")
	;
	; Bad query?
	i wayId'?1.n d notFound^http,logEnd^xapi(logId,0,"404 Not found") q
	;
	; Is it there?
	i '$d(^way(wayId)) d gone^http,logEnd^xapi(logId,0,"410 Gone") q
	;
	d header^http("text/xml")
	d xmlProlog^rest("")
	;
	s indent=""
	d osm^xapi(indent)
	;
	k ^temp($j)
	;
	; Add all nodes that belong to this way
	s ndSeq=""
	i full f  d  i ndSeq="" q
	. s ndSeq=$o(^way(wayId,ndSeq)) i ndSeq="" q
	. s nodeId=^way(wayId,ndSeq)
	. i $d(^temp($j,nodeId)) q
	. s ^temp($j,nodeId)=""
	. w $$xml^node(indent,nodeId,"node|@*|tag|") 
	;
	w $$xml(indent,wayId,"way|@*|nd|tag|")
	;
	w indent,"</osm>",$c(13,10)
	;
	d logEnd^xapi(logId,1,"")
	;
	q
	
	
restWays(step,string)	; Public ; Multi way query
	;
	n logId,wayIds,ok,i,wayId,indent,version,changesetId
	;
	s logId=$$logStart^xapi($$decode^xapi(step),"")
	;
	s wayIds=$p(step,EQUALS,2)
	;
	; Validate query
	s ok=1
	f i=1:1:$l(wayIds,",") d  i 'ok q
	. s wayId=$p(wayIds,",",i)
	. i wayId'?1.n d notFound^http,logEnd^xapi(logId,0,"404 Not found") s ok=0 q
	. i '$d(^wayVersion(wayId)) d gone^http,logEnd^xapi(logId,0,"410 Gone") s ok=0 q
	i 'ok q
	;
	d header^http("text/xml")
	d xmlProlog^rest("")
	;
	s indent=""
	d osm^xapi(indent)
	;
	; Use changeset version in case one of the selected versions has been deleted
	f i=1:1:$l(wayIds,",") d
	. s wayId=$p(wayIds,",",i)
	. s version=$o(^wayVersion(wayId,"v",""),-1) i version="" q
	. s changesetId=^wayVersion(wayId,"v",version)
	. w $$xml^wayVersion(indent,wayId,changesetId,version,"way|@*|nd|tag|")
	;
	w indent,"</osm>",$c(13,10)
	;
	d logEnd^xapi(logId,i,"")
	;
	q
	
	
	
restWayHistory(wayId)	; Public ; All versions of way
	;
	n logId,count,indent
	n version,changeset
	;
	s count=0
	s logId=$$logStart^xapi("way/"_wayId_"/history","")
	;
	; Bad query?
	i wayId'?1.n d notFound^http,logEnd^xapi(logId,0,"404 Not found") q
	;
	; Is it there?
	i '$d(^wayVersion(wayId)),$d(^way(wayId)) d  q
	. w "Status: 307 Moved Temporarily",!
	. w "Location: ","http://api.openstreetmap.org/api/0.6/way/"_wayId_"/history",!
	. w !
	i '$d(^wayVersion(wayId)) d notFound^http,logEnd^xapi(logId,0,"404 Not found") q
	;
	d header^http("text/xml")
	d xmlProlog^rest("")
	;
	s indent=""
	d osm^xapi(indent)
	;
	; Iterate all versions
	s version=""
	f  d  i version="" q
	. s version=$o(^wayVersion(wayId,"v",version)) i version="" q
	. s changeset=^wayVersion(wayId,"v",version)
	. ;
	. w $$xml^wayVersion(indent,wayId,changeset,version,"way|@*|nd|tag|")
	. s count=count+1
	;
	w indent,"</osm>",$c(13,10)
	;
	d logEnd^xapi(logId,count,"")
	;
	q
	
	
currentVersion(wayId)	; Public ; Return the current version number of a way
	;
	; Usage: s currentVersion=$$currentVersion^way(wayId)
	; Input:
	;   wayId - way id, must not be null
	; Output:
	;   currentVersion - if the way does not exists then null is returned (if the way has been deleted then the deleted version number is returned)
	;
	n version
	;
	s version=$o(^wayVersion(wayId,"v",""),-1)
	i version="" s version=$g(^waytag(wayId,"@version"))
	q version
	
