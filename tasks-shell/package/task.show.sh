PROG_SOURCE=$(dirname "$(dirname "$(readlink -f "$(which task.select)")")")
source "$PROG_SOURCE"/common.sh
echo.info "Project: $(cur.project) Task: $(cur.taskId)"
task "$(cur.taskId)" list 2> /dev/null
task parentTaskId:"$(cur.taskId)" +todo todos 2> /dev/null
