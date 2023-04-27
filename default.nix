{ lib, ... }:

rec {
  mkScope = { ... }@args: {
    type = "scope";
    container = args.container or null;
    vars = args.vars or { };
    varsWorkDir = args.varsWorkDir or null;
    funcs = args.funcs or { };
    workDir = args.workDir or null;
    logic = args.logic or [ ];
    opt = args.opt or defaultOptions;
    exports = args.exports or [ ];
  };

  defaultOptions = {
    errexit = false;
    nounset = false;
    noclobber = false;
    noexec = false;
    noglob = false;
    notify = true;
    # pipefail = false; # requires POSIX:2022
  };

  env = name: { ... }@args: {
    type = "environ";
    inherit name;
    defaults = args.defaults or "";
  };

  local = name: {
    type = "local";
    inherit name;
  };

  allArgs = { ... }@args: {
    type = "all-args";
    quoted = args.quoted or true;
  };

  arg = number: { ... }@args:
    (env number args) // { type = "arg"; };

  interpl = values: {
    type = "template";
    from = values;
  };

  scopeIf = cond: scopeArgs:
    mkScope (scopeArgs // {
      container = { type = "if-then"; pred = cond; };
    });

  assertAnd = left: right: {
    type = "cond-and";
    inherit left right;
  };

  assertEmpty = value: {
    type = "cond-empty";
    inherit value;
  };

  mkFdMap = from: to: { ... }@args: {
    type = "fd-map";
    inherit from to;
    toFile = args.toFile or false;
    append = args.append or false;
  };

  outToErr = mkFdMap "1" "2" { };
  outToFile = file: mkFdMap "1" file { toFile = true; };
  outAppendFile = file: mkFdMap "1" file { toFile = true; append = true; };

  run = arg0: { ... }@other: {
    type = "cmd";
    inherit arg0;
    args = other.args or [ ];
    extraVars = other.extraVars or { };
    pipeIn = other.pipeIn or null;
    fdMap = other.fdMap or [ ];
  };

  callFunction = fname: { ... }@other:
    (run fname other) // { type = "call"; };
}
