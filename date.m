date	; Date Class
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
	
	
toNumber(date)	; Public ; Convert an ISO date to a form suitable for numeric comparison
	;
	q $tr(date,"-:TZ","")

toZulu(timestamp)	; Public ; Convert a internal date/time to ISO zulu
	q $tr("CcYy-Mm-DdTHh:Nn:SsZ","CcYyMmDdHhNnSs",timestamp)	
	
nowZulu()	; Public ; Returns date/time in iso format for now using Zulu / GMT timezone
	;
	; Need to adjust ^date("timezoneOffset") when timezones change!
	q $$toZulu($$dtthi^date($$hAddSeconds^date($h,3600*^date("timezoneOffset"))))
	
	
hAddSeconds(hDateTime,seconds)	; Public ; Add seconds to a date time in $h format
	;
	n date,time
	;
	s date=$p(hDateTime,",",1)
	s time=$p(hDateTime,",",2)
	s time=time+seconds
	s date=date+(time\86400)
	s time=time#86400
	q date_","_time
	
	
	
	; Function index:
	; $$dateval  - Validate and transform external date
	; $$datetran - date transformation
	; $$dtthi  - transform $h date,time to internal yyyymmddhhmmss
	; $$dttia  - transform internal yyyymmddhhmmss to dd-mmm-yy hh:mm
	; $$dttid  - transform internal yyyymmddhhmmss to dd/mm/yy hh:mm
	;                                              or mm/dd/yy hh:mm
	; $$dttih  - transform internal yyyymmddhhmmss to $h date,time
	; $$now    - date and time now as yyyymmddhhmmss
	; $$nowx   - date and time now as dd-mmm-yy hh:mm
	; $$today  - today in formats dh di da dd delimited by space
	; $$todaya - today as dd-mon-yy
	; $$todayd - today as dd/mm/yy or mm/dd/yy
	; $$todayh - today as $h date
	; $$todayi - today as yyyymmdd
	; $$format   - valid date formats error message text
	
	; Missing information defaults to day, month and year in argument ti.
	; missing century defaults based on user defined window before and
	; after current year.
	
	; Date format based on locale of user.  Currently two locales are
	; supported: US and European
	
	; Date validation functions accept value of:
	;   1) T + or - days  eg. "T+2", "t-5"
	;   2) dd/mm/[cc]yy or mm/dd/[cc]yy eg. "31/12", "31", "/12/88", "/31/1988"
	;   3) dd mon [cc]yy eg. "13-Oct"
	;   4) ddmon[cc]yy eg. "13OCT88", "1jan1987"
	;   5) ddmm[cc]yy or mmdd[cc]yy eg "131088" or "13102001"
	
	
dayname(dateh)	; Private ; Transform $h format to day of the week
	;
	q $p($$datxd," ",dateh#7+1)
	
	
days(y,m)	; Private ; Get days in month m of year y (or days in year)
	; Get days in month m of year y (or days in year)
	; If only year is passed returns days in year.
	; If year and month number passed returns days in month.
	; Usage:
	;  s ddd=$$days(cccyy[,mm])
	; Inputs:
	;  cccyy  = year of interest
	;  mm     = month of interest (optional)
	; Outputs:
	;  $$days = number of days in year or month
	;
	n v
	;
	i '$d(m) s v=365,m=2 i 1
	e  s v=$P("31-28-31-30-31-30-31-31-30-31-30-31","-",m)
	i +m=2,y#4=0,y#400=0 s v=v+1
	i +m=2,y#4=0,y#100 s v=v+1
	q v
	
	
datetran(date,source,target)	; Public ; Transform date, formats are: a, i, d or h
	; Usage:
	;  s date=$$datetran(date,source,target)
	; Inputs:
	;  date = date in source format
	;  source = format of input date (a,i,h,d)
	;  target = format of output date (a,i,h,d)
	; Outputs:
	;  date = date in target format
	; Notes:
	;  a - alphabetic format, dd-mmm-[ccc]yy
	;  i - internal format, cccyymmdd
	;  h - $h format, no of days before or after 31-Dec-1840
	;  d - decimal format, dd/mm/[ccc]yy or mm/dd/[ccc]yy
	;
	n cccyy,mm,dd
	;
	i date="" q ""
	;
	; First convert to standard format
	i source="a" d atoz(date,.cccyy,.mm,.dd)
	i source="i" d itoz(date,.cccyy,.mm,.dd)
	i source="h" d htoz(date,.cccyy,.mm,.dd)
	i source="d" d dtoz(date,.cccyy,.mm,.dd)
	;
	; Now convert standard form to required external format
	i target="a" q $$ztoa(cccyy,mm,dd)
	i target="i" q $$ztoi(cccyy,mm,dd)
	i target="h" q $$ztoh(cccyy,mm,dd)
	i target="d" q $$ztod(cccyy,mm,dd)
	q error
	
	
dateval(date,target)	; Public ; Validate and transform date, formats are: a, i, d or h
	;
	n cccyy,mm,dd
	;
	i date="" q ""
	;
	i '$$valx(date,.cccyy,.mm,.dd) q 0
	i target="a" q $$ztoa(cccyy,mm,dd)
	i target="i" q $$ztoi(cccyy,mm,dd)
	i target="h" q $$ztoh(cccyy,mm,dd)
	i target="d" q $$ztod(cccyy,mm,dd)
	q 0
	
	
valx(datex,cccyy,mm,dd)	; Private ; Validate external date, return year, month and day components
	; Usage:
	;  s ok=$$valx(datex,.cccyy,.mm,.dd)
	; Inputs:
	;  datex  = date in any external format (eg 1/1/97, t+5, 1-Jan)
	; Outputs:
	;  $$valx = 1 if date valid, 0 if invalid
	;  cccyy  = year
	;  mm     = month
	;  dd     = day
	;
	; Pare the date into component parts
	i '$$parse(datex,.cccyy,.mm,.dd) q 0
	;
	; Expand and validate
	q $$expv(.cccyy,.mm,.dd)
	
	
parse(datex,cccyy,mm,dd)	; Private ; Parse date in external form
	;
	n locale
	;
	; Convert to uppercase
	i datex?.e1l.e s datex=$$upper^%vc1str(datex)
	;
	; t, t+n, t-n, +n, -n - today's date plus or minus a bit
	i $e(datex,1)="T" q $$t(datex,.cccyy,.mm,.dd)
	i $e(datex,1)="+" q $$plus(datex,.cccyy,.mm,.dd)
	i $e(datex,1)="-" q $$minus(datex,.cccyy,.mm,.dd)
	;
	s locale=$$locale
	;
	; Six plus digits (ddmm[ccc]yy or mmdd[ccc]yy)
	i datex?.n,locale="EUROPE" d  q 1
	. s dd=$e(datex,1,2)
	. s mm=$e(datex,3,4)
	. s cccyy=$e(datex,5,$l(datex))
	;
	i datex?.n,locale="US" d  q 1
	. s dd=$e(datex,3,4)
	. s mm=$e(datex,1,2)
	. s cccyy=$e(datex,5,$l(datex))
	;
	;  ddmmm[ccc]yy - break on alpha
	i datex?1.2n3a.n d  q 1
	. n p1,p2
	. f p1=2:1 i $e(datex,p1)?1a q
	. f p2=p1+1:1 i $e(datex,p2)'?1a q
	. s dd=$e(datex,1,p1-1)
	. s mm=$e(datex,p1,p2-1)
	. s mm=$f($$datxmu,mm)-1-$l(mm)/4+1
	. s cccyy=$e(datex,p2,$l(datex))
	;
	;  eepee - Look for a delimiter
	i datex?.e1p.e,datex'?1.p d  q 1
	. n i,p
	. f i=1:1:$l(datex) i $e(datex,i)?1p s p=$e(datex,i) q
	. i locale="EUROPE" d
	. . s dd=$p(datex,p,1)
	. . s mm=$p(datex,p,2)
	. i locale="US" d
	. . s dd=$p(datex,p,2)
	. . s mm=$p(datex,p,1)
	. . i datex?.e1p1.a.e d
	. . . s dd=$p(datex,p,1)
	. . . s mm=$p(datex,p,2)
	. i mm'?1.n i mm'="" s mm=$f($$datxmu,mm)-1-$l(mm)/4+1
	. s cccyy=$p(datex,p,3,99)
	;
	q 0
	
	
t(datex,cccyy,mm,dd)	; Private ; Today +- number of days
	; t|t+nn|t-nn
	;
	n offset
	;
	i datex="T" d htoz($h,.cccyy,.mm,.dd) q 1
	i datex?1"T+"1.n q $$plus($e(datex,2,99),.cccyy,.mm,.dd)
	i datex?1"T-"1.n q $$minus($e(datex,2,99),.cccyy,.mm,.dd)
	q 0
	
	
plus(datex,cccyy,mm,dd)	; Private ; Today + number of days
	; +nn
	;
	n offset
	;
	i datex?1"+"1.n d  q 1
	. s offset=$e(datex,2,$l(datex))
	. d htoz($h+offset,.cccyy,.mm,.dd)
	q 0
	
	
minus(datex,cccyy,mm,dd)	; Private ; Today - number of days
	; -nn
	;
	n offset
	;
	i datex?1"-"1.n d  q 1
	. s offset=$e(datex,2,$l(datex))
	. d htoz($h-offset,.cccyy,.mm,.dd)
	q 0
	
	
format()	; Private ; Valid date formats as text message	
	;
	n locale
	;
	s locale=$$locale
	;
	i locale="EUROPE" q "Valid date formats: dd/mm/yy, ddmmyy, dd-mmm-yy, t (today), t+n or t-n"
	i locale="US" q "Valid date formats: mm/dd/yy, mmddyy, dd-mmm-yy, t (today), t+n or t-n"
	q 1/0
	
	
dtthi(horolog)	; Public ; Transform date/time in $h format to date/time in internal format
	;
	n datei,timei
	;
	s datei=$$datetran(+horolog,"h","i")
	s timei=$$tmths^time($p(horolog,",",2))
	q datei_timei
	
	
dttid(datetime)	; Public ; Transform date/time in internal format to dd/mm/[ccc]yy hh:mm
	;
	n datei,timei,dated,timex
	;
	d datetime(datetime,.datei,.timei)
	s dated=$$datetran(datei,"i","d")
	s timex=$$tmti2^time($e(timei,1,4))
	q dated_" "_timex
	
	
dttih(datetime)	; Public ; Transform date/time in internal format to date/time in $h format
	;
	n datei,timei,dateh,timeh
	;
	d datetime(datetime,.datei,.timei)
	s dateh=$$datetran(datei,"i","h")
	s timeh=($e(timei,1,2)*60*60)+($e(timei,3,4)*60)+$e(timei,5,6)
	q dateh_","_timeh
	
	
datetime(datetime,datei,timei)	; Private ; Derive datei and timei from datetime
	;
	n length
	;
	s length=$l(datetime)
	s datei=$e(datetime,1,length-6)
	s timei=$e(datetime,length-5,length)
	q
	
	
dttia(datetime)	; Public ; Transform date/time in internal format to date/time in dd-mmm-[ccc]yy hh:mm
	;
	n datei,timei,datea,timex
	;
	d datetime(datetime,.datei,.timei)
	s datea=$$datetran(datei,"i","a")
	s timex=$$tmti2^time($e(timei,1,4))
	q datea_" "_timex
	
	
now()	; Public ; Date and time now as cccyymmddhhmmss
	;
	q $$dtthi($h)
	
	
nowx()	; Public ; Date and time now as dd-mmm-[ccc]yy hh:mm
	;
	q $$dttia($$dtthi($h))
	
	
	
today()	; Public ; Today in formats h i a and d delimited by space
	; derive and use yyyymmdd for performance
	;
	n dateh,datei,datea,dated
	;
	s dateh=+$h
	s datei=$$datetran(dateh,"h","i")
	s datea=$$datetran(dateh,"h","a")
	s dated=$$datetran(dateh,"h","d")
	q dateh_" "_datei_" "_datea_" "_dated
	
	
	
todaya()	; Public ; Today as dd-mmm-[ccc]yy
	;
	q $$datetran(+$h,"h","a")
	
	
	
todayd()	; Public ; Today as dd/mm/[ccc]yy or mm/dd/[ccc]yy
	;
	q $$datetran(+$h,"h","d")
	
	
	
todayh()	; Public ; Today as $h date
	;
	q +$h
	
	
	
todayi()	; Public ; Today as cccyymmdd
	;
	q $$datetran(+$h,"h","i")
	
	
	
expv(cccyy,mm,dd)	; Private ; Expand and validate year month and day fields
	; Usage:
	;  d expv(.cccyy,.mm,.dd)
	; Inputs:
	;  cccyy   = year
	;  mm      = month
	;  dd      = day
	; Outputs:
	;  cccyy   = expanded and validated year
	;  mm      = expanded and validated month
	;  dd      = expanded and validated day
	;
	n todayi
	;
	s todayi=$$todayi
	;
	i cccyy_mm_dd'?.1"-".n q 0
	;
	; Year and century default
	; (any year is valid from -infinity to +infinity)
	i cccyy="" s cccyy=$$cccyy(todayi)
	i $l(cccyy)<2 s cccyy=$e(100+cccyy,2,3)
	s cccyy=$$ytocy(cccyy)
	;
	; Month default and validation
	i mm="" s mm=$$mm(todayi)
	i mm>12 q 0
	i mm<1 q 0
	s mm=$e(100+mm,2,3)
	;
	; Day default and validation
	i dd="" s dd=$$dd(todayi)
	i dd>$$days(cccyy,mm) q 0
	i dd<1 q 0
	s dd=$e(100+dd,2,3)
	q 1
	
	
	
htoz(dateh,cccyy,mm,dd)	; Private ; Convert $h date to cccyy, mm, dd
	; Algorithm:
	;  Convert $h date to number of days since 31 Dec -0001 then
	;  iteratively subtract 400 years, then 100 years, then 4 years
	;  then 1 year until less than 365 or 366 days remain.
	;  Derive month based on number of days remaining.
	;  Remainder is the day of the month.
	;  adjust is used to adjust the first iteration of each date
	;  period depending upon whether it is a leap year or not.
	; There is known to be a problem with year 0000.
	;
	n adjust
	;
	s adjust=0
	s dateh=dateh+672412
	;
	; Shortcut if year after 1992 then jump to days in 4 years
	;i dateh>727563 s cccyy=1992,dateh=dateh-727563 g htoz05
	;
	; Derive year
	s cccyy=0
	d htoz10(146097,400,.dateh,.cccyy) ; Number of days in 400 years
	i $$leap(cccyy) s adjust=1
	d htoz10(36524,100,.dateh,.cccyy) ; Number of days in 100 years
htoz05	i '$$leap(cccyy) s adjust=-1
	d htoz10(1461,4,.dateh,.cccyy) ; Number of days in 4 years
	i $$leap(cccyy) s adjust=1
	d htoz10(365,1,.dateh,.cccyy) ; Number of days in 1 year
	;
	; Derive month and day
	i $$leap(cccyy) s adjust=1
	d htoz20
	s dd=dateh
	;
	; Add leading zeros to years 0 through 999
	i $l(cccyy)<4 s cccyy=$e(10000+cccyy,2,5)
	s mm=$e(100+mm,2,3)
	s dd=$e(100+dd,2,3)
	q
	
	
htoz10(days,years,dateh,y)	; Private ; Iteratively subtract days from dateh until no longer possible
	; for each iteration add years to y.
	;
htoz11	i dateh'>(days+adjust) s adjust=0 q
	s dateh=dateh-days-adjust
	s y=y+years
	s adjust=0
	g htoz11
	
	
htoz20	; Private ; Calculate months
	;
	i dateh'>31 s mm=1,dateh=dateh q
	i dateh'>(59+adjust) s mm=2,dateh=dateh-31 q
	i dateh'>(90+adjust) s mm=3,dateh=dateh-(59+adjust) q
	i dateh'>(120+adjust) s mm=4,dateh=dateh-(90+adjust) q
	i dateh'>(151+adjust) s mm=5,dateh=dateh-(120+adjust) q
	i dateh'>(181+adjust) s mm=6,dateh=dateh-(151+adjust) q
	i dateh'>(212+adjust) s mm=7,dateh=dateh-(181+adjust) q
	i dateh'>(243+adjust) s mm=8,dateh=dateh-(212+adjust) q
	i dateh'>(273+adjust) s mm=9,dateh=dateh-(243+adjust) q
	i dateh'>(304+adjust) s mm=10,dateh=dateh-(273+adjust) q
	i dateh'>(334+adjust) s mm=11,dateh=dateh-(304+adjust) q
	s mm=12,dateh=dateh-(334+adjust)
	q
	
	
ztoh(cccyy,mm,dd)	; Private ; Convert cccyy, mm, dd to $h format (allows negative $h)
	;
	n cccyy1,days,month
	;
	; Calculate $h for end of preceeding year
	s cccyy1=cccyy-1
	s days=cccyy1*365
	s days=days+(cccyy1\4) ; Add leap years
	s days=days-(cccyy1\100) ; Subtract centuries
	s days=days+(cccyy1\400) ; Add leap centuries
	;
	; Subtract number of days between 31 December 0000 and 31 December 1840
	s days=days-672046
	;
	; Now add days in each month up to preceeding month
	f month=1:1:mm-1 s days=days+$$days(cccyy,month)
	;
	; Now add days
	s days=days+dd
	;
	q days
	
	
ztod(cccyy,mm,dd)	; Private ; Reformat cccyy, mm, dd to dd/mm/[ccc]yy or mm/dd/[ccc]yy
	;
	n locale
	;
	s locale=$$locale
	;
	i locale="EUROPE" q dd_"/"_mm_"/"_$$cytoy(cccyy)
	i locale="US" q mm_"/"_dd_"/"_$$cytoy(cccyy)
	q 1/0
	
	
ztoa(cccyy,mm,dd)	; Private ; Reformat cccyy, mm, dd to dd-mmm-[ccc]yy
	;
	q dd_"-"_$p($$datxm," ",mm)_"-"_$$cytoy(cccyy)
	
	
ztoi(cccyy,mm,dd)	; Private ; Transform cccyy, mm, dd to cccyymmdd format
	;
	q cccyy_mm_dd
	
	
dtoz(dated,cccyy,mm,dd)	; Private ; Convert dd/mm/[ccc]yy or mm/dd/[ccc]yy to cccyy, mm, dd
	;
	n locale
	;
	s locale=$$locale
	;
	i locale="EUROPE" d
	. s dd=$p(dated,"/",1)
	. s mm=$p(dated,"/",2)
	i locale="US" d
	. s mm=$p(dated,"/",1)
	. s dd=$p(dated,"/",2)
	s cccyy=$p(dated,"/",3)
	s dd=$e(100+dd,2,3)
	s mm=$e(100+mm,2,3)
	s cccyy=$$ytocy(cccyy)
	q
	
	
atoz(datea,cccyy,mm,dd)	; Private ; Convert alphabetic date to cccyy, mm, dd
	;
	n d,m,y
	;
	s d=$p(datea,"-",1)
	s m=$p(datea,"-",2)
	s y=$p(datea,"-",3)
	;
	s dd=$e(100+d,2,3)
	s mm=$$month(m)
	s cccyy=$$ytocy(y)
	q
	
	
month(mmm)	; Private ; Convert alpha month to numeric month
	;
	n mm
	;
	s mm=$f($$datxm,mmm)/4
	q $e(100+mm,2,3)
	
	
itoz(datei,cccyy,mm,dd)	; Private ; Convert internal [ccc]yymmdd date to cccyy, mm, dd format
	s dd=$$dd(datei)
	s mm=$$mm(datei)
	s cccyy=$$cccyy(datei)
	q
	
	
ytocy(year)	; Private ; Convert two digit year to century plus year using window
	;
	n window,todayi,ccc,yy,thresh
	;
	; Already in century plus year form
	i $l(year)>2 q year
	;
	; Get date window (or default to 50 years)
	s window=$g(^%vcvc("date_window"))
	i window="" s window=50
	;
	; Need to know current century and year
	s todayi=$$todayi
	s ccc=$$ccc(todayi)
	s yy=$$yy(todayi)
	;
	; Return the year based on the value entered the current year
	; and the date window
	s thresh=yy+window
	i thresh>100,(year+100)>thresh q (ccc)_year
	i thresh>100 q (ccc+1)_year
	i year>thresh q (ccc-1)_year
	q (ccc)_year
	
	
cytoy(year)	; Private ; Attempt to convert century plus year to two digit year using window
	; If year is outside window then will return century and year to
	; avoid ambiguity.
	;
	n window,todayi,cccyy,winlo,winhi
	;
	; Already in two digit year form
	i $l(year)=2 q year
	;
	; Get date window (or default to 50 years)
	s window=$g(^%vcvc("date_window"))
	i window="" s window=50
	;
	; Need to know current century and year
	s todayi=$$todayi
	s cccyy=$$cccyy(todayi)
	;
	; Calculate window bounds
	s winlo=cccyy-(100-window)
	s winhi=cccyy+window
	;
	; If within window bounds then return two digit year
	i year>winlo,year'>winhi q $e(year,$l(year)-1,$l(year))
	q year
	
	
locale()	; Private ; Derive locale for user
	;
	i $g(%usr)="" q "US"  ; Default to US if user not known
	;
	s locale=$p($g(^%vcmf("user",%usr)),%,6)
	i locale="" q "US"
	q locale
	
	
	; ----------------------
	; Date lexical functions
	; ----------------------
	
cccyy(datei)	; Private ; Get century from internal date
	;
	n length
	;
	s length=$l(datei)
	q $e(datei,1,length-4)
	
	
ccc(datei)	; Private ; Get century from internal date
	;
	n length
	;
	s length=$l(datei)
	q $e(datei,1,length-6)
	
	
yy(datei)	; Private ; Get year from internal date
	;
	n length
	;
	s length=$l(datei)
	q $e(datei,length-5,length-4)
	
	
mm(datei)	; Private ; Get month from internal date
	;
	n length
	;
	s length=$l(datei)
	q $e(datei,length-3,length-2)
	
	
dd(datei)	; Private ; Get day from internal date
	;
	n length
	;
	s length=$l(datei)
	q $e(datei,length-1,length)
	
	
	
leap(y)	; Private ; Is year a leap year?
	;
	i y#400=0 q 1
	i y#100=0 q 0
	i y#4=0 q 1
	q 0
	
	; ---------
	; Constants
	; ---------
	
datxd()	; Private ; Thu Fri Sat Sun Mon Tue Wed
	;
	q "Thu Fri Sat Sun Mon Tue Wed"
	
	
datxm()	; Private ; Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec
	;
	q "Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec"
	
	
datxmu()	; Private ; JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC
	;
	q "JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC"
	
	
