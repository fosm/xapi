osmXml	  ; XML Class
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
	
	
	
	
prolog(xslTemplate)	; Public ; Write xml Prolog and xsl stylesheet elements
	;
	w "<?xml version='1.0' encoding='UTF-8'?>",!
	i xslTemplate'="" w "<?xml-stylesheet type='text/xsl' href='"_xslTemplate_"'?>",!
	;
	q
	
	
allAttributes(object,indent,select)	; Public ; Get all attributes for an object
	; Usage:
	;  d xmlAttributes^%vcXml(.oObject,indent,select)
	; Inputs:
	;  oObject - reference to (ie the $name of) an object (either in memory or on disk)
	;  indent  - string of spaces to indent output by
	;  select  - XPath style selection string eg "element|element|@attributes"
	; Outputs:
	;  STDOUT  - list of attributes value pairs
	;
	n attribute
	;
	s attribute=""
	f  d  i attribute="" q
	. s attribute=$o(@object@(attribute)) i attribute="" q
	. i $d(@object@(attribute))#10=1 w $$attribute(attribute,@object@(attribute),indent,select)
	. i indent'="" w !
	q
	
genAttributes(object,indent,select)	; Public ; Generate all attributes for an object as a string
	; Usage:
	;  d xmlAttributes^%vcXml(.oObject,indent,select)
	; Inputs:
	;  oObject - reference to (ie the $name of) an object (either in memory or on disk)
	;  indent  - string of spaces to indent output by
	;  select  - XPath style selection string eg "element|element|@attributes"
	; Outputs:
	;  STDOUT  - list of attributes value pairs
	;
	n attribute,xml
	s xml=""
	;
	s attribute=""
	f  d  i attribute="" q
	. s attribute=$o(@object@(attribute)) i attribute="" q
	. i $d(@object@(attribute))#10=1 s xml=xml_$$attribute(attribute,@object@(attribute),indent,select)
	. i indent'="" s xml=xml_$c(13,10)
	q xml
	
	
attribute(name,value,indent,select,bAddCrlf)	; Public ; Create xml attribute
	; Usage:
	;  w $$attribute(name,value,[indent],[select],[bAddCrlf]),crlf
	; Inputs:
	;  name     - attribute name
	;  value    - attribute value (unescaped data)
	;  indent   - string of spaces to indent output by (defaults to one space)
	;  select   - XPath style selection string eg "@attribute|@attribute|..."
	;  bAddCrlf - If passed and true, append the crlf terminator to the output
	; Outputs:
	;  $$attribute  - attribute value pair with escaped data
	;
	i '$$selAttribute($g(select),"@"_name) q ""
	q $g(indent)_" "_name_"='"_$$toXml(value)_"'"_$s($g(bAddCrlf):crlf,1:"")
	
	
selAttribute(select,attribute)	; Public ; Is attribute in selection filter
	;
	i select="" q 1 ; No filter
	i ("|"_select_"|")["|@*|" q 1
	i ("|"_select_"|")[("|"_attribute_"|") q 1
	q 0
	
	
utf8(string)	; Private ; Convert an ASCII string to UTF-8
	;
	q string
	n out,x,c
	;
	s out=""
	f x=1:1:$l(string) d
	. s c=$e(string,x)
	. s out=out_$$utf8c(c)
	q out
	
	
utf8c(c)	; Private ; Convert an ASCII character to UTF-8
	;
	n a
	;
	s a=$a(c)
	i a<128 q c
	i a<2048 q $c(192+(a\64),128+(a#64))
	i a<65536 q $c(224+(a\4096),128+((a\64)#64),128+(a#64))
	i a<2097152 q $c(240+(a\262144),128+((a\4096)#64),128+((a\64)#64),128+(a#64))
	i a<67108863 q $c(248+(a\16777216),128+((a\262144)#64),128+((a\4096)#64),128+((a\64)#64),128+(a#64))
	q $c(252+(a\1073741824),128+((a\16777216)#64),128+((a\262144)#64),128+((a\4096)#64),128+((a\64)#64),128+(a#64))
	
	
toXml(string)	; Public ; Escape a string as an xml attribute value
	; Usage:
	;  s xmlString=$$toXml(string)
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
	. i "<>""&'"_$c(13,10)[c s out=out_"&#"_$a(c)_";" q
	. s out=out_c
	q out
	
	
select(select,element)	; Public ; Is element in selection filter
	;
	i ("|"_select_"|")[("|"_element_"|") q 1
	q 0
	
	
getAttribute(line,attribute)	; Public ; Parse out the value of an attribute from a line of xml
	;
	n start,q
	;
	s start=$f(line,attribute_"=")
	i 'start q ""
	;
	s q=$e(line,start)
	q $p($e(line,start+1,$l(line)),q,1)
