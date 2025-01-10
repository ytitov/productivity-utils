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
  areaPathList = pkgs.lib.strings.concatStringsSep "," areaPaths;
  workitemBaseUrl = "https://dev.azure.com/${orgName}/${adoProject}/_workitems/edit";
  orgNameUrl="https://dev.azure.com/${orgName}";
  importWi = pkgs.writeShellScriptBin "workitem.import" ''
    ARGS=$@
    PROG_SOURCE=$(dirname "$(dirname "$(readlink -f "$(which task.select)")")")
    source "$PROG_SOURCE"/common.sh
    echo "workitem.import current workitem: $curWi"
    workitem.load $1
  '';
  help = pkgs.writeShellScriptBin "workitem.help" ./workitem.help.sh;

  # https://learn.microsoft.com/en-us/cli/azure/boards/work-item?view=azure-cli-latest
  load = pkgs.writeShellScriptBin "workitem.load" ''
    echo "param: $1"
    PROG_SOURCE=$(dirname "$(dirname "$(readlink -f "$(which task.select)")")")
    source "$PROG_SOURCE"/common.sh
    lastTaskId="$(cur.taskId)"
    adofile="$TMP_FOLDER/workitem.$1".json
    echo "$(az boards work-item show --id $1 --organization='${orgNameUrl}' --expand all)" > $adofile
    result="$(cat $adofile)"
    cp $adofile "$CUR_WORKITEM"
    if [[ $result =~ ^ERROR ]]; then
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

