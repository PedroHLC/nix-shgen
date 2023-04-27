{ shGen, ... }:

# This is the very beginning of: https://github.com/chaotic-cx/nyx/blob/240be6272a53d585b467f904a111214e44c405a8/devshells/builder.nix#L66

with shGen; mkScope {
  vars =
    {
      NYX_SOURCE = env "NYX_SOURCE" {
        defaults = "./";
      };
      NYX_FLAGS = env "NYX_FLAGS" {
        defaults = "--accept-flake-config";
      };
      NYX_WD = env "NYX_WD" {
        defaults = run "mktemp" { args = [ "-d" ]; };
      };
      R = "\\033[0;31m";
      G = "\\033[0;32m";
      Y = "\\033[1;33m";
      W = "\\033[0m";
    };
  funcs = {
    echo_warning = mkScope {
      logic = [
        (run "echo" {
          args = [
            ("-n")
            (interpl [
              (local "Y")
              ("WARNING:")
              (local "W")
              (" ")
            ])
          ];
        })

        (run "echo" { args = [ (allArgs { }) ]; })
      ];
    };
    echo_error = mkScope {
      logic = [
        (run "echo" {
          args = [
            ("-n")
            (interpl [
              (local "R")
              ("Error:")
              (local "W")
              (" ")
            ])
          ];
          fdMap = [ outToErr ];
        })

        (run "echo" { args = [ (allArgs { }) ]; fdMap = [ outToErr ]; })
      ];
    };
    cached = mkScope { };
  };
  workDir = local "NYX_WD";
  logic =
    let
      prepareFiles =
        run "echo" {
          args = [ "-n" "" ];
          fdMap = [
            (outToFile "push.txt")
            (outToFile "errors.txt")
            (outToFile "success.txt")
            (outToFile "failures.txt")
            (outToFile "cached.txt")
          ];
        };

      warnEmptyKeys = scopeIf
        (assertAnd
          (assertEmpty (env "CACHIX_AUTH_TOKEN" { }))
          (assertEmpty (env "CACHIX_SIGNING_KEY" { }))
        )
        {
          logic = [
            (callFunction "echo_warning" {
              args = [ "No key for cachix -- building anyway." ];
            })
          ];
        };
    in
    [
      warnEmptyKeys
      prepareFiles
    ];
}
