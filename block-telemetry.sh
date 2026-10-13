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
# Idempotent: safe to run multiple times in the same boot session (e.g.
# manual testing followed by the init.d hook also firing) without
# duplicating hosts entries, because /etc/hosts may already be the
# bind-mounted copy from an earlier run this session.
#
# Based on community write-up: Level1Techs "LG TV Block Mini-How-to"
# (https://forum.level1techs.com/t/lg-tv-block-mini-how-to/255178), and
# matches the same /etc/hosts bind-mount pattern Homebrew Channel's own
# startup.sh uses to block LG's software-update servers.
#
# Requires: elevated shell access already present on the TV (out of scope
# for this script — see README).

HOSTS_FILE="/tmp/hosts.privacy"
MARKER="# lg-privacy-guard block"

BLOCKLIST="
$MARKER
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
127.0.0.1 lgtvcommon.com
::1 lgtvcommon.com
127.0.0.1 service.lgtvcommon.com
::1 service.lgtvcommon.com
127.0.0.1 recommend.lgtvcommon.com
::1 recommend.lgtvcommon.com
127.0.0.1 rdl.lgtvcommon.com
::1 rdl.lgtvcommon.com
127.0.0.1 nudge.lgtvcommon.com
::1 nudge.lgtvcommon.com
127.0.0.1 homeprv.lgtvcommon.com
::1 homeprv.lgtvcommon.com
127.0.0.1 cdpsvc.lgtvcommon.com
::1 cdpsvc.lgtvcommon.com
127.0.0.1 cdpbeacon.lgtvcommon.com
::1 cdpbeacon.lgtvcommon.com
"

# Note: /etc/hosts has no wildcard support, so the *.lgtvcommon.com /
# *.lgsmartad.com entries above are listed as explicit known subdomains
# (sourced from a community NextDNS blocklist) rather than true wildcard
# blocks. A subdomain not listed here will still resolve normally — this
# is a real coverage gap compared to a DNS-level wildcard blocker like
# NextDNS/Pi-hole, which remains the more complete option if you have one
# available on your network.

# TODO: this list was compiled from one community write-up and manual
# testing on a single CX unit. It is very likely incomplete. Before this
# repo goes wider, cross-check against other models/firmware versions
# and any newer community findings.

if grep -qF "$MARKER" /etc/hosts 2>/dev/null; then
    echo "Privacy block already applied this boot session — skipping."
    exit 0
fi

cp /etc/hosts "$HOSTS_FILE"
echo "$BLOCKLIST" >> "$HOSTS_FILE"
mount --bind "$HOSTS_FILE" /etc/hosts

echo "Privacy block applied."
