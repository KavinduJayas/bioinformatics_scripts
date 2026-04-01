awk '/^S/{print ">"$2;print $3}' "${1:--}"
