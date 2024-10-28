
#!/usr/bin/env -S bash
## SEE https://github.com/lehmannro/assert.sh for usage

#Exit immediately if a command exits with a non-zero status.
set -e

NAME=test-crypt

VALGRIND_CMD='valgrind -v --log-file=${NAME}_vallog --tool=memcheck --track-origins=yes --leak-check=full --show-leak-kinds=all --show-reachable=no'
. assert.sh

CMD='
LET A0=42\n
SAVE'
EXP="File \"test-crypt.sc.cpt\" written (encrypted)."
export CCRYPT_KEY=secret

assert "echo -e '${CMD}' | $VALGRIND_CMD ../src/sc-im ${NAME}.sc.cpt --nocurses --nodebug --quit_afterload 2>&1 |grep -v '^$\|Interp\|Change\|wider'" "${EXP}"

#we check valgrind log
assert_iffound_notcond ${NAME}_vallog "definitely lost.*bytes" "0 bytes"
assert_iffound_notcond ${NAME}_vallog "indirectly lost.*bytes" "0 bytes"
assert_iffound_notcond ${NAME}_vallog "possibly lost.*bytes" "0 bytes"
assert_iffound_notcond ${NAME}_vallog "Uninitialised value was created by a heap allocation"
assert_iffound_notcond ${NAME}_vallog "Conditional jump or move depends on uninitialised value"
assert_iffound_notcond ${NAME}_vallog "Invalid read of size"
assert_iffound_notcond ${NAME}_vallog "Invalid write of size"
assert_iffound_notcond ${NAME}_vallog "Invalid free() / delete"


EXP=42
CMD='
GETNUM A0\n
'

assert "echo -e '${CMD}' | $VALGRIND_CMD ../src/sc-im ${NAME}.sc.cpt --nocurses --nodebug --quit_afterload 2>&1 |grep -v '^$\|Interp\|Change\|wider'" $EXP

if [ "$1" != "keep-vallog" ];then
    rm ${NAME}_vallog
fi
rm ${NAME}.sc.cpt

assert_end ${NAME}
