# Enterprise Hybrid Cloud SOC & Hardened Detection Range

An end-to-end enterprise network and detection testing ground designed to simulate hybrid identity lifecycles, perimeter boundary defense, adversary credential attacks, and dual-SIEM ingestion.

---

## 🏛️ Topology & Architecture
*(Add your Draw.io architecture diagram here)*  
![Network Topology](images/topology.png)

### Core Segments
* **Perimeter & DNS Defense:** Bare-metal Raspberry Pi running Pi-hole DNS sinkhole (~25% block rate), hardened with UFW and Fail2ban IPS.
* **Hypervisor Layer:** Proxmox VE running on repurposed bare metal with ZFS RAID 1 storage redundancy.
* **Network Segmentation:** Virtualized pfSense gateway routing between `vmbr0` (Management WAN) and `vmbr1` (Isolated SOC Range: `192.168.10.0/24`) with strict outbound NAT and lateral movement blocking.
* **Identity & Directory Services (IAM):** Windows Server 2022 Active Directory (`percy.local`) synchronized with Microsoft Entra ID via Entra Connect Sync (Password Hash Synchronization).
* **Dual-SIEM Telemetry Pipeline:** Simultaneous host and domain auditing using Sysmon and Splunk Universal Forwarders to Splunk Enterprise (on-prem, port 9997) and Microsoft Sentinel (cloud, via Azure Arc & AMA DCRs).

---

## 🛠️ Tech Stack & Tooling
* **Hypervisor & Networking:** Proxmox VE, pfSense, Linux Bridges (`vmbr0`/`vmbr1`), Tailscale Mesh VPN
* **Operating Systems:** Windows Server 2022, Windows 10 Enterprise, Ubuntu Server, Kali Linux, Raspberry Pi OS
* **Security & SIEM:** Splunk Enterprise, Microsoft Sentinel, Sysmon (Olaf Hartong Schema), Pi-hole, Fail2ban, UFW
* **Adversary Simulation:** MITRE ATT&CK Framework (T1110), Hydra, Metasploit Framework, Nmap, Atomic Red Team
* **Automation & Scripting:** PowerShell (Active Directory provisioning), Bash, Docker

---

## 📖 Step-by-Step Documentation Modules

1. [Proxmox Virtualization & Storage Optimization](docs/01-proxmox-virtualization.md)
   * Setup of virtual bridges, pfSense gateway rules, and resolving Windows VirtIO SCSI I/O delay.
2. [Network Pi & Boundary Hardening](docs/02-network-pi-perimeter.md)
   * Port remapping (6767), Fail2ban jail configurations, and Pi-hole upstream filtering.
3. [Active Directory & Hybrid Cloud IAM](docs/03-active-directory-iam.md)
   * PowerShell-automated OU architecture, user provisioning, Entra Connect setup, and scoped Azure RBAC roles.
4. [Threat Emulation & MITRE ATT&CK Triage](docs/04-threat-emulation-mitre.md)
   * Executing Hydra RDP and Metasploit SMB credential attacks; triaging Event IDs `4624`, `4625`, `4720`, and `4740`.
5. [Engineering Troubleshooting & Fixes](docs/05-troubleshooting-playbooks.md)
   * Detailed root-cause analyses for Bash UPN parsing errors, firewall drop rules, and time drift corrections.
6. [Containerized Microservices](docs/06-docker-services.md)
   * Deploying Docker workloads (Jellyfin, AdGuard) on segmented internal bridges.

---

## 🔒 Redaction & Sanitization Notice
All sensitive infrastructure values—including public WAN IP addresses, Azure Subscription/Tenant GUIDs, private keys, and administrative secrets—have been sanitized and replaced with RFC documentation blocks or generic placeholders (`<REDACTED>`).
