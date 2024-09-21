{
  description = "Caddy server with cloudflare dns support";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "github:NixOS/nixpkgs";

  outputs = { self, nixpkgs }:
    let
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
              rev = "v2.8.4";
              sha256 = "sha256-CBfyqtWp3gYsYwaIxbfXO3AYaBiM7LutLC7uZgYXfkQ=" ;
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
              # vendorHash = "${lib.fakeSha256}";
              vendorHash = "sha256-dnKAwOrQkICkUVsyWJO+o2N4HcImLaL+fPyq8hUd5/8=";

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
