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

      lib = nixpkgs.lib;

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
              rev = "v2.7.5";
              sha256 = "sha256-0IZZ7mkEzZI2Y8ed//m0tbBQZ0YcCXA0/b10ntNIXUk=";
            };
          in
          {
            cloudflare-caddy = pkgs.buildGoModule {
              noCheck = true;
              pname = "cloudflare-caddy";
              version = caddySrc.rev;
              subPackages = [ "cmd/caddy" ];
              src = caddySrc;
              patches = [ ./0001-cloudflare.patch ];

              ldflags = [
                "-X github.com/caddyserver/caddy/v2.CustomVersion=${caddySrc.rev}-cloudflare"
              ];

              # set to lib.fakeSha256 to get the new one
              vendorSha256 = "sha256-epR9v8TO7sPs8aL8zHC2t8sH9Kt/NpBonkCKyUIpNUg=";

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
            buildInputs = baseDeps ++ [ packages.${system}.cloudflare-caddy ];
          };
        });

      # The default package for 'nix build'. This makes sense if the
      # flake provides only one package or there is a clear "main"
      # package.
      defaultPackage = forAllSystems (system: self.packages.${system}.cloudflare-caddy);

      overlay = final: prev: {
        cloudflare-caddy = self.packages.${final.system}.cloudflare-caddy;
      };
      formatter = forAllSystems (system: nixpkgsFor.${system}.nixpkgs-fmt);
    };
}
