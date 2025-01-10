{
  stdenv,
  pkgs,
  enableWorkitems ? true,
}:
let
  commonShFunctions = ./common.sh;
  tmpFolder = ".tmp";
  installConfig = ''
    enableWorkitems=${if enableWorkitems == true then "true" else "false"}
  '';
  selectedTaskId = "${tmpFolder}/selected-task-id";
  task.select = pkgs.writeShellScriptBin "task.select" ''
    echo "Is taskrc set: $TASKRC"
    source ${commonShFunctions}
    ${pkgs.taskwarrior3}/bin/task -todo list
    read -p "Type the id of the feature task to select: " id
    echo "$id" > "${selectedTaskId}"
    echo "Stored id in ${selectedTaskId}"
  '';
  task.help = pkgs.writeShellScriptBin "task.help" ./task.help.sh;
  task.show = pkgs.writeShellScriptBin "task.show" ./task.show.sh;
  #task.add = pkgs.writeShellScriptBin "task.add" ./task.add.sh;
  task.add = pkgs.writeShellScriptBin "task.add" ''
    ARGS=$@
    PROG_SOURCE=$(dirname "$(dirname "$(readlink -f "$(which task.select)")")")
    source "$PROG_SOURCE"/common.sh
    curProj="$(cur.project)"
    echo "Project: $curProj -- Adding a task with args: $ARGS"
    task project:$curProj add "$ARGS"
  '';
  project.set = pkgs.writeShellScriptBin "project.set" ''
    ARGS="$*"
    PROG_SOURCE=$(dirname "$(dirname "$(readlink -f "$(which task.select)")")")
    source "$PROG_SOURCE"/common.sh
    set.project $ARGS 
    echo "Project set to $(cur.project)"
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
    pkgs.toml-cli
  ];
  installPhase = ''
    mkdir -p $out/bin
    ln -s ${pkgs.taskwarrior3}/bin/* $out/bin/task
    cat ${commonShFunctions} > $out/common.sh
    cp ${task.add}/bin/* $out/bin
    cp ${task.select}/bin/* $out/bin
    cp ${task.show}/bin/* $out/bin
    cp ${task.help}/bin/* $out/bin
    cp ${project.set}/bin/* $out/bin
    echo '${installConfig}' > $out/install.cfg
  '';
}
