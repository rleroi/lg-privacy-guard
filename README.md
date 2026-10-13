# LG Privacy Guard (in progress — manual install works, packaging TBD)

A boot-persistent telemetry/ACR blocker for rooted LG webOS TVs, aimed at
non-technical users who already have elevated system access (e.g. via
slopbro or dejavuln-autoroot + Homebrew Channel) but don't want to
hand-edit files over SSH every time.

**Status: core mechanism confirmed working, including boot persistence,
on one LG CX (webOS 5.x) unit. Not yet packaged for easy install, not yet
tested on other models/versions.** Do not distribute this more widely
until that happens.

## Goal

One-step installer (ideally a Homebrew Channel app) that:
1. Blocks known LG ACR (automatic content recognition) and ad-telemetry
   domains via a hosts-file override. ✅ working
2. Re-applies that override on every boot (the override does not survive
   a reboot by default since the relevant filesystem layer resets). ✅
   working, via Homebrew Channel's official `init.d` hook
3. Is safe to install/uninstall without any risk of making the TV
   unbootable (worst case is the block not applying, never a broken TV).

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

## Manual installation (current state — tested, works)

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

## Open questions / TODO before this goes anywhere near less-technical users

- [x] Confirm boot-hook mechanism — it's `/var/lib/webosbrew/init.d/`
      (Homebrew Channel's own `run-parts` extension point), confirmed via
      inspecting `startup.sh` directly on a CX unit.
- [x] Confirm the hosts-bind-mount approach survives a reboot — confirmed.
- [ ] Verify domain blocklist is current and complete across more
      models/firmware — currently sourced from one forum write-up plus
      manual testing on a single CX. Likely incomplete.
- [ ] Test on at least 2-3 different webOS versions/models before
      claiming general compatibility.
- [ ] Decide packaging format: a Homebrew-installable `.ipk` app that
      drops the init.d script automatically on install (so users never
      touch SSH) vs. keeping this a manual script repo. The former needs
      real on-device SDK testing (`ares-package`, `ares-install`) that
      hasn't been done yet.
- [ ] Only after the above: look at webosbrew's actual app-catalog
      contribution process (their own docs/repo, not guessed) for getting
      this listed so other users can find it.
- [ ] Write this up in a way that's honest with prospective users about
      what it does, what it doesn't guarantee, and that it requires the TV
      to already have elevated system access via one of the known
      community exploit/installer tools (out of scope for this repo).

## References

- Level1Techs forum: "LG TV Block Mini-How-to" — community write-up this
  approach is based on.
- webosbrew.org — Homebrew Channel project (the app ecosystem this would
  eventually be distributed through, and whose own `startup.sh` this
  approach piggybacks on).
