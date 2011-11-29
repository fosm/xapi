 ; Time Class 
 ; Summary of functions (see comments above function label for details)
 ;
 ; standard argument abbreviations are:
 ;
 ;   t1 - 12 hour alphabetic time: HH:MM am/pm
 ;   t2 - 24 hour clock delimited time : HH:MM
 ;   te - entered time  eg. 'T' '24/9/91' - many possible formats
 ;   th - $h time (seconds since midnight)
 ;   ti - 24 hour clock internal time  : HHMM
 ;
 ; Validation functions: return 0 if invalid time
 ;
 ; $$tmv1(te) - transform external as entered to HH:MMxx (am/pm)
 ; $$tmv2(te) - transform external as entered to HH:MM
 ; $$tmvh(te) - transform external as entered to $h seconds
 ; $$tmvi(te) - transform external as entered to HHMM
 ;
 ; time validation functions accept value of: 
 ;
 ;   24 hour clock eg. 23:05
 ;   12 hour clock eg. 11:05pm
 ;   't' for time now
 ;
 ;  any delimiter can be used
 ;  if no minutes are entered 00 minutes is assumed
 ;  if 3 digits are entered hMM is assumed
 ;  if am/pm is not specified am is assumed
 ;
 ; Functions to transform valid times:
 ;
 ; $$tmt1h(t1) - transform 12 hour time to $h format
 ; $$tmt1i(t1) - transform 12 hour time to HHMM
 ; $$tmt2h(t2) - transform 24 hour time to $h format
 ; $$tmt2i(t2) - transform 24 hour time to HHMM
 ; $$tmth1(th) - transform $h time to 12 hour time
 ; $$tmth2(th) - transform $h time to 24 hour time
 ; $$tmthi(th) - transform $h time to HHMM
 ; $$tmths(th) - transform $h time to HHMMSS (hours, minutes, seconds)
 ; $$tmti1(ti) - transform HHMM to 12 hour time
 ; $$tmti2(ti) - transform HHMM to 24 hour time
 ; $$tmtih(ti) - transform HHMM to $h time
 ;
 ; Constants:
 ;
 ; $$time  - time now in $h HHMM HH:MM HH:MM formats delimited by space
 ; $$time1 - time now in 12 hour format
 ; $$time2 - time now in 24 hour format
 ; $$timeh - time now as $h time
 ; $$timei - time now as HHMM
 
 
time() ; Public ; Time now as $h, HHMM, HH:MM and HH:MMxx delimited by space
 n z s z=$$timeh
 q z_" "_$$tmthi(z)_" "_$$tmth2(z)_" "_$$tmth1(z)
 
 
time1() ; Public ; Time now in 12 hour format
 q $$tmth1($$timeh)
 
 
time2() ; Public ; Time now in 24 hour format
 q $$tmth2($$timeh)
 
 
timeh() ; Public ; Time now as $h time
 q $p($h,",",2)
 
 
timei() ; Public ; Time now as HHMM
 q $$tmthi($$timeh)
 
 
tmt1h(t2) ; Public ; Transform 12 hour time to $h format
 ;
 i t2="" q ""
 q $e(t2,6,7)="pm"*12+$e(t2,1,2)*60+$e(t2,4,5)*60
 
 
tmt1i(t2) ; Public ; Transform 12 hour time to HHMM
 ;
 i t2="" q ""
 q ($e(t2,6,7)="pm"*12+$e(t2,1,2))_$e(t2,4,5)
 
 
tmt2h(t2) ; Public ; Transform 24 hour time to $h format
 ;
 i t2="" q ""
 q $e(t2,1,2)*60+$e(t2,4,5)*60
 
 
tmt2i(t2) ; Public ; Transform 24 hour time to HHMM
 ;
 q $e(t2,1,2)_$e(t2,4,5)
 
 
tmth1(th) ; Public ; Transform $h time to 12 hour time
 ;
 i th="" q ""
 n %h,%m,%s
 d tmtx9
 q $$tmtx4
 
 
tmth2(th) ; Public ; Transform $h time to 24 hour time
 ;
 i th="" q ""
 n %h,%m,%s
 d tmtx9
 q %h_":"_%m
 
 
tmthi(th) ; Public ; Transform $h time to HHMM
 ;
 i th="" q ""
 n %h,%m,%s
 d tmtx9
 q %h_%m
 
 
tmths(th) ; Public ; Transform $h time to HHMMSS
 ;
 i th="" q ""
 n %h,%m,%s
 d tmtx9
 q %h_%m_%s
 
 
tmti1(ti) ; Public ; Transform HHMM to 12 hour time
 ;
 i ti="" q ""
 n %h,%m,%s
 s %h=$e(ti,1,2),%m=$e(ti,3,4)
 q $$tmtx4
 
 
tmti2(ti) ; Public ; Transform HHMM to 24 hour time
 ;
 i ti="" q ""
 q $e(ti,1,2)_":"_$e(ti,3,4)
 
 
tmtih(ti) ; Public ; Transform HHMM to $h time
 ;
 i ti="" q ""
 q $e(ti,1,2)*60+$e(ti,3,4)*60
 
 
tmv1(te) ; Public ; Transform external as entered to HH:MMxx (am/pm)
 ;
 i te="" q ""
 n %h,%m,%s
 i '$$tmvx q 0
 q $$tmtx4
 
 
tmv2(te) ; Public ; Transform external as entered to HH:MM
 ;
 i te="" q ""
 n %h,%m,%s
 i '$$tmvx q 0
 q $$tmti2(%h_%m)
 
 
tmvh(te) ; Public ; Transform external as entered to $h seconds
 ;
 i te="" q ""
 n %h,%m,%s
 i '$$tmvx q 0
 q $$tmtih(%h_%m)
 
 
tmvi(te) ; Public ; Transform external as entered to HHMM
 ;
 i te="" q ""
 n %h,%m,%s
 i '$$tmvx q 0
 q %h_%m
 
 
tmvx() ; Private ; Validate and default external time
 ;
 ; $$tmvx - validate and default external time
 ;         - needs te=time to validate
 ;         - returns %h, %m = hours, minutes padded with leading zeros
 ;
 ; 1) tmvx2: parse input
 ; 2) i %a..: convert alpha suffix to 1/0 flag (0=am,1=pm,other=error)
 ; 3) tmtx1:  check hours, minutes
 ;
 k %h,%m
 n %a s %a=""
 i '$$tmvx2 q 0
 i %a'="" s %a=$f(" AM PM"," "_%a)-2-$l(%a)/3 i %a#1 q 0
 i ($l(%h)>2)!(%h'?1n.n)!(%h>23)!((%h>12)&(%a)) q 0
 i ($l(%m)>2)!(%m'?.n)!(%m>59) q 0
 i %a s %h=%h#12+12
 s %h=$e(100+%h,2,3),%m=$e(100+%m,2,3)
 q 1
 
 
tmvx2() ; Private ; Parse input:--> %h, %m defined if parses ok, %a=am/pm suffix
 ;                 returns 1 if managed to parse, else 0
 ;
 i te?.e1l.e s te=$$upper^%vc1str(te)
 ;
 ;    time="T"
 ;
 i te="T" s th=$p($h,",",2) d tmtx9 q 1
 ;
 ;    eeeU strip am/pm suffix, put into %a
 ;
 i te?.e1u.u d
 .  n %i
 .  f %i=$l(te):-1:0 q:$e(te,%i)?1n
 .  s %a=$e(te,%i+1,99),te=$e(te,1,%i)
 .  f  q:%a'?1p.e  s %a=$e(%a,2,99) ; should strip all punctuation??
 .  q
 ;
 ;    nnnn - pad with zeroes
 ;
 i te?.n d  q 1
 .  i $l(te)<3 s te=te_"00"
 .  i $l(te)=3 s te="0"_te
 .  s %h=$e(te,1,2),%m=$e(te,3,99)
 .  q
 ;
 ;    other - look for delimiter
 ;
 i te'?.n d  q 1
 .  n %i
 .  f %i=1:1 i $e(te,%i)'?1n,$e(te,%i)?.p q
 .  s %h=$e(te,1,%i-1),%m=$e(te,%i+1,99)
 .  q
 ;
 q 0
 
 
tmtx4() ; Private ; reformat %h, %m as HH:MMxx
 q $e(100+$s(%h>12:%h-12,1:%h),2,3)_":"_%m_$s(%h>11:"pm",1:"am")
 
 
tmtx9 ; Private ; extract %h, %m, %s from $h seconds
 s %m=th\60
 s %h=$e(100+(%m\60),2,3),%m=$e(100+(%m#60),2,3),%s=$e(100+(th#60),2,3)
 q



