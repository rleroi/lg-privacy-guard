# LG Privacy Guard (planning stage — not yet functional)

A boot-persistent telemetry/ACR blocker for rooted LG webOS TVs, aimed at
non-technical users who already have root access (e.g. via slopbro or
dejavuln-autoroot + Homebrew Channel) but don't want to hand-edit files over
SSH every time.

**Status: concept + script draft only.** Nothing here has been tested on a
real TV yet. Do not package or distribute this until it has been verified
end-to-end on actual hardware across at least a couple of webOS versions.

## Goal

One-step installer (ideally a Homebrew Channel app) that:
1. Blocks known LG ACR (automatic content recognition) and ad-telemetry
   domains via a hosts-file override.
2. Re-applies that override on every boot (the override does not survive a
   reboot by default since the relevant filesystem layer resets).
3. Is safe to install/uninstall without any risk of making the TV unbootable
   (worst case is the block not applying, never a broken TV).

## Why this is needed

LG webOS TVs ship with ACR and ad-tracking services enabled by default.
Settings-menu toggles (Live Plus, Viewing Information, etc.) help but are
reset by software updates and don't fully stop the underlying processes.
Community research (see References) shows the relevant services are
`acr2` and `admanager`, talking to domains like `lgsmartad.com` and
`lgappstv.com`.

## Planned approach

- `block-telemetry.sh`: copies `/etc/hosts`, appends the domain blocklist,
  bind-mounts the modified copy over `/etc/hosts`.
- A boot hook (exact mechanism TBD — likely a Homebrew Channel startup
  script location, needs confirming per webOS version) re-runs the script
  on every boot, since the override lives on a layer that resets on
  reboot.
- Packaging: eventually ship as an installable Homebrew Channel app rather
  than a manual script, so less technical users can install in one step
  from the Homebrew app catalog.

## Open questions / TODO before this goes anywhere near real users

- [ ] Confirm exact boot-hook path across webOS 4–11 (varies by Homebrew
      Channel version; untested).
- [ ] Verify domain blocklist is current and complete — ad/ACR endpoints
      change over time, and a stale list gives false confidence.
- [ ] Test on at least 2-3 different webOS versions/models before claiming
      general compatibility.
- [ ] Decide packaging format: plain script repo vs. proper webOS service
      app (`.ipk`) — the latter needs real on-device SDK testing
      (`ares-package`, `ares-install`) that hasn't been done.
- [ ] Only after the above: look at webosbrew's actual app-catalog
      contribution process (their own docs/repo, not guessed) for getting
      this listed so other users can find it.
- [ ] Add an uninstall/undo script (restore original `/etc/hosts`, remove
      boot hook) as a first-class feature, not an afterthought.
- [ ] Write this up in a way that's honest with prospective users about
      what it does, what it doesn't guarantee, and that it requires the TV
      to already have elevated system access via one of the known
      community exploit/installer tools (out of scope for this repo).

## Draft script (untested on hardware)

See `block-telemetry.sh`.

## References

- Level1Techs forum: "LG TV Block Mini-How-to" — community write-up this
  approach is based on.
- webosbrew.org — Homebrew Channel project (the app ecosystem this would
  eventually be distributed through).
