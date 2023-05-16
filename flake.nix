{
  description = "A flake for sbmpost/AutoRaise";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    flake-parts.url = "github:hercules-ci/flake-parts";

    autoraise-release.url = "https://github.com/sbmpost/AutoRaise/archive/refs/tags/v3.7.tar.gz";
    autoraise-release.flake = false;
  };

  outputs = {
    self,
    nixpkgs,
    flake-parts,
    autoraise-release,
  } @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-darwin" "aarch64-darwin"];
      perSystem = {
        pkgs,
        self',
        ...
      }: let
        autoraise = {
          alternative_task_switcher ? false,
          old_activation_method ? false,
          experimental_focus_first ? false,
        }:
          pkgs.darwin.apple_sdk_11_0.stdenv.mkDerivation rec {
            pname = "autoraise";
            version = "3.7";

            src = autoraise-release;

            buildInputs = with pkgs.darwin.apple_sdk_11_0.frameworks; [
              ApplicationServices
              AppKit
              Carbon
              SkyLight
            ];

            preConfigure = let
              flags = pkgs.lib.concatStringsSep " " [
                (pkgs.lib.optionalString alternative_task_switcher "-DALTERNATIVE_TASK_SWITCHER")
                (pkgs.lib.optionalString old_activation_method "-DOLD_ACTIVATION_METHOD")
                (pkgs.lib.optionalString experimental_focus_first "-DEXPERIMENTAL_FOCUS_FIRST")
              ];
            in ''
              export CXXFLAGS="${flags}"
            '';

            prePatch = ''
              substituteInPlace AutoRaise.mm --replace 'kAXValueCGPointType' 'kAXValueTypeCGPoint'
              substituteInPlace AutoRaise.mm --replace 'kAXValueCGRangeType' 'kAXValueTypeCGRange'
              substituteInPlace AutoRaise.mm --replace 'kAXValueCGSizeType' 'kAXValueTypeCGSize'
              substituteInPlace Makefile --replace g++ clang++
            '';

            installPhase = ''
              mkdir -p $out/bin
              cp AutoRaise $out/bin
            '';
          };
      in {
        formatter = pkgs.alejandra;
        packages.autoraise = pkgs.callPackage autoraise {};
        packages.default = self'.packages.autoraise;
      };
    };
}
