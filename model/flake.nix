{
  description = "Example ML model apps packaged using poetry2nix";

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
        myPython = pkgs.python38;
        ai4eutils = myPython.pkgs.buildPythonPackage {
            name = "ai4eutils";
            src = pkgs.fetchgit {
                url = "https://github.com/microsoft/ai4eutils";
                rev = "a7aefc9cf6ff0564a83e0a1ddc903ef22561fdd5";
                sha256 = "sha256-w1Eid+0exFzQobLjC3Eh1UlvLgauw/FY5H4LsnER3ek=";
            };
            format = "other";
            installPhase = ''
              mkdir -p $out/lib/python3.8/site-packages/ai4eutils
              cp -r . $out/lib/python3.8/site-packages/ai4eutils/
            '';
        };
        cameraTrapsMD = myPython.pkgs.buildPythonPackage {
            name = "camera_traps_MD"; 
            src = pkgs.fetchFromGitHub {
                owner = "sowbaranika1302";
                repo = "camera_traps_MD";
                rev = "28f91e01b2afadde23a0e653a4ab9d6879a976c9";
                hash = "sha256-VBwprg1qvxtWBMOZpmJk6qqUhXUvmnVNqEvgoES4J5k=";
            };
            format = "other";
            installPhase = ''
              mkdir -p $out/lib/python3.8/site-packages/camera_traps_MD
              cp -r . $out/lib/python3.8/site-packages/camera_traps_MD/
            '';
        };
        yolov5 = myPython.pkgs.buildPythonPackage {
            name = "yolov5";
            src = pkgs.fetchFromGitHub {
                owner = "ultralytics";
                repo = "yolov5";
                rev = "c23a441c9df7ca9b1f275e8c8719c949269160d1";
                hash = "sha256-YbedVzBResnU5lwlxYkMkjqJ0f1Q48FZs+tIS1a1MUk=";
            };
            format = "other";
            installPhase = ''
              mkdir -p $out/lib/python3.8/site-packages/yolov5
              cp -r . $out/lib/python3.8/site-packages/yolov5/
            '';
        };
        mdPtModel = pkgs.fetchurl {
          url = "https://github.com/microsoft/CameraTraps/releases/download/v5.0/md_v5a.0.0.pt";
          sha256 = "0xmj04xwvvpqfhpvxp0j8gbkkmi98zvb8k6cs3iz4l40gklqzs4l";
        };
        ptModelDir = pkgs.stdenv.mkDerivation {
          name = "ptModelDir";
          src = self;
          installPhase = ''
           mkdir -p $out;
           cp ${mdPtModel} $out/md_v5a.0.0.pt
          '';
        };
        myApp = mkPoetryApplication { 
            python = myPython;
            projectDir = ./.; 
            preferWheels = true;
          };
        newPython = myPython.withPackages (
            ps: [ myApp ai4eutils yolov5 cameraTrapsMD ]
        );
        # newPython2 = myPython.pkgs.buildPythonApplication {
        #   name = "newPython2";
        #   propagatedBuildInputs = [ myApp ai4eutils yolov5 cameraTrapsMD ];
        #   pythonPath = [ "${cameraTrapsMD}/lib/python3.8/site-packages/camera_traps_MD/" ];
          
        # };
        newPython3 = pkgs.stdenv.mkDerivation {
            name = "newPython3";
            buildInputs = [ newPython pkgs.makeWrapper ];
            src = self;
            installPhase = ''
              makeWrapper ${newPython}/bin/python $out/bin/python --set PYTHONPATH ${cameraTrapsMD}/lib/python3.8/site-packages/camera_traps_MD/:${ai4eutils}/lib/python3.8/site-packages/ai4eutils:${yolov5}/lib/python3.8/site-packages/yolov5
            '';
        };
        finalBinary = pkgs.writeShellApplication {
            name = "image_scoring_plugin";
            runtimeInputs = [ newPython3 ptModelDir myApp ];
            text = ''
              cd ${ptModelDir}; ${myApp}/bin/zmqtest
            '';
        };
      in
      rec {
        packages = {
          py = finalBinary;
          default = packages.py;
          ai4eutilsPkg = ai4eutils;
          myAppPkg = myApp;
          modelPkg = mdPtModel;
          pythonPkg = newPython3;
        };

        devShells.default = shell {
          packages = [ poetry2nix.packages.${system}.poetry packages.py ];
        };
      });
}