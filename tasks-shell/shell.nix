# see https://taskwarrior.org/docs/terminology/ for terminology used in taskwarrior.. very useful
{
  pkgs ? import <nixpkgs> { },
}:
let
  taskpkgs = import ./package.nix;
in
pkgs.mkShell {
  buildInputs = [
    taskpkgs.task
  ];
  shellHook = ''
    export TASKRC="testtaskrc"
    export TASKDATA="testtaskdata"
    export EDITOR="nvim"
    export TASK_EXPORT_FOLDER=/export/shared/task-export
    echo "taskrc is set to   $TASKRC"
    echo "taskdata is set to $TASKDATA"
  '';
}
