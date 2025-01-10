PROG_SOURCE=$(dirname "$(dirname "$(readlink -f "$(which task.select)")")")
source "$PROG_SOURCE"/common.sh
echo.info "Selected Project: $(cur.project)"
