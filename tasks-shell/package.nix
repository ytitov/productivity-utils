let
  pkgs = import <nixpkgs> { };
  callPackage = pkgs.lib.callPackageWith (pkgs // packages);
  packages = {
    hello = callPackage ./package/hello.nix { };
    task = callPackage ./package/task.nix { };
  };
in
packages
