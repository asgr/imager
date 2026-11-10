#!/bin/sh
# Generate inst/include/CImg.h from the vanilla upstream header plus the local
# patches in tools/cimg/patches/.
#
# Why patches rather than a pre-patched header
# --------------------------------------------
# imager used to vendor CImg.h with its local fixes already applied, which made
# re-vendoring error-prone: there was no record of *what* had been changed, so
# a re-vendor silently lost fixes (the 2021 ss.back() fix and the 2025 vector()
# fix were both lost this way, years apart). Keeping the vanilla header and one
# file per fix means the diff against upstream is always exactly the patch set,
# and a re-vendor is "download, run this script, fix any patch that fails".
#
# The result is generated, not committed. That keeps a single source of truth
# (this directory) and guarantees the header cannot drift from the patches.
#
# Usage:  sh tools/cimg/apply_patches.sh [output-header]
#         (default output: inst/include/CImg.h)
#
# Requires: patch (POSIX/GNU; part of Rtools on Windows, present on macOS and
#           on any Linux build machine).

set -e

root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
vanilla="$root/tools/cimg/CImg_vanilla.h"
patchdir="$root/tools/cimg/patches"
out="${1:-$root/inst/include/CImg.h}"

if [ ! -f "$vanilla" ]; then
  echo "apply_patches: missing $vanilla" >&2
  exit 1
fi
if [ ! -d "$patchdir" ]; then
  echo "apply_patches: missing $patchdir" >&2
  exit 1
fi
if ! command -v patch >/dev/null 2>&1; then
  echo "apply_patches: the 'patch' utility is required but was not found on PATH" >&2
  exit 1
fi

# Build the patched header in a scratch directory laid out as the package root
# is, because the patches carry a/inst/include/CImg.h paths so that they apply
# with -p1 from the package root as well as from here.
work=$(mktemp -d 2>/dev/null || mktemp -d -t imagerp)
trap 'rm -rf "$work"' EXIT INT TERM

mkdir -p "$work/inst/include"
cp "$vanilla" "$work/inst/include/CImg.h"

failed=""
for p in "$patchdir"/*.patch; do
  [ -e "$p" ] || continue
  # -F0: no fuzz. GNU patch fuzzes by default, which lets a patch written
  # against an older upstream land at the wrong offset and still "succeed".
  # For a header that must match upstream exactly plus known fixes, a
  # mislocated hunk is worse than a build failure.
  if ! ( cd "$work" && patch -p1 -F0 --no-backup-if-mismatch -s -i "$p" ); then
    failed="$failed $(basename "$p")"
  fi
done

if [ -n "$failed" ]; then
  cat >&2 <<EOF
apply_patches: these patches did not apply:$failed

This normally means tools/cimg/CImg_vanilla.h was updated to a newer CImg
without re-basing the patches. For each failing patch, port it to the new
header by hand, then regenerate it with:

  cp tools/cimg/CImg_vanilla.h /tmp/CImg.h
  ( edit /tmp/CImg.h until it has the fix, applied to the new upstream code )
  diff -u tools/cimg/CImg_vanilla.h /tmp/CImg.h

Do not delete a patch to make the build pass without first deciding what
happened to the fix it carries.
EOF
  exit 1
fi

mkdir -p "$(dirname "$out")"
cp "$work/inst/include/CImg.h" "$out"
echo "apply_patches: wrote $out from $(ls "$patchdir"/*.patch | wc -l | tr -d ' ') patches"