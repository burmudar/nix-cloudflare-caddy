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
            # the following lines extracts the version number from the go.mod
            lines = builtins.split "\n" (builtins.readFile ./caddy-src/go.mod);
            firstOrNull = list: if builtins.isList list then builtins.elemAt list 0 else null;
            # iterate over all the lines trying to match the regex. If the regex doesn't match it's null otherwise it gives a list back and we take the first element
            # after the map, we filter out all nulls
            result = builtins.filter (x: x != null) (
              builtins.map
                (
                  l: if builtins.isList l then null else firstOrNull (builtins.match "\tgithub\.com\/caddyserver\/caddy\/v2[[:space:]]+(.*)$" l)
                )
                lines
            );
            # if our processing above resulted in at least one item in the list then we use that as the version, otherwise 'dev'
            version = if builtins.length result == 0 then "dev" else builtins.elemAt result 0;
          in
          {
            cloudflare-caddy = pkgs.buildGoModule {
              src = ./caddy-src;
              noCheck = true;
              pname = "cloudflare-caddy";
              version = version;

              ldflags = [
                "-X github.com/caddyserver/caddy/v2.CustomVersion=cloudflare"
              ];

              # set to lib.fakeSha256 to get the new one
              # vendorHash = "${lib.fakeSha256}";
              vendorHash = "sha256-8CpaXbWjngZqk3XHp8OKpJVz+V2iPRbW4lCSxfzXXIs=";
              meta = {
                description = "Caddy server with Cloudflare DNS support";
                homepage = "https://github.com/caddyserver/caddy";
                license = pkgs.lib.licenses.asl20;
                maintainers = with pkgs.lib.maintainers; [ burmudar ];
                mainProgram = "caddy";
              };
            };
          });

      # Add dependencies that are only needed for development
      devShells = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
          baseDeps = with pkgs; [ go_1_23 gopls gotools go-tools ];
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
