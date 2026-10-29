# Enterprise Hybrid Cloud SOC & Hardened Detection Range

A self-built enterprise network and detection lab that simulates a hybrid identity environment (on-prem Active Directory synced to Microsoft Entra ID), defends its perimeter, and feeds endpoint telemetry into **two SIEMs at once** — Splunk Enterprise on-prem and Microsoft Sentinel in Azure — to detect and triage credential attacks mapped to MITRE ATT&CK.

---

## Architecture

![Enterprise Network & Security Architecture](<Network Infrastructure.png>)

### Core Segments
* **Perimeter & DNS defense** – Bare-metal Raspberry Pi running a Pi-hole DNS sinkhole (~26% of queries blocked), hardened with key-only SSH, UFW and Fail2ban.
* **Hypervisor layer** – Proxmox VE on repurposed hardware with ZFS RAID 1 (mirrored) storage.
* **Network segmentation** – Virtualized pfSense gateway between `vmbr0` (home / management) and `vmbr1` (isolated SOC range, `192.168.10.0/24`) with outbound NAT and rules that block lateral movement into the home network.
* **Identity & access** – Windows Server 2022 Active Directory synced to Microsoft Entra ID via Entra Connect (Password Hash Sync), plus least-privilege custom Azure RBAC roles.
* **Dual-SIEM telemetry** – Sysmon + Splunk Universal Forwarder → Splunk Enterprise (TCP 9997), and Azure Arc + Azure Monitor Agent → Microsoft Sentinel using a filtered Data Collection Rule.

---

## Tech Stack

| Area | Tools |
|---|---|
| Virtualization & networking | Proxmox VE, ZFS, pfSense, Linux bridges, Tailscale |
| Operating systems | Windows Server 2022, Windows 10 Enterprise, Ubuntu Server, Kali Linux, Raspberry Pi OS |
| Identity & cloud | Active Directory DS, Microsoft Entra ID, Entra Connect Sync, Azure RBAC, Azure Arc |
| Security & SIEM | Splunk Enterprise, Microsoft Sentinel, Sysmon (Olaf Hartong config), Pi-hole, Fail2ban, UFW |
| Adversary simulation | MITRE ATT&CK, Atomic Red Team, Nmap, Kali tooling |
| Automation | PowerShell, Bash, Docker |

---

## Documentation

| # | Module | Highlights |
|---|---|---|
| 1 | [Proxmox Virtualization & Storage](docs/01-proxmox-virtualization.md) | ZFS mirror, zero-trust VM firewall rules, pfSense segmentation, VirtIO tuning |
| 2 | [Network Pi & Boundary Hardening](docs/02-network-pi-perimeter.md) | Key-only SSH, Fail2ban (aggressive mode), default-deny UFW, Pi-hole, Tailscale |
| 3 | [Active Directory & Hybrid Cloud IAM](docs/03-active-directory-iam.md) | Scripted OU/user build, Entra Connect, custom RBAC role, Splunk + Sentinel pipelines |
| 4 | [Threat Emulation & Detection Triage](docs/04-threat-emulation-mitre.md) | ATT&CK mapping, Event IDs 4624/4625/4720/4740, Splunk searches |
| 5 | [Troubleshooting Playbooks](docs/05-troubleshooting-playbooks.md) | Nine root-cause analyses: DNS, boot devices, SSH overrides, firewall profiles, time drift |
| 6 | [Containerized Services](docs/06-docker-services.md) | Docker host VM and Jellyfin |

---

## Repository Layout

```
.
├── README.md
├── Network Infrastructure.png      # architecture diagram
├── docs/                           # step-by-step build and analysis write-ups
├── screenshots/                    # evidence for each module (sensitive values blurred)
├── scripts/
│   ├── Populate-ADUsers.ps1        # builds OUs + fictional users
│   └── Set-UserDepartments.ps1     # syncs Department attribute, triggers Entra sync
└── configs/
    ├── splunk/inputs.conf          # Universal Forwarder event sources
    ├── splunk/props.conf           # time-zone fix
    └── fail2ban/jail.local         # SSH jail
```

---

## Reproducing the Lab

**Hardware:** any x86 machine with VT-x and two SSDs for the ZFS mirror (16 GB+ RAM recommended), and a Raspberry Pi for DNS.

1. **Hypervisor** – Install Proxmox VE on ZFS RAID 1 and create `vmbr1` → [Module 1](docs/01-proxmox-virtualization.md)
2. **Perimeter** – Build and harden the Pi, then install Pi-hole → [Module 2](docs/02-network-pi-perimeter.md)
3. **Gateway** – Deploy pfSense (WAN `vmbr0`, LAN `vmbr1`) and the lab VMs → [Module 1](docs/01-proxmox-virtualization.md#4-pfsense-gateway--isolated-soc-range)
4. **Identity** – Promote the DC, run `scripts/Populate-ADUsers.ps1`, join the target, and set up Entra Connect → [Module 3](docs/03-active-directory-iam.md)
5. **Telemetry** – Install Sysmon + Splunk UF with `configs/splunk/inputs.conf`, then onboard to Sentinel via Azure Arc → [Module 3](docs/03-active-directory-iam.md#6-dual-siem-telemetry-pipeline)
6. **Validate** – Generate activity and triage it in both SIEMs → [Module 4](docs/04-threat-emulation-mitre.md)

---

## Sanitization Notice

This is a sanitized public copy. Passwords, API tokens, Azure subscription/tenant/object IDs, account emails, usernames, MAC addresses, Wi-Fi names and the custom SSH port have been removed or replaced with placeholders such as `YOUR_USER`, `YOUR_TENANT` and `<CUSTOM_SSH_PORT>`, and are blurred in screenshots. Private RFC 1918 addresses (`192.168.x.x`, `10.x.x.x`) are kept so the docs match the diagram — they are not reachable from the internet. All AD users are fictional.

---

**Designed and built by David Lau**
