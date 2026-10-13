#!/bin/sh
# block-telemetry.sh — tested and confirmed working (survives reboot) on a
# webOS CX TV via the Homebrew Channel init.d hook.
#
# Redirects known LG ACR / ad-telemetry domains to localhost via a
# hosts-file bind-mount, since /etc is a read-only overlay on webOS and
# resets on every reboot. This script is meant to be installed into
# Homebrew Channel's official extension point so it re-applies on every
# boot automatically (see README "Installation" section).
#
# Based on community write-up: Level1Techs "LG TV Block Mini-How-to"
# (https://forum.level1techs.com/t/lg-tv-block-mini-how-to/255178), and
# matches the same /etc/hosts bind-mount pattern Homebrew Channel's own
# startup.sh uses to block LG's software-update servers.
#
# Requires: elevated shell access already present on the TV (out of scope
# for this script — see README).

HOSTS_FILE="/tmp/hosts.privacy"

BLOCKLIST="
127.0.0.1 ad.lgappstv.com
::1 ad.lgappstv.com
127.0.0.1 us.lgsmartad.com
::1 us.lgsmartad.com
127.0.0.1 lgsmartad.com
::1 lgsmartad.com
127.0.0.1 global.lgsmartad.com
::1 global.lgsmartad.com
127.0.0.1 azure.lgsmartad.com
::1 azure.lgsmartad.com
127.0.0.1 collector.bi.webos.lge.com
::1 collector.bi.webos.lge.com
127.0.0.1 svcs.lgsmartad.com
::1 svcs.lgsmartad.com
127.0.0.1 ibis.lgsmartad.com
::1 ibis.lgsmartad.com
127.0.0.1 attic.lgappstv.com
::1 attic.lgappstv.com
127.0.0.1 nvcs.lgsmartad.com
::1 nvcs.lgsmartad.com
"

# TODO: this list was compiled from one community write-up and manual
# testing on a single CX unit. It is very likely incomplete. Before this
# repo goes public, cross-check against other models/firmware versions
# and any newer community findings.

cp /etc/hosts "$HOSTS_FILE"
echo "$BLOCKLIST" >> "$HOSTS_FILE"
mount --bind "$HOSTS_FILE" /etc/hosts

echo "Privacy block applied."
