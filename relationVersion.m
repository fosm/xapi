relationVersion	; Relation Version Class
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
	
	
xmlChangeset(indent,relationId,changeset,select)	  ; Public ; Generate xml for a relation at a given changeset
	;
	n relationChangeset,relationVersion
	;
	d versionAtChangeset^relation(relationId,changeset,.relationChangeset,.relationVersion) i relationChangeset="" q
	;
	q $$xml(indent,relationId,relationChangeset,relationVersion,select)
	
	
xml(indent,relationId,changeset,version,select)	  ; Public ; Generate xml for a relation
	;
	;
	n a,user,uid,timestamp,visible
	n xml
	;
	s xml=""
	;
	s indent=indent_"  "
	;
	i $d(^c(changeset,"r",relationId,"v",version,"a")) d
	. s a=^c(changeset,"r",relationId,"v",version,"a")
	. ; s version=$p(a,$c(1),1) ; we already have this
	. ; s changeset=$p(a,$c(1),2) ; we already have this
	. s timestamp=$p(a,$c(1),3)
	. s uid=$p(a,$c(1),4)
	. s user=$g(^user(uid,"name"))
	. s visible=$p(a,$c(1),5) i visible="" s visible="true"
	e  d
	. ; s version=$g(^c(changeset,"r",relationId,"v",version,"t","@version")) ; We already have this
	. ; s changeset=$g(^relationh(relationId,changeset,"tag","@changeset")) ; We already have this
	. s timestamp=$g(^c(changeset,"r",relationId,"v",version,"t","@timestamp"))
	. s uid=$g(^c(changeset,"r",relationId,"v",version,"t","@uid"))
	. s user=$g(^c(changeset,"r",relationId,"v",version,"t","@user"))
	. s visible=$g(^c(changeset,"r",relationId,"v",version,"t","@visible"),"true")
	;
	s xml=indent_"<relation"
	s xml=xml_$$attribute^osmXml("id",relationId)
	i visible'="" s xml=xml_$$attribute^osmXml("visible",visible)
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
	d xmlMembers(relationId,changeset,version,indent,select)
	;
	d xmlTags(relationId,changeset,version,indent,select)
	s xml=xml_indent_"</relation>"_$c(13,10)
	w xml
	s xml=""
	;
	q xml
	
	
xmlMembers(relationId,changeset,version,indent,select)	; Public ; Generate xml for a relation's members
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
	. s seq=$o(^c(changeset,"r",relationId,"v",version,"s",seq)) i seq="" q
	. s xml=xml_indent_"<member"
	. s type=$g(^c(changeset,"r",relationId,"v",version,"s",seq,"t"))
	. s ref=$g(^c(changeset,"r",relationId,"v",version,"s",seq,"i"))
	. s role=$g(^c(changeset,"r",relationId,"v",version,"s",seq,"r"))
	. i type'="" s xml=xml_$$attribute^osmXml("type",type)
	. i ref'="" s xml=xml_$$attribute^osmXml("ref",ref)
	. s xml=xml_$$attribute^osmXml("role",role)
	. s xml=xml_"/>"_$c(13,10)
	. w xml
	. s xml=""
	q
	
	
xmlTags(relationId,changeset,version,indent,select)	      ; Public ; Generate xml for a relation's tags
	;
	n k,u,xml
	;
	s xml=""
	;
	i '$$select^osmXml(select,"tag") q ""
	;
	s indent=indent_"  "
	;
	s k=""
	f  d  i k="" q
	. s k=$o(^c(changeset,"r",relationId,"v",version,"t",k)) i k="" q
	. i $e(k,1)="@" s k="@zzzzzzzzzzzzzz" q
	. i $d(^c(changeset,"r",relationId,"v",version,"t",k))#10=0 q
	. s xml=xml_indent_"<tag"
	. s xml=xml_" k='"_k_"'" ; Keys are stored as escaped strings
	. s xml=xml_" v='"_^c(changeset,"r",relationId,"v",version,"t",k)_"'" ; Tags are stored as escaped strings
	. s xml=xml_"/>"_$c(13,10)
	. w xml
	. s xml=""
	;
	s u=""
	f  d  i u="" q
	. s u=$o(^c(changeset,"r",relationId,"v",version,"u",u)) i u="" q
	. s k=^key(u)
	. s xml=xml_indent_"<tag"
	. s xml=xml_" k='"_k_"'" ; Keys are stored as escaped strings
	. s xml=xml_" v='"_^c(changeset,"r",relationId,"v",version,"u",u)_"'" ; Tags are stored as escaped strings
	. s xml=xml_"/>"_$c(13,10)
	. w xml
	. s xml=""
	;
	q
	
	
restRelation(relationId,step,string)	; Public ; Single relation version query 
	;
	; Inputs:
	;   string - relationId[ /full | /version/full ]
	;
	n version,full,logId,indent
	n seq,nodeId,wayId,ndSeq,subRelationId
	n count
	;
	; Get next step
	s version=step
	s step=$p(string,SLASH,1),string=$p(string,SLASH,2,$l(string))
	;
	; Two choices here:
	; /version/     - historic relation
	; /version/full - historic relation plus historic members
	s full=0
	i step="" s full=0
	i step="full" s full=1
	;
	k ^temp($j)
	s count=0
	;
	s logId=$$logStart^xapi("relation/"_relationId_"/"_version_$s(full:"/full",1:""),"")
	;
	; Bad query?
	i relationId'?1.n d notFound^http,logEnd^xapi(logId,0,"404 Not found") q
	i version'?1.n d notFound^http,logEnd^xapi(logId,0,"404 Not found") q
	;
	; Is it there?
	i '$d(^relationVersion(relationId,"v",version)) d gone^http,logEnd^xapi(logId,0,"410 Gone") q
	s changeset=^relationVersion(relationId,"v",version)
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
	. s seq=$o(^c(changeset,"r",relationId,"v",version,"s",seq)) i seq="" q
	. ;
	. ; Nodes
	. i ^c(changeset,"r",relationId,"v",version,"s",seq,"t")="node" d  q
	. . s nodeId=^c(changeset,"r",relationId,"v",version,"s",seq,"i")
	. . i $d(^temp($j,"node",nodeId)) q
	. . s ^temp($j,"node",nodeId)=""
	. . w $$xmlChangeset^nodeVersion(indent,nodeId,changeset,"node|@*|tag|")
	. . s count=count+1
	. ;
	. ; Nodes within ways
	. i ^c(changeset,"r",relationId,"v",version,"s",seq,"t")="way" d  q
	. . s wayId=^c(changeset,"r",relationId,"v",version,"s",seq,"i")
	. . ;
	. . ; Get the way version that existed at the time of this changeset
	. . d versionAtChangeset^way(wayId,changeset,.wayChangeset,.wayVersion) i wayChangeset="" q
	. . ;
	. . s ndSeq=""
	. . f  d  i ndSeq="" q
	. . . s ndSeq=$o(^c(wayChangeset,"w",wayId,"v",wayVersion,"n",ndSeq)) i ndSeq="" q
	. . . s nodeId=^c(wayChangeset,"w",wayId,"v",wayVersion,"n",ndSeq)
	. . . i $d(^temp($j,"node",nodeId)) q
	. . . s ^temp($j,"node",nodeId)=""
	. . . w $$xmlChangeset^nodeVersion(indent,nodeId,changeset,"node|@*|tag|")
	. . . s count=count+1
	;
	; Select all ways that belong to this relation
	s seq=""
	i full f  d  i seq="" q
	. s seq=$o(^c(changeset,"r",relationId,"v",version,"s",seq)) i seq="" q
	. i ^c(changeset,"r",relationId,"v",version,"s",seq,"t")'="way" q
	. s wayId=^c(changeset,"r",relationId,"v",version,"s",seq,"i")
	. w $$xmlChangeset^wayVersion(indent,wayId,changeset,"way|@*|nd|tag|")
	. s count=count+1
	;
	; Select this relation
	w $$xml(indent,relationId,changeset,version,"relation|@*|member|tag|")
	s count=count+1
	;
	; Select all relations that belong to this relation
	s seq=""
	i full f  d  i seq="" q
	. s seq=$o(^c(changeset,"r",relationId,"v",version,"s",seq)) i seq="" q
	. i ^c(changeset,"r",relationId,"v",version,"s",seq,"t")'="relation" q
	. s subRelationId=^c(changeset,"r",relationId,"v",version,"s",seq,"i")
	. w $$xmlChangeset(indent,subRelationId,changeset,"relation|@*|member|tag|")
	. s count=count+1
	;
	w indent,"</osm>",$c(13,10)
	;
	d logEnd^xapi(logId,count,"")
	;
	q
