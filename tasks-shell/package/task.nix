{
  stdenv,
  pkgs,
  enableWorkitems ? false,
  ...
} @inputs:
let
  commonShFunctions = ./common.sh;
  workitemCommands = import ./workitem.nix inputs;
  installConfig = ''
    enableWorkitems=${if enableWorkitems == true then "true" else "false"}
  '';
  task.select = pkgs.writeShellScriptBin "task.select" ''
    source ${commonShFunctions}
    ${pkgs.taskwarrior3}/bin/task -todo list
    read -p "Type the id of the feature task to select: " id
    select.task.withId "$id"
  '';
  taskHelpSh = ./task.help.sh;
  task.help = pkgs.writeShellScriptBin "task.help" ''
    source ${commonShFunctions}
    ${taskHelpSh} 
  '';
  taskShowSh = ./task.show.sh;
  task.show = pkgs.writeShellScriptBin "task.show" ''
    source ${commonShFunctions}
    ${taskShowSh}
  '';

  task.add = pkgs.writeShellScriptBin "task.add" ''
    ARGS=$@
    source ${commonShFunctions}
    curProj="$(cur.project)"
    echo.logtofile "[Project: $curProj] -- Adding a task with args: $ARGS"
    task project:$curProj add "$ARGS"
    select.latest.task
  '';

  task.todo = pkgs.writeShellScriptBin "task.todo" ''
    ARGS=$@
    source ${commonShFunctions}
    curProj="$(cur.project)"
    task project:$curProj parentTaskId:"$(cur.taskId)" parentTaskUuid:"$(cur.taskUuid)" +todo add "$ARGS"
  '';

  task.notes = pkgs.writeShellScriptBin "task.notes" ''
    source ${commonShFunctions}
    curProj="$(cur.project)"
    $EDITOR "$NOTES_DIR/$(cur.taskId).md"
  '';
  project.set = pkgs.writeShellScriptBin "project.set" ''
    ARGS="$*"
    source ${commonShFunctions}
    set.project $ARGS 
    echo.logtofile "Project set to $(cur.project)"
  '';
  az-cli-pkg = with pkgs;
    (azure-cli.withExtensions [
      azure-cli.extensions.aks-preview
      azure-cli.extensions.azure-devops
    ]);
  maybeWorkitemScripts = if enableWorkitems == true then ''
    echo "Installing workitem extras"
    ln -s ${az-cli-pkg}/bin/* $out/bin
    cp ${workitemCommands.importWi}/bin/* $out/bin
    cp ${workitemCommands.help}/bin/* $out/bin
    cp ${workitemCommands.load}/bin/* $out/bin
  '' else ''
  '';
in
stdenv.mkDerivation {
  pname = "wrapped-tasks";
  version = "v0.1";
  src = ./.;
  buildInputs = [
    pkgs.taskwarrior3
    project.set
    task.select
    task.show
    task.add
    task.notes
    pkgs.toml-cli
    az-cli-pkg
    pkgs.jq
  ];
  installPhase = ''
    mkdir -p $out/bin
    ln -s ${pkgs.taskwarrior3}/bin/* $out/bin
    ln -s ${pkgs.jq}/bin/* $out/bin
    cp ${task.add}/bin/* $out/bin
    cp ${task.todo}/bin/* $out/bin
    cp ${task.select}/bin/* $out/bin
    cp ${task.show}/bin/* $out/bin
    cp ${task.help}/bin/* $out/bin
    cp ${task.notes}/bin/* $out/bin
    cp ${project.set}/bin/* $out/bin
    echo '${installConfig}' > $out/install.cfg
    ${maybeWorkitemScripts}
  '';
}
