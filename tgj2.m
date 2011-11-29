pipe	; Test output to named pipe
	s pipe="output.pipe"
	o pipe:(nowrap:stream:fifo)
	u pipe
	f i=1:1:100000 w $tr($j("",1000)," ","a")
	w "z"
	c pipe
	q
