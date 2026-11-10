{
  description = "Kodus development toolchain";

  # This revision provides the exact Node version required by .nvmrc.
  # Update the pin and flake.lock together when changing that requirement.
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/36173dbc6ff2b383c4d03b002fd1ea58e2e4dbcd";

  outputs = { nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      requiredNodeVersion = nixpkgs.lib.strings.trim (builtins.readFile ./.nvmrc);
    in
    {
      devShells = nixpkgs.lib.genAttrs systems (system:
        let
          pkgs = import nixpkgs { inherit system; config = {}; overlays = []; };
          nodejs = pkgs.nodejs_22;
          # Keep Corepack's runtime on the same Node version as the project.
          corepack = pkgs.corepack.override { nodejs-slim = pkgs.nodejs-slim_22; };
        in
        {
          default =
            assert pkgs.lib.assertMsg (nodejs.version == requiredNodeVersion)
              "Update the Nixpkgs pin in flake.nix to match .nvmrc (${requiredNodeVersion}).";
            pkgs.mkShellNoCC {
              name = "kodus-dev";
              # Corepack's pnpm wrapper honors package.json's packageManager.
              # Put it before Node's bundled Corepack executable on PATH.
              packages = [ corepack nodejs ];
              COREPACK_ENABLE_PROJECT_SPEC = "1";
            };
        });
    };
}
