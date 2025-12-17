awk '/^S/{print ">"$2;print $3}' $1 > $(basename $1 .gfa).fa
