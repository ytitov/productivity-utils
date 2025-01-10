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
