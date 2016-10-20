#!/bin/sh
# set -ex

for i in */; do
    cd "$i"
    algorithm=$(cat ./diff.txt)
    description=''
    test -f description.txt && description=$(cat ./description.txt)
    ( LC_ALL=C vim -N --cmd ":let g:enhanced_diff_debug=1" -c ':set acd' \
    -c "if filereadable('vimrc') | so vimrc |endif'" \
    -c ":EnhancedDiff $algorithm" -c ':botright vsp +next' -c ':windo :diffthis' -c ':qa!' file* \
    > /dev/null ) 2>&1 | sed '/Vim: Warning: Output is not to a terminal/d'
    diff=`diff normal_diff.ok EnhancedDiff_normal.txt`
    if [ $? -ne 0 ]; then
	printf "Failure with test %s\n" "${i%%/}"
	printf "$diff\n"
	break
    else
	if [ -z "$description" ]; then
	    printf "Test %s: OK\n" "${i%%/}"
	else
	    printf "Test %s (%s): OK\n" "${i%%/}" "$description"
	fi
    fi
    cd ..
done
