{ lib, stdenv, writeTextFile, generatorShell ? runtimeShell, runtimeShell, ... }:

mainScope: name: with lib;
let
  scopeToAsh = { type, container, vars, varsWorkDir, funcs, workDir, logic, opt, exports }@scope:
    (strings.concatStringsSep "\n"
      (lists.flatten
        [
          (ashOptions opt)
          (attrsets.mapAttrsToList (k: v: "${k}() {\n${scopeToAsh v}\n}") funcs)
          (pushdNotNull varsWorkDir)
          (attrsets.mapAttrsToList (k: v: "${k}=${valueToAsh true v}") vars)
          (pushdNotNull workDir)
          (builtins.map logicToAsh logic)
          (exportsToAsh exports)
        ]
      )
    );

  ashOptions = { errexit, nounset, noclobber, noexec, noglob, notify }:
    let
      k = pred: val: if errexit then "-${val}" else "+${val}";
    in
    strings.concatStringsSep " "
      (with lists; flatten [
        "set"
        (k errexit "e")
        (k nounset "u")
        (k noclobber "C")
        (k noexec "n")
        (k noglob "f")
        (k notify "b")
      ]);

  pushdNotNull = dir:
    if dir != null
    then "cd ${valueToAsh true dir}"
    else [ ];

  valueToAsh = quote: value:
    if builtins.isAttrs value then
      if value.type == "environ" || value.type == "arg" then
        let
          core = "$\{" + value.name + ":-" + (valueToAsh false value.defaults) + "}";
        in
        if quote then "\"${core}\"" else core
      else if value.type == "local" then
        let
          core =
            "$\{" + value.name + "}";
        in
        if quote then "\"${core}\"" else core
      else if value.type == "all-args" then
        if value.quoted then "\"$@\"" else "$@"
      else if value.type == "cmd" || value.type == "call" then
        "$(${logicToAsh value})"
      else if value.type == "template" then
        let
          core = lib.strings.concatStrings
            (builtins.map (valueToAsh false) value.from);
        in
        if quote then "\"${core}\"" else core
      else
        throw "Cannot coerce ${value.type} into value."
    else if quote then escapeShellArg value
    else value;

  logicToAsh = value:
    lib.strings.concatStringsSep " "
      (lists.flatten
        (if value.type == "cmd" || value.type == "call" then
          [
            (if value.pipeIn != null then [ (logicToAsh value.pipeIn) "|" ] else [ ])
            (attrsets.mapAttrsToList (k: v: "${k}=${valueToAsh true v}") value.extraVars)
            (valueToAsh true value.arg0)
            (builtins.map (valueToAsh true) value.args)
            (builtins.map fdMapToAsh value.fdMap)
          ]
        else if value.type == "scope" then
          if value.container == null then
            [ "{" (scopeToAsh value) "}" ]
          else if value.container.type == "if-then" then
            [ "if" (logicToAsh value.container.pred) "\nthen" (scopeToAsh value) "\nfi" ]
          else throw "Cannot coerce container ${value.container.type} into logic."
        else if value.type == "cond-and" then
          [ (logicToAsh value.left) "&&" (logicToAsh value.right) ]
        else if value.type == "cond-empty" then
          [ "[ -z" (valueToAsh true value.value) " ]" ]
        else throw "Cannot coerce ${value.type} into logic."
        )
      );

  fdMapToAsh = { type, from, to, toFile, append }:
    "${if from == "1" then "" else from}>${if append then ">" else ""}${if toFile then valueToAsh true to else "&${to}"}";

  exportsToAsh = list:
    if (builtins.length list) != 0 then
      lib.strings.concatStringsSep " "
        ([ "export" ] ++ list)
    else [ ];
in
writeTextFile
{
  inherit name;
  executable = true;
  text = ''
    #!${generatorShell}
    ${scopeToAsh mainScope}
  '';
  checkPhase = ''
    ${stdenv.shellDryRun} "$target"
  '';
}
