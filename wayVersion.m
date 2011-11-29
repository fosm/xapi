wayVersion	; Way Version Class
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
	
	
xmlChangeset(indent,wayId,changeset,select)	; Public ; Generate xml for a way at a specific changeset
	;
	n wayChangeset,wayVersion
	;
	d versionAtChangeset^way(wayId,changeset,.wayChangeset,.wayVersion) i wayChangeset="" q ""
	;
	q $$xml(indent,wayId,wayChangeset,wayVersion,select)
	
	
xml(indent,wayId,changeset,version,select)	    ; Public ; Generate xml for a way
	;
	; Usage:
	;  w $$xml^wayVersion(indent,wayId,changeset,[version],select)
	;
	n a,user,uid,timestamp,visible
	n xml
	;
	s xml=""
	;
	s indent=indent_"  "
	;
	i $d(^c(changeset,"w",wayId,"v",version,"a")) d
	. s a=^c(changeset,"w",wayId,"v",version,"a")
	. ; s version=$p(a,$c(1),1) ; we already have this
	. ; s changeset=$p(a,$c(1),2) ; we already have this
	. s timestamp=$p(a,$c(1),3)
	. s uid=$p(a,$c(1),4)
	. s user=$g(^user(uid,"name"))
	. s visible=$p(a,$c(1),5) i visible="" s visible="true"
	e  d
	. ; s version=$g(^c(changeset,"w",wayId,"v",version,"t","@version")) ; We already have this value
	. ; s changeset=$g(^c(changeset,"w",wayId,"v",version,"t","@changeset")) ; We already have this value
	. s timestamp=$g(^c(changeset,"w",wayId,"v",version,"t","@timestamp"))
	. s uid=$g(^c(changeset,"w",wayId,"v",version,"t","@uid"))
	. s user=$g(^c(changeset,"w",wayId,"v",version,"t","@user"))
	. s visible=$g(^c(changeset,"w",wayId,"v",version,"t","@visible"),"true")
	;
	s xml=indent_"<way"
	s xml=xml_$$attribute^osmXml("id",wayId)
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
	d xmlNodes(indent,wayId,changeset,version,select)
	;
	d xmlTags(indent,wayId,changeset,version,select)
	s xml=xml_indent_"</way>"_$c(13,10)
	w xml
	s xml=""
	;
	q xml
	
	
xmlNodes(indent,wayId,changeset,version,select)	; Public ; Generate xml for a way's nodes
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
	. s ndSeq=$o(^c(changeset,"w",wayId,"v",version,"n",ndSeq)) i ndSeq="" q
	. s xml=xml_indent_"<nd"
	. s xml=xml_$$attribute^osmXml("ref",^c(changeset,"w",wayId,"v",version,"n",ndSeq))
	. s xml=xml_"/>"_$c(13,10)
	. w xml
	. s xml=""
	q
	
	
xmlTags(indent,wayId,changeset,version,select)	; Public ; Generate xml for a way's tags
	;
	n k,u,xml
	;
	s xml=""
	;
	s indent=indent_"  "
	;
	s k=""
	f  d  i k="" q
	. s k=$o(^c(changeset,"w",wayId,"v",version,"t",k)) i k="" q
	. i $e(k,1)="@" s k="@zzzzzzzzzzzzzzzz" q
	. i $d(^c(changeset,"w",wayId,"v",version,"t",k))#10=0 q
	. s xml=xml_indent_"<tag"
	. s xml=xml_" k='"_k_"'" ; Keys are stored as escaped strings
	. s xml=xml_" v='"_^c(changeset,"w",wayId,"v",version,"t",k)_"'" ; Tags are stored as escaped strings
	. s xml=xml_"/>"_$c(13,10)
	. w xml
	. s xml=""
	;
	s u=""
	f  d  i u="" q
	. s u=$o(^c(changeset,"w",wayId,"v",version,"u",u)) i u="" q
	. s k=^key(u)
	. s xml=xml_indent_"<tag"
	. s xml=xml_" k='"_k_"'" ; Keys are stored as escaped strings
	. s xml=xml_" v='"_^c(changeset,"w",wayId,"v",version,"u",u)_"'" ; Tags are stored as escaped strings
	. s xml=xml_"/>"_$c(13,10)
	. w xml
	. s xml=""
	;
	q
	
	
restWay(wayId,step,string)	; Public ; Single way version
	;
	n logId,version,full,changeset,ndSeq,nodeId
	;
	; Get next step
	s version=step
	s step=$p(string,SLASH,1),string=$p(string,SLASH,2,$l(string))
	;
	; Two choices here:
	; #version      - historic way
	; #version/full - historic way plus historic nodes
	s full=0
	i step="" s full=0
	i step="full" s full=1
	;
	s logId=$$logStart^xapi("way/"_wayId_"/"_version_"/"_step,"")
	;
	; Bad query?
	i wayId'?1.n d notFound^http,logEnd^xapi(logId,0,"404 Not found") q
	i version'?1.n d notFound^http,logEnd^xapi(logId,0,"404 Not found") q
	;
	; Is it there?
	i '$d(^wayVersion(wayId,"v",version)) d gone^http,logEnd^xapi(logId,0,"410 Gone") q
	;
	s changeset=^wayVersion(wayId,"v",version)
	i '$d(^c(changeset,"w",wayId,"v",version)) d notFound^http,logEnd^xapi(logId,0,"404 Not found") q
	;
	d header^http("text/xml")
	d xmlProlog^rest("")
	;
	k ^temp($j)
	;
	s indent=""
	d osm^xapi(indent)
	;
	; Add all nodes that belong to this way
	s ndSeq=""
	i full f  d  i ndSeq="" q
	. s ndSeq=$o(^c(changeset,"w",wayId,"v",version,"n",ndSeq)) i ndSeq="" q
	. s nodeId=^c(cchangeset,"w",wayId,"v",version,"n",ndSeq)
	. ;
	. i $d(^temp($j,nodeId)) q
	. s ^temp($j,nodeId)=""
	. ;
	. w $$xmlChangeset^nodeVersion(indent,nodeId,changeset,"node|@*|tag|") 
	;
	w $$xml(indent,wayId,changeset,version,"way|@*|nd|tag|")
	;
	w indent,"</osm>",$c(13,10)
	;
	d logEnd^xapi(logId,1,"")
	;
	q
	
