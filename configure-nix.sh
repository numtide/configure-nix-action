#!/usr/bin/env bash
set -euo pipefail

if ! type -p nix ; then
  echo "Aborting: Nix is not installed"
  exit
fi

# GitHub command to put the following log messages into a group which is collapsed by default
echo "::group::Configuring Nix"

# Create a temporary workdir
workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT

# Configure Nix
add_config() {
  echo "$1" >> "$workdir/nix.conf"
}

add_config "show-trace = true"

# TODO review darwin support
#if [[ $OSTYPE =~ darwin ]]; then
#  add_config "ssl-cert-file = /etc/ssl/cert.pem"
#fi

# Add a GitHub access token.
# Token-less access is subject to lower rate limits.
# todo do we need to set a username for the github token in netrc and if so, what should it be
if [[ -n "${INPUT_GITHUB_ACCESS_TOKEN:-}" ]]; then
  echo "::debug::Using the provided github_access_token for github.com"
  add_config "access-tokens = github.com=$INPUT_GITHUB_ACCESS_TOKEN"

# Use the default GitHub token if available.
# Skip this step if running an Enterprise instance. The default token there does not work for github.com.
elif [[ -n "${GITHUB_TOKEN:-}" && $GITHUB_SERVER_URL == "https://github.com" ]]; then
  echo "::debug::Using the default GITHUB_TOKEN for github.com"
  add_config "access-tokens = github.com=$GITHUB_TOKEN"
else
  echo "::debug::Continuing without a GitHub access token"
fi

# Append extra nix configuration if provided
if [[ -n "${INPUT_EXTRA_NIX_CONFIG:-}" ]]; then
  add_config "$INPUT_EXTRA_NIX_CONFIG"
fi

if [[ ! $INPUT_EXTRA_NIX_CONFIG =~ "experimental-features" ]]; then
  add_config "experimental-features = nix-command flakes"
fi

# Set the user nix.conf and netrc
nix_conf_dir="$HOME/.config/nix"
mkdir -p "$nix_conf_dir"

mv "$workdir/nix.conf" "$nix_conf_dir/nix.conf"

# Set path
if [[ -n "${INPUT_NIX_PATH:-}" ]]; then
  echo "NIX_PATH=${INPUT_NIX_PATH}" >> "$GITHUB_ENV"
fi

# Close the log message group which was opened above
echo "::endgroup::"