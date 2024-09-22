# Nix Cloudflare Caddy build

## How to update and build

1. Enter the caddy-src directory `cd caddy-src`
2. Install the latest Caddy tag with `go get -u github.com/caddyserver/caddy/v2@v2.8.4`
3. Update `go.sum` by running `go mod tidy`
4. Build the package with nix `nix build '.#cloudflare-caddy'` which will fail with a hash-mismatch
```bash
nix build '.#cloudflare-caddy'
warning: Git tree '/home/william/code/nix-cloudflare-caddy' is dirty
warning: found empty hash, assuming 'sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA='
error: hash mismatch in fixed-output derivation '/nix/store/mrk2n5gkcwdqsy3y826dj84prd0bmry7-cloudflare-caddy-v2.8.4-go-modules.drv':
         specified: sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
            got:    sha256-8CpaXbWjngZqk3XHp8OKpJVz+V2iPRbW4lCSxfzXXIs=
error: 1 dependencies of derivation '/nix/store/k1j8bgw7ggvgq5mwqc9zzlqykw9wi4mq-cloudflare-caddy-v2.8.4.drv' failed to build
```
5. Update `vendorHash` with the `got` value in the bash output
```diff
diff --git a/flake.nix b/flake.nix
index 6b0e9e0..e06aedb 100644
--- a/flake.nix
+++ b/flake.nix
@@ -51,7 +51,7 @@

               # set to lib.fakeSha256 to get the new one
               # vendorHash = "${lib.fakeSha256}";
-              vendorHash = "sha256-dEuxEG6mW2V7iuSXvziR82bmF+Hwe6ePCfdNj5t3t4c=";
+              vendorHash = "sha256-8CpaXbWjngZqk3XHp8OKpJVz+V2iPRbW4lCSxfzXXIs=";
               meta = {
                 description = "Caddy server with Cloudflare DNS support";
                 homepage = "https://github.com/caddyserver/caddy";

```
6. Building the package should now succeed
```bash
$ nix build '.#cloudflare-caddy'
$ ./result/bin/caddy version
cloudflare v2.8.4
$ ./result/bin/caddy list-modules | grep cloudflare
dns.providers.cloudflare
$
```
