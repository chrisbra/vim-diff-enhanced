#!/bin/sh

for i in */; do
    cd "$i"
    algorithm=$(cat ./diff.txt)
    vim -u NONE -N --cmd ":let g:enhanced_diff_debug=1" --cmd ":source ~/.vim/plugin/EnhancedDiff.vim" \
    -c ':set acd' -c ":CustomDiff $algorithm" -c ':botright vsp +next' -c ':windo :diffthis' -c ':qa!' file* \
    > /dev/null  2>&1
    diff=`diff normal_diff.ok EnhancedDiff_normal.txt`
    if [ $? -ne 0 ]; then
	printf "Failure with test %s\n" "${i%%/}"
	printf "$diff\n"
	break
    else
	printf "Test %s: OK\n" "${i%%/}"
    fi
    cd ..
done
