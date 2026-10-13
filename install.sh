#!/bin/sh
# install.sh — run this directly on a rooted LG webOS TV via SSH.
#
# Installs block-telemetry.sh into Homebrew Channel's init.d hook so it
# re-applies the ACR/ad telemetry hosts block on every boot, and runs it
# immediately.
#
# Usage (on the TV, over SSH):
#   curl -ksL https://raw.githubusercontent.com/rleroi/lg-privacy-guard/master/block-telemetry.sh \
#     -o /var/lib/webosbrew/init.d/50-privacy-guard-tmp \
#   && mkdir -p /var/lib/webosbrew/init.d \
#   && mv /var/lib/webosbrew/init.d/50-privacy-guard-tmp /var/lib/webosbrew/init.d/50-privacy-guard \
#   && chmod +x /var/lib/webosbrew/init.d/50-privacy-guard \
#   && /var/lib/webosbrew/init.d/50-privacy-guard
#
# This script exists mainly as documentation of that one-liner; most
# users will just copy the one-liner above directly rather than fetching
# this file too.

set -e

# raw.githubusercontent.com is served through a CDN that caches content
# for a few minutes after a push, so always cache-bust this fetch —
# otherwise a freshly-pushed fix can silently not apply.
RAW_URL="https://raw.githubusercontent.com/rleroi/lg-privacy-guard/master/block-telemetry.sh?nocache=$(date +%s)"
DEST="/var/lib/webosbrew/init.d/50-privacy-guard"

mkdir -p /var/lib/webosbrew/init.d
curl -ksL "$RAW_URL" -o "$DEST"
chmod +x "$DEST"
"$DEST"

echo "Installed. Will re-apply automatically on every boot."
echo "To uninstall: rm $DEST && reboot"
