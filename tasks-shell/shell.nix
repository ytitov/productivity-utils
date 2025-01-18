# see https://taskwarrior.org/docs/terminology/ for terminology used in taskwarrior.. very useful
{
  pkgs ? import <nixpkgs> { },
}:
let
  taskpkgs = import ./package.nix { enableWorkitems = false; };
in
pkgs.mkShell {
  buildInputs = [
    taskpkgs.task
    pkgs.figlet
    pkgs.lolcat
  ];
  shellHook = ''
    figlet "MyTasks" | lolcat
    export GLOBAL_TASKRC=~/.taskrc
    export TASKRC="testtaskrc"
    export TASKDATA="testtaskdata"
    export EDITOR="nvim"
    export TASK_EXPORT_FOLDER=/export/shared/task-export
    echo "taskrc is set to   $TASKRC"
    echo "taskdata is set to $TASKDATA"
  '';
}
