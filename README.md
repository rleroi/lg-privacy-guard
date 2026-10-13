# LG Privacy Guard

A boot-persistent telemetry/ACR blocker for rooted LG webOS TVs, aimed at
non-technical users who already have elevated system access (e.g. via
slopbro or dejavuln-autoroot + Homebrew Channel) but don't want to
hand-edit files over SSH every time.

**Status: core mechanism confirmed working, including boot persistence,
on one LG CX (webOS 5.x) unit, installed via a one-liner over SSH. Only
tested on the one unit above; other models/versions are untested (see
Step 0 below for how to check compatibility and report back if you try
it).

## Step 0: get root/elevated shell access first

This repo does nothing on its own — it assumes your TV already has root
SSH access via one of the community tools below. If you don't have that
yet, do it first:

1. Check whether your TV's firmware is even exploitable:
   **[cani.rootmy.tv](https://cani.rootmy.tv/)** — look up your model and
   webOS version.
2. If it is, use **[slopbro](https://github.com/throwaway96/slopbro)**
   to root it and install Homebrew Channel. (This is what was used to
   develop and test this repo, on an LG CX / webOS 5.x.)
3. Come back here once you have root SSH working (see the "secure SSH
   access" section below for one more setup step).

This repo has only been tested on one LG CX (webOS 5.x) unit — it very
likely works on other webOS 4–11 models/versions too (same general
system layout), but that's unconfirmed. If you try it on a different
model/version, please open an issue with the result either way.

## Goal

A one-line installer, run once over SSH, that:
1. Blocks known LG ACR (automatic content recognition) and ad-telemetry
   domains via a hosts-file override. ✅ working
2. Re-applies that override on every boot (the override does not survive
   a reboot by default since the relevant filesystem layer resets). ✅
   working, via Homebrew Channel's official `init.d` hook
3. Is safe to install/uninstall without any risk of making the TV
   unbootable (worst case is the block not applying, never a broken TV).

## Prerequisite: secure SSH access first

Homebrew Channel ships a well-known default root SSH password (`alpine`)
until you replace it with key-based auth. If you haven't done this yet,
do it before anything else:

1. Generate a key pair on your computer if you don't have one:
   ```bash
   ssh-keygen -t ed25519 -f ~/.ssh/webos_tv
   ```
2. Copy the public key to the TV (you'll be prompted for the default
   `alpine` password one last time):
   ```bash
   ssh-copy-id -i ~/.ssh/webos_tv.pub root@<TV_IP>
   ```
   If `ssh-copy-id` isn't available, do it manually:
   ```bash
   cat ~/.ssh/webos_tv.pub | ssh root@<TV_IP> "mkdir -p /home/root/.ssh && cat >> /home/root/.ssh/authorized_keys"
   ```
3. Reboot the TV. Homebrew's own startup script checks for
   `/home/root/.ssh/authorized_keys` and automatically skips setting the
   default password once that file exists — confirmed by reading
   `/var/lib/webosbrew/startup.sh` directly on-device.
4. From then on, connect with `ssh -i ~/.ssh/webos_tv root@<TV_IP>`
   instead of a password.

Note: a plain `passwd` command on the TV won't work — `/etc/shadow` is
on a read-only overlay, so the only supported way to move off the
default password is the SSH-key method above.

## Why this is needed

LG webOS TVs ship with ACR and ad-tracking services enabled by default.
Settings-menu toggles (Live Plus, Viewing Information, etc.) help but are
reset by software updates and don't fully stop the underlying processes.
Community research (see References) shows the relevant services are
`acr2` and `admanager`, talking to domains like `lgsmartad.com` and
`lgappstv.com`.

## How it works (confirmed)

- `block-telemetry.sh` copies `/etc/hosts`, appends the domain blocklist,
  and bind-mounts the modified copy over `/etc/hosts`.
- Homebrew Channel's own `startup.sh` runs `run-parts /var/lib/webosbrew/init.d`
  on every boot — this is the official, documented extension point
  Homebrew itself uses to re-apply its own `/etc/hosts` tweaks (it uses
  the identical bind-mount trick to block LG's software-update servers).
  Dropping our script there means it reruns automatically on every boot,
  no custom boot hook needed.
- Verified: domains resolve to `0.0.0.0`/`::` both immediately after
  running the script and after a full reboot.

## Installation

One-liner (see `install.sh`):
```bash
curl -ksL https://raw.githubusercontent.com/rleroi/lg-privacy-guard/master/install.sh | sh
```

Or step by step:

```bash
# copy the script to the TV
scp block-telemetry.sh root@<TV_IP>:/tmp/

# on the TV:
ssh root@<TV_IP>
mkdir -p /var/lib/webosbrew/init.d
cp /tmp/block-telemetry.sh /var/lib/webosbrew/init.d/50-privacy-guard
chmod +x /var/lib/webosbrew/init.d/50-privacy-guard

# test immediately
/var/lib/webosbrew/init.d/50-privacy-guard
cat /etc/hosts | tail -15

# test persistence
reboot
# wait, ssh back in:
cat /etc/hosts | tail -15
nslookup ad.lgappstv.com   # should resolve to 0.0.0.0 / ::
```

## Uninstall

```bash
rm /var/lib/webosbrew/init.d/50-privacy-guard
reboot
```
(The hosts override itself lives in a reset-on-boot layer, so removing
the init.d hook is enough — nothing else to clean up.)

## Open questions / TODO

- [x] Confirm boot-hook mechanism — it's `/var/lib/webosbrew/init.d/`
      (Homebrew Channel's own `run-parts` extension point), confirmed via
      inspecting `startup.sh` directly on a CX unit.
- [x] Confirm the hosts-bind-mount approach survives a reboot — confirmed.
- [x] One-liner installer via SSH — confirmed working.
- [ ] Verify domain blocklist is current and complete across more
      models/firmware — currently sourced from one forum write-up, a
      community NextDNS list, plus manual testing on a single CX. Likely
      incomplete.
- [ ] Test on other webOS versions/models — only confirmed on LG CX
      (webOS 5.x) so far.

## References

- Level1Techs forum: "LG TV Block Mini-How-to" — community write-up this
  approach is based on.
- webosbrew.org — Homebrew Channel project, whose own `startup.sh` and
  `init.d` boot-hook mechanism this approach piggybacks on.
- A community-shared NextDNS custom blocklist (found via Reddit, original
  source/author not tracked down) contributed the `lgtvcommon.com` and
  related subdomains blocked above.
