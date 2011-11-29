string	; String Class
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


	
contains(string,substring,delimiter)	; Public ; Does string contain substring
	;
	q (delimiter_string_delimiter)[(delimiter_substring_delimiter)
	
	
upper(string)	; Public ; Convert string to upper case
	q $tr(string,"abcdefghijklmnopqrstuvwxyz","ABCDEFGHIJKLMNOPQRSTUVWXYZ")
	
	
lower(string)	; Public ; Convert string to lower case
	q $tr(string,"ABCDEFGHIJKLMNOPQRSTUVWXYZ","abcdefghijklmnopqrstuvwxyz")
	
toB64(txt) ; Public ; encode txt as base64
         n result,char64,pos,triple,bytenum,bits
         s result=""
         s char64="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
         f pos=1:3:$l(txt) d
         . s triple=$e(txt,pos,pos+2)
         . s bits=0
         . f bytenum=1:1:$l(triple) s bits=bits*256+$a(triple,bytenum)
         . i bytenum=3 s result=result_$e(char64,bits\262144+1)_$e(char64,bits\4096#64+1)_$e(char64,bits\64#64+1)_$e(char64,bits#64+1) q
         . i bytenum=2 s bits=bits*4,result=result_$e(char64,bits\4096+1)_$e(char64,bits\64#64+1)_$e(char64,bits#64+1)_"=" q
         . s bits=bits*16,result=result_$e(char64,bits\64+1)_$e(char64,bits#64+1)_"=="
         q result
 
 
fromB64(txt) ; Public ; Decode txt from base64
         n result,char64,pos,quad,bytenum,bits,worth
         s result=""
         s char64="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
         f pos=1:4:$l(txt) d
         . s quad=$e(txt,pos,pos+3)
         . s bits=0
         . f bytenum=1:1:$l(quad) d  q:worth<0
         . . s worth=$f(char64,$e(quad,bytenum))-2
         . . q:worth<0
         . . s bits=bits*64+worth
         . i worth'<0 s result=result_$c(bits\65536,bits\256#256,bits#256) q
         . i bytenum=4 s result=result_$c(bits\1024,bits\4#256) q
         . i bytenum=3 s result=result_$c(bits\16) q
         . n zer
         . s zer="fromB64^%vc1str\Bad base64 input"
         . d force^%vc9er
         q result
