#!/usr/bin/env -S bash
## SEE https://github.com/lehmannro/assert.sh for usage

#Exit immediately if a command exits with a non-zero status.
set -e

NAME=test-read

VALGRIND_CMD='valgrind -v --log-file=${NAME}_vallog --tool=memcheck --track-origins=yes --leak-check=full --show-leak-kinds=all --show-reachable=no'
. assert.sh

CMD="
let A0 = 10\n\
let A1 = 11\n\
let B0 = 12\n\
let B1 = 13\n\
execute \"read ${NAME}.csv\"\n\
getnum A0\n\
movetosheet \"Sheet1\"\n\
getnum A0\n\
getnum {\"${NAME}.csv\"}!A0
"
EXP="
1\n\
10\n\
1
"
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
assert "echo -e '${CMD}' | $VALGRIND_CMD ../src/sc-im  --nocurses --nodebug --quit_afterload 2>&1 |grep -v '^$\|Interp\|Change\|wider'" $EXP
check_log
cp ${NAME}_vallog ${NAME}_1_vallog
assert "echo -e '${CMD}' | $VALGRIND_CMD ../src/sc-im ${NAME}.sc  --nocurses --nodebug --quit_afterload 2>&1 |grep -v '^$\|Interp\|Change\|wider'" $EXP
cp ${NAME}_vallog ${NAME}_2_vallog
check_log

if [ "$1" != "keep-vallog" ];then
   rm ${NAME}_?_vallog
fi

assert_end ${NAME}
