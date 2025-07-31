{
  description = "My NixOS system configuration";

  # inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  inputs.linkwarden-pkgs.url = "github:jvanbruegge/nixpkgs/linkwarden";

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      linkwarden-pkgs,
      ...
    }:
    let
      system = "x86_64-linux";
    in
    {
      nixosConfigurations = {
        nixos = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            "${linkwarden-pkgs}/nixos/modules/services/web-apps/linkwarden.nix"
            {
              nixpkgs.overlays = [
                (final: prev: {
                  linkwarden = (import linkwarden-pkgs { inherit system; }).linkwarden;
                })
              ];
            }
            ./configuration.nix
          ];
        };
      };
    };
}

# iso = nixpkgs.lib.nixosSystem {
#   inherit system;
#   modules = [
#     # (
#     #   { pkgs, modulesPath, ... }:
#     #   {
#     #     # "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
#     #     imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix") ];
#     #     # "${nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
#     #   }
#     # )
#     (nixpkgs + "/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix")
#     (nixpkgs + "/nixos/modules/installer/cd-dvd/channel.nix")
#     ./configuration.nix
#   ];
# };
