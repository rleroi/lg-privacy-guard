# LG Privacy Guard

A boot-persistent telemetry/ACR blocker for rooted LG webOS TVs. For
anyone who already has root SSH access (e.g. via slopbro or
dejavuln-autoroot + Homebrew Channel) and wants a one-line install
instead of hand-typing the commands over SSH each time.

Tested on an LG CX (webOS 5.x). Other webOS models/versions are
untested — if you try it elsewhere, please open an issue with the
result either way.

## Step 0: get root SSH access

This repo does nothing on its own — it assumes your TV already has root
SSH access via one of the community tools below.

1. Check whether your TV's firmware is exploitable:
   **[cani.rootmy.tv](https://cani.rootmy.tv/)** — look up your model and
   webOS version.
2. If it is, use **[slopbro](https://github.com/throwaway96/slopbro)**
   to root it and install Homebrew Channel.
3. Then do the one-time SSH hardening step below before installing this.

## Step 1: secure SSH access

Homebrew Channel ships a well-known default root SSH password (`alpine`)
until you replace it with key-based auth.

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
   `/home/root/.ssh/authorized_keys` and skips setting the default
   password once that file exists.
4. From then on, connect with `ssh -i ~/.ssh/webos_tv root@<TV_IP>`
   instead of a password.

Note: a plain `passwd` command on the TV won't work — `/etc/shadow` is
on a read-only overlay, so the SSH-key method above is the way to move
off the default password.

## Step 2: install the privacy guard

Run from your computer, no need to open a separate SSH session first —
replace `<TV_IP>`:

```bash
ssh -i ~/.ssh/webos_tv root@<TV_IP> 'curl -ksL https://raw.githubusercontent.com/rleroi/lg-privacy-guard/master/install.sh | sh'
```

That's it — it applies immediately and re-applies automatically on every
boot from then on.

### What it does

LG webOS TVs ship with ACR (automatic content recognition) and
ad-tracking enabled by default. Settings-menu toggles (Live Plus,
Viewing Information, etc.) help but are reset by software updates and
don't fully stop the underlying processes (`acr2` and `admanager`,
talking to domains like `lgsmartad.com` and `lgappstv.com`).

This installer:
- Redirects those domains to localhost via a hosts-file override
  (`/etc` is a read-only overlay on webOS, so this is done with a
  bind-mount rather than a direct edit).
- Drops that override into `/var/lib/webosbrew/init.d/` — Homebrew
  Channel's own official `run-parts` boot-hook extension point, the same
  one it uses internally to block LG's software-update servers — so the
  override re-applies on every boot without any custom boot hook.
- Is safe to install and uninstall: the override lives on a layer that
  resets on reboot anyway, so nothing here can make the TV unbootable.

### Manual / step-by-step install

If you'd rather not pipe `curl` to `sh`, do it by hand:

```bash
scp block-telemetry.sh root@<TV_IP>:/tmp/

ssh root@<TV_IP>
mkdir -p /var/lib/webosbrew/init.d
cp /tmp/block-telemetry.sh /var/lib/webosbrew/init.d/50-privacy-guard
chmod +x /var/lib/webosbrew/init.d/50-privacy-guard
/var/lib/webosbrew/init.d/50-privacy-guard
```

### Verify it worked

```bash
cat /etc/hosts | tail -15
nslookup ad.lgappstv.com   # should resolve to 0.0.0.0 / ::
```

### Uninstall

```bash
rm /var/lib/webosbrew/init.d/50-privacy-guard
reboot
```
(The hosts override itself lives in a reset-on-boot layer, so removing
the init.d hook is enough — nothing else to clean up.)

## Known limitations

- `/etc/hosts` has no wildcard support, so subdomains are listed
  explicitly rather than as true wildcard blocks. A subdomain not in the
  list will still resolve normally. A DNS-level blocker (NextDNS,
  Pi-hole) on your network gives more complete coverage if you have one.
- The domain list is sourced from one forum write-up, a community
  NextDNS list, and manual testing on a single CX — likely incomplete.
  PRs adding verified domains are welcome.
- Only confirmed on webOS 5.x (LG CX) so far.

## References

- Level1Techs forum: "LG TV Block Mini-How-to" — community write-up this
  approach is based on.
- webosbrew.org — Homebrew Channel project, whose own `startup.sh` and
  `init.d` boot-hook mechanism this approach piggybacks on.
- A community-shared NextDNS custom blocklist (found via Reddit, original
  source/author not tracked down) contributed the `lgtvcommon.com` and
  related subdomains blocked above.
