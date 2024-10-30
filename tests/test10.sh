#!/usr/bin/env -S bash
## SEE https://github.com/lehmannro/assert.sh for usage

#Exit immediately if a command exits with a non-zero status.
set -e

NAME=test10

VALGRIND_CMD='valgrind -v --log-file=${NAME}_vallog --tool=memcheck --track-origins=yes --leak-check=full --show-leak-kinds=all --show-reachable=no'
. assert.sh

CMD='
label A0 = "10"\n
label A1 = "10.1"\n
label A2 = "01:00"\n
label A3 = "01:00.1"\n
label A4 = "01:01:01"\n
label A5 = "00"\n
LET B0=@hmstosec(@sval("A",@myrow))\n
LET B1=@hmstosec(@sval("A",@myrow))\n
LET B2=@hmstosec(@sval("A",@myrow))\n
LET B3=@hmstosec(@sval("A",@myrow))\n
LET B4=@hmstosec(@sval("A",@myrow))\n
LET B5=@hmstosec(@sval("A",@myrow))\n
label C0 = @sectohms(B0)\n
label C1 = @sectohms(B1)\n
label C2 = @sectohms(B2)\n
label C3 = @sectohms(B3)\n
label C4 = @sectohms(B4)\n
label C5 = @sectohms(B5)\n
recalc\n
GETNUM B0\n
GETNUM B1\n
GETNUM B2\n
GETNUM B3\n
GETNUM B4\n
GETSTRING C0\n
GETSTRING C1\n
GETSTRING C2\n
GETSTRING C3\n
GETSTRING C4\n
GETSTRING C5\n
'
EXP="
10\n\
10.1\n\
60\n\
60.1\n\
3661\n\
00:10\n\
00:10.1\n\
01:00\n\
01:00.1\n\
01:01:01\n\
00:00
"
assert "echo -e '${CMD}' | $VALGRIND_CMD ../src/sc-im ${NAME}.sc --nocurses --nodebug --quit_afterload 2>&1 |grep -v '^$\|Interp\|Change\|wider'" $EXP
#we check valgrind log
assert_iffound_notcond ${NAME}_vallog "definitely lost.*bytes" "0 bytes"
assert_iffound_notcond ${NAME}_vallog "indirectly lost.*bytes" "0 bytes"
assert_iffound_notcond ${NAME}_vallog "possibly lost.*bytes" "0 bytes"
assert_iffound_notcond ${NAME}_vallog "Uninitialised value was created by a heap allocation"
assert_iffound_notcond ${NAME}_vallog "Conditional jump or move depends on uninitialised value"
assert_iffound_notcond ${NAME}_vallog "Invalid read of size"
assert_iffound_notcond ${NAME}_vallog "Invalid write of size"
assert_iffound_notcond ${NAME}_vallog "Invalid free() / delete"
if [ "$1" != "keep-vallog" ];then
    rm ${NAME}_vallog
fi

assert_end ${NAME}
