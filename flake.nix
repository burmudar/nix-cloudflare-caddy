{
  description = "xcaddy with cloudflare";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "github:NixOS/nixpkgs";

  outputs = { self, nixpkgs }:
    let

      # to work with older version of flakes
      lastModifiedDate = self.lastModifiedDate or self.lastModified or "19700101";


      # System types to support.
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });

    in
    rec {

      # Provide some binary packages for selected system types.
      packages = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
          caddySrc = nixpkgsFor.${system}.fetchFromGitHub {
            owner = "caddyserver";
            repo = "caddy";
            rev = "v2.6.4";
            sha256 = "sha256-3a3+nFHmGONvL/TyQRqgJtrSDIn0zdGy9YwhZP17mU0=";
          };
          cloudflareSrc = nixpkgsFor.${system}.fetchFromGitHub {
            owner = "caddy-dns";
            repo = "cloudflare";
            rev = "ed330a8";
            sha256 = "sha256-3a3+nFHmGONvL/TyQRqgJtrSDIn0zdGy9YwhZP17mU0=";
          };
        in
        rec {
          cloudflare_caddy = pkgs.buildGoModule rec {
            noCheck = true;
            pname = "caddy";
            version = "2.6.4";
            subPackages = [ "caddy" ];
            # in the Nix store.
            src = caddySrc;

            vendorSha256 = "sha256-toi6efYZobjDV3YPT9seE/WZAzNaxgb1ioVG4txcuXM=";

            checkPhase = ''
           '';
            preBuild = ''
                         echo ${pkgs.go.src}
                         mkdir -p caddy
                         cat << EOF > caddy/main.go
              package main

              import (
                caddycmd "github.com/caddyserver/caddy/v2/cmd"

                // plug in Caddy modules here
                _ "github.com/caddy-dns/cloudflare"
                _ "github.com/caddyserver/caddy/v2/modules/standard"
              )

              func main() {
                caddycmd.Main()
              }
              EOF
                          cd caddy && go mod init caddy && go mod tidy && cd -
            '';

          };
        });

      # Add dependencies that are only needed for development
      devShells = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
          baseDeps = with pkgs; [ go gopls gotools go-tools ];
        in
        {
          default = pkgs.mkShell {
            buildInputs = baseDeps ++ [ packages.${system}.cloudflare ];
          };
        });

      # The default package for 'nix build'. This makes sense if the
      # flake provides only one package or there is a clear "main"
      # package.
      defaultPackage = forAllSystems (system: self.packages.${system}.cloudflare_caddy);
    };
}
