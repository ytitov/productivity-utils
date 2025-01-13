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
  curWi="$(cat "$CUR_WORKITEM" || echo "no-workitem-selected")"
  checkValue=$(echo "$curWi" | xargs)
  if [ "$checkValue" == "" ]; then
    echo "no-workitem-selected"
  else
    echo "$checkValue"
  fi
}


cur.workitemId() {
  cur.workitem | jq -c '.id'
}

import_as_task() {
  local projname="notset"
  projname="$(cat "$CUR_PROJECT")"
  echo "Asked to import: $1 into tasks project: $projname" >> "$TASKDATA"/log.txt
  local adofile="$1"
  local workitemid="$(cat "$adofile" | jq -c '.id')"
  local title="$(cat "$adofile" | jq -c '.fields."System.Title"')"
  local state="$(cat "$adofile" | jq -c '.fields."System.State"')"
  descr="$(cat $adofile | jq -c '.fields."System.Description"')"
  assignedTo="$(cat $adofile | jq -c '.fields."System.AssignedTo".displayName')"
  createdBy="$(cat $adofile | jq -c '.fields."System.CreatedBy".displayName')"
  startDate="$(cat $adofile | jq -c '.fields."Microsoft.VSTS.Scheduling.StartDate"')"
  local dueDate="$(cat $adofile | jq -c '.fields."Custom.SLACERTDate"')"
  local extraParams=""
  if [[ ! $dueDate == "null" ]]; then
    extraParams="$extraParams due:$dueDate"
  fi
  if [[ "$state" =~ Closed ]]; then
    echo.info "Looks like this is Closed, marking the task as done"
    extraParams="$extraParams status:done"
  fi
  taskid=$(task \( workitemid:$workitemid \) modify $extraParams "workitem-$workitemid $title" || task.add $extraParams workitem:$workitemid add "workitem-$workitemid $title" || echo "ERROR: importing ado item failed")
}
