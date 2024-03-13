# configure-nix-action

![GitHub Actions badge](https://github.com/numtide/configure-nix-action/workflows/configure-nix-action%20test/badge.svg)

Configures [Nix](https://nixos.org/nix/) on GitHub Actions for the supported platforms: Linux and macOS.

> Draws heavily from [Install Nix Action](https://github.com/cachix/install-nix-action) and is intended for use with
self-hosted [Github Action Runners](https://nix-community.github.io/srvos/github_actions_runner/). Once the kinks are 
smoothed out this should be merged into cachix/install-nix-action.

By default it has no nixpkgs configured, you have to set `nix_path`
by [picking a channel](https://status.nixos.org/)
or [pin nixpkgs yourself](https://nix.dev/reference/pinning-nixpkgs)
(see also [pinning tutorial](https://nix.dev/tutorials/towards-reproducibility-pinning-nixpkgs)).

# Features

- Allows specifying `$NIX_PATH` and channels via `nix_path`
- Enables `flakes` and `nix-command` experimental features by default (to disable, set `experimental-features` via `extra_nix_config`)

## Usage

Create `.github/workflows/test.yml` in your repo with the following contents:

```yaml
name: "Test"
on:
  pull_request:
  push:
jobs:
  tests:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - uses: numtide/configure-nix-action@v1
      with:
        nix_path: nixpkgs=channel:nixos-unstable
    - run: nix-build
```

## Usage with Flakes

```yaml
name: "Test"
on:
  pull_request:
  push:
jobs:
  tests:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - uses: numtide/configure-nix-action@v1
      with:
        github_access_token: ${{ secrets.GITHUB_TOKEN }}
    - run: nix build
    - run: nix flake check
```

To install Nix from any commit, go to [the corresponding installer_test action](https://github.com/NixOS/nix/runs/2219534360) and click on "Run numtide/configure-nix-action@XX" step and expand the first line.

## Inputs (specify using `with:`)

- `extra_nix_config`: append to `$HOME/.config/nix/nix.conf`

- `github_access_token`: configure Nix to pull from GitHub using the given GitHub token. This helps work around rate limit issues. Has no effect when `access-tokens` is also specified in `extra_nix_config`.

- `nix_path`: set `NIX_PATH` environment variable, for example `nixpkgs=channel:nixos-unstable`

---

## FAQ

### How do I print nixpkgs version I have configured?

```yaml
- name: Print nixpkgs version
  run: nix-instantiate --eval -E '(import <nixpkgs> {}).lib.version'
```

### How do I run NixOS tests?

With the following inputs:

```yaml
- uses: numtide/configure-nix-action@vXX
  with:
    extra_nix_config: "system-features = nixos-test benchmark big-parallel kvm"
```

### How do I install packages via nix-env from the specified `nix_path`?

```
nix-env -i mypackage -f '<nixpkgs>'
```

### How do I add a binary cache?

```yaml
- uses: numtide/configure-nix-action@v25
  with:
    extra_nix_config: |
      trusted-public-keys = nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs= cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=
      substituters = https://nix-community.cachix.org https://cache.nixos.org/
```

### How do I pass environment variables to commands run with `nix develop` or `nix shell`?

Nix runs commands in a restricted environment by default, called `pure mode`.
In pure mode, environment variables are not passed through to improve the reproducibility of the shell.

You can use the `--keep / -k` flag to keep certain environment variables:

```yaml
- name: Run a command with nix develop
  run: nix develop --ignore-environment --keep MY_ENV_VAR --command echo $MY_ENV_VAR
  env:
    MY_ENV_VAR: "hello world"
```

Or you can disable pure mode entirely with the `--impure` flag:

```
nix develop --impure
```