{ enableWorkitems ? false, ...}:
let
  pkgs = import <nixpkgs> { };
  callPackage = pkgs.lib.callPackageWith (pkgs // packages);
  packages = {
    task = callPackage ./package/task.nix { inherit enableWorkitems; };
  };
in
packages
