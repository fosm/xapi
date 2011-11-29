total	; REST ; Calculate totals for various tags 
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
	
	
	n date,f
	;
	s date=^osmPlanet("date")
	d generate(date)
	;
	s f="/home/etienne/www/total.xml"
	o f:NEW
	u f
	d xmlProlog("total.xsl")
	;
	d xmlTotal(date,"total|count|distinct|@*")
	;
	c f
	q
	
	
	
xmlTotal(date,select)	; Generate xml dataset of totals for a given date
	;
	n i,element,key,value,type,comment
	;	
	i '$$select^osmXml(select,"total") q
	;
	w "<total"
	w $$attribute^osmXml("date",date,"",select)
	w ">",!
	;
	s i=""
	f  d  i i="" q
	. s i=$o(^total("date",date,"item",i)) i i="" q
	. s element=$g(^total("date",date,"item",i,"element"))
	. s key=$g(^total("date",date,"item",i,"key"))
	. s value=$g(^total("date",date,"item",i,"value"))
	. s type=$g(^total("date",date,"item",i,"type"))
	. s count=$g(^total("date",date,"item",i,"count"))
	. s distinct=$g(^total("date",date,"item",i,"distinct"))
	. s comment=$g(^total("date",date,"item",i,"comment"))
	. i type="count" d xmlCount(element,key,value,count,comment,select)
	. i type="distinct" d xmlDistinct(element,key,distinct,comment,select)
	w "</total>",!
	;
	q
	
	
xmlCount(element,key,value,count,comment,select)	;
	;
	i '$$select^osmXml(select,"count") q
	;
	w "<count"
	w $$attribute^osmXml("element",element,"",select)
	w $$attribute^osmXml("key",key,"",select)
	w $$attribute^osmXml("value",value,"",select)
	w $$attribute^osmXml("count",count,"",select)
	w $$attribute^osmXml("comment",comment,"",select)
	w "/>",!
	q
	
	
xmlDistinct(element,key,distinct,comment,select)	;
	;
	i '$$select^osmXml(select,"distinct") q
	;
	w "<distinct"
	w $$attribute^osmXml("element",element,"",select)
	w $$attribute^osmXml("key",key,"",select)
	w $$attribute^osmXml("count",distinct,"",select)
	w $$attribute^osmXml("comment",comment,"",select)
	w "/>",!
	q
	
	
generate(date)	; Generate current stats and store as given date
	;
	n i,element,key,value,type,comment
	;
	; Only record one set of stats per day
	i $d(^total("date",date)) k ^total("date",date)
	;
	s i=""
	f  d  i i="" q
	. s i=$o(^total("param",i)) i i="" q
	. s element=$g(^total("param",i,"element"))
	. s key=$g(^total("param",i,"key"))
	. s value=$g(^total("param",i,"value"))
	. s type=$g(^total("param",i,"type"))
	. s comment=$g(^total("param",i,"comment"))
	. i type="count" d genCount(date,i,element,key,value,comment)
	. i type="distinct" d genDistinct(date,i,element,key,comment)
	;
	q
	
	
genCount(date,item,element,key,value,comment)	;
	;
	n e,i,count,qt,id
	;
	s count=0
	i element["node" s count=count+$g(^count("node",key,value))
	i element["way" s count=count+$g(^count("waykv",key,value))
	;
	s ^total("date",date,"item",item,"element")=element
	s ^total("date",date,"item",item,"key")=key
	s ^total("date",date,"item",item,"value")=value
	s ^total("date",date,"item",item,"type")="count"
	s ^total("date",date,"item",item,"comment")=comment
	s ^total("date",date,"item",item,"count")=count
	;
	q
	
	
genDistinct(date,item,element,key,comment)	;
	;
	n i,e,distinct,value
	;
	s distinct=0
	i element["node" d
	. s value=""
	. f  d  i value="" q
	. . s value=$o(^nodex(key,value)) i value="" q
	. . s distinct=distinct+1
	;
	i element["way" d
	. s value=""
	. f  d  i value="" q
	. . s value=$o(^wayx(key,value)) i value="" q
	. . i '$d(^nodex(key,value)) s distinct=distinct+1
	;
	s ^total("date",date,"item",item,"element")=element
	s ^total("date",date,"item",item,"key")=key
	s ^total("date",date,"item",item,"type")="distinct"
	s ^total("date",date,"item",item,"comment")=comment
	s ^total("date",date,"item",item,"distinct")=distinct
	;
	q
	
	
add	;
	;
	w !,"Type " r t i t="" s t="count" w t
	w !,"Element " r e i e="" s e="node|way" w e
	w !,"Key " r k i k="" s k="*" w k
	i t="count" w !,"Value " r v i v="" s v="*" w v
	w !,"Comment " r comment
	;
	s i=$g(^total("paramCount"))+1
	s ^total("paramCount")=i
	;
	s ^total("param",i,"type")=t
	s ^total("param",i,"element")=e
	s ^total("param",i,"key")=k
	i t="count" s ^total("param",i,"value")=v
	s ^total("param",i,"comment")=comment
	w !,"Added as entry #",i
	g add
	
	
	
xmlProlog(xslTemplate)	; Public ; Write xml Prolog and xsl stylesheet elements
	;
	w "<?xml version='1.0' standalone='no'?>",!
	i xslTemplate'="" w "<?xml-stylesheet type='text/xsl' href='"_xslTemplate_"'?>",!
	;
	q
