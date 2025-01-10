ARGS="$*"
PROG_SOURCE=$(dirname "$(dirname "$(readlink -f "$(which task.select)")")")
source "$PROG_SOURCE"/common.sh
curProj="$(cur.project)"
echo "Adding a task with args: $ARGS"
task "project:$curProj" add "$ARGS"
