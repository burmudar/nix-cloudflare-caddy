# Nix Cloudflare Caddy build

## How to update and build

1. Update the `rev` attribute in `caddySrc` to the version you want ie. `v2.7.6`
2. Replace `sha256` value with an empty string ie. `sha256 = "";`
3. Do `nix build` which should tell you that it found an empty sha and assuming a value of ``. It will also list the sha value you should be using:
```bash
nix build
warning: Git tree '/home/william/code/nix-cloudflare-caddy' is dirty
warning: found empty hash, assuming 'sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA='
error: hash mismatch in fixed-output derivation '/nix/store/gaw0d9km9rn3x1xsq7l38297m85j0mdf-cloudflare-caddy-v2.7.6-go-modules.drv':
         specified: sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
            got:    sha256-dnKAwOrQkICkUVsyWJO+o2N4HcImLaL+fPyq8hUd5/8=
error: 1 dependencies of derivation '/nix/store/rmrwby0qal7i10z10di2fzlr7cfwmh3k-cloudflare-caddy-v2.7.6.drv' failed to build
```

4. Replace `sha256` with the sha value reported by `nix-build`
5. With the `sha256` value updated, run `nix build` again. The build might fail to apply the patch.
```bash
nix build
warning: Git tree '/home/user/code/nix-cloudflare-caddy' is dirty
error: builder for '/nix/store/b5gd2lmydb6j6y90rvnrspzzfn2jdj5v-cloudflare-caddy-v2.7.6.drv' failed with exit code 1;
       last 10 log lines:
       > applying patch /nix/store/ygf32kr7sy9zgp206flw60ca33im65ga-0001-cloudflare.patch
       > patching file cmd/caddy/main.go
       > patching file go.mod
       > Hunk #1 FAILED at 7.
       > Hunk #2 FAILED at 55.
       > 2 out of 2 hunks FAILED -- saving rejects to file go.mod.rej
       > patching file go.sum
       > Hunk #1 FAILED at 93.
       > Hunk #2 succeeded at 344 (offset -92 lines).
       > 1 out of 2 hunks FAILED -- saving rejects to file go.sum.rej
       For full logs, run 'nix log /nix/store/b5gd2lmydb6j6y90rvnrspzzfn2jdj5v-cloudflare-caddy-v2.7.6.drv'.
```
6. If `nix build` failed to apply due to the patch then refer to [How to update the patch](#how-to-update-the-patch)` to resolve this.
7. If `nix build` successfully applies the patch but complains about `inconsistent vendoring` we need to replace the `vendorHash` value with an empty string `""`, so that the build regenerates the internal vendor directory and ultimately a new vendor hash. As in step 3, when `vendorHash` is an empty string, the `vendorHash` that should be used will be printed.
8. With the `vendorHash` updated, `nix build` should now succeed.

### How to update the patch

1. `git clone github.com:caddyserver/caddy --branch v2.7.6 --single-branch` where `v2.7.6` is the tag or version we're interested in
2. Edit `./cmd/caddy/main.go` so that it looks like

```go
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
```

3. `cd cmd/caddy`

> [!IMPORTANT]
> The following steps have to be executed in cmd/caddy.

4. `go get github.com/caddy-dns/cloudflare`
5. Check that we can build it with `go build .`
6. Generate the patch with `git -P diff > 0001-cloudflare.patch`
7. Move the patch to the root of this repo. Since we're currently in the caddy repo at `cmd/caddy` to move to the root of THIS repo we have to execute `mv 0001-cloudflare.patch ../../../0001-cloudflare.patch`
