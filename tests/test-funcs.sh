#!/usr/bin/env -S bash
## SEE https://github.com/lehmannro/assert.sh for usage

#Exit immediately if a command exits with a non-zero status.
set -e

NAME=test-funcs

VALGRIND_CMD='valgrind -v --log-file=${NAME}_vallog --tool=memcheck --track-origins=yes --leak-check=full --show-leak-kinds=all --show-reachable=no'
. assert.sh

CMD='
let A0=@rand\n
let A1=@rand(0,1000)\n
let A2=@rand(1000,0)\n
let A3=@rand(1000,1000)\n
let A4=@find(":","st:ring:a",1)\n
let A5=@find(":","st:ring:a",2)\n
let A6=@find(":","st:ring:a",-1)\n
let A7=@find(":","st:ring:a",-2)\n
recalc\n
GETNUM A0\n
GETNUM A1\n
GETNUM A2\n
GETNUM A3\n
GETNUM A4\n
GETNUM A5\n
GETNUM A6\n
GETNUM A7\n
'
EXP="
0.469834515679288\n\
610\n\
0.241806316754301\n\
1000\n\
3\n\
8\n\
8\n\
3
"
# need this to get coverage of seed generation
CMD2='
let A0=@rand\n
recalc\n
'

check_log(){
#we check valgrind log
assert_iffound_notcond ${NAME}_vallog "definitely lost.*bytes" "0 bytes"
assert_iffound_notcond ${NAME}_vallog "indirectly lost.*bytes" "0 bytes"
assert_iffound_notcond ${NAME}_vallog "possibly lost.*bytes" "0 bytes"
assert_iffound_notcond ${NAME}_vallog "Uninitialised value was created by a heap allocation"
assert_iffound_notcond ${NAME}_vallog "Conditional jump or move depends on uninitialised value"
assert_iffound_notcond ${NAME}_vallog "Invalid read of size"
assert_iffound_notcond ${NAME}_vallog "Invalid write of size"
assert_iffound_notcond ${NAME}_vallog "Invalid free() / delete"
}

assert "echo -e '${CMD2}' | $VALGRIND_CMD ../src/sc-im ${NAME}.sc --nocurses --nodebug --quit_afterload 2>&1 |grep -v '^$\|Interp\|Change\|wider'" ""
check_log
mv ${NAME}_vallog ${NAME}_1_vallog
export SCIM_RAND_SEED=0
assert "echo -e '${CMD}' | $VALGRIND_CMD ../src/sc-im ${NAME}.sc --nocurses --nodebug --quit_afterload 2>&1 |grep -v '^$\|Interp\|Change\|wider'" $EXP
check_log
mv ${NAME}_vallog ${NAME}_2_vallog

if [ "$1" != "keep-vallog" ];then
   rm ${NAME}_?_vallog
   rm -f ${NAME}_vallog*
fi

assert_end ${NAME}
