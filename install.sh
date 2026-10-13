#!/bin/sh
# install.sh — run this directly on a rooted LG webOS TV via SSH.
#
# Installs block-telemetry.sh into Homebrew Channel's init.d hook so it
# re-applies the ACR/ad telemetry hosts block on every boot, and runs it
# immediately.
#
# Usage (on the TV, over SSH):
#   curl -ksL https://raw.githubusercontent.com/rleroi/lg-privacy-guard/master/install.sh | sh
#
# This script exists mainly as documentation of that one-liner; most
# users will just run the one-liner above directly rather than fetching
# this file separately.

set -e

# Note: raw.githubusercontent.com is served through a CDN with a ~5
# minute cache, keyed by path only (query-string cache-busting does NOT
# work here). If you just pushed a change to this repo and are testing
# immediately, wait a few minutes rather than trying to force a refresh.
RAW_URL="https://raw.githubusercontent.com/rleroi/lg-privacy-guard/master/block-telemetry.sh"
DEST="/var/lib/webosbrew/init.d/50-privacy-guard"

mkdir -p /var/lib/webosbrew/init.d
curl -ksL "$RAW_URL" -o "$DEST"
chmod +x "$DEST"
"$DEST"

echo "Installed. Will re-apply automatically on every boot."
echo "To uninstall: rm $DEST && reboot"
