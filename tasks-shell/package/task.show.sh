PROG_SOURCE=$(dirname "$(dirname "$(readlink -f "$(which task.select)")")")
source "$PROG_SOURCE"/common.sh
echo.info "Project: $(cur.project) Task: $(cur.task)"
task "$(cur.task)" list 2> /dev/null
task parentTaskId:"$(cur.task)" +todo todos 2> /dev/null
