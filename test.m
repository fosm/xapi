test	;
	n $zt
	s $zt="s $zroutines="""_$zroutines_""" d error^test zgoto "_($zlevel-1)
	w !,"start"
	d sub1
	w !,"end"
	q
	
sub1	w !,"sub1 - start"
	d sub2
	w !,"sub2 - end"
	q
	
sub2	w !,"sub2 - start"
	w 1/0
	w !,"sub2 - end"
	q
	
	
error	;
	s $ze=""
	w !,"error^test"
	w !,$zstatus
	;
	q



open	s f="gaga.txt"
	o f:(READ:EXCEPTION="g fail")
	u 0 w "opened"
	c f
	q

fail	u 0 w "fail"
	q

	
