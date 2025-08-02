#!/bin/bash

set -e

if [[ $# -eq 0 ]]; then
  echo "Usage: $0 file1.deb [file2.deb ...]"
  exit 1
fi

for DEBFILE in "$@"; do
  if [[ ! -f "$DEBFILE" ]]; then
    echo "Skipping: $DEBFILE is not a regular file."
    continue
  fi

  echo "Processing: $DEBFILE"
  TMPDIR=$(mktemp -d /tmp/deb.XXXXXXXXXX) || exit 1
  trap "rm -rf '$TMPDIR'" EXIT

  dpkg-deb -x "$DEBFILE" "$TMPDIR"
  dpkg-deb --control "$DEBFILE" "$TMPDIR/DEBIAN"

  CONTROL="$TMPDIR/DEBIAN/control"
  if [[ ! -f "$CONTROL" ]]; then
    echo "Error: control file not found in $DEBFILE."
    continue
  fi

  OLD_HASH=$(sha256sum "$CONTROL" | cut -d ' ' -f1)
  nano "$CONTROL"
  NEW_HASH=$(sha256sum "$CONTROL" | cut -d ' ' -f1)

  if [[ "$OLD_HASH" == "$NEW_HASH" ]]; then
    echo "Not modified: $DEBFILE"
  else
    echo "Modified. Rebuilding: $DEBFILE"
    dpkg-deb -b "$TMPDIR" "$DEBFILE"
    echo "Updated: $DEBFILE"
  fi

  rm -rf "$TMPDIR"
done

echo "Generating Packages file..."
dpkg-scanpackages -m . /dev/null > Packages
bzip2 -fks Packages
echo "Done."
