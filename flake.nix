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
      packages = forAllSystems
        (system:
          let
            pkgs = nixpkgsFor.${system};
            caddySrc = nixpkgsFor.${system}.fetchFromGitHub {
              owner = "caddyserver";
              repo = "caddy";
              rev = "v2.6.4";
              sha256 = "sha256-3a3+nFHmGONvL/TyQRqgJtrSDIn0zdGy9YwhZP17mU0=";
            };
          in
          {
            cloudflare-caddy = pkgs.buildGoModule rec {
              noCheck = true;
              pname = "cloudflare-caddy";
              version = "2.6.4";
              subPackages = [ "cmd/caddy" ];
              src = caddySrc;
              patches = [ ./0001-cloudflare.patch ];

              vendorSha256 = "sha256-BcUWQYf76vl7TSQKcTWnjOHPGnXkRV8x/XgFVb7E2Iw=";

              checkPhase = ''
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

      overlay.default = final: prev: {
        cloudflare-caddy = self.defaultPackage;
      };
    };
}
