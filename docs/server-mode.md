# Server Mode

Runs `sakost-pc` as a headless, unattended SSH server (no desktop) while away.
Implementation: `modules/profiles/server.nix`, enabled by the `sakost-server`
flake output.

## Switching

```bash
sudo nixos-rebuild switch --flake .#sakost-server   # → server mode
sudo nixos-rebuild switch --flake .#sakost-pc       # → desktop mode (works over SSH)
```

> **Footgun**: `sudo nixos-rebuild switch --flake .` (no output name) matches
> by hostname and silently selects the **desktop** config. SSH stays enabled
> there so access is not lost, but the server hardening is gone. While away,
> always pass the explicit output name.

## What server mode changes

- Desktop off (hyprland + greetd force-disabled), boots to `multi-user.target`.
- Home-manager's hyprland module force-disabled too (it would otherwise
  drag in its xdg.portal assertion with no system portal stack present).
- Sleep/suspend/hibernate targets disabled.
- fail2ban on (LAN `192.168.1.0/24` and Tailscale `100.64.0.0/10` exempt),
  `MaxAuthTries 3`.
- WiFi powersave off.
- Hardware watchdog: reboot after 2min kernel hang.
- Everything else (NVIDIA/CUDA, podman, Tailscale, snapshots) unchanged.
  Tailscale is always on (modules/services/tailscale.nix), so the box is
  reachable as `sakost-pc` over MagicDNS in either mode.

## Checklist before leaving

### One-time on the PC
1. Create the WiFi connection as a system connection (no profile exists yet —
   the box is on ethernet today; WiFi card is Intel AX210, `wlp7s0`):
   `sudo nmcli device wifi connect "<SSID>" password "<psk>"`
   Then verify: `nmcli -f NAME,TYPE,AUTOCONNECT connection show` shows the
   SSID with autoconnect `yes`, and it survives `sudo systemctl restart NetworkManager`
   with no user logged in.
2. `sudo tailscale up` — log in once; verify the box appears in the tailnet
   and `ssh sakost@sakost-pc` works from another device. Disable key expiry
   for this node in the admin console so it never drops off unattended.
3. Switch to server mode and run the full test list below.

### Router
1. Static DHCP lease for the AX210 WiFi MAC (`ip link show wlp7s0`).
2. Port-forward: external TCP `<non-standard-port>` → `<PC-LAN-IP>:22`
   (non-standard external port cuts scanner noise; sshd itself stays on 22).
3. Test from outside (phone hotspot): `ssh -p <port> sakost@<public-ip>`.
4. Confirm the LAN subnet matches fail2ban's `ignoreIP` (`192.168.1.0/24`
   in modules/profiles/server.nix) — adjust if the router hands out a
   different range.

### BIOS
- "Restore on AC Power Loss" = On.
- ErP / deep sleep states = Off.

## Rules while away

- **Never update firmware (fwupd/BIOS) remotely** — TPM unlock is PCR-bound;
  a changed PCR leaves the box at a passphrase prompt nobody can answer.
  Kernel/NixOS updates via lanzaboote are fine.
- Prefer `nixos-rebuild switch` over `boot` for remote updates: failures
  surface while the old system is still running. Reboot only when needed.
- Rollback safety: systemd-boot keeps 5 generations (`configurationLimit`).
- **Dynamic IP**: the port-forward path assumes the home public IP stays
  put. Set up DDNS or a periodic phone-home (e.g. a cron that publishes
  the current public IP somewhere you can read) before leaving.
- **Risky remote updates**: schedule a dead-man's reboot first —
  `sudo systemd-run --on-active=10m reboot`, then `nixos-rebuild test`
  (no bootloader change); if the new config kills networking, the
  scheduled reboot brings back the previous boot default. Cancel the
  timer (`systemctl stop <unit>`) once access is confirmed. Also use
  `IdentitiesOnly yes` / an explicit `IdentityFile` in the away client's
  SSH config — an agent offering 3+ keys exhausts `MaxAuthTries 3` and
  earns a 10-minute fail2ban ban.

## Full test list (run while still home)

1. Both outputs build (`/check` habit):
   `nix build .#nixosConfigurations.sakost-{pc,server}.config.system.build.toplevel --no-link`
2. Switch to server mode: monitor shows console/no greeter.
3. SSH from LAN works; `nvidia-smi` works over SSH; podman containers run.
4. SSH from phone hotspot via public IP + forwarded port works.
5. `ssh sakost@sakost-pc` (Tailscale/MagicDNS) works from the hotspot too.
6. Unplug ethernet: box stays reachable over WiFi.
7. Cold-boot test with no keyboard/monitor: power off, power on → TPM
   unlocks → WiFi autoconnects → SSH reachable.
8. `sudo fail2ban-client status sshd` shows the jail active.
9. Switch back to desktop mode: Hyprland session returns intact.
