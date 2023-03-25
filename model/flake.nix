{
  description = "Example Events apps packaged using poetry2nix";

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.poetry2nix = {
    url = "github:nix-community/poetry2nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.shell-utils.url = "github:waltermoreira/shell-utils";

  outputs = { self, nixpkgs, flake-utils, poetry2nix, shell-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        # see https://github.com/nix-community/poetry2nix/tree/master#api for more functions and examples.
        inherit (poetry2nix.legacyPackages.${system}) mkPoetryApplication mkPoetryEnv;
        pkgs = nixpkgs.legacyPackages.${system};
        shell = shell-utils.myShell.${system};
        ai4eutils = pkgs.python310Packages.buildPythonPackage {
            name = "ai4eutils";
            src = pkgs.fetchgit {
                url = "https://github.com/microsoft/ai4eutils";
                rev = "a7aefc9cf6ff0564a83e0a1ddc903ef22561fdd5";
                sha256 = "sha256-w1Eid+0exFzQobLjC3Eh1UlvLgauw/FY5H4LsnER3ek=";
            };
            format = "other";
            installPhase = ''
              mkdir -p $out/lib/python3.10/site-packages
              cp -r ai4eutils $out/lib/python3.10/site-packages/
            '';

        }
#        ai4eutils = pkgs.stdenv.mkDerivation rec {
#            name = "ai4eutils";
#          src = pkgs.fetchgit {
#                url = "https://github.com/microsoft/ai4eutils";
#                rev = "a7aefc9cf6ff0564a83e0a1ddc903ef22561fdd5";
#                sha256 = "sha256-w1Eid+0exFzQobLjC3Eh1UlvLgauw/FY5H4LsnER3ek=";
#            };
#            buildPhase = "";
#           installPhase = ''
#              mkdir -p $out
#              cp -r ${src} $out
#            '';
#        };
        myApp = mkPoetryApplication { 
            projectDir = ./.; 
            preferWheels = true;
          };
        newPython = pkgs.python310.withPackages (
            ps: [ myApp ai4eutils ]
        );
      in
      rec {
        packages = {
          py = newPython;
          default = packages.py;
          ai4eutilsPkg = ai4eutils;
        };

        devShells.default = shell {
          packages = [ poetry2nix.packages.${system}.poetry packages.py ];
        };
      });
}