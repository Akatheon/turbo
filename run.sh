#!/usr/bin/env bash
# Akatheon Turbo: fetches the pinned release archive, checks its SHA-256, and runs it.
# Copyright (c) 2026 Beaverise Inc. ("Akatheon"). All rights reserved. Patent Pending - U.S. Provisional App. No. 64/178,842.
# Use is governed by LICENSE.
set -euo pipefail

VERSION=1.2.2
SHA256=090762d0411579408f0fa55200f528a4bcae949947eed6257bb5eb1ace6143d9
URL=${AKATHEON_TURBO_URL:-https://dl.akatheon.com/turbo/$VERSION/akatheon-turbo-$VERSION-linux-x86_64.tar.gz}

if [ "$(uname -s)-$(uname -m)" != Linux-x86_64 ]; then
  echo "Akatheon Turbo runs on Linux x86_64 runners (this one is $(uname -s)-$(uname -m))" >&2
  exit 2
fi

DIR="${RUNNER_TEMP:-${TMPDIR:-/tmp}}/akatheon-turbo-$VERSION"
if [ ! -f "$DIR/.verified" ]; then
  rm -rf "$DIR" "$DIR.tar.gz"
  mkdir -p "$DIR"
  curl -fsSL --retry 3 --retry-delay 2 "$URL" -o "$DIR.tar.gz"
  if ! echo "$SHA256  $DIR.tar.gz" | sha256sum -c --quiet - ; then
    echo "Akatheon Turbo: the downloaded archive does not match its pinned SHA-256; not running it" >&2
    rm -f "$DIR.tar.gz"
    exit 3
  fi
  tar -xzf "$DIR.tar.gz" -C "$DIR" --strip-components=1
  rm -f "$DIR.tar.gz"
  touch "$DIR/.verified"
fi

# the certificates folder is never part of the change under test
CERTS=${AKCI_CERTS_DIR:-.akatheon-ci}
if EXCLUDE=$(git rev-parse --git-path info/exclude 2>/dev/null) && ! grep -qxF "$CERTS/" "$EXCLUDE" 2>/dev/null; then
  mkdir -p "$(dirname "$EXCLUDE")"
  echo "$CERTS/" >> "$EXCLUDE"
fi

export AKCI_PLUGIN_DIR="$DIR/poly"
export AKCI_RT_LIB="$DIR/lib/libak_rt.so"
exec "$DIR/bin/akatheon-ci" action
