# see https://taskwarrior.org/docs/terminology/ for terminology used in taskwarrior.. very useful
{
  pkgs ? import <nixpkgs> { },
}:
let
  taskHelpMessage = ''
    💡 Operating on a Task:
    🔹 'task.help' shows this message
    🔹 'task.show' shows the selected task and the related todos
    🔹 'task.select' selects a task to run other commands on like `todo.add`
    🔹 'task.notes' launches editor with an attached markdown file you can write down your notes in
    🔹 'todo.add' adds a task with parentTaskId taken from first arg, adds a +todo tag

    💡 Tools to integrate workitems into tasks and also operate on them:
    💡 az login - call this command to log into ADO
    🔹 'workitem.import' imports a workitem from ado as a task
    🔹 'workitem.load' loads a workitem without importing
    🔹 'workitem.comment' adds a comment to a workitem visible on ADO
    🔹 'workitem.close' changes the status of the workitem in ado to 'Closed'
    🔹 'workitem.listnew' lists all of the workitems in ADO marked as new no matter what sprint they're on
    🔹 'workitem.listold' lists all of the workitems in ADO marked as new and older than 180 days
    🔹 'workitem.show' show selected workitem url
  '';
  areaPaths = [
    "'SomeProject\\SomeArea\\SomeAreaPart'"
    "'SomeProject\\SomeAreaTwo\\AnotherAreaPart'"
  ];
  adoTeamIterationPath = "'\\SomeProject\\Iteration\\Experience\\AnotherAreaPart'";
  adoProject = "SomeProject";
  areaPathList = pkgs.lib.strings.concatStringsSep "," areaPaths;
  workitemBaseUrl = "https://dev.azure.com/someorgname/SomeProject/_workitems/edit";
  tmpFolder = ".tmp";
  notesFolder = "$TASKDATA/.notes";
  currentWorkitem = "${tmpFolder}/currentWorkitem.json";
  lastAddTaskId = "${tmpFolder}/last-add-task-id";
  lastTodoId = "${tmpFolder}/last-add-todo-id";
  selectedTaskId = "${tmpFolder}/selected-task-id";
  #lastAddTaskContent = ".last-add-task-content";
  #lastFeatureContent = ".last-feature-content";
  args = {
    org = "https://dev.azure.com/someorgname";
  };
  # THIS WORKS:
  # az boards query --org="https://dev.azure.com/someorgname" --wiql="select [system.id], [system.title] from workitems where [system.teamproject] = 'SomeProject' and [system.areapath] = 'SomeProject\SomeArea\SomeAreaPart' AND [system.state] = 'New'"

  queries = {
    new = "select [system.id], [system.title], [system.state] FROM workitems WHERE [system.teamproject] = 'SomeProject' AND [system.areapath] IN ('SomeProject\\SomeArea\\SomeAreaPart') AND [system.state] = 'New'";
    new_params = "select [system.id], [system.title], [system.state] FROM workitems WHERE [system.teamproject] = 'SomeProject' AND [system.areapath] IN (${areaPathList}) AND [system.state] = 'New'";
    very_old_items = "select [system.id], [system.title], [system.state] FROM workitems WHERE [system.teamproject] = 'SomeProject' AND [system.areapath] = 'SomeProject\\SomeArea\\SomeAreaPart' AND [system.CreatedDate] > @today - 180 AND [system.State] NOT IN ('Closed', 'Resolved')";
    # NOTE: not working yet.. the query is much more complex.  See the sprints query content or my queries
    sprints = "select [System.AreaPath], [System.IterationPath], [System.IterationId], [system.id], [system.title], [system.state] FROM workitemLinks WHERE [Source].[System.IterationPath] UNDER 'SomeProject\\Experience' AND [System.AreaPath] IN (${areaPathList})";
    sprints2 = builtins.readFile ./ado.queries.wql;
  };

  # create a "permanent feature" task.  These are linked to for things that
  # repeat often
  #impl-task-base = pkgs.writeShellScriptBin "impl-task-base" ''
  #  lastTaskId="$(cat ${lastAddTaskId})"
  #  # either ends up being project name or an empty string
  #  project_name="$(${project-name-or-empty}/bin/project-name-or-empty)"
  #  echo "last id: $lastTaskId"
  #  featureId=$(task +feature "$project_name" feature:''${1:-core} add "''${@:2}" || echo "error")
  #  if [ "$featureId" == "error" ]; then
  #    echo "$@" > "${lastFeatureContent}"
  #    echo "Error making the task.  Saved in ${lastFeatureContent}"
  #  else
  #    echo "created a feature: $featureId with args: $@"
  #  fi
  #  echo "$featureId" > "${selectedTaskId}"
  #'';

  # all tasks that involve remodeling
  echo.error = pkgs.writeShellScriptBin "echo.error" ''
    echo " 🚨 $@"
  '';
  echo.info = pkgs.writeShellScriptBin "echo.info" ''
    echo " 💡 $@"
  '';

  # helper to do any operation with the assumption of a todo
    #new-todo = pkgs.writeShellScriptBin "new-todo" ''
    #  check=$(task -todo $1 2> /dev/null || echo "notfound")
    #  if [ "$check" == "notfound" ];
    #  then
    #    echo.error "Please provide a valid task id which is not a todo."
    #    echo.info "You can list those by running 'task -todo list'"
    #  else
    #    task parentTaskId:$1 +todo "''${@:2}"
    #  fi
    #'';

  # select the feature task
  task.select = pkgs.writeShellScriptBin "task.select" ''
    task -todo list
    read -p "Type the id of the feature task to select: " id
    echo "$id" > "${selectedTaskId}"
    echo "Stored id in ${selectedTaskId}"
  '';

  view-selected-task = pkgs.writeShellScriptBin "view-selected-task" ''
    selectedTaskId="$(cat ${selectedTaskId})"
    selectedTask="$(task $selectedTaskId export 2> /dev/null)"
    taskId="$(echo $selectedTask | jq -c '.[0].id')"
    descr="$(echo $selectedTask | jq -c '.[0].description')"
    if [ ! "$taskId" == "$selectedTaskId" ]; then
      echo.error "selectedTaskId != retrieved taskId... make sure you have run task.select first"
    else
      echo.info "Selected Task: $descr"
      list-todos 2> /dev/null
    fi
  '';

  # select the feature task
  add-todo = pkgs.writeShellScriptBin "add-todo" ''
    lastTaskId="$(cat ${lastAddTaskId})"
    todoid=$(task parentTaskId:$lastTaskId +todo add $@ || echo "error")
    if [[ $result =~ ^ERROR ]]; then
      echo "did not add the todo"
    else
      echo "$todoid" > "${lastTodoId}"
      echo "Stored id in ${lastTodoId}"
    fi
    task rc._forcecolor=on parentTaskId:$lastTaskId todos | sed 's/Completed/✅/g'
  '';


  # select the feature task
  list-todos = pkgs.writeShellScriptBin "list-todos" ''
    lastTaskId="$(cat ${lastAddTaskId})"
    # update the icons before showing
    #task status:Completed parentTaskId:$lastTaskId modify statusIcon:🔘
    #task status:Pending parentTaskId:$lastTaskId modify statusIcon:🔴
    # NOTE: had to put in the exta spaces otherwise it messes up the column alignment
    #task rc._forcecolor=on parentTaskId:$lastTaskId todos | sed 's/Completed/✅       /g'
    task parentTaskId:$lastTaskId todos
  '';

  # https://learn.microsoft.com/en-us/cli/azure/boards/work-item?view=azure-cli-latest
  workitem.load = pkgs.writeShellScriptBin "workitem.load" ''
    lastTaskId="$(cat ${lastAddTaskId})"
    adofile="${tmpFolder}/workitem.$1".json
    echo "$(az boards work-item show --id $1 --organization='${args.org}' --expand all)" > $adofile
    result="$(cat $adofile)"
    cp $adofile ${currentWorkitem}
    if [[ $result =~ ^ERROR ]]; then
      echo.error "Ran into a problem loading workitem $1 -- $result"
    else
      echo "$adofile"
    fi
  '';

  ado.listsprints = pkgs.writeShellScriptBin "ado.listsprints" ''
    q="${queries.sprints2}"
    echo "az boards query --org='${args.org}' --wiql=$(printf "%s\n" $q)" > query.sh
  '';

  az.boards = pkgs.writeShellScriptBin "az.boards" ''
    az boards  $@ --organization='${args.org}' --path="${adoTeamIterationPath}" --project="${adoProject}"
  '';

  confirm.message = pkgs.writeShellScriptBin "confirm.message" ''
    message="''${1:-Are you sure you want to continue}"
    confirmMessage="''${2:-Type ENTER to confirm}"
    cancelMessage="''${3:-'Ctrl-C to Cancel'}"
    echo "$message"
    echo "✅  $confirmMessage"
    echo "❌  $cancelMessage"
    read -p "Waiting for your choice" response
  '';

  workitem.comment = pkgs.writeShellScriptBin "workitem.comment" ''
    comment="\"$@\""
    workitemid="$(cat "${currentWorkitem}" | jq -c '.id')"
    adofile=".ado.$workitemid".tmp.json
    
    ${confirm.message}/bin/confirm.message "About to add a comment to workitem $workitemid comment: $comment"
    echo "$(az boards work-item update --id $workitemid --organization='${args.org}' --discussion="$comment")" > $adofile
    result="$(cat $adofile)"
    if [[ $result =~ ^ERROR ]]; then
      echo "ERROR"
      echo.error "Ran into a problem commenting on workitem $1 -- $result"
    else
      echo "$adofile"
    fi
  '';

  workitem.close = pkgs.writeShellScriptBin "workitem.close" ''
    workitemid="$(cat "${currentWorkitem}" | jq -c '.id')"
    maybe_closing_arg=""
    if [ ! $2 == "" ]; then
      maybe_closing_arg="--discussion="\"''${@:2}\"""
    fi
    echo "$(az boards work-item update --id $workitemid --organization='${args.org}' $maybe_closing_arg --state=Closed)" > ${currentWorkitem}
    result="$(cat ${currentWorkitem})"
    echo "$result"
    if [[ $result =~ ^ERROR ]]; then
      echo "ERROR"
    else
      echo.info "Setting the workitem state to Closed and marking tagged tasks to being done"
      task \( "workitemid:$workitemid" \) modify status:done 2> /dev/null
      ${workitem.display}/bin/workitem.display "$result"
    fi
  '';

  workitem.import = pkgs.writeShellScriptBin "workitem.import" ''
    adofile="$(workitem.load $1)"
    echo "processing file: $adofile"
    if [[ $result =~ ^ERROR ]]; then
      echo.error "ADO returned an error: $(cat $adofile)"
      mv $adofile ".prev.failure.$adofile"
    else
      workitemid="$(cat $adofile | jq -c '.id')"
      title="$(cat $adofile | jq -c '.fields."System.Title"')"
      state="$(cat $adofile | jq -c '.fields."System.State"')"
      descr="$(cat $adofile | jq -c '.fields."System.Description"')"
      assignedTo="$(cat $adofile | jq -c '.fields."System.AssignedTo".displayName')"
      createdBy="$(cat $adofile | jq -c '.fields."System.CreatedBy".displayName')"
      startDate="$(cat $adofile | jq -c '.fields."Microsoft.VSTS.Scheduling.StartDate"')"
      dueDate="$(cat $adofile | jq -c '.fields."Custom.SLACERTDate"')"
      extraParams=""
      if [[ ! $dueDate == "null" ]]; then
        extraParams="$extraParams due:$dueDate"
      fi
      if [[ "$state" =~ Closed ]]; then
        echo.info "Looks like this is Closed, marking the task as done"
        extraParams="$extraParams status:done"
      fi
      taskid=$(task \( workitemid:$workitemid \) modify $extraParams "workitem-$workitemid $title" || task $extraParams workitem:$workitemid add "workitem-$workitemid $title" || echo "ERROR: importing ado item failed")
      workitem.show
    fi
  '';

  workitem.show = pkgs.writeShellScriptBin "workitem.show" ''
    ${workitem.display}/bin/workitem.display "${currentWorkitem}"
    if [[ "$@" =~ "--raw" ]]; then
      yq -P < "${currentWorkitem}"
    fi
  '';

  workitem.display = pkgs.writeShellScriptBin "workitem.display" ''
    result="$(cat $1)"
    adofile="$1"
    if [[ $result =~ ^ERROR ]]; then
      echo.error "ADO returned an error: $(cat $adofile)"
      mv $adofile ".prev.failure.$adofile"
    else
      workitemid="$(cat $adofile | jq -c '.id')"
      title="$(cat $adofile | jq -c '.fields."System.Title"')"
      state="$(cat $adofile | jq -c '.fields."System.State"')"
      descr="$(cat $adofile | jq -c '.fields."System.Description"' | sed -e 's/<[^>]*>//g')"
      assignedTo="$(cat $adofile | jq -c '.fields."System.AssignedTo".displayName')"
      createdBy="$(cat $adofile | jq -c '.fields."System.CreatedBy".displayName')"
      startDate="$(cat $adofile | jq -c '.fields."Microsoft.VSTS.Scheduling.StartDate"')"
      dueDate="$(cat $adofile | jq -c '.fields."Custom.SLACERTDate"')"

      echo "🌐 ${workitemBaseUrl}/$workitemid"
      echo "[workitem]   $workitemid  [state] $state"
      echo "[title]      $title"
      echo "[createdBy]  $createdBy [assignedTo] $assignedTo "
      echo "[startDate]  $startDate [dueDate] $dueDate"
      echo "[descr]      $descr"
    fi
    '';

  # returns either the git repo name or "ERROR" if something went wrong
  get-repo-name = pkgs.writeShellScriptBin "get-repo-name" ''
    # check if we are in a git repo first
    if [[ "$(git status &> /dev/null && echo "yes" || echo "no")" =~ yes ]];
    then
      # since we are in a git repo, get the name of the repo
      echo "$(basename `git rev-parse --show-toplevel || echo "ERROR"`)"
    else
      echo "ERROR"
    fi
  '';

  project-name-or-empty = pkgs.writeShellScriptBin "project-name-or-empty" ''
    # check if we are in a git repo first
    if [[ "$(git status &> /dev/null && echo "yes" || echo "no")" =~ yes ]];
    then
      # since we are in a git repo, get the name of the repo
      echo "project:$(basename `git rev-parse --show-toplevel || echo ""`)"
    else
      echo ""
    fi
  '';

    # wraps the  jrnl in order to pass it the generated configuration file
  wrap-jrnl = pkgs.writeShellScriptBin "jrnl" ''
    echo "config path: $JRNL_CONFIG_PATH args: $@"
    ${pkgs.jrnl}/bin/jrnl --config-file $JRNL_CONFIG_PATH $@
  '';

  workitem.listold = pkgs.writeShellScriptBin "workitem.listold" ''
    az boards query --org='${args.org}' --wiql="${queries.very_old_items}"
  '';

  workitem.listnew = pkgs.writeShellScriptBin "workitem.listnew" ''
    az boards query --org='${args.org}' --wiql="${queries.new}"
  '';
  workitem.listnewtest = pkgs.writeShellScriptBin "workitem.listnewtest" ''
    tasks=${tmpFolder}/workitem.query.output.json
    az boards query --org='${args.org}' --wiql="${queries.new_params}" > ${tmpFolder}/workitem.query.output.json
    cat task | jq -c '.[]' | while read -r workitem; do
      workitemid="$(echo $workitem | jq -r '.id')"
      adofile="${tmpFolder}/workitem.$workitemid".json
    done
  '';

  iter-ado-tasks = pkgs.writeShellScriptBin "iter-ado-tasks" ''
    cat tasks.json | jq -c '.[]' | while read -r workitem; do
      workitemid="$(echo $workitem | jq -r '.id')"
      title="$(echo $workitem | jq -r '.fields."System.Title"')"
      state="$(echo $workitem | jq -r '.fields."System.State"')"
      #echo "state: $state"
      task \( workitemid:$workitemid \) modify "$title" || task workitemid:$workitemid add "workitemid:$workitemid $title" || echo "add or update failed for $workitemid"
    done
    #echo "deleting tasks.json - import did not error"
    #rm tasks.json
  '';

  todo.add = pkgs.writeShellScriptBin "todo.add" ''
    task parentTaskId:$(cat ${selectedTaskId}) +todo add $@
  '';

  task.show = pkgs.writeShellScriptBin "task.show" ''
    view-selected-task
    task \( parentTaskId:$(cat ${selectedTaskId}) \) +todo todos 2> /dev/null
  '';

  task.notes = pkgs.writeShellScriptBin "task.notes" ''
    mkdir -p ${notesFolder}
    selectedTaskId="$(cat ${selectedTaskId})"
    taskUuid=$(task $selectedTaskId export | jq -r '.[0].uuid')
    notesFile="${notesFolder}/$taskUuid.notes.md"
    $EDITOR $notesFile
  '';

  task.help = pkgs.writeShellScriptBin "task.help" ''
    echo "${taskHelpMessage}"
  '';
in
with pkgs;
pkgs.mkShell {
  name = "mng-dev-tasks";
  inherit system;

  buildInputs = [
    pkgs.nixfmt-rfc-style
    pkgs.emoji-picker
    pkgs.taskwarrior3
    (azure-cli.withExtensions [
      azure-cli.extensions.aks-preview
      azure-cli.extensions.azure-devops
    ])
    pkgs.jq
    pkgs.yq-go # help with converting json to yaml for easier viewing

    wrap-jrnl

    get-repo-name

    echo.error
    echo.info

    # interacting with tasks
    task.help
    # show cur task
    task.show
    task.select
    task.notes
    view-selected-task


    # interacting with todos
    list-todos
    add-todo

    # ado helpers
    workitem.import
    workitem.load
    workitem.comment
    workitem.close
    workitem.listnew
    workitem.listnewtest
    workitem.listold
    workitem.show


    iter-ado-tasks

    # add a todo
    todo.add

    az.boards
    ado.listsprints
  ];

  shellHook = ''
    export EDITOR="nvim"
    export TASKRC="''${TASKRC:-$(pwd)/.taskrc}"
    export TASKDATA="''${TASKDATA:-$(pwd)/.task}"
    export JRNL_CONFIG_PATH="$(pwd)/.jrnl.yaml"
    echo "Storing notes in ${notesFolder}"
    DEF=$PS1
    export PS1=$DEF echo hi
    mkdir -p ${tmpFolder}
    echo "
    editor: nvim -c 'set ft=markdown'
    display_format: markdown
    journals:
      default: $(pwd)/tasks.journal.txt
    " > $JRNL_CONFIG_PATH
    echo "${taskHelpMessage}"
    # ...
  '';
}
