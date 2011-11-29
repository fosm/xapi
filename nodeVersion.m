nodeVersion	; Node Version Class
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
	
	
xmlChangeset(indent,nodeId,changeset,select)	  ; Public ; Generate xml for a node at a given changeset
	;	
	n nodeChangeset,nodeVersion
	;
	d versionAtChangeset^node(nodeId,changeset,.nodeChangeset,.nodeVersion) i nodeChangeset="" q ""
	;
	q $$xml(indent,nodeId,nodeChangeset,nodeVersion,select)
	
	
xml(indent,nodeId,changeset,version,select)	  ; Public ; Generate xml for a node version
	;
	n latlon,a,user,users,uid,timestamp,visible
	n xml
	;
	s xml=""
	;
	s indent=indent_"  "
	;
	s latlon=$g(^c(changeset,"n",nodeId,"v",version,"l")) i latlon="" q ""
	i $d(^c(changeset,"n",nodeId,"v",version,"a")) d
	. s a=^c(changeset,"n",nodeId,"v",version,"a")
	. ; s version=$p(a,$c(1),1) ; We already have this value
	. ; s changeset=$p(a,$c(1),2) ; We already have this
	. s timestamp=$p(a,$c(1),3)
	. s uid=$p(a,$c(1),4)
	. s user="" i uid'="" s user=$g(^user(uid,"name"))
	. s visible=$p(a,$c(1),5) i visible="" s visible="true"
	e  d
	. ; s version=$g(^c(changeset,"n",nodeId,"v",version,"t","@version")) ; We already have this value
	. ; s changeset=$g(^c(changeset,"n",nodeId,"v",version,"t","@changeset")) ; We already have this value
	. s timestamp=$g(^c(changeset,"n",nodeId,"v",version,"t","@timestamp"))
	. s uid=$g(^c(changeset,"n",nodeId,"v",version,"t","@uid"))
	. s user=$g(^c(changeset,"n",nodeId,"v",version,"t","@user"))
	. s visible=$g(^c(changeset,"n",nodeId,"v",version,"t","@visible"),"true")
	;
	s xml=xml_indent_"<node"
	s xml=xml_$$attribute^osmXml("id",nodeId)
	s xml=xml_$$attribute^osmXml("lat",$p(latlon,$c(1),1))
	s xml=xml_$$attribute^osmXml("lon",$p(latlon,$c(1),2))
	i changeset'="" s xml=xml_$$attribute^osmXml("changeset",changeset)
	i user'="" s xml=xml_$$attribute^osmXml("user",user)
	i uid'="" s xml=xml_$$attribute^osmXml("uid",uid)
	i visible'="" s xml=xml_$$attribute^osmXml("visible",visible)
	i timestamp'="" s xml=xml_$$attribute^osmXml("timestamp",timestamp)
	i version'="" s xml=xml_$$attribute^osmXml("version",version)
	;
	s xml=xml_">"_$c(13,10)
	;
	s xml=xml_$$xmlTags(indent,nodeId,changeset,version,select)
	s xml=xml_indent_"</node>"_$c(13,10)
	;
	q xml
	
	
xmlTags(indent,id,changeset,version,select)	  ; Public ; Generate xml for node's tags
	;
	n k,u,xml
	;
	s xml=""
	;
	s indent=indent_"  "
	;
	s k=""
	f  d  i k="" q
	. s k=$o(^c(changeset,"n",nodeId,"v",version,"t",k)) i k="" q
	. i $e(k,1)="@" s k="@zzzzzzzzzzzzzzz" q
	. i $d(^c(changeset,"n",nodeId,"v",version,"t",k))#10=0 q
	. s xml=xml_indent_"<tag"
	. s xml=xml_" k='"_k_"'" ; keyas are stored as escaped strings
	. s xml=xml_" v='"_^c(changeset,"n",nodeId,"v",version,"t",k)_"'" ; Tags are stored as escaped strings
	. s xml=xml_"/>"_$c(13,10)
	;
	s u=""
	f  d  i u="" q
	. s u=$o(^c(changeset,"n",nodeId,"v",version,"u",u)) i u="" q
	. s k=^key(u)
	. s xml=xml_indent_"<tag"
	. s xml=xml_" k='"_k_"'" ; keyas are stored as escaped strings
	. s xml=xml_" v='"_^c(changeset,"n",nodeId,"v",version,"u",u)_"'" ; Tags are stored as escaped strings
	. s xml=xml_"/>"_$c(13,10)
	;
	q xml
	
	
restNode(nodeId,step,string)	; Public ; Single node query for specific version
	;
	n logId,version,changeset,indent
	;
	; Get next step
	s version=step
	s step=$p(string,SLASH,1),string=$p(string,SLASH,2,$l(string))
	;
	; Two choices here:
	;               - specific version of node only
	; ways          - all ways that use this version of the node
	i step="ways" d restWaysByNode(nodeId,version) q
	;
	s logId=$$logStart^xapi("node/"_nodeId_"/"_version,"")
	;
	; Bad query?
	i nodeId'?1.n d notFound^http,logEnd^xapi(logId,0,"404 Not found") q
	i version'?1.n d notFound^http,logEnd^xapi(logId,0,"404 Not found") q
	;
	; Is it there?
	i '$d(^nodeVersion(nodeId,"v",version)) d notFound^http,logEnd^xapi(logId,0,"404 Not found") q
	s changeset=^nodeVersion(nodeId,"v",version)
	;
	; Is the history present for this node
	i '$d(^c(changeset,"n",nodeId,"v",version)) d notFound^http,logEnd^xapi(logId,0,"404 Not found") q
	;
	d header^http("text/xml")
	d xmlProlog^rest("")
	;
	s indent=""
	d osm^xapi(indent)
	;
	w $$xml(indent,nodeId,changeset,version,"node|@*|tag|")
	;
	w indent,"</osm>",$c(13,10)
	;
	d logEnd^xapi(logId,1,"")
	;
	q
	
	
restWaysByNode(nodeId,version)	; Public ; Ways used by a specific version of a node
	;
	n logId,count,indent
	n changeset,nodeStartChangeset,nodeEndChangeset,wayStartChangeset,wayEndChangeset,wayId
	;
	s count=0
	s logId=$$logStart^xapi("node/"_nodeId_"/"_version_"/ways","")
	;
	; Bad query?
	i nodeId'?1.n d notFound^http,logEnd^xapi(logId,0,"404 Not found") q
	i version'?1.n d notFound^http,logEnd^xapi(logId,0,"404 Not found") q
	;
	; Is it there?
	i '$d(^nodeVersion(nodeId,"v",version)) d notFound^http,logEnd^xapi(logId,0,"404 Not found") q
	;
	; Is the history present for this node
	s changeset=^nodeVersion(nodeId,"v",version)
	i '$d(^c(changeset,"n",nodeId,"v",version)) d notFound^http,logEnd^xapi(logId,0,"404 Not found") q
	;
	d header^http("text/xml")
	d xmlProlog^rest("")
	;
	s indent=""
	d osm^xapi(indent)
	;
	; Find the start and end of the selected node version
	s nodeStartChangeset=^nodeVersion(nodeId,"v",version)
	s nodeEndChangeset=$g(^nodeVersion(nodeId,"v",version+1))
	;
	; Iterate all changesets that happened before the node got replaced
	s wayStartChangeset=""
	f  d  i wayStartChangeset="" q
	. s wayStartChangeset=$o(^nodeVersion(nodeId,"c",wayStartChangeset)) i wayStartChangeset="" q
	. i nodeEndChangeset'="",nodeEndChangeset<wayStartChangeset s wayStartChangeset="" q
	. ;
	. ; Iterate all ways that got modified in this changeset and also happen to reference our node
	. s wayId=""
	. f  d  i wayId="" q
	. . s wayId=$o(^nodeVersion(nodeId,"c",wayStartChangeset,"w",wayId)) i wayId="" q
	. . s wayEndChangeset=^nodeVersion(nodeId,"c",wayStartChangeset,"w",wayId)
	. . ;
	. . ; If the way got replaced before this version of this node got created then we are
	. . ; not interested in it
	. . i wayEndChangeset'="",nodeStartChangeset>wayEndChangeset q
	. . ;
	. . ; So this version of this way (w) was created before this node version (v) got replaced and
	. . ; and it (w) did not get replaced until after this node version (v) got replaced.
	. . w $$xmlChangeset^wayVersion(indent,wayId,wayStartChangeset,"way|@*|nd|tag|")
	. . s count=count+1
	;
	w indent,"</osm>",$c(13,10)
	;
	d logEnd^xapi(logId,count,"")
	;
	q
	
	
bbox(nodeId,version,bllat,bllon,trlat,trlon)	; Public ; Get bbox for a node version
	;
	n changesetId,l,lat,lon
	;
	s changesetId=^nodeVersion(nodeId,"v",version)
	s l=^c(changesetId,"n",nodeId,"v",version,"l")
	s lat=$p(l,$c(1),1)
	s lon=$p(l,$c(1),2)
	;
	s trlat=lat
	s bllat=lat
	s trlon=lon
	s bllon=lon
	q
