node	; Node Class (new structure using ^element instead of ^node and ^nodetag)
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
	
	
	
	; add(sNode,delete)	; Public ; Add a node
	; #sNode = stream object containing node
	;
	n line,nodeId,users,lat,lon,timestamp,user,uid,version,changeset,qsOld
	;
	s line=sNode("current")
	;
	s nodeId=$$getAttribute^osmXml(line,"id")
	s version=$$getAttribute^osmXml(line,"version")
	s changeset=$$getAttribute^osmXml(line,"changeset")
	s qsOld=""
	;
	s currentVersion=0,fork=0
	i $d(^nodeVersion(nodeId,"v")) d 
	. s qsOld=$$qsBox(nodeId)
	. s fork=$p($g(^e(qsOld,"n",nodeId,"a")),$c(1),6)
	;
	i ($$currentVersion(nodeId)>version)!(fork) d  q  ; Don't load older versions
	. ;
	. ; Log conflict
	. s uid=$p($g(^e(qsOld,"n",nodeId,"a")),$c(1),4)
	. i uid="" q
	. ;
	. s seq=$g(^conflict(uid))+1
	. s ^conflict(uid)=seq
	. s ^conflict(uid,seq,"@type")="node"
	. s ^conflict(uid,seq,"@id")=nodeId
	. s ^conflict(uid,seq,"@changeset")=changeset
	. s ^conflict(uid,seq,"@version")=version
	. s ^conflict(uid,seq,"@uid")=$$getAttribute^osmXml(line,"uid")
	. s ^conflict(uid,seq,"@timestamp")=$$getAttribute^osmXml(line,"timestamp")
	. s ^conflict(uid,seq,"@visible")=$s(delete:"false",1:"true")
	. ;
	. ; Skip rest of node element
	. i line["/>" q
	. f  d  i line["</node>" q
	. . s line=$$read^stream(.sNode)
	;
	s lat=$$getAttribute^osmXml(line,"lat")
	s lon=$$getAttribute^osmXml(line,"lon")
	i lon["e" s lon=+$tr(lon,"e","E")
	s qsBox=$$llToQs^quadString(lat,lon)
	;
	; Update - node
	i 'delete d
	. i qsOld'="",qsOld'=qsBox k ^e(qsOld,"n",nodeId,"l")
	. s ^e(qsBox,"n",nodeId,"l")=lat_$c(1)_lon
	;
	; Update - changeset
	i '$d(^c(changeset)) s ^c(changeset)=""
	i '$d(^c(changeset,"n",nodeId)) s ^c(changeset,"n",nodeId)=""
	s ^c(changeset,"n",nodeId,"v",version)=""
	s ^c(changeset,"n",nodeId,"v",version,"l")=lat_$c(1)_lon
	;
	s timestamp=$$getAttribute^osmXml(line,"timestamp")
	s user=$$getAttribute^osmXml(line,"user")
	i user["'" s user=$$xmlEscapeApostrophe(user)
	s uid=$$getAttribute^osmXml(line,"uid")
	;
	; Update - node attributes
	i qsOld'="",qsOld'=qsBox k ^e(qsOld,"n",nodeId,"a")
	s visible="" i delete s visible="false"
	s a=version_$c(1)_changeset_$c(1)_timestamp_$c(1)_uid_$c(1)_visible_$c(1)_$c(1)
	s ^e(qsBox,"n",nodeId,"a")=a
	s ^c(changeset,"n",nodeId,"v",version,"a")=a
	;
	; Update - changeset by version index
	s ^nodeVersion(nodeId,"q")=qsBox
	s ^nodeVersion(nodeId,"v",version)=changeset
	s ^nodeVersion(nodeId,"c",changeset,version)=""
	;
	; Update process <tag> elements
	i line'["/>" f  d  i line'["<tag" q
	. s line=$$read^stream(.sNode)
	. i line["<tag" d sUpdateTag(.sNode,qsOld,qsBox,nodeId,changeset,version,delete)
	;
	; Delete all tags that are not on the new version of the node
	s u=""
	i qsOld'="" f  d  i u="" q
	. s u=$o(^e(qsOld,"n",nodeId,"u",u)) i u="" q
	. s key=^key(u)
	. i 'delete,$d(^c(changeset,"n",nodeId,"v",version,"u",u)) q
	. s value=^e(qsOld,"n",nodeId,"u",u)
	. s intValue=value
	. i $l(intValue)>100 s intValue=$e(value,1,100)_".."
	. i intValue'="" k ^nodex(key,intValue,qsOld,nodeId)
	. k ^nodex(key,"*",qsOld,nodeId)
	. k ^e(qsOld,"n",nodeId,"u",u)
	;
	i delete,qsOld'="" k ^e(qsOld,"n",nodeId)
	;
	; Create export index
	s ^export($$nowZulu^date(),"n",changeset,nodeId,version)=""
	;
	; Update user class
	d add^user(uid,user)
	;
	d onEdit^user(uid)
	q
	
	
import(sNode,delete)	; Public ; Import a node and add it to the changeset
	; #sNode = stream object containing node
	;
	n line,nodeId,version,changeset
	n lat,lon,qsNew,timestamp,user,uid
	n visible,fork,a
	;
	s line=sNode("current")
	;
	s nodeId=$$getAttribute^osmXml(line,"id")
	s version=$$getAttribute^osmXml(line,"version")
	s changeset=$$getAttribute^osmXml(line,"changeset")
	;
	s lat=$$getAttribute^osmXml(line,"lat")
	s lon=$$getAttribute^osmXml(line,"lon")
	i lon["e" s lon=+$tr(lon,"e","E")
	s qsNew=$$llToQs^quadString(lat,lon)
	;
	; Update - changeset
	i '$d(^c(changeset)) s ^c(changeset)=""
	i '$d(^c(changeset,"n",nodeId)) s ^c(changeset,"n",nodeId)=""
	s ^c(changeset,"n",nodeId,"v",version)=""
	s ^c(changeset,"n",nodeId,"v",version,"l")=lat_$c(1)_lon
	;
	s timestamp=$$getAttribute^osmXml(line,"timestamp")
	s user=$$getAttribute^osmXml(line,"user")
	i user["'" s user=$$xmlEscapeApostrophe(user)
	s uid=$$getAttribute^osmXml(line,"uid")
	;
	; Update - node attributes
	s visible="" i delete s visible="false"
	s fork=0
	s a=version_$c(1)_changeset_$c(1)_timestamp_$c(1)_uid_$c(1)_visible_$c(1)_fork_$c(1)_qsNew
	s ^c(changeset,"n",nodeId,"v",version,"a")=a
	s ^temp($j,"loadDiff","n",nodeId,"a")=a
	;
	; Update process <tag> elements
	i line'["/>" f  d  i line'["<tag" q
	. s line=$$read^stream(.sNode)
	. i line["<tag" d sImportTag(.sNode,qsNew,nodeId,changeset,version)
	;	
	; Update user class
	d add^user(uid,user)
	;
	d onEdit^user(uid)
	;
	q
	
	
sImportTag(sNode,qsNew,nodeId,changeset,version)	; Private load a tag and add it to the changeset
	;
	n line,key,value
	;
	s line=sNode("current")
	i line'["/>" f  d  i line["/>" q
	. s line=line_$$read^stream(.sNode)
	;
	s key=$$getAttribute^osmXml(line,"k") i key="" q
	i $l(key)>100 s key=$e(key,1,100)_".."
	s value=$$getAttribute^osmXml(line,"v")
	i value["'" s value=$$xmlEscapeApostrophe(value)
	i $l(value)>4000 s value=$e(value,1,4000)_".."
	;
	d importTag(qsNew,nodeId,key,value,changeset,version)
	q
	
	
importTag(qsNew,nodeId,key,newValue,newChangeset,newVersion)	; Private ; Add key/value pair for a node to the changeset
	;
	; Usage:
	; d updateTag(qsNew,nodeId,key,newValue,newChangeset,newVersion)
	;  qsNew        - qs of the new node. Null if this tag is to be deleted
	;  nodeId       - id of the node in question
	;  key          - the tag's key
	;  newValue     - the new value of the tag, may be null
	;  newChangeset - the id of the changeset for this update
	;  newVersion   - the version number of the node being updated
	;
	n u,intNewValue
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
	s intNewValue=newValue
	i $l(newValue)>100 s intNewValue=$e(newValue,1,100)_".."
	;
	; Add the tag to the node definition in the changeset
	s ^c(newChangeset,"n",nodeId,"v",newVersion,"u",u)=newValue
	;
	q
	
	
addNodeFromChangeset(changeset,nodeId,version)	; Public ; Add a node from a changeset
	;
	n qsOld,a,timestamp,delete,qsNew,l
	n u,key,value,intValue
	;
	s qsOld=$g(^nodeVersion(nodeId,"q"))
	;
	s a=^c(changeset,"n",nodeId,"v",version,"a")
	s timestamp=$p(a,$c(1),3)
	s delete=($p(a,$c(1),5)="false")
	s qsNew=$p(a,$c(1),7)
	s l=^c(changeset,"n",nodeId,"v",version,"l")
	;
	; Old changesets don't have the qs stored on them
	i qsNew="" s qsNew=$$llToQs^quadString($p(l,$c(1),1),$p(l,$c(1),2))
	;
	; Update - node
	i 'delete d
	. ;
	. ; If the qs key has changed then delete the old entries
	. i qsOld'="",qsOld'=qsNew d
	. . k ^e(qsOld,"n",nodeId,"l")
	. . k ^e(qsOld,"n",nodeId,"a")
	. ;
	. ; Update the node with new values
	. s ^e(qsNew,"n",nodeId,"l")=l
	. s ^e(qsNew,"n",nodeId,"a")=$p(a,$c(1),1,6)
	;
	; Update - changeset by version index
	s ^nodeVersion(nodeId,"q")=qsNew
	s ^nodeVersion(nodeId,"v",version)=changeset
	s ^nodeVersion(nodeId,"c",changeset,version)=""
	;
	; Update process <tag> elements
	s u=""
	f  d  i u="" q
	. s u=$o(^c(changeset,"n",nodeId,"v",version,"u",u)) i u="" q
	. s value=^c(changeset,"n",nodeId,"v",version,"u",u)
	. d addTagFromChangeset(qsOld,qsNew,nodeId,u,value,changeset,version,delete)
	;
	; Delete all tags that are not on the new version of the node
	s u=""
	i qsOld'="" f  d  i u="" q
	. s u=$o(^e(qsOld,"n",nodeId,"u",u)) i u="" q
	. s key=^key(u)
	. i 'delete,$d(^c(changeset,"n",nodeId,"v",version,"u",u)) q
	. s value=^e(qsOld,"n",nodeId,"u",u)
	. s intValue=value
	. i $l(intValue)>100 s intValue=$e(value,1,100)_".."
	. i intValue'="" k ^nodex(key,intValue,qsOld,nodeId)
	. k ^nodex(key,"*",qsOld,nodeId)
	. k ^e(qsOld,"n",nodeId,"u",u)
	;
	i delete,qsOld'="" k ^e(qsOld,"n",nodeId)
	;
	; Create export index
	s ^export($$nowZulu^date(),"n",changeset,nodeId,version)=""
	;
	; Update metrics
	i version=1 d update^metric("osmNodeCount",1)
	i delete d update^metric("osmNodeCount",-1)
	d update^metric("osmNodeEdits",1)
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
	
	
	
addDiff(sNode,delete,changeset)	; Public ; Add a node from the diff upload API (not from the OSM import)
	; #sNode = stream object containing node
	;
	n line,nodeId,users,lat,lon,timestamp,user,uid,version,qsOld,ok
	n a,visible,fork
	;
	;
	s line=sNode("current")
	;
	s nodeId=$$getAttribute^osmXml(line,"id")
	s timestamp=$$nowZulu^date()
	;
	; New nodes
	s ok=1
	i nodeId<0 d
	. s oldId=nodeId
	. l +^id("node")
	. s nodeId=^id("node")+1
	. s ^id("node")=nodeId
	. l -^id("node")
	. s newId=nodeId
	. s version=1
	. s qsOld=""
	. ;
	. ; Add to new item map
	. s ^temp($j,"node",oldId)=newId
	;
	; Existing nodes
	e  d  i 'ok q 0
	. s version=$$getAttribute^osmXml(line,"version")
	. ; check version match
	. i $$currentVersion(nodeId)'=version d error409^http("Version mismatch: Provided "_version_", server had: "_$$currentVersion(nodeId)_" of Node "_nodeId) s ok=0 q  ; Version mismatch
	. s oldId=nodeId
	. s newId=nodeId
	. s version=version+1
	. s qsOld=$$qsBox(nodeId)
	;
	s lat=$$getAttribute^osmXml(line,"lat")
	s lon=$$getAttribute^osmXml(line,"lon")
	i lon["e" s lon=+$tr(lon,"e","E")
	s qsBox=$$llToQs^quadString(lat,lon)
	;
	; Update - node
	i 'delete d
	. i qsOld'="",qsOld'=qsBox k ^e(qsOld,"n",nodeId,"l")
	. s ^e(qsBox,"n",nodeId,"l")=lat_$c(1)_lon
	;
	; Update - changeset
	i '$d(^c(changeset)) s ^c(changeset)=""
	i '$d(^c(changeset,"n",nodeId)) s ^c(changeset,"n",nodeId)=""
	s ^c(changeset,"n",nodeId,"v",version)=""
	s ^c(changeset,"n",nodeId,"v",version,"l")=lat_$c(1)_lon
	;
	s uid=$g(^c(changeset,"t","@uid"))
	s user=^user(uid,"name")
	i user["'" s user=$$xmlEscapeApostrophe(user)
	;
	; Update - node attributes
	i qsOld'="",qsOld'=qsBox k ^e(qsOld,"n",nodeId,"a")
	s visible="" i delete s visible="false"
	s fork=1
	s a=version_$c(1)_changeset_$c(1)_timestamp_$c(1)_uid_$c(1)_visible_$c(1)_fork_$c(1)
	s ^e(qsBox,"n",nodeId,"a")=a
	s ^c(changeset,"n",nodeId,"v",version,"a")=a
	;
	; Update - changeset by version index
	s ^nodeVersion(nodeId,"q")=qsBox
	s ^nodeVersion(nodeId,"v",version)=changeset
	s ^nodeVersion(nodeId,"c",changeset,version)=""
	;
	; Process any <tag> elements
	i line'["/>" f  d  i line'["<tag" q
	. s line=$$read^stream(.sNode)
	. i line["<tag" d sUpdateTag(.sNode,qsOld,qsBox,nodeId,changeset,version,delete)
	;
	; Delete all tags that are not on the new version of the node
	s u=""
	i qsOld'="" f  d  i u="" q
	. s u=$o(^e(qsOld,"n",nodeId,"u",u)) i u="" q
	. s key=^key(u)
	. i 'delete,$d(^c(changeset,"n",nodeId,"v",version,"u",u)) q
	. s value=^e(qsOld,"n",nodeId,"u",u)
	. s intValue=value
	. i $l(intValue)>100 s intValue=$e(value,1,100)_".."
	. i intValue'="" k ^nodex(key,intValue,qsOld,nodeId)
	. k ^nodex(key,"*",qsOld,nodeId)
	. k ^e(qsOld,"n",nodeId,"u",u)
	;
	i delete,qsOld'="" k ^e(qsOld,"n",nodeId)
	;
	; Create export index
	s ^export(timestamp,"n",changeset,nodeId,version)=""
	;
	s rSeq=$g(^response($j))+1
	s ^response($j)=rSeq
	;
	i delete s newId="",version=""
	;
	s ^response($j,rSeq,"oldId")=oldId
	s ^response($j,rSeq,"newId")=newId
	s ^response($j,rSeq,"version")=version
	s ^response($j,rSeq,"element")="node"
	;
	d onEdit^user(uid)
	;
	; Update metrics
	i version=1 d update^metric("fosmNodeCount",1)
	i delete d update^metric("fosmNodeCount",-1)
	d update^metric("fosmNodeEdits",1)
	;
	q 1
	
	
	
	
	
sUpdateTag(sNode,qsOld,qsNew,nodeId,changeset,version,delete)	; Private load a tag and add it
	;
	n line,key,value
	;
	s line=sNode("current")
	i line'["/>" f  d  i line["/>" q
	. s line=line_$$read^stream(.sNode)
	;
	s key=$$getAttribute^osmXml(line,"k") i key="" q
	i $l(key)>100 s key=$e(key,1,100)_".."
	s value=$$getAttribute^osmXml(line,"v")
	i value["'" s value=$$xmlEscapeApostrophe(value)
	i $l(value)>4000 s value=$e(value,1,4000)_".."
	;
	d updateTag(qsOld,qsNew,nodeId,key,value,changeset,version,delete)
	q
	
	
updateTag(qsOld,qsNew,nodeId,key,newValue,newChangeset,newVersion,delete)	; Private ; Update (add/modify/delete) a key/value pair for a node
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
	n u,oldValue,intNewValue,intOldValue
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
	s oldValue=""
	i qsOld'="" s oldValue=$g(^e(qsOld,"n",nodeId,"u",u))
	;
	s intNewValue=newValue
	i $l(newValue)>100 s intNewValue=$e(newValue,1,100)_".."
	;
	s intOldValue=oldValue
	i $l(oldValue)>100 s intOldValue=$e(oldValue,1,100)_".."
	;
	; Always add the tag to the node definition in the changeset
	s ^c(newChangeset,"n",nodeId,"v",newVersion,"u",u)=newValue
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
	
	
delete(nodeId)	; Public ; Delete a node
	;
	n key,u,value,qsBox
	;
	s qsBox=$$qsBox(nodeId) i qsBox="" q
	;
	s u=""
	f  d  i u="" q
	. s u=$o(^e(qsBox,"n",nodeId,"u",u)) i u="" q
	. s value=^e(qsBox,"n",nodeId,"u",u)
	. s key=^key(u)
	. i $l(value)>100 s value=$e(value,1,100)_".."
	. i value'="" k ^nodex(key,value,qsBox,nodeId)
	. k ^nodex(key,"*",qsBox,nodeId)
	;
	k ^e(qsBox,"n",nodeId)
	;
	q
	
	
xml(indent,nodeId,select,qsBox)	  ; Public ; Generate xml for node
	;
	; indent = XML indent
	; nodeId = id of node to emit
	; select [deprecated] = attributes and sub-elements to emit
	; qsBox [optional] = qsBox of element if known (faster if provided)
	;
	n latlon,a,user,uid,uidUser,timestamp,version,changeset
	n xml
	;
	i $g(qsBox)="" s qsBox=$$qsBox(nodeId) i qsBox="" q ""
	;
	s xml=""
	;
	s latlon=$g(^e(qsBox,"n",nodeId,"l")) i latlon="" q ""
	s a=^e(qsBox,"n",nodeId,"a")
	s version=$p(a,$c(1),1)
	s changeset=$p(a,$c(1),2)
	s timestamp=$p(a,$c(1),3)
	s uid=$p(a,$c(1),4)
	s user="" i uid'="" s user=$g(^user(uid,"name"))
	;
	s xml=xml_indent_"<node"
	s xml=xml_$$attribute^osmXml("id",nodeId)
	s xml=xml_$$attribute^osmXml("lat",$p(latlon,$c(1),1))
	s xml=xml_$$attribute^osmXml("lon",$p(latlon,$c(1),2))
	i version'="" s xml=xml_$$attribute^osmXml("version",version)
	i changeset'="" s xml=xml_$$attribute^osmXml("changeset",changeset)
	i user'="" s xml=xml_$$attribute^osmXml("user",user)
	i uid'="" s xml=xml_$$attribute^osmXml("uid",uid)
	s xml=xml_$$attribute^osmXml("visible","true")
	i timestamp'="" s xml=xml_$$attribute^osmXml("timestamp",timestamp)
	;
	s xml=xml_">"_$c(13,10)
	;
	s xml=xml_$$xmlTags(nodeId,indent,qsBox)
	s xml=xml_indent_"</node>"_$c(13,10)
	;
	q xml
	
	
xmlTags(id,indent,qsBox)	  ; Private ; Generate xml for node's tags
	;
	n k,u,xml
	;
	s xml=""
	;
	s indent=indent_"  "
	;
	; Compiled keys
	s u=""
	f  d  i u="" q
	. s u=$o(^e(qsBox,"n",id,"u",u)) i u="" q
	. s k=^key(u)
	. s xml=xml_indent_"<tag"
	. s xml=xml_" k='"_k_"'" ; Keys are stored as escaped strings
	. s xml=xml_" v='"_^e(qsBox,"n",id,"u",u)_"'" ; Tags are stored as escaped strings
	. s xml=xml_"/>"_$c(13,10)
	;
	q xml
	
	
qsBox(nodeId)	; Public ; Get quadString for a node
	;
	q $g(^nodeVersion(nodeId,"q"))
	
	
bbox(nodeId,bllat,bllon,trlat,trlon)	; Public ; Get bbox for a node
	;
	n latlon,lat,lon,qsBox
	;
	s qsBox=$$qsBox(nodeId) i qsBox="" q
	;
	s latlon=$g(^e(qsBox,"n",nodeId,"l"))
	s lat=$p(latlon,$c(1),1)
	s lon=$p(latlon,$c(1),2)
	;
	s trlat=lat
	s bllat=lat
	s trlon=lon
	s bllon=lon
	q
	
	
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
	
	
hasRealTag(id)	; Public ; Does this node have a real tag?
	;
	n qsBox
	;
	s qsBox=$$qsBox(id)
	;
	i $d(^e(qsBox,"n",id,"u")) q 1
	;
	q 0
	
	
versionAtChangeset(nodeId,changeset,nodeChangeset,nodeVersion)	; Public ; Get the changeset and version that was current at a given changeset time
	;
	; Usage:
	;  d versionAtChangeset^node(nodeId,changeset,.nodeChangeset,.nodeVersion) i nodeChangeset="" ...
	; Output:
	;  nodeChangeset - null if not found
	;  nodeVersion - null if not found
	;
	s nodeChangeset=changeset
	s nodeVersion=""
	i '$d(^nodeVersion(nodeId,"c",nodeChangeset)) s nodeChangeset=$o(^nodeVersion(nodeId,"c",nodeChangeset),-1) i nodeChangeset="" q
	s nodeVersion=$o(^nodeVersion(nodeId,"c",nodeChangeset,""),-1) i nodeVersion="" s nodeChangeset="" q
	;
	q
	
	
restNode(string)	; Public ; Single node query
	;
	n step,nodeId,full,logId,indent
	;
	; Get next step
	s step=$p(string,SLASH,1),string=$p(string,SLASH,2,$l(string))
	s nodeId=step
	;
	; Get next step
	s step=$p(string,SLASH,1),string=$p(string,SLASH,2,$l(string))
	;
	; Four choices here:
	;                - current node only
	; ways           - all ways that use the node
	; #version       - specific version of node
	; #version/ways  - all ways that used this version of the node
	; history        - all versions of this node
	s full=0
	i step="" s full=0
	i step="ways" d restWaysByNode(nodeId) q
	i step="relations" d restRelationsByNode(nodeId) q
	i step="history" d restNodeHistory(nodeId) q
	i step?1.n d restNode^nodeVersion(nodeId,step,string) q
	;
	s logId=$$logStart^xapi("node/"_nodeId,"")
	;
	; Bad query?
	i nodeId'?1.n d notFound^http,logEnd^xapi(logId,0,"404 Not found") q
	;
	; Is it there?
	i '$d(^nodeVersion(nodeId)) d notFound^http,logEnd^xapi(logId,0,"404 Not found") q
	s qsBox=$$qsBox(nodeId)
	i '$d(^e(qsBox,"n",nodeId)) d gone^http,logEnd^xapi(logId,0,"410 Gone") q
	i $p($g(^e(qsBox,"n",nodeId,"a")),$c(1),5)="false" d gone^http,logEnd^xapi(logId,0,"410 Gone") q
	;
	d header^http("text/xml")
	d xmlProlog^rest("")
	;
	s indent=""
	d osm^xapi(indent)
	;
	w $$xml(indent,nodeId,"node|@*|tag|")
	;
	w indent,"</osm>",$c(13,10)
	;
	d logEnd^xapi(logId,1,"")
	;
	q
	
	
restWaysByNode(nodeId)	; Public ; Ways by Node
	;
	n indent,logId,wayId,count
	;
	s count=0
	s logId=$$logStart^xapi("node/"_nodeId_"/ways","")
	;
	; Bad query?
	i nodeId'?1.n d notFound^http,logEnd^xapi(logId,0,"404 Not found") q
	;
	; Is it there?
	i '$d(^nodeVersion(nodeId)) d notFound^http,logEnd^xapi(logId,0,"404 Not found") q
	s qsBox=$$qsBox(nodeId)
	i $p($g(^e(qsBox,"n",nodeId,"a")),$c(1),5)="false" d gone^http,logEnd^xapi(logId,0,"410 Gone") q
	;
	d header^http("text/xml")
	d xmlProlog^rest("")
	;
	s indent=""
	d osm^xapi(indent)
	;
	s wayId=""
	f  d  i wayId="" q
	. s wayId=$o(^wayByNode(nodeId,wayId)) i wayId="" q
	. w $$xml^way(indent,wayId,"way|@*|nd|tag|")
	. s count=count+1
	;
	w indent,"</osm>",$c(13,10)
	;
	d logEnd^xapi(logId,count,"")
	;
	q
	
	
restRelationsByNode(nodeId)	; Public ; Relations by Node
	;
	n indent,logId,relationId,count
	;
	s count=0
	s logId=$$logStart^xapi("node/"_nodeId_"/relations","")
	;
	; Bad query?
	i nodeId'?1.n d notFound^http,logEnd^xapi(logId,0,"404 Not found") q
	;
	; Is it there?
	i '$d(^nodeVersion(nodeId)) d notFound^http,logEnd^xapi(logId,0,"404 Not found") q
	s qsBox=$$qsBox(nodeId)
	i $p($g(^e(qsBox,"n",nodeId,"a")),$c(1),5)="false" d gone^http,logEnd^xapi(logId,0,"410 Gone") q
	;
	d header^http("text/xml")
	d xmlProlog^rest("")
	;
	s indent=""
	d osm^xapi(indent)
	;
	s relationId=""
	f  d  i relationId="" q
	. s relationId=$o(^relationMx("node",nodeId,relationId)) i relationId="" q
	. w $$xml^relation(indent,relationId,"relation|@*|member|tag|")
	. s count=count+1
	;
	w indent,"</osm>",$c(13,10)
	;
	d logEnd^xapi(logId,count,"")
	;
	q
	
	
restNodes(step,string)	; Public ; Multi node query
	;
	n logId,count,indent
	n nodeIds,nodeId,ok,i,version,changesetId
	;
	s count=0
	s logId=$$logStart^xapi($$decode^xapi(step),"")
	;
	s nodeIds=$p(step,EQUALS,2)
	;
	; Validate query
	s ok=1
	f i=1:1:$l(nodeIds,",") d  i 'ok q
	. s nodeId=$p(nodeIds,",",i)
	. i nodeId'?1.n d notFound^http,logEnd^xapi(logId,0,"404 Not found") s ok=0 q
	. ; Is it there?
	. i '$d(^nodeVersion(nodeId)) d notFound^http,logEnd^xapi(logId,0,"404 Not found") s ok=0 q
	. ; s qsBox=$$qsBox(nodeId)
	. ; i '$d(^e(qsBox,"n",nodeId)) d gone^http,logEnd^xapi(logId,0,"410 Gone") s ok=0 q
	. ; i $p($g(^e(qsBox,"n",nodeId,"a")),$c(1),5)="false" d gone^http,logEnd^xapi(logId,0,"410 Gone") s ok=0 q
	i 'ok q
	;
	d header^http("text/xml")
	d xmlProlog^rest("")
	;
	s indent=""
	d osm^xapi(indent)
	;
	f i=1:1:$l(nodeIds,",") d
	. s nodeId=$p(nodeIds,",",i)
	. s version=$o(^nodeVersion(nodeId,"v",""),-1) i version="" q
	. s changesetId=^nodeVersion(nodeId,"v",version)
	. w $$xml^nodeVersion(indent,nodeId,changesetId,version,"node|@*|tag|")
	. s count=count+1
	;
	w indent,"</osm>",$c(13,10)
	;
	d logEnd^xapi(logId,count,"")
	;
	q
	
	
restNodeHistory(nodeId)	; Public ; All versions of node
	;
	n logId,count,indent
	n version,changeset
	;
	s count=0
	s logId=$$logStart^xapi("node/"_nodeId_"/history","")
	;
	; Bad query?
	i nodeId'?1.n d notFound^http,logEnd^xapi(logId,0,"404 Not found") q
	;
	; Is it there?
	i '$d(^nodeVersion(nodeId)) d notFound^http,logEnd^xapi(logId,0,"404 Not found") q
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
	. s version=$o(^nodeVersion(nodeId,"v",version)) i version="" q
	. s changeset=^nodeVersion(nodeId,"v",version)
	. ;
	. w $$xml^nodeVersion(indent,nodeId,changeset,version,"node|@*|tag|")
	. s count=count+1
	;
	w indent,"</osm>",$c(13,10)
	;
	d logEnd^xapi(logId,count,"")
	;
	q
	
	
currentVersion(nodeId)	; Public ; Return the current version number of a node
	;
	; Usage: s currentVersion=$$currentVersion^node(nodeId)
	; Input:
	;   nodeId - node id, must not be null
	; Output:
	;   currentVersion - if the node does not exists then null is returned
	;
	q $o(^nodeVersion(nodeId,"v",""),-1)
	
