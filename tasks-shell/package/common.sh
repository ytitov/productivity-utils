export TASKRC=${TASKRC:-~/.taskrc}
export TASKDATA=${TASKDATA:-~/.tasks}
export CUR_PROJECT=$TASKDATA/.cur_project
export CUR_TASK=$TASKDATA/.cur_task
touch "$TASKRC"
PROG_SOURCE=$(dirname "$(dirname "$(readlink -f "$(which task.select)")")")
export INSTALL_CFG=$PROG_SOURCE/install.cfg
export NOTES_DIR="$TASKDATA/.notes";
export TMP_FOLDER=$TASKDATA/temp;
mkdir -p "$TMP_FOLDER"
mkdir -p "$NOTES_DIR"

# check if it already has the fields we need
checkfields="$(grep -i uda.parentTaskId < "$TASKRC")"
if [ "$checkfields" == "" ]; then
  echo "Adding required configs to task warrior"
  echo "turning confirmation to off.  Feel free to turn it back on if you wish"
  echo "### Do not edit below ###" >> "$TASKRC"
  task config confirmation off
  # these are for the todo's attached to each task
  task config uda.parentTaskId.label Parent Task
  task config uda.parentTaskId.description The actual task this entry belongs to
  task config uda.parentTaskId.type string

  # each todo is assigned a parent task id, and is tagged as a todo
  task config report.todos.columns parentTaskId,id,due,description
  task config report.todos.labels pId,id,due,description
  task config report.todos.sort parentTaskId,id
  task config report.todos.filter \( -DELETED \) and \( +todo \)

  task config report.list.columns id,workitemid,start.age,entry.age,depends.indicator,priority,project,tags,recur.indicator,scheduled.countdown,due,until.remaining,description.count,urgency
  task config report.list.context 1
  task config report.list.description Most details of tasks
  task config report.list.filter status:pending -WAITING -todo
  task config report.list.labels ID,wi,Active,Age,D,P,Project,Tags,R,Sch,Due,Until,Description,Urg

  echo "### END Do not edit ^^^" >> "$TASKRC"
fi


echo.error() {
  echo " 🚨 $*"
}

echo.info() {
  echo " 💡 $*"
}

echo.logtofile() {
  echo "$*" >> "$TASKDATA"/log.txt
}


cur.project() {
  touch "$CUR_PROJECT"
  curProj="$(cat "$CUR_PROJECT" || echo "Default")"
  checkValue=$(echo "$curProj" | xargs)
  if [ "$checkValue" == "" ]; then
    echo "Default"
  else
    echo "$checkValue"
  fi
}

cur.taskId() {
curTask="$(cur.task | jq -c '.id' || echo "0")"
  checkValue=$(echo "$curTask" | xargs)
  if [ "$checkValue" == "" ]; then
    echo "0"
  else
    echo "$checkValue"
  fi
}

cur.taskUuid() {
  curTask="$(cur.task | jq -c '.uuid' || echo "0")"
  checkValue=$(echo "$curTask" | xargs)
  if [ "$checkValue" == "" ]; then
    echo "0"
  else
    echo "$checkValue"
  fi
}

set.project() {
  echo "$*" > "$CUR_PROJECT"
}

cur.task() {
  cat "$CUR_TASK" || echo "{}"
}

set.task() {
  echo "$*" > "$CUR_TASK"
}

select.latest.task() {
  task export newest | jq -c '.[0]' > "$CUR_TASK"
}

select.task.withId() {
  if [ ! "$1" == "" ]; then
    task "$1" export | jq -c '.[0]' > "$CUR_TASK"
    echo.logtofile "Selected task with id $1 : $(cat "$CUR_TASK")"
  fi
}

#
# enable workitems is found
#
checkworkitem="$(grep -i uda.workitemid < "$TASKRC")"
enable_workitems="$(grep -i 'enableWorkitems=true' < "$INSTALL_CFG")"

if [ ! "$enable_workitems" == "" ]; then
  if [ "$checkworkitem" == "" ]; then
    echo "### Do not edit below ###" >> "$TASKRC"
    task config uda.workitemid.label Workitem
    task config uda.workitemid.description Workitem ID
    task config uda.workitemid.type string
    echo "### END Do not edit ^^^" >> "$TASKRC"
  fi
fi
checktaskuuid="$(grep -i uda.parentTaskUuid < "$TASKRC")"
if [ "$checktaskuuid" == "" ]; then
  echo "### Do not edit below ###" >> "$TASKRC"
  # these are for the todo's attached to each task
  # UUID seem to be more global, adding to fiture proof
  task config uda.parentTaskUuid.label Parent Task
  task config uda.parentTaskUuid.description The actual task this entry belongs to
  task config uda.parentTaskUuid.type string
  echo "### END Do not edit ^^^" >> "$TASKRC"
fi
