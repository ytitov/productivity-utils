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

export CUR_WORKITEM="$TASKDATA/.currentWorkitem.json";

cur.workitem() {
  touch "$CUR_WORKITEM"
  cat "$CUR_WORKITEM" || echo '{}'
}
export -f cur.workitem

cur.workitemId() {
  cur.workitem | jq -c '.id'
}
export -f cur.workitemId

import_as_task() {
  local projname="notset"
  projname="$(cat "$CUR_PROJECT")"
  echo.logtofile "Asked to import: $1 into tasks project: $projname" >> "$TASKDATA"/log.txt
  local adofile="$1"
  local workitemid="$(cat "$adofile" | jq -c '.id')"
  local title="$(cat "$adofile" | jq -c '.fields."System.Title"')"
  local state="$(cat "$adofile" | jq -c '.fields."System.State"')"
  descr="$(cat $adofile | jq -c '.fields."System.Description"')"
  assignedTo="$(cat $adofile | jq -c '.fields."System.AssignedTo".displayName')"
  createdBy="$(cat $adofile | jq -c '.fields."System.CreatedBy".displayName')"
  startDate="$(cat $adofile | jq -c '.fields."Microsoft.VSTS.Scheduling.StartDate"')"
  local dueDate="$(cat "$adofile" | jq -c '.fields."Custom.SLACERTDate"')"
  local extraParams="project:$projname"
  local status=""
  if [[ ! "$dueDate" == "null" ]]; then
    extraParams=" $extraParams due:$dueDate"
  fi
  if [[ "$state" =~ Closed ]]; then
    echo.logtofile "Looks like this is Closed, marking the task as done"
    status="status:done "
  fi
  numExist=$(task workitemid:"$workitemid" -DELETED export | jq -c length)
  numDeleted=$(task workitemid:"$workitemid" +DELETED export | jq -c length)
  echo.logtofile "Running a create or modify in order to import the workitem as a task: extraParams: $extraParams, workitemid: $workitemid, title: $title"
  if [ ! "$numDeleted" == "0" ]; then
    echo.error "This task was imported and deleted already or there was an error retreiving it"
  elif [ "$numExist" == "0" ]; then
    echo.logtofile Creating the workitem as a new task
    task "$extraParams" workitem:"$workitemid" "$status" add "workitem-$workitemid $title"  
    select.latest.task
  elif [ "$numExist" == "1" ]; then
    echo.logtofile Updating the existing task
    task \( workitemid:"$workitemid" \) -DELETED modify "$extraParams" "$status" "workitem-$workitemid $title" 
    select.latest.task
  else 
    echo.error "Came up with more than one task attached to a workitem, not sure how to import"
  fi
}
export -f import_as_task
