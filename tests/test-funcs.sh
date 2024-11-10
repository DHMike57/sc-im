#!/usr/bin/env -S bash
## SEE https://github.com/lehmannro/assert.sh for usage

#Exit immediately if a command exits with a non-zero status.
set -e

NAME=test-funcs

VALGRIND_CMD='valgrind -v --log-file=${NAME}_vallog --tool=memcheck --track-origins=yes --leak-check=full --show-leak-kinds=all --show-reachable=no'
. assert.sh

CMD='
set calc_order="bycols"\n
let A0=@rand\n
let A1=@rand(0,1000)\n
let A2=@rand(1000,0)\n
let A3=@rand(1000,1000)\n
let A4=@rand(-10,0)\n
let b0=@prand(6)\n
let b1=@prand(6)\n
let b2=@nrand\n
let b3=@nrand\n
let b4=@xrand(5)\n
let b5=@xrand(0.5)\n
let A5=@find(":","st:ring:a",1)\n
let A6=@find(":","st:ring:a",2)\n
let A7=@find(":","st:ring:a",-1)\n
let A8=@find(":","st:ring:a",-2)\n
recalc\n
GETNUM A0\n
GETNUM A1\n
GETNUM A2\n
GETNUM A3\n
GETNUM A4\n
GETNUM B0\n
GETNUM B1\n
GETNUM B2\n
GETNUM B3\n
GETNUM B4\n
GETNUM B5\n
GETNUM A5\n
GETNUM A6\n
GETNUM A7\n
GETNUM A8\n
'
EXP="
0.823720814285708\n\
984\n\
0\n\
1000\n\
-5\n\
6\n\
10\n\
0.351318769677963\n\
-0.5089201755285\n\
0.346454045097051\n\
1.3561880949397\n\
3\n\
8\n\
8\n\
3\n\
"
# need this to get coverage of seed generation
CMD2='
let A0=@rand\n
recalc\n
'
#median
CMD3='
let G0 = @median(A0:F0)\n
let G1 = @median(A1:F1)\n
let G2 = @median(A2:F2)\n
let G3 = @median(A3:F3)\n
let G4 = @median(A4:F4)\n
let G5 = @median(A5:F5)\n
let G6 = @median(A6:F6)\n
let G7 = @median(A7:F7)\n
let G8 = @median(A8:F8)\n
recalc\n
GETNUM G0\n
GETNUM G1\n
GETNUM G2\n
GETNUM G3\n
GETNUM G4\n
GETNUM G5\n
GETNUM G6\n
GETNUM G7\n
GETNUM G8\n
'
EXP3="
7\n\
3.5\n\
3\n\
3\n\
3.5\n\
3\n\
2\n\
2\n\
-1
"
# sumprod
CMD4='
let E24 = @sumprod(A20:A22,C20:C22)\n
let E25 = @sumprod(A20:A22,C20:C22,@eqs(G20,"a"))\n
let E26 = @sumprod(A20:B22,C20:D22,A20<20)\n
let E27 = @sumprod(A20:B22,C20:D22)\n
recalc\n
GETNUM E24\n
GETNUM E25\n
GETNUM E26\n
GETNUM E27\n
'

EXP4="
32\n\
22\n\
102\n\
532
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

# @rand with seed generation
assert "echo -e '${CMD2}' | $VALGRIND_CMD ../src/sc-im ${NAME}.sc --nocurses --nodebug --quit_afterload 2>&1 |grep -v '^$\|Interp\|Change\|wider'" ""
check_log
mv ${NAME}_vallog ${NAME}_2_vallog
export SCIM_RAND_SEED=0
#echo -e "${CMD}" | ../src/sc-im ${NAME}.sc --nocurses --nodebug --quit_afterload 2>&1

# @rand family and @find
assert "echo -e '${CMD}' | $VALGRIND_CMD ../src/sc-im ${NAME}.sc --nocurses --nodebug --quit_afterload 2>&1 |grep -v '^$\|Interp\|Change\|wider\|invalid'" $EXP
check_log
mv ${NAME}_vallog ${NAME}_1_vallog

# @median
assert "echo -e '${CMD3}' | $VALGRIND_CMD ../src/sc-im ${NAME}.sc --nocurses --nodebug --quit_afterload 2>&1 |grep -v '^$\|Interp\|Change\|wider\|invalid'" $EXP3
check_log
mv ${NAME}_vallog ${NAME}_3_vallog

# @sumprod
assert "echo -e '${CMD4}' | $VALGRIND_CMD ../src/sc-im ${NAME}.sc --nocurses --nodebug --quit_afterload 2>&1 |grep -v '^$\|Interp\|Change\|wider\|invalid'" $EXP4
check_log
mv ${NAME}_vallog ${NAME}_4_vallog

if [ "$1" != "keep-vallog" ];then
   rm ${NAME}_?_vallog
   rm -f ${NAME}_vallog*
fi

assert_end ${NAME}
