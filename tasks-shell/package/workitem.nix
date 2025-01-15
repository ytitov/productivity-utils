{
  stdenv,
  pkgs,
  areaPaths ? [
    "'SomeProject\\SomeArea\\SomeAreaPart'"
    "'SomeProject\\SomeAreaTwo\\AnotherAreaPart'"
  ],
  adoTeamIterationPath ? "'\\SomeProject\\Iteration\\Experience\\AnotherAreaPart'",
  adoProject ? "SomeProject",
  orgName ? "someorgname",
  ...
}:
let
  commonShFunctions = ./common.sh;
  commonShWorkitems = ./common.workitems.sh;
  areaPathList = pkgs.lib.strings.concatStringsSep "," areaPaths;
  workitemBaseUrl = "https://dev.azure.com/${orgName}/${adoProject}/_workitems/edit";
  orgNameUrl="https://dev.azure.com/${orgName}";
  importWi = pkgs.writeShellScriptBin "workitem.import" ''
    ARGS=$@
    source ${commonShFunctions}
    source ${commonShWorkitems}
    echo.logtofile "workitem.import current workitem: $curWi"
    workitemid=$(workitem.load $1)
    echo.logtofile "Load result: $workitemid"
    import_as_task $workitemid
  '';
  help = pkgs.writeShellScriptBin "workitem.help" ./workitem.help.sh;

  # https://learn.microsoft.com/en-us/cli/azure/boards/work-item?view=azure-cli-latest
  load = pkgs.writeShellScriptBin "workitem.load" ''
    source ${commonShFunctions}
    source ${commonShWorkitems}
    lastTaskId="$(cur.taskId)"
    workItemId=''${1:-MISSING_WORKITEM_ID}
    adofile="$TMP_FOLDER/workitem.$workItemId".json
    echo "$(az boards work-item show --id $workItemId --organization='${orgNameUrl}' --expand all)" > $adofile
    result="$(cat $adofile)"
    cp $adofile "$CUR_WORKITEM"
    if [[ $result =~ ERROR ]]; then
      echo.error "Ran into a problem loading workitem $1 -- $result"
    else
      echo "$adofile"
    fi
  '';
in
{
  inherit importWi;
  inherit help;
  inherit load;
}

