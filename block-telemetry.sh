#!/bin/sh
# block-telemetry.sh — draft, UNTESTED on real hardware.
# Redirects known LG ACR / ad-telemetry domains to localhost via a
# hosts-file bind-mount, since /etc is a read-only overlay on webOS.
#
# Based on community write-up: Level1Techs "LG TV Block Mini-How-to"
# (https://forum.level1techs.com/t/lg-tv-block-mini-how-to/255178)
#
# Requires: elevated shell access already present on the TV (out of scope
# for this script — see README).

HOSTS_FILE="/tmp/hosts.privacy"

BLOCKLIST="
127.0.0.1 ad.lgappstv.com
127.0.0.1 us.lgsmartad.com
127.0.0.1 lgsmartad.com
127.0.0.1 global.lgsmartad.com
127.0.0.1 azure.lgsmartad.com
127.0.0.1 collector.bi.webos.lge.com
127.0.0.1 svcs.lgsmartad.com
127.0.0.1 ibis.lgsmartad.com
127.0.0.1 attic.lgappstv.com
127.0.0.1 nvcs.lgsmartad.com
"

# TODO: verify this list is current; cross-check against the referenced
# forum thread and any newer community findings before relying on it.

cp /etc/hosts "$HOSTS_FILE"
echo "$BLOCKLIST" >> "$HOSTS_FILE"
mount --bind "$HOSTS_FILE" /etc/hosts

echo "Privacy block applied (this session only — see README for the"
echo "still-unsolved boot-persistence step)."
