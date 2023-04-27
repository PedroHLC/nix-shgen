{
  description = "Generate multi-platform multi-project shell scripts.";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { nixpkgs, ... }:
    let
      forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
    in
    rec {
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixpkgs-fmt);

      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          shGen = pkgs.callPackage ./default.nix { };
          exampleData = import ./example.nix { inherit shGen; };
          toAsh = pkgs.callPackage ./generators/ash/default.nix { };
          toDash = pkgs.callPackage ./generators/ash/default.nix {
            generatorShell = "${pkgs.dash}/bin/dash";
          };
        in
        {
          default = shGen;
          inherit toAsh;
          exampleJson = pkgs.writeTextFile {
            name = "example.json";
            text = (builtins.toJSON exampleData);
          };
          exampleAsh = toAsh exampleData "example.sh";
          exampleDash = toDash exampleData "example.sh";
        }
      );
    };
}
