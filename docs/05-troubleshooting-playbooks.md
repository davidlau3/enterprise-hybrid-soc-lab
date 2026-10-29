# 05 – Engineering Troubleshooting & Fixes

Real problems hit while building the lab, written up as short root-cause analyses: **Symptom → Root cause → Fix → Verification**.

---

## 1. VM could ping but not resolve DNS

| | |
|---|---|
| **Symptom** | After isolating a VM from the LAN, `ping 8.8.8.8` worked but `ping google.com` failed ("Temporary failure in name resolution"). |
| **Root cause** | The VM's DNS server is the Pi-hole (`192.168.8.200`), which lives inside the `192.168.8.0/24` range the new DROP rule blocks. |
| **Fix** | Added an exception **above** the DROP rule: `ACCEPT → 192.168.8.200 UDP/53`. |
| **Verification** | Names resolve; every other LAN destination is still dropped. |
| **Lesson** | Firewall rules are first-match — exceptions must sit above broad denies. |

---

## 2. Windows IO delay → INACCESSIBLE_BOOT_DEVICE

| | |
|---|---|
| **Symptom** | Windows guests ran with ~80% IO delay. Moving the disk from SATA to VirtIO SCSI then caused a **blue screen: INACCESSIBLE_BOOT_DEVICE**. |
| **Root cause** | Windows only loads storage drivers it already uses at boot. The VirtIO SCSI driver (`vioscsi`) was installed but never initialized. |
| **Fix** | 1. Install `virtio-win` guest drivers. 2. Move the boot disk back to SATA so Windows boots. 3. Attach a **1 GB dummy disk on SCSI**, then boot — Windows detects it and initializes `vioscsi`. 4. Confirm *Red Hat VirtIO SCSI controller* in Device Manager. 5. Shut down, remove the dummy, move the real disk to SCSI0, and set it first in the boot order. |
| **Verification** | Boots cleanly on VirtIO SCSI, and IO delay drops to normal. |

---

## 3. SSH hardening silently overridden

| | |
|---|---|
| **Symptom** | After setting `PasswordAuthentication no` and `PermitRootLogin no`, password and root logins still worked. |
| **Root cause** | (a) `UsePAM yes` let PAM make its own authentication decision. (b) `/etc/ssh/sshd_config.d/50-cloud-init.conf`, left over from first-boot provisioning, is loaded **after** the main config and re-enabled passwords — effectively a backdoor. |
| **Fix** | Set `UsePAM no` and disable the drop-in: `sudo mv /etc/ssh/sshd_config.d/50-cloud-init.conf{,.bak}`, then `sudo systemctl restart ssh`. |
| **Verification** | Password-only and root attempts are refused. |
| **Lesson** | Always audit `sshd_config.d/` — or run `sshd -T` to see the effective configuration. |

---

## 4. Fail2ban never banned anyone

| | |
|---|---|
| **Symptom 1** | Two `[sshd]` sections in `jail.local` conflicted. |
| **Fix 1** | Configure a single `[sshd]` jail. |
| **Symptom 2** | Failed key-based attempts never triggered a ban. |
| **Root cause 2** | In `normal` mode Fail2ban only matches bad-password log lines, and password auth was already disabled. |
| **Fix 2** | `mode = aggressive` to match all unauthorized connection patterns. |
| **Verification** | Three failures → source IP appears in `fail2ban-client status sshd`. |

---

## 5. No authentication telemetry in the SIEM

| | |
|---|---|
| **Symptom** | Authentication tests against the Windows target produced **zero** 4624/4625 events in Splunk, and ICMP pings showed 100% loss. |
| **Root cause** | Windows Firewall blocks ICMP by default, and the built-in SMB (TCP 445) rules only applied to the Domain/Private profiles — so traffic never reached the authentication layer. |
| **Fix** | On the target (admin PowerShell):<br>`New-NetFirewallRule -DisplayName "Allow SMB 445 All Profiles" -Direction Inbound -LocalPort 445 -Protocol TCP -Action Allow -Profile Any`<br>`Enable-NetFirewallRule -DisplayGroup "File and Printer Sharing"` |
| **Verification** | Port 445 reports open, and 4625/4624 events appear in `index=endpoint`. |

---

## 6. Username format broke on the command line

| | |
|---|---|
| **Symptom** | Logins in `DOMAIN\user` format failed from a Bash shell even with valid credentials, and no logon events were generated. |
| **Root cause** | Bash treated the backslash as an escape (`\n` became a newline), so the username sent was wrong. |
| **Fix** | Use the **UPN format** (`user@lab.local`), which has no backslash. |
| **Verification** | Authentication completes and the expected logon events reach the SIEM. |

---

## 7. Lab VMs could not resolve DNS behind pfSense

| | |
|---|---|
| **Symptom** | VMs on `vmbr1` had an IP address but no name resolution. |
| **Fix** | Set DNS per OS. **Windows:** `ncpa.cpl` → IPv4 DNS. **Ubuntu:** add nameservers in `/etc/netplan/50-cloud-init.yaml`, then `sudo netplan apply`. **Kali:** `nmcli connection modify "Wired connection 1" ipv4.dns "8.8.8.8 1.1.1.1"`. Domain members use the DC (`192.168.10.102`) as DNS. |

---

## 8. SIEM timestamps were off by hours

| | |
|---|---|
| **Symptom** | Events in Splunk didn't line up with when the activity happened, which made correlation unreliable. |
| **Root cause** | Time-zone and clock drift between the Ubuntu SIEM and the Windows hosts. |
| **Fix** | **Windows:** `Set-TimeZone -Id "Eastern Standard Time"` then `w32tm /resync /force`. **Splunk server:** `sudo timedatectl set-timezone America/New_York`, plus an explicit `TZ` in `props.conf` ([`configs/splunk/props.conf`](../configs/splunk/props.conf)), then restart Splunk. |
| **Verification** | Event times match the host clocks. |

---

## 9. Entra Connect Express install synced nothing

| | |
|---|---|
| **Symptom** | No on-prem users appeared in Entra ID after an Express install. |
| **Fix** | Reinstall with **Customize**: Password Hash Sync, a new least-privilege connector account, continue without verified UPN suffixes, and explicit OU filtering. See [Module 03](03-active-directory-iam.md#4-hybrid-identity--microsoft-entra-connect-sync). |
